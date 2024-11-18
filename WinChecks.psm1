# Le fichier principal du module .pms1, contient toutes les fonctions que vous souhaitez exposer.

# Module PowerShell effectue des contrôles de sécurité sur un système Windows. 
# Il génère un rapport avec les résultats et l'envoie dans un fichier texte. 
# Celui-ci peut être utilisé pour vérifier rapidement le niveau de sécurité d'un système Windows
# et identifier les problèmes potentiels à résoudre.

$versionScript = "1.0."
#versioning de la configuration
#Release Notes
#1.0 - 2024-11-18 10:30
# - Première version du module WinChecks.psm1
# - Function Get-SystemReport
# - Function Write-Log

<#
.SYNOPSIS
    Générer un rapport contenant les informations de sécurité du système d'exploitation Windows.
    Import-Module .\WinChecks.psm1

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

Function Get-SystemReport {
    param (
        [string]$Language = "fr"  
        # Par défaut, le rapport sera en français 
        # options "es" - Espanol, "en" - English
    )
    
    # Définir les entrées de la fonction Write-Log
    $LogPath = "C:\Temp\xLuna"      # Répertoire où le fichier de log sera stocké
    $LogName= 'SystemReport.txt'    # Nom du fichier
    $Type = 'Info'                  # Type de message (Info)
    $Message = ''

    # Créer le répertoire de log si nécessaire
    if (-not (Test-Path -Path $LogPath)) {
        New-Item -ItemType Directory -Path $LogPath
    }

    # En-tête du rapport
    switch ($Language) {
        "fr" { $Message += "Rapport d'information système" + "`n" }
        "es" { $Message += "Reporte de la información del sistema" + "`n" }
        "en" { $Message += "System Information Report" + "`n" }
        default { Write-Host "Langue non supportée, le rapport sera en français." }
    }
    $Message += "------------------------------------------------------------`n"
    
    # Informations système de base
    switch ($Language) {
        "fr" {$Message += "## Informations de base sur le système" + "`n"}
        "es" {$Message += "## Información básica de la computadora" + "`n" }
        "en" {$Message += "## Basic System Information" + "`n" }
    }
    $Message += Get-ComputerInfo | Select-Object CsName, OsArchitecture, WindowsVersion, Manufacturer, Model | Format-List | Out-String
    $Message += "`n"

    # Informations OS
    switch ($Language) {
        "fr" {$Message += "## Informations sur le système d'exploitation" + "`n" }
        "es" { $Message += "## Información sobre el sistema operativo" + "`n" }
        "en" { $Message += "## Operating System Information" + "`n" }
    }
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $Message += "OS Name: $($osInfo.Caption)`n"
    $Message += "Version: $($osInfo.Version)`n"
    $Message += "Build: $($osInfo.BuildNumber)`n"
    $Message += "`n"

    # Informations sur le processeur
    switch ($Language) {
        "fr" { $Message += "## Informations sur le processeur" + "`n" }
        "es" { $Message += "## Información sobre el procesador" + "`n"  }
        "en" { $Message += "## CPU Information" + "`n" }
    }
    $cpuInfo = Get-CimInstance -ClassName Win32_Processor
    $Message += "CPU Name: $($cpuInfo.Name)`n"
    $Message += "Cores: $($cpuInfo.NumberOfCores)`n"
    $Message += "Clock Speed: $($cpuInfo.MaxClockSpeed) MHz`n"
    $Message += "`n"

    # Informations sur la mémoire RAM
    switch ($Language) {
        "fr" { $Message += "## Informations sur la mémoire RAM" + "`n" }
        "es" { $Message += "## Información sobre la memoria RAM" + "`n" }
        "en" { $Message += "## RAM Information" + "`n" }
    }
    $memoryInfo = Get-CimInstance -ClassName Win32_PhysicalMemory
    $totalMemory = ($memoryInfo | Measure-Object -Property Capacity -Sum).Sum / 1GB
    $Message += "Total RAM memory: $([math]::round($totalMemory, 2)) Go`n"
    $Message += "`n"

    # Informations sur les disques
    switch ($Language) {
        "fr" {$Message += "## Informations sur les disques" + "`n"}
        "es" {$Message += "## Información sobre los discos" + "`n"}
        "en" {$Message += "## Disk Information" + "`n"}
    }
    $diskInfo = Get-CimInstance -ClassName Win32_DiskDrive
    if ($diskInfo) {
        $diskInfo | ForEach-Object {
            # Ajouter les informations du disque physique
            $Message += "Disk Model: " + $_.Model + "`n"
            $Message += "Size: " + [math]::round($_.Size / 1GB, 2) + " GB" + "`n"
            $Message += "Media Type: " + $_.MediaType + "`n"
            # Maintenant on récupère l'espace libre et utilisé à partir des partitions logiques associées
            $partitions = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $_.DeviceID }
            if ($partitions) {
                $partitions | ForEach-Object {
                    $Message += "Drive: " + $_.DeviceID + "`n"
                    $Message += "Free Space: " + [math]::round($_.FreeSpace / 1GB, 2) + " GB" + "`n"
                    $Message += "Total Space: " + [math]::round($_.Size / 1GB, 2) + " GB" + "`n"
                    $Message += "File System: " + $_.FileSystem + "`n"
                    $Message += "`n"
                }
            } else {
                $Message += "No logical disk partitions found." + "`n"
            }
        }
    } else { $Message += "No disk information found." + "`n"}
    $Message += "`n"

    # Informations sur les adaptateurs réseau
    switch ($Language) {
        "fr" { $Message += "## Informations sur les adaptateurs réseau" + "`n" }
        "es" { $Message += "## Información sobre los adaptadores de red" + "`n" }
        "en" { $Message += "## Network Adapter Information" + "`n" }
    }
    $networkAdapters = Get-CimInstance -ClassName Win32_NetworkAdapter | Where-Object { $_.NetConnectionStatus -eq 2 }
    # Seulement les adaptateurs connectés
    if ($networkAdapters) {
        $networkAdapters | ForEach-Object {
            # Obtenir l'IP de l'adaptateur réseau
            $adapterConfig = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Where-Object { $_.InterfaceIndex -eq $_.InterfaceIndex }
            $ipAddress = if ($adapterConfig.IPAddress) { $adapterConfig.IPAddress -join ", " } else { "Aucune IP" }
            # Ajouter les informations de l'adaptateur réseau
            $Message += "Adapter Name: " + $_.Name + "`n"
            $Message += "MAC Address: " + $_.MACAddress + "`n"
            $Message += "Adresse IP: " + $ipAddress + " bps" + "`n"
            $Message += "Speed: " + $_.Speed + " bps" + "`n"
        }
    } else {
        $Message += "No connected network adapters found." + "`n" 
        }
    $Message += "`n"


    # Récupérer la liste des utilisateurs locaux
    switch ($Language) {
        "fr" { $Message += "## Liste des utilisateurs locaux." + "`n" }
        "es" { $Message += "## Lista de usuarios locales." + "`n" }
        "en" { $Message += "## List of local users." + "`n" }
    }
    $users = Get-LocalUser
    
    # Boucle pour chaque utilisateur afin d'obtenir les groupes auxquels ils appartiennent
    foreach ($user in $users) {
        # Ajouter le nom de l'utilisateur au rapport
        $Message += "UserName : " + $user.Name
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
            $Message += ": Security Groups : " + ($userGroups -join ", ") + "`n"
        } else { 
            # Gestion des utilisateurs sans groupes
            $Message += " : Security Groups : No security groups found for this user." + "`n"    
        }
    }
    $Message += "`n"

    # Logiciels installés
    switch ($Language) {
        "fr" { $Message += "## Logiciels installés" + "`n" }
        "es" { $Message += "## Programas instalados" + "`n" }
        "en" { $Message += "## Installed Software" + "`n" }
    }
    $softwareList = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue
    $softwareList | ForEach-Object {
        if ($_.DisplayName) {
            $Message += "$($_.DisplayName) $($_.DisplayVersion) (Vendor: $($_.Publisher))`n"
        }
    }
    $Message += "`n"
    
    # Écrire le rapport
    Write-Log -LogPath $LogPath -LogName $LogName -Type $Type -Message $Message
    # Afficher l'emplacement du rapport
    Write-Host "Le rapport a été généré et sauvegardé à l'emplacement suivant : $LogPath\$LogName"
}

