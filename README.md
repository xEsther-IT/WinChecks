# WinChecks
WinChecks est un script PowerShell qui effectue des contrôles de sécurité sur un système d'exploitation Windows en vérifiant l'état de Windows Defender. Le script génère ensuite un rapport avec les résultats et l'envoie dans un fichier texte. Cet outil permet de vérifier rapidement le niveau de sécurité d'un système Windows et d'identifier tout problème potentiel à résoudre. Utilisation à vos propres risques et périls.

Créé par @xesther.meza.

# Clause de non-responsabilité 
Ce script est fourni tel quel et sans garantie. Vous l'utilisez à vos risques et périls. L'auteur décline toute responsabilité en cas de dommages ou de pertes causés par l'utilisation de ce script..

# Avant commencer
1. Téléchargez les fichiers WinChecks.psd1 et WinChecks.psm1, soit en cliquant sur le bouton Download, soit en clonant le dépôt GitHub https://github.com/xEsther-IT/WinChecks 
2. Enregistrez les deux fichiers dans un répertoire de votre choix.
3. Ouvrez PowerShell en tant qu'administrateur.
4. Naviguez jusqu'au répertoire du module. C'est dans le répertoire où vous avez enregistré les fichiers WinChecks.psd1 et WinChecks.psm1 que vous devez naviguer.
5. Pour commencer, exécutez la commande PowerShell comme suit : 

# Installation du module 
📫 Pour installer le module WinChecks, exécutez la commande suivante dans PowerShell :
==
Install-Module -Name WinChecks
==

# Importation du module
📫 Une fois le module installé, utilisez la commande suivante pour l'importer :
Import-Module .\WinChecks.psd1 -Force

# Lancer le menu principal 
📫 En frances : 
start-WinCheks
start-WinCheks -laguage “fr”

📫 En anglais: 
start-WinCheks -laguage “en” 

📫 En espanol: 
start-WinCheks -laguage “es”

# Sortie attendue
Le script générera un rapport détaillant l'état de la sécurité de votre système, y compris des informations sur Windows Defender, et l'enverra dans un fichier texte. Vous pourrez alors analyser ce fichier pour identifier toute vulnérabilité ou tout problème potentiel.

# Module Windows-Security-Checks v1.0.6 Created by @xesther.meza 
Ce script PowerShell effectue des contrôles de sécurité sur un système Windows

    === Menu des options ===
    1. Vérifier les prérequis minimaux pour l'exécution du module WinChecks
    2. Afficher les informations système de base
    3. Lister les utilisateurs locaux et leurs groupes
    4. Lister les applications installées
    5. Lister Informations sur WindowsDefender (Antivirus)
    6. ---Configurer WindowsDefender Security
       ---ATTENTION : option 6 Modifie le registre de Windows
    7. Générer un rapport système complet
    0. Quitter
    ======================== + 
