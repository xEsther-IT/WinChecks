<#
.SYNOPSIS
	Générer un rapport avec les informations de base du système d'exploitation Windows 
.DESCRIPTION
	Ce script PowerShell recherche les détails du matériel de l'ordinateur local et génère un rapport en français, anglais ou espagnol contenant ces informations.
    ✅ Informations sur le système d'exploitation
    ✅ Informations sur le processeur
    ✅ Informations sur la mémoire RAM
    ✅ Informations sur les adaptateurs réseau
    ✅ Liste des utilisateurs locaux
    ✅ Logiciels installés 

.PARAMETER -Language
    Spécifie la langue du rapport. Par défaut, le rapport sera en français. 
    # Options « es » - Espagnol, « en » - Anglais.

.OUTPUTS
    Le script génère un rapport au format txt avec les informations recueillies.
    # .\System_Report_20241116.txt

.EXAMPLE
    # Pour générer un rapport en français
	PS> ./Generate-SystemReport.ps1
    
    # Pour générer un rapport en anglais
    PS> ./Generate-SystemReport -Language "en"

    # Pour générer un rapport en espagnol
    PS> ./Generate-SystemReport -Language "es"
	
.LINK
	https://github.com/xEsther-IT/WinChecks

.NOTES
	Author: 2024 @xesther.meza | License: MIT
#>

function Get-SystemReport {
    param (
        [string]$Language = "fr"  # Par défaut, le rapport sera en français 
        # options "es" - Espanol, "en" - English
    )

    # Définir le chemin du fichier de sortie avec la date formatée
    $outputFile = "C:\tmp\xLuna\System_Report_" + (Get-Date -Format "yyyyMMdd") + ".txt"

    # Assurez-vous que le répertoire existe
    $outputDir = "C:\tmp\xLuna"
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir
    }

    # Initialiser le contenu du rapport
    $reportContent = ""

# En-tête du rapport 
    switch ($Language) {
        "fr" {
            $reportContent += "Rapport d'information système" + "`n"
            $reportContent += "Généré le : " + (Get-Date) + "`n"
            $reportContent += "------------------------------------------------------------" + "`n"
        }
        "es" {
            $reportContent += "Reporte de la información del sistema" + "`n"
            $reportContent += "Creado el : " + (Get-Date) + "`n"
            $reportContent += "------------------------------------------------------------" + "`n"
        }
        "en" {
            $reportContent += "System Information Report" + "`n"
            $reportContent += "Generated on: " + (Get-Date) + "`n"
            $reportContent += "------------------------------------------------------------" + "`n"
        }
        default {
            Write-Host "Langue non supportée, le rapport sera en français."
            $reportContent += "Rapport d'information système" + "`n"
            $reportContent += "Généré par : Esther Meza"+ "`n"
            $reportContent += "Généré le : " + (Get-Date) + "`n"
            $reportContent += "------------------------------------------------------------" + "`n"
        }
    }

# Informations sur l'ordinateur 
    switch ($Language) {
        "fr" {$reportContent += "## Informations de base sur le système" + "`n"}
        "es" {$reportContent += "## Información básica de la computadora" + "`n" }
        "en" {$reportContent += "## Basic System Information" + "`n" }
    }

    $reportContent += (Get-ComputerInfo | Select-Object -Property CsName, OsArchitecture, WindowsVersion, WindowsBuildLabEx, Manufacturer, Model | Format-List | Out-String)
    $reportContent += "`n"

# Informations sur le système d'exploitation
    switch ($Language) {
        "fr" {$reportContent += "## Informations sur le système d'exploitation" + "`n" }
        "es" { $reportContent += "## Información sobre el sistema operativo" + "`n" }
        "en" { $reportContent += "## Operating System Information" + "`n" }
    }

    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $reportContent += "OS Name: " + $osInfo.Caption + "`n"
    $reportContent += "Version: " + $osInfo.Version + "`n"
    $reportContent += "Build: " + $osInfo.BuildNumber + "`n"
    $reportContent += "Last Boot Time: " + $osInfo.LastBootUpTime + "`n"
    $reportContent += "`n"

