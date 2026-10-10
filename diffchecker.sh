#!/bin/bash
#
# diffchecker.sh
#
# Description: Ce script compare deux répertoires pour les différences de fichiers et de contenu.
#
# Codes de retour (comme diff) :
#   0 : répertoires identiques (ou statistiques seules avec -c)
#   1 : des différences ont été trouvées
#   2 : erreur d'utilisation ou répertoire introuvable

set -uo pipefail

# Fonction affichant comment utiliser le script et ses options.
usage() {
    echo "Usage: $0 [-c] [-d] [-o fichier] [-e motif]... [-h] <source_directory> <destination_directory>"
    echo "  -c : Calculer uniquement les statistiques des répertoires."
    echo "  -d : Générer un rapport détaillé (incluant la comparaison du contenu des fichiers)."
    echo "  -o : Fichier du rapport détaillé (défaut : report_<date>.txt dans le répertoire courant)."
    echo "  -e : Exclure les fichiers/répertoires correspondant au motif (glob, ex: \"*.log\")."
    echo "       L'option peut être répétée."
    echo "  -h : Afficher ce message d'aide."
}

# Initialisation des variables pour les options.
calculate_stats_only=false
detailed_report=false
report_file=""
exclude_patterns=()

# Lecture des options de ligne de commande et affectation aux variables.
while getopts "cde:o:h" opt; do
    case $opt in
        c) calculate_stats_only=true ;;      # Option pour calculer uniquement les statistiques.
        d) detailed_report=true ;;           # Option pour générer un rapport détaillé.
        e) exclude_patterns+=("$OPTARG") ;;  # Option pour exclure certains fichiers/répertoires.
        o) report_file=$OPTARG ;;            # Option pour choisir le fichier de rapport.
        h) usage; exit 0 ;;                  # Option pour afficher l'aide.
        ?) usage >&2; exit 2 ;;              # Option inconnue : aide sur la sortie d'erreur.
    esac
done

# Ajustement des paramètres positionnels (chemins des répertoires).
shift $((OPTIND -1))

# Vérification du nombre d'arguments (doit être 2).
if [ "$#" -ne 2 ]; then
    usage >&2
    exit 2
fi

# Attribution des répertoires source et destination (sans "/" final, pour que
# les chemins affichés par diff soient prévisibles).
source_dir=${1%/}
dest_dir=${2%/}
[ -n "$source_dir" ] || source_dir=/
[ -n "$dest_dir" ] || dest_dir=/
[ -n "$report_file" ] || report_file="report_$(date +%Y%m%d_%H%M%S).txt"

# Vérification de l'existence des répertoires.
for dir in "$source_dir" "$dest_dir"; do
    if [ ! -d "$dir" ]; then
        echo "Erreur : répertoire introuvable : $dir" >&2
        exit 2
    fi
done

# Les mêmes exclusions s'appliquent partout : au comptage (find), au calcul
# de taille (du) et à la comparaison (diff). Comme `diff -x`, un motif porte
# sur le nom d'un fichier ou d'un répertoire, à n'importe quelle profondeur.
find_excludes=()
du_excludes=()
diff_excludes=()
for pattern in "${exclude_patterns[@]}"; do
    [ "${#find_excludes[@]}" -gt 0 ] && find_excludes+=(-o)
    find_excludes+=(-name "$pattern")
    du_excludes+=("--exclude=$pattern")
    diff_excludes+=(-x "$pattern")
done

# Fonction pour calculer et afficher les statistiques d'un répertoire.
calculate_directory_stats() {
    local dir=$1
    local total_size total_files

    total_size=$(du -sh "${du_excludes[@]}" "$dir" 2>/dev/null | cut -f1)
    if [ "${#find_excludes[@]}" -eq 0 ]; then
        total_files=$(find "$dir" -type f 2>/dev/null | wc -l)
    else
        # -prune : un répertoire exclu n'est pas parcouru du tout
        total_files=$(find "$dir" \( "${find_excludes[@]}" \) -prune -o -type f -print 2>/dev/null | wc -l)
    fi

    # Affichage des statistiques.
    echo "Répertoire : $dir"
    echo "Poids total : $total_size"
    echo "Nombre total de fichiers : $total_files"
    echo ""
}

# Résultats de la comparaison (remplis par compare_directories).
only_in_source=()
only_in_dest=()
content_differs=()
other_differences=()

