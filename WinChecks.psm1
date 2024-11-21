#
# Module PowerShell effectue des contrôles de sécurité sur un système Windows. 
# Il génère un rapport avec les résultats et l'envoie dans un fichier texte. 
# Celui-ci peut être utilisé pour vérifier rapidement le niveau de sécurité d'un système Windows
# et identifier les problèmes potentiels à résoudre.

#Versioning de la configuration
#Release Notes
#v1.0.4 - 2024-11-21-5:04
# - Functions : Start-WinChecks / Show-WinCheksMenu - Pour creer une menu avec les commandes disponibles dans le module
# - Function : Get-WinCheckMinimumRequired - Pour verifier minimums (powerShell 7.4, bypass, executer as admin) avant utilisation du module pour assurer les prérequis.
# - Renomer funtions pour respecter les bonnes pratiques pour le module WinCheck 
# - - Get-SystemReport -> Get-WinCheckReport
# - - Get-BasicSystemInfo -> Get-WinCheckBasicSystemInfo
# - - Get-LocalUserGroups -> Get-WinCheckLocalUserGroups
# - - Write-Log -> Write-WinCheckLog
#v1.0.3 - 2024-11-20-4:37
# - Les vérifications (« checks ») ont été séparées en fonctions distinctes.
# - Function : Get-WinCheckBasicSystemInfo - Pour
# - Function : Get-WinCheckLocalUserInGroups - Pour 
# - Function : Get-WinCheckInstalledApplications - Pour 
#v1.0.2 - 2024-11-19-23:51
# - Creation des variables gobales ($scriptVersion, $language)
# - Correction des erreurs mineures de traduction « fr » - « es » - « en » 
# - Correction des noms de quelques variables pour respecter les bonnes pratiques.
#v1.0.1 - 2024-11-18-6:28 
# - Nom de fichier SystemReport avec la date LogName = 'SystemReport'+$date+'.txt'  
#v1.0.0 - 2024-11-17 10:30
# - Première version du module WinChecks.psm1
# - Function Get-WinCheckSystemReport
# - Function Write-WinCheckLog

# # # VARIABLES GLOBALES # # #
$moduleVersion = "v1.0.4"
#$moduleDate = [datetime]::ParseExact("2024-09-08-11:00", 'yyyy-MM-dd-HH:mm', $null)
# $language = "fr" - Francais par default. Options : "es" - Espanol, "en" - English
$global:language = "fr"

function Start-WinChecks { # Fonction principale pour afficher le menu et exécuter les choix
# Exemple d'utilisation 
# # Pour générer un rapport en français
# PS> Start-WinChecks -Language "fr"  -or  Start-WinChecks 
# # Pour générer un rapport en anglais
# PS> Start-WinChecks -Language "en"
# # Pour générer un rapport en espagnol
# PS> Start-WinChecks -Language "es"
    param (
        # Si aucune valeur n'est passée, utiliser la variable globale
        [string]$language = "fr"
    )
    # Définir une variable globale:langue dans le module
    $global:language = $language

    do {
        # Afficher les options du menu
        Write-Host "Module Windows-Security-Checks $moduleVersion Created by @xesther.meza "  -ForegroundColor Cyan
        Write-Host "This PowerShell script performs security checks on a Windows system" + "`n"
        Show-WinCheksMenu
        
        switch ($language) {
            "fr" { $choice = Read-Host "Choisissez une option" }
            "es" { $choice = Read-Host "Elija una opción" }
            "en" { $choice = Read-Host "Choose an option" }
        }

        # Traiter le choix de l'utilisateur et exécuter la fonction correspondante
        switch ($choice) {
            "1" { Get-WinCheckMinimumRequired }
            "2" { Get-WinCheckBasicSystemInfo }
            "3" { Get-WinCheckLocalUserInGroups }
            "4" { Get-WinCheckInstalledApplications }
            "5" { Get-WinCheckSystemReport }
            "0" { Write-Host "Exit..." -ForegroundColor Yellow; break }
            default { Write-Host "Invalid choice, please try again." -ForegroundColor Red }
        }

        Read-Host "Press Enter to continue..."
        Clear-Host
    } while ($choice -ne "0")


} # END function Start-WinChecks

