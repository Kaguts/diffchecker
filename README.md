
# Diffchecker

diffchecker est un script Bash pour comparer deux répertoires afin d'identifier les différences en termes de fichiers et de contenu.

## Fonctionnalités

- Calcule et affiche les statistiques des répertoires (taille totale, nombre total de fichiers).
- Compare deux répertoires pour trouver les fichiers/répertoires présents dans l'un mais absents dans l'autre.
- Option pour générer un rapport détaillé, y compris la comparaison du contenu des fichiers.
- Possibilité d'exclure certains fichiers ou répertoires de la comparaison.

## Utilisation

Pour utiliser diffchecker, lancez le script avec les options suivantes :

```bash
./diffchecker.sh [-c] [-d] [-e exclude_pattern] [-h] <source_directory> <destination_directory>
```

### Options

- `-c` : Calcule uniquement les statistiques des répertoires sans faire de comparaison.
- `-d` : Génère un rapport détaillé incluant la comparaison du contenu des fichiers.
- `-e` : Exclut les fichiers/répertoires correspondant au motif spécifié.
- `-h` : Affiche l'aide et explique l'utilisation du script.

### Exemples

Calculer uniquement les statistiques des répertoires :

```bash
./diffchecker.sh -c /chemin/source /chemin/destination
```

Générer un rapport détaillé :

```bash
./diffchecker.sh -d /chemin/source /chemin/destination
```

Exclure certains fichiers de la comparaison :

```bash
./diffchecker.sh -e "*.log" /chemin/source /chemin/destination
```

## Installation

Clonez ce dépôt Git et rendez le script exécutable :

```bash
git clone <url_du_dépôt>
cd <nom_du_dépôt>
chmod +x diffchecker.sh
```

## Contribution

Les contributions au projet sont les bienvenues. Veuillez créer une issue ou une pull request pour suggérer des améliorations ou des corrections.

## Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.
```