# Compare les deux répertoires en un seul passage de diff et classe chaque
# différence. LC_ALL=C garantit des messages dans une langue fixe.
compare_directories() {
    local line dir name rest rel_len
    while IFS= read -r line; do
        if [[ "$line" =~ ^Only\ in\ (.*):\ ([^/]*)$ ]]; then
            dir=${BASH_REMATCH[1]}
            name=${BASH_REMATCH[2]}
            # Comparaison exacte du chemin (et non par préfixe : "a" ne doit
            # pas capter les lignes de "ab").
            if [ "$dir" = "$source_dir" ] || [[ "$dir" == "$source_dir"/* ]]; then
                only_in_source+=("$dir/$name")
            else
                only_in_dest+=("$dir/$name")
            fi
        elif [[ "$line" == "Files $source_dir/"*" differ" ]]; then
            # "Files <source>/<rel> and <dest>/<rel> differ" : <rel> apparaît
            # deux fois, on en déduit sa longueur sans dépendre de son contenu.
            rest=${line#"Files $source_dir/"}
            rest=${rest%" differ"}
            rel_len=$(( (${#rest} - ${#dest_dir} - 6) / 2 ))
            content_differs+=("${rest:0:rel_len}")
        elif [ -n "$line" ]; then
            # Types différents (fichier d'un côté, répertoire de l'autre), etc.
            other_differences+=("$line")
        fi
    done < <(LC_ALL=C diff -rq --no-dereference "${diff_excludes[@]}" "$source_dir" "$dest_dir" 2>&1)
}

# Affiche les différences classées par compare_directories.
print_differences() {
    local total=$(( ${#only_in_source[@]} + ${#only_in_dest[@]} + ${#content_differs[@]} + ${#other_differences[@]} ))

    if [ "$total" -eq 0 ]; then
        echo "Les deux répertoires sont identiques."
        echo ""
        return
    fi

    if [ "${#only_in_source[@]}" -gt 0 ]; then
        echo "Fichiers/répertoires présents dans $source_dir mais absents dans $dest_dir (${#only_in_source[@]}) :"
        printf '%s\n' "${only_in_source[@]}"
        echo ""
    fi
    if [ "${#only_in_dest[@]}" -gt 0 ]; then
        echo "Fichiers/répertoires présents dans $dest_dir mais absents dans $source_dir (${#only_in_dest[@]}) :"
        printf '%s\n' "${only_in_dest[@]}"
        echo ""
    fi
    if [ "${#content_differs[@]}" -gt 0 ]; then
        echo "Fichiers présents des deux côtés mais au contenu différent (${#content_differs[@]}) :"
        printf '%s\n' "${content_differs[@]}"
        echo ""
    fi
    if [ "${#other_differences[@]}" -gt 0 ]; then
        echo "Autres différences (${#other_differences[@]}) :"
        printf '%s\n' "${other_differences[@]}"
        echo ""
    fi
    echo "Total : $total différence(s)."
    echo ""
}

# Fonction pour comparer le contenu des fichiers communs aux deux répertoires.
compare_file_contents() {
    echo "Comparaison du contenu des fichiers :"
    LC_ALL=C diff -ru --no-dereference "${diff_excludes[@]}" "$source_dir" "$dest_dir"
    echo ""
}

# Exécution des calculs et affichage des statistiques pour chaque répertoire si demandé.
if $calculate_stats_only; then
    calculate_directory_stats "$source_dir"
    calculate_directory_stats "$dest_dir"
    exit 0
fi

# Comparaison de base : statistiques et différences de fichiers/répertoires.
# Tout est calculé une seule fois, puis réutilisé pour le rapport.
summary=$(
    calculate_directory_stats "$source_dir"
    calculate_directory_stats "$dest_dir"
)
compare_directories
differences=$(print_differences)

printf '%s\n\n%s\n' "$summary" "$differences"

# Comparaison des contenus des fichiers et génération du rapport détaillé si demandé.
if $detailed_report; then
    if ! {
        printf '%s\n\n%s\n\n' "$summary" "$differences"
        compare_file_contents
    } > "$report_file"; then
        echo "Erreur : impossible d'écrire le rapport dans $report_file" >&2
        exit 2
    fi
    echo "Rapport généré à : $report_file"
fi

total_differences=$(( ${#only_in_source[@]} + ${#only_in_dest[@]} + ${#content_differs[@]} + ${#other_differences[@]} ))
[ "$total_differences" -eq 0 ]