# Informations sur le processeur
    switch ($Language) {
        "fr" { $reportContent += "## Informations sur le processeur" + "`n" }
        "es" { $reportContent += "## Información sobre el procesador" + "`n"  }
        "en" { $reportContent += "## CPU Information" + "`n" }
    }

    $cpuInfo = Get-CimInstance -ClassName Win32_Processor
    $reportContent += "CPU Name: " + $cpuInfo.Name + "`n"
    $reportContent += "Cores: " + $cpuInfo.NumberOfCores + "`n"
    $reportContent += "Logical Processors: " + $cpuInfo.NumberOfLogicalProcessors + "`n"
    $reportContent += "Clock Speed: " + $cpuInfo.MaxClockSpeed + " MHz" + "`n"
    $reportContent += "`n"

# Informations sur la mémoire RAM
    switch ($Language) {
        "fr" { $reportContent += "## Informations sur la mémoire RAM" + "`n" }
        "es" { $reportContent += "## Información sobre la memoria RAM" + "`n" }
        "en" { $reportContent += "## RAM Information" + "`n" }
    }
    # Obtenir les informations sur la RAM
    $memoryInfo = Get-CimInstance -ClassName Win32_PhysicalMemory

    # Vérifier si des informations sur la RAM ont été récupérées
    if ($memoryInfo) {
        # Calculer la RAM totale en additionnant les capacités de chaque barrette
        $totalMemory = 0
        foreach ($memory in $memoryInfo) {
            $totalMemory += $memory.Capacity
        }

        # Obtenir la vitesse de la RAM (en prenant la première barrette)
        $ramSpeed = $memoryInfo[0].Speed

        # Ajouter les informations de RAM au rapport
        $reportContent += "Mémoire RAM totale : " + [math]::round($totalMemory / 1GB, 2) + " Go" + "`n"
        $reportContent += "Vitesse de la RAM : " + $ramSpeed + " MHz" + "`n"
        $reportContent += "`n"
    } else {
        # Si aucune information sur la RAM n'est trouvée
        $reportContent += "Aucune information sur la RAM disponible." + "`n"
        $reportContent += "`n"
    }

# Informations sur les disques
    switch ($Language) {
        "fr" {$reportContent += "## Informations sur les disques" + "`n"}
        "es" {$reportContent += "## Información sobre los discos" + "`n"}
        "en" {$reportContent += "## Disk Information" + "`n"}
    }

    if ($diskInfo) {
        $diskInfo | ForEach-Object {
            # Ajouter les informations du disque physique
            $reportContent += "Disk Model: " + $_.Model + "`n"
            $reportContent += "Size: " + [math]::round($_.Size / 1GB, 2) + " GB" + "`n"
            $reportContent += "Media Type: " + $_.MediaType + "`n"
            
            # Maintenant on récupère l'espace libre et utilisé à partir des partitions logiques associées
            $partitions = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $_.DeviceID }
            if ($partitions) {
                $partitions | ForEach-Object {
                    $reportContent += "Drive: " + $_.DeviceID + "`n"
                    $reportContent += "Free Space: " + [math]::round($_.FreeSpace / 1GB, 2) + " GB" + "`n"
                    $reportContent += "Total Space: " + [math]::round($_.Size / 1GB, 2) + " GB" + "`n"
                    $reportContent += "File System: " + $_.FileSystem + "`n"
                    $reportContent += "`n"
                }
            } else {
                $reportContent += "No logical disk partitions found." + "`n"
            }
        }
    } else {
        switch ($Language) {
            "fr" { $reportContent += "Aucune information sur les disques trouvée." + "`n" }
            "es" { $reportContent += "No se encontró información sobre los discos." + "`n" }
            "en" { $reportContent += "No disk information found." + "`n" }
        }
    }

