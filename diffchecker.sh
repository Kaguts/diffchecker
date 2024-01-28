#!/bin/bash
# 
# diffchecker.sh
#
# Description: Ce script compare deux répertoires pour les différences de fichiers et de contenu.

# Fonction affichant comment utiliser le script et ses options.
usage() {
    echo "Usage: $0 [-c] [-d] [-e exclude_pattern] [-h] <source_directory> <destination_directory>"
    echo "  -c : Calculer uniquement les statistiques des répertoires."
    echo "  -d : Générer un rapport détaillé (incluant la comparaison du contenu des fichiers)."
    echo "  -e : Exclure les fichiers/répertoires correspondant au motif."
    echo "  -h : Afficher ce message d'aide."
    exit 0
}

# Initialisation des variables pour les options.
calculate_stats_only=false
detailed_report=false
exclude_pattern=""

# Lecture des options de ligne de commande et affectation aux variables.
while getopts "cde:h" opt; do
    case $opt in
        c) calculate_stats_only=true ;;  # Option pour calculer uniquement les statistiques.
        d) detailed_report=true ;;       # Option pour générer un rapport détaillé.
        e) exclude_pattern=$OPTARG ;;    # Option pour exclure certains fichiers/répertoires.
        h) usage ;;                      # Option pour afficher l'aide.
        ?) usage ;;                      # Afficher l'aide en cas d'option inconnue.
    esac
done

# Ajustement des paramètres positionnels (chemins des répertoires).
shift $((OPTIND -1))

# Vérification du nombre d'arguments (doit être 2).
if [ "$#" -ne 2 ]; then
    usage
fi

# Attribution des répertoires source et destination.
source_dir=$1
dest_dir=$2
report_file="report_$(date +%Y%m%d_%H%M%S).txt"

# Vérification de l'existence des répertoires.
if [ ! -d "$source_dir" ] || [ ! -d "$dest_dir" ]; then
    echo "Erreur : Répertoires non trouvés."
    exit 1
fi

# Fonction pour calculer et afficher les statistiques d'un répertoire.
calculate_directory_stats() {
    local dir=$1
    local total_size=$(du -sh "$dir" | cut -f1)  # Calcul de la taille totale.
    local total_files                           # Variable pour le nombre total de fichiers.

    # Calcul du nombre de fichiers, en excluant ceux correspondant au motif si spécifié.
    if [ -z "$exclude_pattern" ]; then
        total_files=$(find "$dir" -type f | wc -l)
    else
        total_files=$(find "$dir" -type f | grep -vE "$exclude_pattern" | wc -l)
    fi

    # Affichage des statistiques.
    echo "Répertoire : $dir"
    echo "Poids total : $total_size"
    echo "Nombre total de fichiers : $total_files"
    echo ""
}

# Fonction pour trouver les différences entre les répertoires.
find_differences() {
    local source=$1
    local destination=$2

    # Capture des différences entre les répertoires source et destination.
    local diff_source_to_dest=$(diff -r "$source" "$destination" | grep "^Seulement dans $source")
    local diff_dest_to_source=$(diff -r "$destination" "$source" | grep "^Seulement dans $destination")

    # Vérification et affichage des différences.
    if [ -z "$diff_source_to_dest" ] && [ -z "$diff_dest_to_source" ]; then
        echo "Les deux répertoires sont identiques."
    else
        # Affichage des fichiers/répertoires manquants dans chaque direction.
        if [ ! -z "$diff_source_to_dest" ]; then
            echo "Fichiers/répertoires présents dans $source mais absents dans $destination :"
            echo "$diff_source_to_dest" | sed "s/^Seulement dans \(.*\): /\1\//"
            echo ""
        fi
        if [ ! -z "$diff_dest_to_source" ]; then
            echo "Fichiers/répertoires présents dans $destination mais absents dans $source :"
            echo "$diff_dest_to_source" | sed "s/^Seulement dans \(.*\): /\1\//"
            echo ""
        fi
    fi
}

# Exécution des calculs et affichage des statistiques pour chaque répertoire si demandé.
if $calculate_stats_only; then
    calculate_directory_stats "$source_dir"
    calculate_directory_stats "$dest_dir"
    find_differences "$source_dir" "$dest_dir"
    exit 0
fi

# Comparaison des contenus des fichiers et génération du rapport détaillé si demandé.
if $detailed_report; then
    calculate_directory_stats "$source_dir"
    calculate_directory_stats "$dest_dir"
    compare_file_contents "$source_dir" "$dest_dir"
    echo "Rapport généré à : $report_file"
fi