function Show-WinCheksMenu { # function Show-WinCheksMenu qui affiche un menu d'options basé sur la langue definit. 
# Exemple d'utilisation
# Show-Menu
    $menuFr = @"
    === Menu des options ===
    1. Vérifier les prérequis minimaux pour l'exécution du module WinChecks
    2. Afficher les informations système de base
    3. Lister les utilisateurs locaux et leurs groupes
    4. Lister les applications installées
    5. Générer un rapport système complet
    0. Quitter
    ========================
"@

    $menuEs = @"
    === Menú de opciones ===
    1. Verificar los requisitos mínimos de ejecución del módulo WinChecks
    2. Mostrar información básica del sistema
    3. Listar los usuarios locales y sus grupos
    4. Listar las aplicaciones instaladas
    5. Generar un informe completo del sistema
    0. Salir
    ========================
"@

    $menuEn = @"
    === Options Menu ===
    1. Check minimum requirements for running the WinChecks module
    2. Display basic system information
    3. List local users and their groups
    4. List installed applications
    5. Generate a complete system report
    0. Exit
    ========================
"@

    switch ($language) {
        "fr" { Write-Host $menuFr + "`n" }
        "es" { Write-Host $menuEs + "`n" }
        "en" { Write-Host $menuEn + "`n" }
        default { Write-Host $menuFr + "`n" }
    }
} # END function : Show-WinCheksMenu