<#
.SYNOPSIS
	Écrire des messages de log dans un fichier spécifié. 
.DESCRIPTION
	Write-Log.ps1 script permet d'écrire des messages de log dans un fichier spécifié tout en affichant les messages dans la console avec une coloration appropriée en fonction du type de message 
     ℹ️  Info
    ✅ Success
    ❌ Error
    ⚠️ Inconnu

.PARAMETER -LogPath
    Chemin du répertoire où enregistrer le fichier de log
.PARAMETER -LogName
    Nom du fichier de log
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
    $LogPath = "C:\Temp\xLuna"  # Répertoire où le fichier de log sera stocké
    $LogName= 'test.log'      # Nom du fichier de log
    $Type = 'Success'         # Type de message (Success)
    $Message = 'Ma fonction pour écrire des logs'

.LINK
	https://github.com/xEsther-IT/WinChecks

.NOTES
	Author: 2024 @xesther.meza | License: MIT

#>
Function Write-Log {
    Param (
        [string]$LogPath,   # Chemin du répertoire où enregistrer le fichier de log
        [string]$LogName,    # Nom du fichier de log
        [string]$Type,       # Type de message (Info, Success, Error)
        [string]$Message     # Message à enregistrer
    )

    # Format de la date (exemple: "2024-11-17 12:45:30")
    $DateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Vérifier que le chemin du log est défini
    If ($LogPath) {
        # Vérifier si le répertoire existe, sinon le créer
        If (-Not (Test-Path -Path $LogPath)) {
            Try {
                New-Item -Path $LogPath -ItemType Directory -Force
                Write-Host -ForegroundColor Green "Le répertoire de log a été créé : $LogPath"
            } Catch {
                Write-Host -ForegroundColor Red "Erreur : Impossible de créer le répertoire de log."
                Return
            }
        }

        # Créer le chemin complet du fichier de log
        $LogFilePath = Join-Path -Path $LogPath -ChildPath $LogName

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
    Switch ($Type) {
        "Info" {
            # Enregistrer dans le fichier 
            Add-Content -Path $LogFilePath -Encoding 'UTF-8' -Value "$DateTime [INFO] $Message"
            # Afficher dans la console
            Write-Host "$DateTime [INFO] $Message"
        }

        "Success" {
            # Enregistrer dans le fichier 
            Add-Content -Path $LogFilePath -Encoding 'UTF-8' -Value "$DateTime [SUCCESS] $Message"
            # Afficher dans la console en vert (succès)
            Write-Host -ForegroundColor Green "$DateTime [SUCCESS] $Message"
        }

        "Error" {
            # Enregistrer dans le fichier 
            Add-Content -Path $LogFilePath -Encoding 'UTF-8' -Value "$DateTime [ERROR] $Message"
            # Afficher dans la console en rouge (erreur)
            Write-Host -ForegroundColor Red -BackgroundColor Black "$DateTime [ERROR] $Message"
        }

        Default {
            # Enregistrer dans le fichier 
            Add-Content -Path $LogFilePath -Encoding 'UTF-8' -Value "$DateTime [INCONNU] $Message"
            # Afficher dans la console en yellow (Inconnu)
            Write-Host -ForegroundColor Yellow "$DateTime [INCONNU] $Message"
        }
    }
}


