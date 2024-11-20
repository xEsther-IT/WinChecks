#
# Module PowerShell effectue des contrôles de sécurité sur un système Windows. 
# Il génère un rapport avec les résultats et l'envoie dans un fichier texte. 
# Celui-ci peut être utilisé pour vérifier rapidement le niveau de sécurité d'un système Windows
# et identifier les problèmes potentiels à résoudre.
#
#Versioning de la configuration
#Release Notes
#v1.0.2 - 2024-11-19 23:51
# - Creation des variables gobales ($scriptVersion, $language)
# - Correction des erreurs mineures de traduction « fr » - « es » - « en » 
# - Correction des noms de quelques variables pour respecter les bonnes pratiques.
#v1.0.1 - 2024-11-18 6:28 
# - Nom de fichier SystemReport avec la date LogName = 'SystemReport'+$date+'.txt'  
#v1.0.0 - 2024-11-17 10:30
# - Première version du module WinChecks.psm1
# - Function Get-SystemReport
# - Function Write-Log

<#
.SYNOPSIS
    Générer un rapport contenant les informations de sécurité du système d'exploitation Windows.

.DESCRIPTION
    Get-SystemReport.ps1 script PowerShell recherche les détails du matériel de l'ordinateur local et génère un rapport 
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
	PS> Get-SystemReport 
    
    # Pour générer un rapport en anglais
    PS> Get-SystemReport -Language "en"

    # Pour générer un rapport en espagnol
    PS> Get-SystemReport -Language "es"
	
.LINK
	https://github.com/xEsther-IT/WinChecks

.NOTES
    1.PowerShell 7.4 en mode administrateur nécessaire.
    2.Import-Module .\WinChecks.psm1
    
    Author: 2024 @xesther.meza | License: MIT
#>
# Global variables
$scriptVersion = "1.0.2"
# $language = "fr" - Francais par default. Options : "es" - Espanol, "en" - English
$language = "fr"