function Get-WinCheckMinimumRequired { # Fonction pour vérifier les prérequis minimaux 

    # Vérifier la version de PowerShell
    switch ($language) {
        "fr" { Write-Host "## Vérification de la version de PowerShell..." + "`n" }
        "es" { Write-Host "## Verificando de la versión de PowerShell..." + "`n" }
        "en" { Write-Host "## PowerShell version check..." + "`n" }
    }
    $requiredVersion = [Version]"7.4.0"
    $currentVersion = $PSVersionTable.PSVersion
    # Comparer la version actuelle avec la version requise
    
    switch ($language) {
        "fr" { 
            if ($currentVersion -lt $requiredVersion) {
                Write-Host "La version actuelle de PowerShell ($($currentVersion)) est insuffisante. Vous devez avoir PowerShell version 7.4 ou supérieure." -ForegroundColor Red
                Write-Host "Veuillez consulter la documentation pour l'installation de PowerShell 7.4 : https://learn.microsoft.com/fr-fr/powershell/scripting/install/installing-powershell?view=powershell-7.4" -ForegroundColor Yellow
            } else {
                Write-Host "Version de PowerShell : $($currentVersion.Major).$($currentVersion.Minor).$($currentVersion.Build) - Version suffisante pour l'exécution de ce module." -ForegroundColor Green
            }
        }
        "es" { 
            if ($currentVersion -lt $requiredVersion) {
                Write-Host "La versión actual de PowerShell ($($currentVersion)) es insuficiente. Necesita PowerShell versión 7.4 o superior." -ForegroundColor Red
                Write-Host "Por favor, consulte la documentación para la instalación de PowerShell 7.4: https://learn.microsoft.com/fr-fr/powershell/scripting/install/installing-powershell?view=powershell-7.4" -ForegroundColor Yellow
            } else {
                Write-Host "Versión de PowerShell: $($currentVersion.Major).$($currentVersion.Minor).$($currentVersion.Build) - Versión suficiente para ejecutar este módulo." -ForegroundColor Green
            } 
        }
        "en" { 
            if ($currentVersion -lt $requiredVersion) {
                Write-Host "The current version of PowerShell ($($currentVersion)) is insufficient. You must have PowerShell version 7.4 or higher." -ForegroundColor Red
                Write-Host "Please refer to the documentation for installing PowerShell 7.4: https://learn.microsoft.com/fr-fr/powershell/scripting/install/installing-powershell?view=powershell-7.4" -ForegroundColor Yellow
            } else {
                Write-Host "PowerShell version: $($currentVersion.Major).$($currentVersion.Minor).$($currentVersion.Build) - Sufficient version for running this module." -ForegroundColor Green
            }
        }
    }
    

    # Vérifier si l'utilisateur est administrateur
    switch ($language) {
        "fr" { Write-Host "## Vérification des privilèges d'administrateur..." + "`n" }
        "es" { Write-Host "## Verificando los privilegios de administrador..." + "`n" }
        "en" { Write-Host "## Checking administrator privileges..." + "`n" }
    }
    
    $currentUser = $env:USERNAME
    # Write-Host "currentUser:", $currentUser
    $users =  Get-LocalUser | Where-Object { $_.Name -match $($currentUser) }
    $message = Get-WinCheckLocalUserInGroups($users)
    $culture = Get-Culture
    $cultureLanguage = $culture.TwoLetterISOLanguageName
    # Write-Host $cultureLanguage
    
    switch ($cultureLanguage) {
        "fr" { 
            if ($message -match 'Administrateurs') {
                Write-Host "L'utilisateur dispose des privilèges d'administrateur. $message" -ForegroundColor Green
                Write-Host "Assurez-vous d'avoir exécuté PowerShell en tant qu'administrateur." -ForegroundColor Yellow
            } else {
                Write-Host "$message L'utilisateur ne dispose pas des privilèges d'administrateur." -ForegroundColor Red
            }
        }
        "es" { 
            if ($message -match 'Administradores') {
                Write-Host "El usuario tiene privilegios de administrador. $message" -ForegroundColor Green
                Write-Host "Asegúrese de haber ejecutado PowerShell como administrador." -ForegroundColor Yellow
            } else {
                Write-Host "$message El usuario no tiene privilegios de administrador." -ForegroundColor Red
            } 
        }
        "en" { 
            if ($message -match 'Administrators') {
                Write-Host "The user has administrator privileges. $message" -ForegroundColor Green
                Write-Host "Make sure you have run PowerShell as administrator." -ForegroundColor Yellow
            } else {
                Write-Host "$message The user does not have administrator privileges." -ForegroundColor Red
            } 
        }
    }

    # Vérifier la politique d'exécution
    switch ($language) {
        "fr" { Write-Host "## Vérification de la politique d'exécution..." + "`n" }
        "es" { Write-Host "## Verificando la política de ejecución..." + "`n" }
        "en" { Write-Host "## Check execution policy..." + "`n" }
    }
    
    $currentExecutionPolicy = Get-ExecutionPolicy
    $requiredExecutionPolicy = "Bypass"

    switch ($language) {
        "fr" { 
            if ($currentExecutionPolicy -ne $requiredExecutionPolicy) {
                Write-Host "La politique d'exécution actuelle est '$currentExecutionPolicy'. La politique recommandée est '$requiredExecutionPolicy'." -ForegroundColor Red
                Write-Host "La modification de la politique d'exécution en '$requiredExecutionPolicy' est nécessaire pour permettre l'exécution des fonctions du Module-WinCheck." -ForegroundColor Yellow
                Write-Host "Si vous êtes d'accord, exécutez la commande PowerShell : Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force" -ForegroundColor Yellow
            } else {
                Write-Host "Politique d'exécution actuelle : $currentExecutionPolicy. Aucune modification nécessaire pour permettre l'exécution des fonctions du Module-WinCheck." -ForegroundColor Green
            }
        }
        "es" { 
            if ($currentExecutionPolicy -ne $requiredExecutionPolicy) {
                Write-Host "La política de ejecución actual es '$currentExecutionPolicy'. La política recomendada es '$requiredExecutionPolicy'." -ForegroundColor Red
                Write-Host "Es necesario modificar la política de ejecución a '$requiredExecutionPolicy' para permitir la ejecución de las funciones del módulo Module-WinCheck." -ForegroundColor Yellow
                Write-Host "Si está de acuerdo, ejecute el siguiente comando de PowerShell: Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force" -ForegroundColor Yellow
            } else {
                Write-Host "Política de ejecución actual: $currentExecutionPolicy. No es necesario realizar ninguna modificación para permitir la ejecución de las funciones del módulo Module-WinCheck." -ForegroundColor Green
            }
        }
        "en" { 
            if ($currentExecutionPolicy -ne $requiredExecutionPolicy) {
                Write-Host "The current execution policy is '$currentExecutionPolicy'. The recommended policy is '$requiredExecutionPolicy'." -ForegroundColor Red
                Write-Host "Changing the execution policy to '$requiredExecutionPolicy' is required to allow the execution of the Module-WinCheck functions." -ForegroundColor Yellow
                Write-Host "If you agree, execute the following PowerShell command: Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force" -ForegroundColor Yellow
            } else {
                Write-Host "Current execution policy: $currentExecutionPolicy. No changes are needed to allow the execution of the Module-WinCheck functions." -ForegroundColor Green
            }
        }
    }
    
} # END de function : Get-WinCheckMinimumRequired 

