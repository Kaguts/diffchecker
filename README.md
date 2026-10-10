
# Diffchecker

diffchecker est un script Bash pour comparer deux répertoires afin d'identifier les différences en termes de fichiers et de contenu.

## Fonctionnalités

- Calcule et affiche les statistiques des répertoires (taille totale, nombre total de fichiers).
- Compare deux répertoires et classe les différences :
  - fichiers/répertoires présents dans l'un mais absents dans l'autre ;
  - fichiers présents des deux côtés mais au contenu différent ;
  - autres cas (fichier d'un côté, répertoire de l'autre...).
- Option pour générer un rapport détaillé, y compris la comparaison du contenu des fichiers.
- Possibilité d'exclure certains fichiers ou répertoires, de façon identique pour les statistiques et pour la comparaison.
- Code de retour exploitable dans un script ou une tâche planifiée.

## Prérequis

Bash et les outils GNU `diff`, `find` et `du` (présents par défaut sur Debian, Ubuntu, RHEL et dérivés).

## Utilisation

Pour utiliser diffchecker, lancez le script avec les options suivantes :

```bash
./diffchecker.sh [-c] [-d] [-o fichier] [-e motif]... [-h] <source_directory> <destination_directory>
```

### Options

- `-c` : Calcule uniquement les statistiques des répertoires sans faire de comparaison.
- `-d` : Génère un rapport détaillé incluant la comparaison du contenu des fichiers.
- `-o` : Chemin du rapport détaillé (par défaut `report_<date>.txt` dans le répertoire courant).
- `-e` : Exclut les fichiers/répertoires dont le nom correspond au motif, à n'importe quelle profondeur. L'option peut être répétée.
- `-h` : Affiche l'aide et explique l'utilisation du script.

### Codes de retour

| Code | Signification |
|---|---|
| `0` | Répertoires identiques (ou statistiques seules avec `-c`) |
| `1` | Des différences ont été trouvées |
| `2` | Erreur d'utilisation, répertoire introuvable ou rapport impossible à écrire |

### Exemples

Comparaison de base (statistiques des deux répertoires et liste des fichiers/répertoires différents) :

```bash
./diffchecker.sh /chemin/source /chemin/destination
```

Calculer uniquement les statistiques des répertoires :

```bash
./diffchecker.sh -c /chemin/source /chemin/destination
```

Générer un rapport détaillé dans un fichier choisi :

```bash
./diffchecker.sh -d -o /tmp/rapport.txt /chemin/source /chemin/destination
```

Exclure certains fichiers et répertoires de la comparaison :

```bash
./diffchecker.sh -e "*.log" -e ".git" /chemin/source /chemin/destination
```

Vérifier une copie dans un script :

```bash
if ./diffchecker.sh /chemin/source /chemin/copie > /dev/null; then
    echo "Copie conforme"
fi
```

### Remarques

- Les liens symboliques sont comparés en tant que liens (leur cible n'est pas suivie).
- Les noms de fichiers contenant un retour à la ligne ne sont pas gérés.

## Installation

Clonez ce dépôt Git et rendez le script exécutable :

```bash
git clone https://github.com/Kaguts/diffchecker.git
cd diffchecker
chmod +x diffchecker.sh
```

## Contribution

Les contributions au projet sont les bienvenues. Veuillez créer une issue ou une pull request pour suggérer des améliorations ou des corrections.

## Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.