Function Get-SystemReport {
    # param (
    #     [string]$language = "fr"  
    #     # Par défaut, le rapport sera en français options : "es" - Espanol, "en" - English
    # )
    # Format de la date (exemple: "2024-11-17 12:45:30")
    $date = Get-Date -Format "yyyy-MM-dd"

    # Définir les entrées de la fonction Write-Log
    $logPath = "C:\Temp\xLuna"              # Répertoire où le fichier de log sera stocké
    $logName= 'SystemReport-'+$date+'.txt'   # Nom du fichier
    $typeMessage = 'Info'                          # Type de message (Info)
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
    
    # Informations système de base
    switch ($language) {
        "fr" {$message += "## Informations de base sur le système" + "`n"}
        "es" {$message += "## Información básica de la computadora" + "`n" }
        "en" {$message += "## Basic System Information" + "`n" }
    }
    $message += Get-ComputerInfo | Select-Object CsName, OsArchitecture, WindowsVersion, Manufacturer, Model | Format-List | Out-String
    $message += "`n"

    # Informations OS
    switch ($language) {
        "fr" {$message += "## Informations sur le système d'exploitation" + "`n" }
        "es" { $message += "## Información sobre el sistema operativo" + "`n" }
        "en" { $message += "## Operating System Information" + "`n" }
    }
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $message += "OS Name: $($osInfo.Caption)`n"
    $message += "Version: $($osInfo.Version)`n"
    $message += "Build: $($osInfo.BuildNumber)`n"
    $message += "`n"

    # Informations sur le processeur
    switch ($language) {
        "fr" { $message += "## Informations sur le processeur" + "`n" }
        "es" { $message += "## Información sobre el procesador" + "`n"  }
        "en" { $message += "## CPU Information" + "`n" }
    }
    $cpuInfo = Get-CimInstance -ClassName Win32_Processor
    $message += "CPU Name: $($cpuInfo.Name)`n"
    $message += "Cores: $($cpuInfo.NumberOfCores)`n"
    $message += "Clock Speed: $($cpuInfo.MaxClockSpeed) MHz`n"
    $message += "`n"

    # Informations sur la mémoire RAM
    switch ($language) {
        "fr" { $message += "## Informations sur la mémoire RAM" + "`n" }
        "es" { $message += "## Información sobre la memoria RAM" + "`n" }
        "en" { $message += "## RAM Information" + "`n" }
    }
    $memoryInfo = Get-CimInstance -ClassName Win32_PhysicalMemory
    $totalMemory = ($memoryInfo | Measure-Object -Property Capacity -Sum).Sum / 1GB
    $message += "Total RAM memory: $([math]::round($totalMemory, 2)) Go`n"
    $message += "`n"

    # Informations sur les disques
    switch ($language) {
        "fr" {$message += "## Informations sur les disques" + "`n"}
        "es" {$message += "## Información sobre los discos" + "`n"}
        "en" {$message += "## Disk Information" + "`n"}
    }
    $diskInfo = Get-CimInstance -ClassName Win32_DiskDrive
    if ($diskInfo) {
        $diskInfo | ForEach-Object {
            # Ajouter les informations du disque physique
            $message += "Disk Model: " + $_.Model + "`n"
            $message += "Size: " + [math]::round($_.Size / 1GB, 2) + " GB" + "`n"
            $message += "Media Type: " + $_.MediaType + "`n"
            # Maintenant on récupère l'espace libre et utilisé à partir des partitions logiques associées
            $partitions = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $_.DeviceID }
            if ($partitions) {
                $partitions | ForEach-Object {
                    $message += "Drive: " + $_.DeviceID + "`n"
                    $message += "Free Space: " + [math]::round($_.FreeSpace / 1GB, 2) + " GB" + "`n"
                    $message += "Total Space: " + [math]::round($_.Size / 1GB, 2) + " GB" + "`n"
                    $message += "File System: " + $_.FileSystem + "`n"
                    $message += "`n"
                }
            } else {
                $message += "No logical disk partitions found." + "`n"
            }
        }
    } else { $message += "No disk information found." + "`n"}
    $message += "`n"

    # Informations sur les adaptateurs réseau
    switch ($language) {
        "fr" { $message += "## Informations sur les adaptateurs réseau" + "`n" }
        "es" { $message += "## Información sobre los adaptadores de red" + "`n" }
        "en" { $message += "## Network Adapter Information" + "`n" }
    }
    $networkAdapters = Get-CimInstance -ClassName Win32_NetworkAdapter | Where-Object { $_.NetConnectionStatus -eq 2 }
    # Seulement les adaptateurs connectés
    if ($networkAdapters) {
        $networkAdapters | ForEach-Object {
            # Obtenir l'IP de l'adaptateur réseau
            $adapterConfig = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Where-Object { $_.InterfaceIndex -eq $_.InterfaceIndex }
            $ipAddress = if ($adapterConfig.IPAddress) { $adapterConfig.IPAddress -join ", " } else { "Aucune IP" }
            # Ajouter les informations de l'adaptateur réseau
            $message += "Adapter Name: " + $_.Name + "`n"
            $message += "MAC Address: " + $_.MACAddress + "`n"
            $message += "Adresse IP: " + $ipAddress + " bps" + "`n"
            $message += "Speed: " + $_.Speed + " bps" + "`n"
        }
    } else {
        $message += "No connected network adapters found." + "`n" 
        }
    $message += "`n"


    # Récupérer la liste des utilisateurs locaux
    switch ($language) {
        "fr" { $message += "## Liste des utilisateurs locaux." + "`n" }
        "es" { $message += "## Lista de usuarios locales." + "`n" }
        "en" { $message += "## List of local users." + "`n" }
    }
    $users = Get-LocalUser
    
    # Boucle pour chaque utilisateur afin d'obtenir les groupes auxquels ils appartiennent
    foreach ($user in $users) {
        # Ajouter le nom de l'utilisateur au rapport
        $message += "UserName : " + $user.Name
        # Extraire uniquement le nom d'utilisateur sans le préfixe du domaine ou de l'ordinateur
        $userName =  $user.Name.Split("\")[-1].Trim()
        # Initialiser un tableau pour stocker les groupes auxquels cet utilisateur appartient
        $userGroups = @()
    
        # Récupérer les groupes locaux et leurs membres
        $groups = Get-LocalGroup
        foreach ($group in $groups) {
            # Récupérer les membres de chaque groupe
            $members = Get-LocalGroupMember -Group $group.Name
            
            # Comparer chaque membre avec l'utilisateur actuel
            foreach ($member in $members) {
                # Extraire uniquement le nom d'utilisateur sans le préfixe du domaine ou de l'ordinateur
                $memberName = $member.Name.Split("\")[-1]
            
                # Si le membre est l'utilisateur actuel, l'ajouter aux groupes de l'utilisateur
                if ($memberName -eq $userName) {
                    $userGroups += $group.Name
                    break  # On arrête dès qu'on trouve un groupe correspondant
                }
            }
        }
        # Si des groupes sont trouvés, les ajouter au rapport
        if ($userGroups.Count -gt 0) {
            $message += ": Security Groups : " + ($userGroups -join ", ") + "`n"
        } else { 
            # Gestion des utilisateurs sans groupes
            $message += " : Security Groups : No security groups found for this user." + "`n"    
        }
    }
    $message += "`n"

    # Logiciels installés
    switch ($language) {
        "fr" { $message += "## Logiciels installés" + "`n" }
        "es" { $message += "## Programas instalados" + "`n" }
        "en" { $message += "## Installed Software" + "`n" }
    }
    $softwareList = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue
    $softwareList | ForEach-Object {
        if ($_.DisplayName) {
            $message += "$($_.DisplayName) $($_.DisplayVersion) (Vendor: $($_.Publisher))`n"
        }
    }
    $message += "`n"
    
    # Afficher l'emplacement du rapport
    switch ($language) {
        "fr" { $message += "## Le rapport a été généré et sauvegardé à l'emplacement suivant : " + "`n" }
        "es" { $message += "## El informe se ha generado y guardado en la siguiente ubicación :" + "`n" }
        "en" { $message += "## The report has been generated and saved in the following location : " + "`n" }
    }
    $message += "$logPath\$logName"
    # Écrire le rapport
    Write-Log -LogPath $logPath -LogName $logName -Type $typeMessage -Message $message
}

<#
.SYNOPSIS
	Écrire des messages (chains de caracteres) dans un fichier spécifié. 
.DESCRIPTION
	Le script Write-Log.ps1 permet d'écrire des messages dans un fichier spécifié tout en affichant les messages dans la console avec une coloration appropriée en fonction du type de message. 
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
    # Exemple d'utilisation de la fonction Write-Log
    $logPath = "C:\Temp\xLuna"  # Répertoire où le fichier de log sera stocké
    $logName= 'test.log'      # Nom du fichier de log
    $typeMessage = 'Success'         # Type de message (Success)
    $message = 'Ma fonction pour écrire des logs'
    
    # Appel de la fonction Write-Log
    # Write-Log -LogPath $logPath -LogName $logName -Type $typeMessage -Message $message

.LINK
	https://github.com/xEsther-IT/WinChecks

.NOTES
	Author: 2024 @xesther.meza | License: MIT

#>
Function Write-Log {
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
}