<# # Fonction pour générer un rapport système complet
.SYNOPSIS
    Générer un rapport contenant les informations de sécurité du système d'exploitation Windows.

.DESCRIPTION
    Get-WinCheckSystemReport.ps1 script PowerShell recherche les détails du matériel de l'ordinateur local et génère un rapport 
    en français, anglais ou espagnol contenant ces informations : 
    ✅ Informations sur le système d'exploitation
    ✅ Informations sur le processeur
    ✅ Informations sur la mémoire RAM
    ✅ Informations sur les adaptateurs réseau
    ✅ Utilisateurs locaux
    ✅ Logiciels installés

.PARAMETER -Language
    Spécifie la langue du rapport. Par défaut, le rapport sera en français. 
    # Options « es » - Espagnol, « en » - Anglais.

.OUTPUTS
    Le script génère un rapport au format txt avec les informations recueillies.
    # .\System_Report_20241116.txt

.EXAMPLE
    # Pour générer un rapport en français
	PS> Get-WinCheckSystemReport 
    
    # Pour générer un rapport en anglais
    PS> Get-WinCheckSystemReport -Language "en"

    # Pour générer un rapport en espagnol
    PS> Get-WinCheckSystemReport -Language "es"
	
.LINK
	https://github.com/xEsther-IT/WinChecks

.NOTES
    1.PowerShell 7.4 en mode administrateur nécessaire.
    2.Import-Module .\WinChecks.psm1
    
    Author: 2024 @xesther.meza | License: MIT
#>
function Get-WinCheckSystemReport { # Fonction pour générer un rapport système complet
    param (
        # Si aucune valeur n'est passée, utiliser la variable globale
        [string]$language = "fr"
    )
    # Format de la date (exemple: "2024-11-17 12:45:30")
    $date = Get-Date -Format "yyyy-MM-dd"

    # Définir les entrées de la fonction Write-WinCheckLog
    $logPath = "C:\Temp\xLuna"              # Répertoire où le fichier de log sera stocké
    $logName= 'SystemReport-'+$date+'.txt'  # Nom du fichier
    $typeMessage = 'Info'                   # Type de message (Info)
    $message = ''                           # Message

    # Créer le répertoire de log si nécessaire
    if (-not (Test-Path -Path $logPath)) {
        New-Item -ItemType Directory -Path $logPath
    }

    # En-tête du rapport
    switch ($language) {
        "fr" { $message += "Rapport d'information système Version :" + $scriptVersion + "`n" }
        "es" { $message += "Reporte de la información del sistema Version :" + $scriptVersion + "`n" }
        "en" { $message += "System Information Report Version :" + $scriptVersion + "`n" }
        default { 
            $message += "Langue " + $language +" non supportée. Le rapport sera présenté en français." + "`n" 
            $message += "Rapport d'information système Version :" + $scriptVersion + "`n"
        }
    }
    $message += "------------------------------------------------------------`n"
    
    # Récupérer les informations de base sur le système
    $message += Get-WinCheckBasicSystemInfo
    $message += "`n"

    # Récupérer la liste des utilisateurs locaux et les groupes auxquels chaque utilisateur local appartient.
    $message += Get-WinCheckLocalUserInGroups
    $message += "`n"

    # Récupérer les applications 
    $message += Get-WinCheckInstalledApplications
    $message += "`n"
    
    # Afficher l'emplacement du rapport
    switch ($language) {
        "fr" { $message += "## Le rapport a été généré et sauvegardé à l'emplacement suivant : " + "`n" }
        "es" { $message += "## El informe se ha generado y guardado en la siguiente ubicación :" + "`n" }
        "en" { $message += "## The report has been generated and saved in the following location : " + "`n" }
    }
    $message += "$logPath\$logName"
    # Écrire le rapport
    Write-WinCheckLog -LogPath $logPath -LogName $logName -Type $typeMessage -Message $message

} # END de function : Get-WinCheckSystemReport