# Informations sur les adaptateurs réseau
    switch ($Language) {
        "fr" { $reportContent += "## Informations sur les adaptateurs réseau" + "`n" }
        "es" { $reportContent += "## Información sobre los adaptadores de red" + "`n" }
        "en" { $reportContent += "## Network Adapter Information" + "`n" }
    }

    $networkAdapters = Get-CimInstance -ClassName Win32_NetworkAdapter | Where-Object { $_.NetConnectionStatus -eq 2 }
    # Seulement les adaptateurs connectés
    if ($networkAdapters) {
        $networkAdapters | ForEach-Object {
            # Obtenir l'IP de l'adaptateur réseau
            $adapterConfig = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Where-Object { $_.InterfaceIndex -eq $_.InterfaceIndex }
            $ipAddress = if ($adapterConfig.IPAddress) { $adapterConfig.IPAddress -join ", " } else { "Aucune IP" }
            # Ajouter les informations de l'adaptateur réseau
            $reportContent += "Adapter Name: " + $_.Name + "`n"
            $reportContent += "MAC Address: " + $_.MACAddress + "`n"
            $reportContent += "Speed: " + $_.Speed + " bps" + "`n"
            $reportContent += "Adresse IP: " + $ipAddress + " bps" + "`n"
            $reportContent += "`n"
        }
    } else {
        switch ($Language) {
            "fr" { $reportContent += "Aucun adaptateur réseau connecté trouvé." + "`n" }
            "es" { $reportContent += "No se encontraron adaptadores de red conectados." + "`n" }
            "en" { $reportContent += "No connected network adapters found." + "`n" }
        }
    }


# Récupérer la liste des utilisateurs locaux
    switch ($Language) {
        "fr" { $reportContent += "## Liste des utilisateurs locaux." + "`n" }
        "es" { $reportContent += "## Lista de usuarios locales." + "`n" }
        "en" { $reportContent += "## List of local users." + "`n" }
    }

    $users = Get-CimInstance -ClassName Win32_UserAccount | Where-Object { $_.LocalAccount -eq $true }

    # Pour chaque utilisateur, obtenir les groupes de sécurité auxquels ils appartiennent
    foreach ($user in $users) {
        $reportContent += "Nom d'utilisateur : " + $user.Name + "`n"
    
        # Récupérer les groupes de sécurité auxquels l'utilisateur appartient
        $groups = Get-CimInstance -ClassName Win32_GroupUser | Where-Object { $_.PartComponent -like "*$($user.Name)*" }

        if ($groups) {
            $reportContent += "Groupes de sécurité : " + "`n"
            $groups | ForEach-Object {
                $groupName = ($_).GroupComponent -replace '.*"([^"]+)".*', '$1'
                $reportContent += " - " + $groupName + "`n"
            }
        } else {
            switch ($Language) {
                "fr" { $reportContent += "Aucun groupe de sécurité trouvé pour cet utilisateur." + "`n" }
                "es" { $reportContent += "No se han encontrado grupos de seguridad para este usuario." + "`n" }
                "en" { $reportContent += "No security groups found for this user." + "`n" }
        
            }
        }
    }
    $reportContent += "`n"

# Logiciels installés 
        switch ($Language) {
        "fr" { $reportContent += "## Logiciels installés" + "`n" }
        "es" { $reportContent += "## Programas instalados" + "`n" }
        "en" { $reportContent += "## Installed Software" + "`n" }
    }
    # Récupérer les informations sur les logiciels installés et leur date d'installation depuis le registre
    $softwareList = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue
    $softwareList32Bit = Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue

    # Combiner les logiciels 64 bits et 32 bits
    $allSoftware = $softwareList + $softwareList32Bit

    # Ajouter chaque logiciel au rapport
    $allSoftware | ForEach-Object {
        # Assurez-vous qu'il y a un nom de programme
        if ($_.DisplayName) {
            $reportContent += $_.DisplayName + " " + $_.DisplayVersion + " (Vendor: " + $_.Publisher + ")"
        
            # Ajouter la date d'installation (formatée)
            if ($_.InstallDate) {
                # La date d'installation est souvent dans le format YYYYMMDD
                $installDate = $_.InstallDate
                $formattedDate = [datetime]::ParseExact($installDate, "yyyyMMdd", $null)
                $reportContent += " - Install Date: " + $formattedDate.ToString("dd/MM/yyyy")
            } else {
                $reportContent += " - Install Date: Not Available"
            }
        $reportContent += "`n"
        }
    }
    $reportContent += "`n"

    # Écrire le rapport dans un fichier texte
    $reportContent | Out-File -FilePath $outputFile

    # Afficher l'emplacement du rapport
    Write-Host "Le rapport a été généré et sauvegardé à l'emplacement suivant : $outputFile"
    
# Fin de la fonction get-SystemReport
}

# Exemple d'appel de la fonction pour générer un rapport en français
Get-SystemReport 

# Exemple d'appel de la fonction pour générer un rapport en anglais
# Get-SystemReport -Language "en"

# Exemple d'appel de la fonction pour générer un rapport en espagnol
# Get-SystemReport -Language "es"