function Get-WinCheckBasicSystemInfo { # Fonction pour obtenir les informations système de base
    # Récupérer les informations de base sur le système
    # - Informations OS
    # - Informations sur le processeur
    # - Informations sur la mémoire RAM
    # - Informations sur les disques
    # - Informations sur les adaptateurs réseau
    # Exemple d'Utilisation :
    # $BasicSystemInfo = Get-WinCheckBasicSystemInfo
    # Write-WinCheckLog $BasicSystemInfo

    $checkMessage = '' 
    
    switch ($language) {
        "fr" {$checkMessage += "## Informations de base sur le système" + "`n"}
        "es" {$checkMessage += "## Información básica de la computadora" + "`n" }
        "en" {$checkMessage += "## Basic System Information" + "`n" }
    }
    $checkMessage += Get-ComputerInfo | Select-Object CsName, OsArchitecture, WindowsVersion, Manufacturer, Model | Format-List | Out-String
    $checkMessage += "`n"

    # Informations OS
    switch ($language) {
        "fr" {$checkMessage += "## Informations sur le système d'exploitation" + "`n" }
        "es" {$checkMessage += "## Información sobre el sistema operativo" + "`n" }
        "en" {$checkMessage += "## Operating System Information" + "`n" }
    }
    $checkMessage += Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object Caption, Version, BuildNumber | Format-List | Out-String
    # $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem 
    # $checkMessage += "OS Name: $($osInfo.Caption)`n"
    # $checkMessage += "Version: $($osInfo.Version)`n"
    # $checkMessage += "Build: $($osInfo.BuildNumber)`n"
    $checkMessage += "`n"

    # Informations sur le processeur
    switch ($language) {
        "fr" {$checkMessage += "## Informations sur le processeur" + "`n" }
        "es" {$checkMessage += "## Información sobre el procesador" + "`n"  }
        "en" {$checkMessage += "## CPU Information" + "`n" }
    }
    $checkMessage += Get-CimInstance -ClassName Win32_Processor | Select-Object Name, NumberOfCores, MaxClockSpeed | Format-List | Out-String
    # $cpuInfo = Get-CimInstance -ClassName Win32_Processor
    # $checkMessage += "CPU Name: $($cpuInfo.Name)`n"
    # $checkMessage += "Cores: $($cpuInfo.NumberOfCores)`n"
    # $checkMessage += "Clock Speed: $($cpuInfo.MaxClockSpeed) MHz`n"
    $checkMessage += "`n"

    # Informations sur la mémoire RAM
    switch ($language) {
        "fr" {$checkMessage += "## Informations sur la mémoire RAM" + "`n" }
        "es" {$checkMessage += "## Información sobre la memoria RAM" + "`n" }
        "en" {$checkMessage += "## RAM Information" + "`n" }
    }
    $memoryInfo = Get-CimInstance -ClassName Win32_PhysicalMemory
    $totalMemory = ($memoryInfo | Measure-Object -Property Capacity -Sum).Sum / 1GB
    $checkMessage += "Total RAM memory: $([math]::round($totalMemory, 2)) Go`n"
    $checkMessage += "`n"

    # Informations sur les disques
    switch ($language) {
        "fr" {$checkMessage += "## Informations sur les disques" + "`n"}
        "es" {$checkMessage += "## Información sobre los discos" + "`n"}
        "en" {$checkMessage += "## Disk Information" + "`n"}
    }
    $diskInfo = Get-CimInstance -ClassName Win32_DiskDrive
    if ($diskInfo) {
        $diskInfo | ForEach-Object {
            # Ajouter les informations du disque physique
            $checkMessage += "Disk Model: " + $_.Model + "`n"
            $checkMessage += "Size: " + [math]::round($_.Size / 1GB, 2) + " GB" + "`n"
            $checkMessage += "Media Type: " + $_.MediaType + "`n"
            # Maintenant on récupère l'espace libre et utilisé à partir des partitions logiques associées
            $partitions = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $_.DeviceID }
            if ($partitions) {
                $partitions | ForEach-Object {
                    $checkMessage += "Drive: " + $_.DeviceID + "`n"
                    $checkMessage += "Free Space: " + [math]::round($_.FreeSpace / 1GB, 2) + " GB" + "`n"
                    $checkMessage += "Total Space: " + [math]::round($_.Size / 1GB, 2) + " GB" + "`n"
                    $checkMessage += "File System: " + $_.FileSystem + "`n"
                    $checkMessage += "`n"
                }
            } else {
                $checkMessage += "No logical disk partitions found." + "`n"
            }
        }
    } else {$checkMessage += "No disk information found." + "`n"}
    $checkMessage += "`n"

    # Informations sur les adaptateurs réseau
    switch ($language) {
        "fr" {$checkMessage += "## Informations sur les adaptateurs réseau" + "`n" }
        "es" {$checkMessage += "## Información sobre los adaptadores de red" + "`n" }
        "en" {$checkMessage += "## Network Adapter Information" + "`n" }
    }
    $networkAdapters = Get-CimInstance -ClassName Win32_NetworkAdapter | Where-Object { $_.NetConnectionStatus -eq 2 }
    # Seulement les adaptateurs connectés
    if ($networkAdapters) {
        $networkAdapters | ForEach-Object {
            # Obtenir l'IP de l'adaptateur réseau
            $adapterConfig = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Where-Object { $_.InterfaceIndex -eq $_.InterfaceIndex }
            $ipAddress = if ($adapterConfig.IPAddress) { $adapterConfig.IPAddress -join ", " } else { "Aucune IP" }
            # Ajouter les informations de l'adaptateur réseau
            $checkMessage += "Adapter Name: " + $_.Name + "`n"
            $checkMessage += "MAC Address: " + $_.MACAddress + "`n"
            $checkMessage += "Adresse IP: " + $ipAddress + " bps" + "`n"
            $checkMessage += "Speed: " + $_.Speed + " bps" + "`n"
        }
    } else {
        $checkMessage += "No connected network adapters found." + "`n" 
        }
    
    return $checkMessage
} # END function : Get-WinCheckBasicSystemInfo
 
function Get-WinCheckLocalUserInGroups { # Fonction pour obtenir les utilisateurs locaux et leurs groupes
    # Récupérer les groupes auxquels chaque utilisateur local appartient.
    # Exemple d'Utilisation:
    # Cas 1 - Filtrer l'utilisateur souhaité
    # $users = Get-LocalUser | Where-Object { $_.Name -match 'Administrator' }
    # $message += Get-LocalUserGroups($users)
    # Cas 2 - Si aucun utilisateur n'est envoyé, la fonction récupère les utilisateurs locaux avec $users = $(Get-LocalUser). 
    # $message += Get-LocalUserGroups 
    param (
        # Si $users est null, récupérer tous les utilisateurs locaux
        [System.Object]$users = $(Get-LocalUser)
    )
      
    $checkMessage = ''

    # Si $users ne contient qu'un seul élément, ne pas imprimer le titre de la section.  
    if($users.Count -gt 1) {
        # Message en fonction de la langue (variable globale)
        switch ($language) {
            "fr" { $checkMessage += "## Liste des utilisateurs locaux." + "`n" }
            "es" { $checkMessage += "## Lista de usuarios locales." + "`n" }
            "en" { $checkMessage += "## List of local users." + "`n" }
        }
    }
    
    # Récupérer tous les groupes et leurs membres avant la boucle pour les utilisateurs
    $groups = Get-LocalGroup
    $groupMembers = @{}
    foreach ($group in $groups) {
        # Récupérer les membres de chaque groupe
        $members = Get-LocalGroupMember -Group $group.Name
        $groupMembers[$group.Name] = $members
    }

    # Boucle pour chaque utilisateur afin d'obtenir les groupes auxquels ils appartiennent
    foreach ($user in $users) {
        # Ajouter le nom de l'utilisateur au rapport
        $checkMessage += "UserName: " + $user.Name
        
        # Extraire uniquement le nom d'utilisateur sans le préfixe du domaine ou de l'ordinateur
        $userName = $user.Name.Split("\")[-1].Trim()
        
        # Initialiser un tableau pour stocker les groupes auxquels cet utilisateur appartient
        $userGroups = @()

        # Vérifier chaque groupeName pour voir si l'utilisateur en fait partie
        foreach ($groupName in $groupMembers.Keys) {
            $members = $groupMembers[$groupName]
            foreach ($member in $members) {
                $memberName = $member.Name.Split("\")[-1]
                
                # Si le membre est égal à l'utilisateur actuel, l'ajouter aux groupes de cet utilisateur.
                if ($memberName -eq $userName) {
                    $userGroups += $groupName
                    break  # L'utilisateur appartient à ce groupe, puis passer au prochain groupe.
                }
            }
        }

        # Ajouter les groupes ou message d'absence de groupes
        if ($userGroups.Count -gt 0) {
            $checkMessage += ": Groups: " + ($userGroups -join ", ") + "`n"
        } else {
            $checkMessage += ": Groups: No security groups found for this user." + "`n"
        }
    }

    return $checkMessage
} # END function : Get-WinCheckLocalUserInGroups

function Get-WinCheckInstalledApplications { # Fonction pour obtenir les applications installées
    # Récupérer les applications 
    # Exemple d'Utilisation :
    # $installedApps = Get-WinCheckInstalledApplications
    # Write-WinCheckLog $installedApps

    $checkMessage = ''
    
    # Message en fonction de la langue (variable globale)
    switch ($language) {
        "fr" { $checkMessage += "## Applications installées (x64)" + "`n" }
        "es" { $checkMessage += "## Aplicaciones instaladas (x64)" + "`n" }
        "en" { $checkMessage += "## Installed applications (x64)" + "`n" }
    }

    # Récupérer les applications 64 bits
    $appList64 = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue
    $appList64Formatted = $appList64 | Where-Object { $_.DisplayName } | 
        Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
        Format-Table -AutoSize | Out-String
    $checkMessage += $appList64Formatted

    # Récupérer les applications 32 bits
    switch ($language) {
        "fr" { $checkMessage += "## Applications installées (x32)" + "`n" }
        "es" { $checkMessage += "## Aplicaciones instaladas (x32)" + "`n" }
        "en" { $checkMessage += "## Installed applications (x32)" + "`n" }
    }

    # Récupérer les applications 32 bits
    $appList32 = Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue
    $appList32Formatted = $appList32 | Where-Object { $_.DisplayName } |
        Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
        Format-Table -AutoSize | Out-String
    $checkMessage += $appList32Formatted

    return $checkMessage
} # END function : Get-WinCheckInstalledApplications

<#
.SYNOPSIS
	Écrire des messages (chains de caracteres) dans un fichier spécifié. 
.DESCRIPTION
	Le script Write-WinCheckLog.ps1 permet d'écrire des messages dans un fichier spécifié tout en affichant les messages dans la console avec une coloration appropriée en fonction du type de message. 
    Ce script permet également de créer des rapports au format texte ou des fichiers de log.
     ℹ️  Info
    ✅ Success
    ❌ Error
    ⚠️ Inconnu

.PARAMETER -LogPath
    Chemin du répertoire où enregistrer le fichier de log
.PARAMETER -LogName
    Nom du fichier
.PARAMETER -Type
    Type de message (Info, Success, Error)
.PARAMETER -Message
    Message à enregistrer

.OUTPUTS
    Affichage dans la console :
    Les messages sont affichés avec une mise en forme spécifique : vert pour Success, rouge pour Error, et standard pour Info.

    Enregistrement dans le fichier de log :
    Le message est écrit dans le fichier de log avec la date () et type ([INFO], [SUCCESS], [ERROR], [INCONNU]), suivi du message.
    exemple: "2024-11-17 12:45:30" [SUCCESS] Ma fonction pour écrire des logs

.EXAMPLE
    # Exemple d'utilisation de la fonction Write-WinCheckLog
    $logPath = "C:\Temp\xLuna"  # Répertoire où le fichier de log sera stocké
    $logName= 'test.log'      # Nom du fichier de log
    $typeMessage = 'Success'         # Type de message (Success)
    $message = 'Ma fonction pour écrire des logs'
    
    # Appel de la fonction Write-WinCheckLog
    # Write-WinCheckLog -LogPath $logPath -LogName $logName -Type $typeMessage -Message $message

.LINK
	https://github.com/xEsther-IT/WinChecks

.NOTES
	Author: 2024 @xesther.meza | License: MIT

#>
Function Write-WinCheckLog { # Fonction pour créer le fichier du rapport
    Param (
        [string]$logPath,   # Chemin du répertoire où enregistrer le fichier de log
        [string]$logName,    # Nom du fichier de log
        [string]$typeMessage,       # Type de message (Info, Success, Error)
        [string]$message     # Message à enregistrer
    )

    # Format de la date (exemple: "2024-11-17 12:45:30")
    $dateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Vérifier que le chemin du log est défini
    If ($logPath) {
        # Vérifier si le répertoire existe, sinon le créer
        If (-Not (Test-Path -Path $logPath)) {
            Try {
                New-Item -Path $logPath -ItemType Directory -Force
                Write-Host -ForegroundColor Green "Le répertoire de log a été créé : $logPath"
            } Catch {
                Write-Host -ForegroundColor Red "Erreur : Impossible de créer le répertoire de log."
                Return
            }
        }

        # Créer le chemin complet du fichier de log
        $LogFilePath = Join-Path -Path $logPath -ChildPath $logName

        # S'assurer que le fichier de log existe, sinon le créer
        If (-Not (Test-Path -Path $LogFilePath)) {
            Try {
                New-Item -Path $LogFilePath -ItemType File -Force
                Write-Host -ForegroundColor Green "Le fichier de log a été créé : $LogFilePath"
            } Catch {
                Write-Host -ForegroundColor Red "Erreur : Impossible de créer le fichier de log."
                Return
            }
        }
    }

    # Fonction pour enregistrer dans le log et afficher dans la console
    Switch ($typeMessage) {
        "Info" {
            # Enregistrer dans le fichier 
            Add-Content -Path $LogFilePath -Encoding 'UTF-8' -Value "$dateTime [INFO] $message"
            # Afficher dans la console
            Write-Host "$dateTime [INFO] $message"
        }

        "Success" {
            # Enregistrer dans le fichier 
            Add-Content -Path $LogFilePath -Encoding 'UTF-8' -Value "$dateTime [SUCCESS] $message"
            # Afficher dans la console en vert (succès)
            Write-Host -ForegroundColor Green "$dateTime [SUCCESS] $message"
        }

        "Error" {
            # Enregistrer dans le fichier 
            Add-Content -Path $LogFilePath -Encoding 'UTF-8' -Value "$dateTime [ERROR] $message"
            # Afficher dans la console en rouge (erreur)
            Write-Host -ForegroundColor Red -BackgroundColor Black "$dateTime [ERROR] $message"
        }

        Default {
            # Enregistrer dans le fichier 
            Add-Content -Path $LogFilePath -Encoding 'UTF-8' -Value "$dateTime [INCONNU] $message"
            # Afficher dans la console en yellow (Inconnu)
            Write-Host -ForegroundColor Yellow "$dateTime [INCONNU] $message"
        }
    }
} # END function : Get-WinCheckInstalledApplications
