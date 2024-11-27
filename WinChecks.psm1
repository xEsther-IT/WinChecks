# Module PowerShell effectue des contrôles de sécurité sur un système Windows. 
# Il génère un rapport avec les résultats et l'envoie dans un fichier texte. 
# Celui-ci peut être utilisé pour vérifier rapidement le niveau de sécurité d'un système Windows
# et identifier les problèmes potentiels à résoudre.
#
#Versioning de la configuration
#Release Notes
#v1.0.6 - 2024-11-27-11:01
# - Corrections dans la fonction Set-WinCheckDefenderConfig : policy-csp-defender 
# - Une alerte a été ajoutée au menu : ATTENTION : option 6. Modifie le registre de Windows.
# - Get-WinCheckMinimumRequired - Fonctionnalité ajoutée : # Vérifiez que PowerShell a été lancé en tant qu'administrateur.
# - Ajout de commentaires détaillés sur chacune des fonctions.
#v1.0.5 - 2024-11-25-2:00
# - Function : Get-WinCheckDefenderStatus - Pour obtenir des informations sur l'état du Windows Defender (antivirus).
# - Function : Set-WinCheckDefenderConfig - Pour configurer 4 paramètres de sécurité sur Windows Defender (Antivirus). La fonction Set-WinCheckDefenderConfig permet de configurer 
# - quatre paramètres de sécurité de Windows Defender. Les paramètres sont d'abord vérifiés, puis définis le cas échéant, et toutes les actions sont enregistrées dans le fichier de log « WinChecksWindowsDefender ».
# - - CloudExtendedTimeout : Prolonger la durée de l'analyse de sécurité du cloud jusqu'à un maximum de 60 secondes ; par défaut, elle est de 10 secondes.
# - -> # https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-defender 
# - -> # ✅ Windows 10, version 1709 [10.0.16299] and later
# - -> # Définir la valeur du registre CloudExtendedTimeout à 60 minutes
# - -> # Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows Defender\MpEngine" -Name "CloudExtendedTimeout" -Value 60
# - - DaysToRetainCleanedMalware : Supprime les éléments mis en quarantaine au bout d'un jour au lieu de les conserver indéfiniment comme c'est le cas par défaut.
# - -> # https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-defender
# - -> # ✅ Windows 10, version 1507 [10.0.10240] and later
# - -> # Définir la valeur du registre Quarantine_PurgeItemsAfterDelay pour activer la suppression automatique après un délai
# - -> # Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Quarantine" -Name "DaysToRetainCleanedMalware" -Value 1
# - - AllowFullScanOnMappedNetworkDrives : Permet à Microsoft Defender d'analyser les lecteurs réseau mappés pendant l'analyse complète.
# - -> # https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-defender 
# - -> # ✅ Windows 10, version 1607 [10.0.14393] and later
# - -> # Activer l'analyse complète des lecteurs réseau mappés
# - -> # Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows Defender\Scan" -Name "AllowFullScanOnMappedNetworkDrives" -Value 1
# - - CheckForSignaturesBeforeRunningScan - Permet d'activer la vérification des mises à jour avant le scan
# - -> # https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-defender
# - -> # ✅ Windows 10, version 1809 [10.0.17763] and later
# - -> # Définir la valeur du registre CheckForSignaturesBeforeRunningScan à 1 pour activer la vérification des mises à jour avant le scan
# - -> # Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows Defender\Scan" -Name "CheckForSignaturesBeforeRunningScan" -Value 1
# - Creation du fichier Log : l'execution de Set-WinCheckDefenderConfig genere le log : C:\temp\xLuna\WinChecksWindowsDefender-2024-11-25.log
# - - Exemple :
# - - 2024-11-25 01:49:44 [INFO] ## Windows Defender Security Configuration
# - - 2024-11-25 01:49:44 [INFO] Windows Defender Antivirus est déjà activé : 
# - - 2024-11-25 01:49:44 [ERROR] Erreur: Impossible de récupérer l'heure de la dernière mise à jour des signatures.
# - - 2024-11-25 01:49:44 [SUCCESS] CloudExtendedTimeout est défini sur 60 secondes.
#v1.0.4 - 2024-11-21-5:04
# - Functions : Start-WinChecks / Show-WinCheksMenu - Fonction principale pour afficher le menu avec les commandes disponibles dans le module et exécuter les choix
# - Function : Get-WinCheckMinimumRequired - Fonction permettant de vérifier les prérequis minimaux (version de PowerShell, privilèges d'administrateur, politique d'exécution) pour garantir le bon fonctionnement du module.
# - Renomer funtions pour respecter les bonnes pratiques pour le module WinCheck 
# - - Get-SystemReport -> Get-WinCheckReport
# - - Get-BasicSystemInfo -> Get-WinCheckBasicSystemInfo
# - - Get-LocalUserGroups -> Get-WinCheckLocalUserGroups
# - - Write-Log -> Write-WinCheckLog
#v1.0.3 - 2024-11-20-4:37
# - Les vérifications (« checks ») ont été séparées en fonctions distinctes.
# - Function : Get-WinCheckBasicSystemInfo - Fonction permettant d'obtenir les informations système d'exploitation de base.
# - Function : Get-WinCheckLocalUserInGroups - Fonction pour obtenir les utilisateurs locaux et leurs groupes
# - Function : Get-WinCheckInstalledApplications - Fonction pour obtenir les applications installées 
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
$moduleVersion = "v1.0.6"
# $language = "fr" - Francais par default. Options : "es" - Espanol, "en" - English
$global:language = "fr"

function Start-WinChecks { # Lance WinCheck et fait la liaison entre les fonctions à exécuter
<#
.DESCRIPTION
    Start-WinChecks : Lance WinCheck et fait la liaison entre les fonctions à exécuter et 
    l'appel au display du menu avec trois choix de langue.
.PARAMETER -language
    Langue du menu principal. « fr » - français par défaut. Options : « es » - espagnol, « en » - anglais.
    Si aucune valeur n'est passée, alors utilise la valeur définie : $global:language = « fr »
.EXAMPLE
    Exemple d'utilisation de la fonction Start-WinChecks
    Pour générer un menu en français
        PS> Start-WinChecks -Language "fr"   
        PS> Start-WinChecks 
    Pour générer un rapport en anglais
        PS> Start-WinChecks -Language "en"
    Pour générer un rapport en espagnol
        PS> Start-WinChecks -Language "es"
.LINK
    https://github.com/xEsther-IT/WinChecks
.NOTES
    Author: 2024 @xesther.meza | License: MIT
#>
    param (
        # Si aucune valeur n'est passée, utiliser la variable globale
        [string]$language = $global:language
    )
    # Définir une variable globale:langue dans le module
    $global:language = $language

    do {
        # Afficher les options du menu
        Write-Host "Module Windows-Security-Checks $moduleVersion Created by @xesther.meza "  -ForegroundColor Cyan
        Write-Host "Ce script PowerShell effectue des contrôles de sécurité sur un système Windows`n"
        Show-WinCheksMenu
        
        switch ($language) {
            "fr" { $choix = Read-Host "Choisissez une option" }
            "es" { $choix = Read-Host "Elija una opción" }
            "en" { $choix = Read-Host "Choose an option" }
        }

        # Traiter le choix de l'utilisateur et exécuter la fonction correspondante
        switch ($choix) {
            "1" { Get-WinCheckMinimumRequired }
            "2" { Get-WinCheckBasicSystemInfo }
            "3" { Get-WinCheckLocalUserInGroups }
            "4" { Get-WinCheckInstalledApplications }
            "5" { Get-WinCheckDefenderStatus }
            "6" { Set-WinCheckDefenderConfig }
            "7" { Get-WinCheckSystemReport }
            "0" { Write-Host "Sortir..." -ForegroundColor Yellow; break }
            default { Write-Host "Choix non valide, veuillez réessayer." -ForegroundColor Red }
        }

        Read-Host "Appuyez sur la touche Entrée pour continuer..."
        Clear-Host
    } while ($choix -ne "0")
} # END function Start-WinChecks

function Show-WinCheksMenu { # Lance le menu principal basé sur la langue definit. 
<#
.DESCRIPTION
    Show-WinCheksMenu : Lance le menu principal basé sur la langue definit.
.OUTPUTS
    Module Windows-Security-Checks v1.0.7 Created by @xesther.meza 
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
    ========================
.EXAMPLE
    Exemple d'utilisation de la fonction Start-WinChecks
    Show-WinCheksMenu
.LINK
    https://github.com/xEsther-IT/WinChecks
.NOTES
    Author: 2024 @xesther.meza | License: MIT
#>
    $menuFr = @"
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
    ========================
"@

    $menuEs = @"
    === Menú de opciones ===
    1. Verificar los requisitos mínimos de ejecución del módulo WinChecks
    2. Mostrar información básica del sistema
    3. Listar los usuarios locales y sus grupos
    4. Listar las aplicaciones instaladas
    5. Listar Información sobre WindowsDefender (Antivirus)
    6. ---Configurar WindowsDefender Security
       ---ATENCIÓN: la opción 6 modifica el registro de Windows
    7. Generar un informe completo del sistema
    0. Salir
    ========================
"@

    $menuEn = @"
    === Options Menu ===
    1. Check minimum requirements for running the WinChecks module
    2. Display basic system information
    3. List local users and their groups
    4. List installed applications
    5. List Information about WindowsDefender (Antivirus)
    6. ---Configurer WindowsDefender Security
       ---WARNING: option 6 Modifies the Windows registry
    7. Generate a complete system report
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

function Get-WinCheckMinimumRequired { # Verifie les prérequis minimaux afin de garantir que le module PowerShell fonctionne correctement. 
<#
.DESCRIPTION
	Get-WinCheckMinimumRequired. Verifie les prérequis minimaux afin de garantir que le module PowerShell fonctionne correctement. 
    Elle effectue trois vérifications principales en gérant trois options de langues différentes :
    1. Vérification de la version de PowerShell : La fonction compare la version actuelle de PowerShell avec une version requise (dans ce cas, version 7.4).
    2. Vérification des privilèges d'administrateur : Elle vérifie à la fois si PowerShell est exécuté avec des privilèges élevés (en tant qu'administrateur) et si l'utilisateur appartient au groupe "Administrateurs". 
    3. Vérification de la politique d'exécution : La fonction vérifie la politique d'exécution de PowerShell, qui contrôle les scripts autorisés à s'exécuter. Elle compare la politique d'exécution actuelle avec une politique requise, ici définie comme "Bypass". 
.OUTPUTS
    ## Vérification de la version de PowerShell...
    Version de PowerShell : 7.4. - Version suffisante pour l'exécution de ce module.

    ## Vérification des privilèges d'administrateur...
    The user has privileges and is running PowerShell as administrator 

    ## Vérification de la politique d'exécution...
    Politique d'exécution actuelle : Bypass. Aucune modification nécessaire pour permettre l'exécution des fonctions du Module-WinCheck.
.EXAMPLE 
    Appel de la fonction Get-WinCheckMinimumRequired 
    Get-WinCheckMinimumRequired
.LINK
	https://github.com/xEsther-IT/WinChecks
.NOTES
	Author: 2024 @xesther.meza | License: MIT
#>
    # 1. Vérification de la version de PowerShell
    switch ($language) {
        "fr" { Write-Host "`n## Vérification de la version de PowerShell..."}
        "es" { Write-Host "`n## Verificando de la versión de PowerShell..." }
        "en" { Write-Host "`n## PowerShell version check..." }
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
    
    # 2. Vérification des privilèges d'administrateur 
    switch ($language) {
        "fr" { Write-Host "`n## Vérification des privilèges d'administrateur..." }
        "es" { Write-Host "`n## Verificando los privilegios de administrador..." }
        "en" { Write-Host "`n## Checking administrator privileges..." }
    }
    
    # Obtenir l'identite de qui exécute PowerShell
    $current = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    # Cela permettra d'évaluer si PowerShell a été lancé en tant qu'administrateur/Administrador/Administrator
    $process = New-Object System.Security.Principal.WindowsPrincipal($current)
    
    # Obtenir le nom d'utilisateur actuel 
    $currentUser = $env:USERNAME
    $user =  Get-LocalUser | Where-Object { $_.Name -like $($currentUser) }
    $userInGroups = Get-WinCheckLocalUserInGroups($user)

    # Obtenir la culture actuelle du système
    $culture = Get-Culture
    # Extraire le code de la langue à deux lettres
    $cultureLanguage = $culture.TwoLetterISOLanguageName
    switch ($cultureLanguage) {
        "fr" { 
            # Vérifiez que PowerShell a été lancé en tant qu'administrateur.
            $isElevated = $process.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrateur)
            # Vérifier que l'utilisateur actuel appartient au groupe des administrateurs.
            $inAdminGroup = $($userInGroups -match 'Administrateurs')
            if ($inAdminGroup -and $isElevated) {
                Write-Host "L'utilisateur dispose de privilèges et exécute PowerShell en tant qu'administrateur. $userInGroups" -ForegroundColor Green
            } else {
                Write-Host "$userInGroups L'utilisateur ne dispose pas des privilèges d'administrateur." -ForegroundColor Red
            }
        }
        "es" { 
            # Vérifiez que PowerShell a été lancé en tant qu'administrateur.
            $isElevated = $process.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrador)
            # Vérifier que l'utilisateur actuel appartient au groupe des administrateurs.
            $inAdminGroup = $($userInGroups -match 'Administradores')
            if ($inAdminGroup -and $isElevated) {
                Write-Host "El usuario tiene privilegios de administrador y está ejecutando PowerShell como administrador. $userInGroups" -ForegroundColor Green
            } else {
                Write-Host "$userInGroups El usuario no tiene privilegios de administrador." -ForegroundColor Red
            } 
        }
        "en" { 
            # Vérifiez que PowerShell a été lancé en tant qu'administrateur.
            $isElevated = $process.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
            # Vérifier que l'utilisateur actuel appartient au groupe des administrateurs.
            $inAdminGroup = $($userInGroups -match 'Administrators')                        
            if ($inAdminGroup -and $isElevated) {
                Write-Host "The user has privileges and is running PowerShell as administrator $message" -ForegroundColor Green
            } else {
                Write-Host "$message The user has no administrator privileges." -ForegroundColor Red
            } 
        }
    }

    # 3. Vérification de la politique d'exécution
    switch ($language) {
        "fr" { Write-Host "`n## Vérification de la politique d'exécution..." }
        "es" { Write-Host "`n## Verificando la política de ejecución..." }
        "en" { Write-Host "`n## Check execution policy..." }
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

function Get-WinCheckDefenderStatus{ # Obtiens des informations sur l'état du Windows Defender (antivirus).
<#
.DESCRIPTION
	Get-WinCheckDefenderStatus. Obtiens des informations sur l'état de Windows Defender (l'antivirus natif de Windows)
    Elle vérifie aussi des paramètres de sécurité avancée définis dans le registre Windows.
    1. Récupération de l'état de Windows Defender
    2. Vérification de l'état de fonctionnement normal de Windows Defender
    3. Vérification des paramètres avancés de sécurité dans le registre
.OUTPUTS
    ## État actuel de Windows Defender
    Windows Defender Antivirus est activé.
    La protection en temps réel est activée.
    Dernière mise à jour des signatures antivirus : 2024-11-26 22:21:39
    La protection contre les logiciels espions est activée.
    Dernière analyse rapide lancée : 11/27/2024 04:24:05

    ## Windows Defender fonctionne normalement.

    ##  État de la sécurité avancé :
    Valeur actuelle du CloudExtendedTimeout : 60
    DaysToRetainCleanedMalware n'est pas défini.
    AllowFullScanOnMappedNetworkDrives n'est pas défini.
    CheckForSignaturesBeforeRunningScan n'est pas défini.
.EXAMPLE  
    Appel de la fonction Get-WinCheckDefenderStatus
    Get-WinCheckDefenderStatus
.LINK
	https://github.com/xEsther-IT/WinChecks
.NOTES
	Author: 2024 @xesther.meza | License: MIT
#>    
    try {
        # Obtenir l'état de Windows Defender
        $defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue

        # Initialisation de la variable pour stocker le message à afficher
        $checkMessage = "## État actuel de Windows Defender" + "`n"

        # Vérifier si Windows Defender est activé
        if ($defenderStatus.AntivirusEnabled) {
            $checkMessage += "Windows Defender Antivirus est activé." + "`n"
        } else {
            $checkMessage += "Windows Defender Antivirus n'est pas activé." + "`n"
        }

        # Affichage si la protection en temps réel est activée
        if ($defenderStatus.RealTimeProtectionEnabled -eq $true) {
            $checkMessage += "La protection en temps réel est activée." + "`n"
        } else {
            $checkMessage += "La protection en temps réel est désactivée." + "`n"
        }

        # Vérifier si les signatures antivirus sont à jour
        $lastUpdated = $defenderStatus.AntivirusSignatureLastUpdated
        if ($lastUpdated) {
            $checkMessage += "Dernière mise à jour des signatures antivirus : $($lastUpdated.ToString('yyyy-MM-dd HH:mm:ss'))" + "`n"
        } else {
            $checkMessage += "Impossible de récupérer l'heure de la dernière mise à jour des signatures." + "`n"
        }

        # Vérifier si la protection contre les logiciels espions est activée
        if ($defenderStatus.AntispywareEnabled) {
            $checkMessage += "La protection contre les logiciels espions est activée." + "`n"
        } else {
            $checkMessage += "La protection contre les logiciels espions n'est pas activée." + "`n"
        }

        # Vérifier si l'analyse rapide a été lancée
        if ($defenderStatus.QuickScanStartTime) {
            $checkMessage += "Dernière analyse rapide lancée : $($defenderStatus.QuickScanStartTime)" + "`n"
        } else {
            $checkMessage += "Aucune analyse rapide lancée récemment." + "`n"
        }

        # Vérification finale : Windows Defender fonctionne correctement si toutes les conditions sont réunies
        if ($defenderStatus.AntivirusEnabled -eq $true -and 
            $defenderStatus.RealTimeProtectionEnabled -eq $true -and 
            $defenderStatus.AMRunningMode -eq 'Normal' -and 
            $defenderStatus.AntivirusSignatureLastUpdated -gt (Get-Date).AddDays(-2) -and 
            $defenderStatus.AntispywareEnabled -eq $true) {
            $checkMessage += "`n" + "## Windows Defender fonctionne normalement." + "`n"
        } else {
            $checkMessage += "`n" + "## Un ou plusieurs paramètres de Windows Defender ne sont pas optimaux." + "`n"
        }

        # État de la sécurité avancé
        $checkMessage += "`n" + "##  État de la sécurité avancé :" + "`n"
        # CloudExtendedTimeout : Prolonger la durée de l'analyse de sécurité du cloud jusqu'à un maximum de 60 secondes
        # Documentation : https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-defender
        # Définir la valeur du registre CloudExtendedTimeout à 60 minutes
        # Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows Defender" -Name "CloudExtendedTimeout" -Value 60
        $path = "HKLM:\Software\Policies\Microsoft\Windows Defender\MpEngine"
        $name = "CloudExtendedTimeout"
        $registryKey = $null
        $registryKey = Test-WinChecksRegistryKey -Path $path -Name $name 
        
        if($null -eq $RegistryKey){
            $checkMessage += "$name n'est pas défini. " + "`n"
        } else {
            $checkMessage += "Valeur actuelle du $name : $(($registryKey).$name) " + "`n" 
            }

        # DaysToRetainCleanedMalware : Supprime les éléments mis en quarantaine après un jour
        # Documentation : https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-defender 
        # Définir la valeur de Quarantine_PurgeItemsAfterDelay à 1 si elle n'est pas déjà définie
        # Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Quarantine" -Name "DaysToRetainCleanedMalware" -Value 1
        $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Quarantine"
        $name = "DaysToRetainCleanedMalware"
        $registryKey = $null
        $registryKey = Test-WinChecksRegistryKey -Path $path -Name $name 
        
        if($null -eq $RegistryKey){
            $checkMessage += "$name n'est pas défini.  " + "`n"
        } else {
            $checkMessage += "Valeur actuelle du $name : $(($registryKey).$name) " + "`n" 
            }

        # AllowFullScanOnMappedNetworkDrives : Permet à Defender d'analyser les lecteurs réseau mappés pendant l'analyse complète
        # Documentation : https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-defender
        # Définir la valeur de AllowFullScanOnMappedNetworkDrives à 1 si elle n'est pas déjà définie
        # Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Scan" -Name "AllowFullScanOnMappedNetworkDrives" -Value 1
        $path = "HKLM:\Software\Policies\Microsoft\Windows Defender\Scan"
        $name = "AllowFullScanOnMappedNetworkDrives"
        $registryKey = $null
        $registryKey = Test-WinChecksRegistryKey -Path $path -Name $name 
        
        if($null -eq $RegistryKey){
            $checkMessage += "$name n'est pas défini. " + "`n"
        } else {
            $checkMessage += "Valeur actuelle du $name : $(($registryKey).$name) " + "`n" 
            }

        # CheckForSignaturesBeforeRunningScan : Vérifie les signatures avant de lancer une analyse
        # Documentation : https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-defender 
        # Définir la valeur de CheckForSignaturesBeforeRunningScan à 1 si elle n'est pas déjà définie
        # Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Scan" -Name "CheckForSignaturesBeforeRunningScan" -Value 1 
        $path = "HKLM:\Software\Policies\Microsoft\Windows Defender\Scan"
        $name = "CheckForSignaturesBeforeRunningScan"
        $registryKey = $null
        $registryKey = Test-WinChecksRegistryKey -Path $path -Name $name 
        
        if($null -eq $RegistryKey){
            $checkMessage += "$name n'est pas défini. " + "`n"
        } else {
            $checkMessage += "Valeur actuelle du $name : $(($registryKey).$name) " + "`n" 
            }
        
    } catch {
        # Gérer les erreurs potentielles, par exemple si Get-MpComputerStatus échoue
        $checkMessage += "Erreur lors de la récupération de l'état de Windows Defender : $_"
        Write-Host $checkMessage -ForegroundColor Red    
    }
    return $checkMessage
} # END functionn : Get-WinCheckDefenderStatus

function Set-WinCheckDefenderConfig { # Configure 4 paramètres de sécurité sur Windows Defender (Antivirus).
# La fonction Set-WinCheckDefenderConfig permet de configurer quatre paramètres de sécurité de Windows Defender.
# Les paramètres sont d'abord vérifiés, puis définis le cas échéant, et toutes les actions sont enregistrées dans le fichier de log « WinChecksWindowsDefender ».

    $date = Get-Date -Format "yyyy-MM-dd"
    # Définir les entrées de la fonction Write-WinCheckLog afin de generer raport : WinChecksWindowsDefender-yyyy-MM-dd.log
    $logPath = "C:\Temp\xLuna"              # Répertoire où le fichier de log sera stocké
    $logName= 'WinChecksWindowsDefender-'+$date+'.log'  # Nom du fichier
    $typeMessage = 'Info'                   # Type de message (Info, Success, Error)
    $logMessage = "## Windows Defender Security Configuration"        # Message
    Write-Host $logMessage
    Write-WinCheckLog -LogPath $logPath -LogName $logName -Type $typeMessage -Message $logMessage

    # Vérifier l'état actuel de Windows Defender Antivirus
    try {
        # Récupérer les préférences de Windows Defender
        $defenderStatus = Get-MpComputerStatus

        # Vérifier si Windows Defender est activé ou non
        if ($defenderStatus.AntivirusEnabled -eq $false) {
            # Activer Windows Defender Antivirus
            Set-MpPreference -DisableAntivirus $false -ErrorAction SilentlyContinue
            # Vérifier de nouveau si la protection antivirus est activée
            $defenderStatus = Get-MpPreference  

            # Log du succès
            $logMessage = "Windows Defender Status : $($defenderStatus.AntivirusEnabled)"
            Write-Host $logMessage 
            Write-WinCheckLog -LogPath $logPath -LogName $logName -Type 'Success' -Message $logMessage
        } else {
            # Si déjà activé, log et message indiquant l'état actuel
            $logMessage = "Windows Defender Antivirus est activé : $($defenderStatus.AntivirusEnabled)"
            Write-Host $logMessage 
            Write-WinCheckLog -LogPath $logPath -LogName $logName -Type 'Info' -Message $logMessage
        }

        # Vérifier si les définitions de Windows Defender sont à jour
        $definitionsLastUpdated = $defenderStatus.AntivirusSignatureLastUpdated
        if ($definitionsLastUpdated) {
            if ($definitionsLastUpdated -lt (Get-Date).AddDays(-2)) {
                Write-Host "Les définitions de Windows Defender ne sont pas à jour. Mise à jour en cours..." -ForegroundColor Green
                # Planifier la mise à jour des signatures
                Set-MpPreference -SignatureScheduleDay 0 -SignatureScheduleTime 0 -ErrorAction SilentlyContinue
                Update-MpSignature -ErrorAction SilentlyContinue

                # Log de mise à jour des signatures
                $logMessage = "Les signatures de Windows Defender ont été mises à jour."
                Write-Host $logMessage -ForegroundColor Green
                Write-WinCheckLog -LogPath $logPath -LogName $logName -Type 'Success' -Message $logMessage
            } else {
                Write-Host "Les définitions de Windows Defender sont à jour." 
            }
        } else {
            Write-Host "Impossible de récupérer l'heure de la dernière mise à jour des signatures." -ForegroundColor Red
            $logMessage = "Erreur: Impossible de récupérer l'heure de la dernière mise à jour des signatures."
            Write-WinCheckLog -LogPath $logPath -LogName $logName -Type 'Error' -Message $logMessage
        }
    } catch {
        # En cas d'erreur, capturer l'exception et afficher un message
        $logMessage = "Erreur lors de l'activation de la protection contre les virus et menaces : $_"
        Write-Host $logMessage -ForegroundColor Red
        Write-WinCheckLog -LogPath $logPath -LogName $logName -Type 'Error' -Message $logMessage
    }
    # Si vous voulez désactiver Windows Defender (ne le faites que si vous avez un autre antivirus)
    # Set-MpPreference -DisableAntivirus $true

    # Configuration de la sécurité avancée de Windows Defender. 
    # Cette partie du code modifie le Registre de Windows.
    try {
        # CloudExtendedTimeout : Prolonger la durée de l'analyse de sécurité du cloud jusqu'à un maximum de 60 secondes
        # Documentation : https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-defender
        # Définir la valeur du registre CloudExtendedTimeout à 60 minutes
        # Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows Defender" -Name "CloudExtendedTimeout" -Value 60
        $path = "HKLM:\Software\Policies\Microsoft\Windows Defender\MpEngine"
        $name = "CloudExtendedTimeout"
        $value = 60
       
        $actual = Test-WinChecksRegistryKey -Path $path -Name $name 
        if($null -ne $actual){
            $logMessage = "Valeur actuelle du $name : " +  $(($actual).$name) 
            Write-WinCheckLog -LogPath $logPath -LogName $logName -Type 'Info' -Message $logMessage
        } else{
            $logMessage = "Valeur de $name n'existe pas " 
            Write-WinCheckLog -LogPath $logPath -LogName $logName -Type 'Error' -Message $logMessage
        }  
        # Définir la nouvelle valeur de CloudExtendedTimeout à 60. 
        Set-WinChecksRegistryKey -Path $path -Name $name -Value $value -ErrorAction SilentlyContinue
        $logMessage = "`n" + "$name est défini sur 60 secondes."
        Write-Host $logMessage -ForegroundColor Green
        Write-Host "CloudExtendedTimeout : Prolonger la durée de l'analyse de sécurité du cloud jusqu'à un maximum de 60 secondes"
        Write-Host "Documentation : https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-defender"
        Write-WinCheckLog -LogPath $logPath -LogName $logName -Type 'Info' -Message $logMessage

        # DaysToRetainCleanedMalware : Supprime les éléments mis en quarantaine après un jour
        # Documentation : https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-defender 
        # Définir la valeur de DaysToRetainCleanedMalware à 1 si elle n'est pas déjà définie
        # Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Quarantine" -Name "DaysToRetainCleanedMalware" -Value 1
        $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Quarantine"
        $name = "DaysToRetainCleanedMalware"
        $value = 1  # Défini sur 1 jour

        $actual = Test-WinChecksRegistryKey -Path $path -Name $name 
        if($null -ne $actual){
            $logMessage = "Valeur actuelle du $name : " +  $(($actual).$name) 
            Write-WinCheckLog -LogPath $logPath -LogName $logName -Type 'Info' -Message $logMessage
        } else{
            $logMessage = "Valeur de $name n'existe pas " 
            Write-WinCheckLog -LogPath $logPath -LogName $logName -Type 'Error' -Message $logMessage
        } 
        # Définir la valeur de PurgeItemsAfterDelay à 1 (supprimer après 1 jour)
        # Set-WinChecksRegistryKey -Path $path -Name $name -Value $value -ErrorAction SilentlyContinue
        $logMessage = "`n" + "$name est défini sur 1 jour."
        Write-Host $logMessage -ForegroundColor Green
        Write-Host "DaysToRetainCleanedMalware : Supprime les éléments mis en quarantaine après un jour"
        Write-Host "Documentation : https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-defender"
        Write-WinCheckLog -LogPath $logPath -LogName $logName -Type 'Info' -Message $logMessage
    
        
        # AllowFullScanOnMappedNetworkDrives : Permet à Microsoft Defender d'analyser les lecteurs réseau mappés pendant l'analyse complète.
        # https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-defender 
        # Activer l'analyse complète des lecteurs réseau mappés
        # Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows Defender\Scan" -Name "AllowFullScanOnMappedNetworkDrives" -Value 1
        $path = "HKLM:\Software\Policies\Microsoft\Windows Defender\Scan"
        $name = "AllowFullScanOnMappedNetworkDrives"
        $value = 1
        
        $actual = Test-WinChecksRegistryKey -Path $path -Name $name 
        if($null -ne $actual){
            $logMessage = "Valeur actuelle du $name : " +  $(($actual).$name) 
            Write-WinCheckLog -LogPath $logPath -LogName $logName -Type 'Info' -Message $logMessage
        } else{
            $logMessage = "Valeur de $name n'existe pas " 
            Write-WinCheckLog -LogPath $logPath -LogName $logName -Type 'Error' -Message $logMessage
        } 
        # Définir la valeur de DisableScanningMappedNetworkDrivesForFullScan à 1
        # Set-WinChecksRegistryKey -Path $path -Name $name -Value $value -ErrorAction SilentlyContinue
        $logMessage = "`n" + "$name est défini sur 1."
        Write-Host $logMessage -ForegroundColor Green
        Write-Host "AllowFullScanOnMappedNetworkDrives : Activer l'analyse complète des lecteurs réseau mappés "
        Write-Host "Documentation : https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-defender"
        Write-WinCheckLog -LogPath $logPath -LogName $logName -Type 'Info' -Message $logMessage
    
        
        # CheckForSignaturesBeforeRunningScan : Vérifie les signatures avant de lancer une analyse
        # Documentation : https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-defender 
        # Définir la valeur de CheckForSignaturesBeforeRunningScan à 1 si elle n'est pas déjà définie
        # Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Scan" -Name "CheckForSignaturesBeforeRunningScan" -Value 1 
        $path = "HKLM:\Software\Policies\Microsoft\Windows Defender\Scan"
        $name = "CheckForSignaturesBeforeRunningScan"
        $value = 1
        
        $actual = Test-WinChecksRegistryKey -Path $path -Name $name 
        if($null -ne $actual){
            $logMessage = "Valeur actuelle du $name : " +  $(($actual).$name) 
            Write-WinCheckLog -LogPath $logPath -LogName $logName -Type 'Info' -Message $logMessage
        } else{
            $logMessage = "Valeur de $name n'existe pas " 
            Write-WinCheckLog -LogPath $logPath -LogName $logName -Type 'Error' -Message $logMessage
        } 
        # Définir la valeur de CheckForSignaturesBeforeRunningScan à 1
        # Set-WinChecksRegistryKey -Path $path -Name $name -Value $value -ErrorAction SilentlyContinue
        $logMessage = "`n" + "$name est défini sur 1."
        Write-Host $logMessage -ForegroundColor Green
        Write-Host "CheckForSignaturesBeforeRunningScan : Vérifie les signatures avant de lancer une analyse"
        Write-Host "Documentation : https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-defender"
        Write-WinCheckLog -LogPath $logPath -LogName $logName -Type 'Info' -Message $logMessage
    }
    catch {
        $logMessage =  "Erreurs lors de la configuration de la sécurité avancée de Windows Defender : $_" 
        Write-Host $logMessage -ForegroundColor Red
        Write-WinCheckLog -LogPath $logPath -LogName $logName -Type 'Error' -Message $logMessage    
    }
} # END de fonction : Set-WinCheckDefenderConfig

function Set-WinChecksRegistryKey { #Configure des clés de registre Windows
<#
.DESCRIPTION
	Set-WinChecksRegistryKey. Configure des clés de registre Windows ou ajouter des valeurs spécifiques dans le registre. 
.PARAMETER -path
    Le chemin de la clé de registre où la valeur doit être ajoutée ou modifiée
.PARAMETER -name
    Le nom de la valeur à modifier ou ajouter dans la clé de registre spécifiée.
.PARAMETER -value
    La valeur à définir pour la clé et la valeur de registre spécifiées.
.OUTPUTS
    retun [bool]$keyModifie : qui indique si la clé de registre a été modifiée ou créée avec succès :
    -true si la clé et la valeur ont été modifiées ou créées correctement.
    -false si une erreur est survenue durant l'opération.
.EXAMPLE
    Exemple 1 :
    Set-WinChecksRegistryKey -path "HKLM:\Software\Policies\Microsoft\Windows Defender" -name "CloudExtendedTimeout" -value 60

    Exemple 2 :
    $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Quarantine"
    $name = "DaysToRetainCleanedMalware"
    $value = 1  
    Set-WinChecksRegistryKey -Path $path -Name $name -Value $value 
.LINK
	https://github.com/xEsther-IT/WinChecks
.NOTES
	Author: 2024 @xesther.meza | License: MIT
#>
    Param (
        [string]$path,        # Chemin de la clé de registre à configurer
        [string]$name,        # Nom de la valeur à configurer
        [string]$value        # Valeur à configurer
    )
    # Variable pour indiquer si la clé a été modifiée avec succès
    [bool]$keyModifie = $false

    # Vérifier si la clé et la valeur existent
    if(Test-WinChecksRegistryKey -path $path -name $name){
        # Si la clé existe, tenter de modifier ou ajouter la valeur
        try {
            Set-ItemProperty -Path $path -Name $name -Value $value -ErrorAction SilentlyContinue
            $keyModifie = $true
            # Write-Host "La valeur '$name' a été mise à jour avec succès." -ForegroundColor Green
        }
        catch {
            $keyModifie = $false
            # Write-Host "Erreur lors de la mise à jour de la valeur '$name' : $_" -ForegroundColor Red
        }
    } else {
        # Si la clé n'existe pas, la créer et définir la valeur
        try {
            New-Item -Path $path -Force | Out-Null
            Set-ItemProperty -Path $path -Name $name -Value $value
            $keyModifie = $true
            # Write-Host "La clé '$path' a été créée et la valeur '$name' a été définie à '$value'." -ForegroundColor Green
        } catch {
            $keyModifie = $false
            # Write-Host "Erreur lors de la création de la clé ou de la définition de la valeur : $_" -ForegroundColor Red
        }
    }
    # Retourner l'état de la modification
    return $keyModifie
} # END de function : Set-WinChecksRegistryKey 

function Test-WinChecksRegistryKey { # Vérifie l'existence d'une clé de registre
<#
.DESCRIPTION
	Test-WinChecksRegistryKey. Vérifie l'existence d'une clé de registre et renvoie l'object correspondant à cette clé si elle existe.
.PARAMETER -path
    Le chemin de la clé de registre où la valeur doit être ajoutée ou modifiée
.PARAMETER -name
    Le nom de la valeur à modifier ou ajouter dans la clé de registre spécifiée.
.OUTPUTS
    retun $registry : Si la clé de registre existe et que la valeur est trouvée, la fonction retourne un objet contenant les propriétés de cette valeur.
    Dans le cas contraire, elle retourne $null.
.EXAMPLE
    Exemple 1 :
    $path = "HKLM:\Software\Policies\Microsoft\Windows Defender\Scan"
    $name = "CheckForSignaturesBeforeRunningScan"
    $registry = Test-WinChecksRegistryKey -Path $path -Name $name 
        if($null -ne $registry){ Write-Host "Valeur actuelle du $name : " +  $(($registry).$name) } 
.LINK
	https://github.com/xEsther-IT/WinChecks
.NOTES
	Author: 2024 @xesther.meza | License: MIT
#>
    Param (
        [string]$path,        # Chemin de la clé de registre à vérifier
        [string]$name         # Nom de la valeur à vérifier
    )
    # Variable qui contient la valeur de $path\$name si la clé a été trouvée.
    $registry = $null

    # Vérifier si la clé de registre existe
    if (Test-Path $path) {
        # Si la clé existe, tenter de lire la valeur
        $registry = Get-ItemProperty -Path $path -Name $name -ErrorAction SilentlyContinue
        # $value = $registry.$name
    }
    # Retourner l'état de la vérification (si la valeur a été récupérée Sinon $null)
    return $registry 
} # END de function : Test-WinChecksRegistryKey

function Get-WinCheckSystemReport { # Génere un rapport contenant les informations de sécurité du système
<# 
.SYNOPSIS
     Get-WinCheckSystemReport. Générer un rapport contenant les informations de sécurité du système d'exploitation Windows.

.DESCRIPTION
    Get-WinCheckSystemReport.ps1 script PowerShell recherche les détails du matériel de l'ordinateur local et génère un rapport 
    en français, anglais ou espagnol contenant ces informations : 
    ✅ Informations sur le système d'exploitation
    ✅ Informations sur le processeur
    ✅ Informations sur la mémoire RAM
    ✅ Informations sur les adaptateurs réseau
    ✅ Utilisateurs locaux
    ✅ Logiciels installés
    ✅ Windows Defender (Antivirus)
.PARAMETER -language
    Spécifie la langue du rapport. Par défaut, le rapport sera en français. 
    Options « es » - Espagnol, « en » - Anglais.
.OUTPUTS
    Return $message : Le script génère un rapport au format txt avec les informations recueillies.
    Le repertoir par defaut : C:\temp\xLuna\SystemReport-2024-11-27.txt
    Le rapport est retourné sous forme de chaîne de texte. 
.EXAMPLE
    # Pour générer un rapport en français
	PS> Get-WinCheckSystemReport 
    PS> Get-WinCheckSystemReport -language "fr"
    
    # Pour générer un rapport en anglais
    PS> Get-WinCheckSystemReport -language "en"

    # Pour générer un rapport en espagnol
    PS> Get-WinCheckSystemReport -language "es"
.LINK
	https://github.com/xEsther-IT/WinChecks
.NOTES
    Author: 2024 @xesther.meza | License: MIT
#>
    param (
        # Si aucune valeur n'est passée, utiliser "fr"
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

    # Récupérer WindowsDefender status information
    $message += Get-WinCheckDefenderStatus
    $message += "`n"
    
    # Afficher l'emplacement du rapport
    switch ($language) {
        "fr" { $message += "## Le rapport a été généré et sauvegardé à l'emplacement suivant : " + "`n" }
        "es" { $message += "## El informe se ha generado y guardado en la siguiente ubicación :" + "`n" }
        "en" { $message += "## The report has been generated and saved in the following location : " + "`n" }
    }
    $message += "$logPath\$logName"
    Write-host $message
    # Écrire le rapport
    Write-WinCheckLog -LogPath $logPath -LogName $logName -Type $typeMessage -Message $message

} # END de function : Get-WinCheckSystemReport

function Get-WinCheckBasicSystemInfo { # Collecte des informations de base sur le système Windows.
<#
.DESCRIPTION
	Get-WinCheckBasicSystemInfo. Collecte des informations de base sur le système Windows. Tel que :
    - Informations OS
    - Informations sur le processeur
    - Informations sur la mémoire RAM
    - Informations sur les disques
    - Informations sur les adaptateurs réseau
.PARAMETER -language
    Spécifie la langue du rapport. Par défaut, le rapport sera en français. 
    Options « es » - Espagnol, « en » - Anglais.
.OUTPUTS
    Return $checkMessage : Retourne un rapport détaillé dans un format lisible et structuré. 
    Avec la possibilité de personnaliser la langue (français, espagnol, anglais) pour les titres du rapport.
    Le rapport est retourné sous forme de chaîne de texte. 
.EXAMPLE
    $BasicSystemInfo = Get-WinCheckBasicSystemInfo
    Write-Host $BasicSystemInfo
.LINK
	https://github.com/xEsther-IT/WinChecks
.NOTES
	Author: 2024 @xesther.meza | License: MIT
#>  
    param (
        # Si aucune valeur n'est passée, utiliser "fr"
        [string]$language = "fr"
    )
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
    $checkMessage += "`n"

    # Informations sur le processeur
    switch ($language) {
        "fr" {$checkMessage += "## Informations sur le processeur" + "`n" }
        "es" {$checkMessage += "## Información sobre el procesador" + "`n"  }
        "en" {$checkMessage += "## CPU Information" + "`n" }
    }
    $checkMessage += Get-CimInstance -ClassName Win32_Processor | Select-Object Name, NumberOfCores, MaxClockSpeed | Format-List | Out-String
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
    # Obtenir les informations sur le disque
	# Vérifier si la taille du disque est supérieure à 0
	$diskInfo = Get-CimInstance -ClassName Win32_DiskDrive | Where-Object { $_.Size -gt 0 }
    if ($diskInfo) {
        $diskInfo | ForEach-Object {
            # Ajouter les informations du disque physique
            $checkMessage += "Disk Model: " + $_.Model + "`n"
            $checkMessage += "Size: " + [math]::round($_.Size / 1GB, 2) + " GB" + "`n"
            $checkMessage += "Media Type: " + $_.MediaType + "`n"
            # Maintenant on récupère l'espace libre et utilisé à partir des partitions logiques associées
            $partitions = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $_.DeviceID } | Where-Object { $_.Size -gt 0 }
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

    # Si des adaptateurs réseau connectés sont trouvés
    if ($networkAdapters) {
        $networkAdapters | ForEach-Object {
            # Pour chaque adaptateur, récupérez la configuration réseau associée via InterfaceIndex
            $adapterConfig = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Where-Object { $_.InterfaceIndex -eq $_.InterfaceIndex }

            # Déboguer : Ajouter les valeurs d'InterfaceIndex pour chaque carte
            $checkMessage += "Adapter: $($_.Name), InterfaceIndex: $($_.InterfaceIndex)" + "`n"

            # Si des adresses IP existent
            if ($adapterConfig.IPAddress) {
                $ipAddress = $adapterConfig.IPAddress -join ", "
                $checkMessage += "IP Address for $($_.Name): $ipAddress" + "`n"
                # Ajouter les adresses IP récupérées pour chaque carte
            } else {
                $ipAddress = "Aucune IP"
                $checkMessage += "No IP Address for $($_.Name)" + "`n"
            }

            # Ajouter les informations de l'adaptateur réseau au message
            $checkMessage += "Adapter Name: " + $_.Name + "`n"
            $checkMessage += "MAC Address: " + $_.MACAddress + "`n"
            $checkMessage += "Adresse IP: " + $ipAddress + "`n"
            $checkMessage += "Speed: " + $_.Speed + " bps" + "`n"
            $checkMessage += "`n"  # Saut de ligne pour séparer chaque carte
        }
    } else {
        $checkMessage += "No connected network adapters found." + "`n"
    }

    return $checkMessage
} # END function : Get-WinCheckBasicSystemInfo
 
function Get-WinCheckLocalUserInGroups { # Récupere les utilisateurs locaux d'un système Windows ainsi que les groupes auxquels ces utilisateurs appartiennent. 
<#
.DESCRIPTION
	Get-WinCheckLocalUserInGroups. Récupére les utilisateurs locaux d'un système Windows ainsi que les groupes auxquels ces utilisateurs appartiennent. 
.PARAMETER -users
    [System.Object]$users = $(Get-LocalUser)
.PARAMETER -language
    [string]$language = "fr"
.OUTPUTS
    Return $checkMessage : Après avoir parcouru tous les utilisateurs et déterminé les groupes auxquels chaque utilisateur appartient, le contenu de $checkMessage (le rapport) est retourné.
    Le rapport est retourné sous forme de chaîne de texte.
.EXAMPLE
    Exemple 1 : Récupérer les groupes de tous les utilisateurs locaux :
    $message = Get-WinCheckLocalUserInGroups
    Write-Host $message

    Exemple 2 : Récupérer les groupes d'un utilisateur spécifique :
    $users = Get-LocalUser | Where-Object { $_.Name -match 'Administrator' }
    $message = Get-WinCheckLocalUserInGroups -users $users
    Write-Host $message
.LINK
	https://github.com/xEsther-IT/WinChecks
.NOTES
	Author: 2024 @xesther.meza | License: MIT
#>
    param (
        # Si $users est null, récupérer tous les utilisateurs locaux
        [System.Object]$users = $(Get-LocalUser),
        [string]$language = "fr"
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

function Get-WinCheckInstalledApplications { # Récupere les applications installées
<#
.DESCRIPTION
	Get-WinCheckInstalledApplications. Récupérer et de lister les applications installées sur un système Windows, séparées en deux catégories : les applications 64 bits et les applications 32 bits. 
.PARAMETER -$language
    [string]$language = "fr" 
.OUTPUTS
    Return $checkMessage : Une fois les informations des applications 64 bits et 32 bits collectées et formatées, la fonction retourne la variable $checkMessage qui contient l'intégralité du rapport.
    Le rapport est retourné sous forme de chaîne de texte.
.EXAMPLE
    $installedApps = Get-WinCheckInstalledApplications
    Write-Host $installedApps
.LINK
	https://github.com/xEsther-IT/WinChecks
.NOTES
	Author: 2024 @xesther.meza | License: MIT
#>
    param (
        # Si aucune valeur n'est passée, utiliser "fr"
        [string]$language = "fr"
    )
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

function Write-WinCheckLog { # Écrire des messages (chains de caracteres) dans un fichier spécifié.
<#
.DESCRIPTION
	Write-WinCheckLog. Écrire des messages (chains de caracteres) dans un fichier spécifié. Le script Write-WinCheckLog.ps1 permet d'écrire des messages dans un fichier spécifié tout en affichant les messages dans la console avec une coloration appropriée en fonction du type de message. 
    Ce script permet également de créer des rapports au format texte ou des fichiers de log.
    ℹ️  Info, ✅ Success, ❌ Error, ⚠️ Inconnu
.PARAMETER -logPath
    Chemin du répertoire où enregistrer le fichier de log
.PARAMETER -logName
    Nom du fichier
.PARAMETER -type
    Type de message (Info, Success, Error)
.PARAMETER -message
    Message à enregistrer
.OUTPUTS
    Enregistrement dans le fichier de log :
    Le message est écrit dans le fichier de log avec la date () et type ([INFO], [SUCCESS], [ERROR], [INCONNU]), suivi du message.
    exemple: "2024-11-17 12:45:30" [SUCCESS] Ma fonction pour écrire des logs
.EXAMPLE
    $logPath = "C:\Temp\xLuna"  # Répertoire où le fichier de log sera stocké
    $logName= 'test.log'        # Nom du fichier de log
    $typeMessage = 'Success'    # Type de message (Success)
    $message = 'Ma fonction pour écrire des logs'
    
    # Appel de la fonction Write-WinCheckLog
    # Write-WinCheckLog -LogPath $logPath -LogName $logName -Type $typeMessage -Message $message
.LINK
	https://github.com/xEsther-IT/WinChecks
.NOTES
	Author: 2024 @xesther.meza | License: MIT
#>
    Param (
        [string]$logPath,   # Chemin du répertoire où enregistrer le fichier de log
        [string]$logName,   # Nom du fichier de log
        [string]$typeMessage,   # Type de message (Info, Success, Error)
        [string]$message    # Message à enregistrer
    )

    # Format de la date (exemple: "2024-11-17 12:45:30")
    $dateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Vérifier que le chemin du log est défini
    If ($logPath) {
        # Vérifier si le répertoire existe, sinon le créer
        If (-Not (Test-Path -Path $logPath)) {
            Try {
                New-Item -Path $logPath -ItemType Directory -Force -ErrorAction SilentlyContinue
                Write-Host  "Le répertoire de log a été créé : $logPath" -ForegroundColor Green
            } Catch {
                Write-Host "Impossible de créer le répertoire de log. Erreur : $_" -ForegroundColor Red
                Return
            }
        }

        # Créer le chemin complet du fichier de log
        $LogFilePath = Join-Path -Path $logPath -ChildPath $logName

        # S'assurer que le fichier de log existe, sinon le créer
        If (-Not (Test-Path -Path $LogFilePath)) {
            Try {
                New-Item -Path $LogFilePath -ItemType File -Force -ErrorAction SilentlyContinue
                Write-Host -ForegroundColor Green "Le fichier de log a été créé : $LogFilePath"
            } Catch {
                Write-Host "Impossible de créer le fichier de log. Erreur : $_" -ForegroundColor Red
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
            # Write-Host "$dateTime [INFO] $message"
        }

        "Success" {
            # Enregistrer dans le fichier 
            Add-Content -Path $LogFilePath -Encoding 'UTF-8' -Value "$dateTime [SUCCESS] $message"
            # Afficher dans la console en vert (succès)
            # Write-Host -ForegroundColor Green "$dateTime [SUCCESS] $message"
        }

        "Error" {
            # Enregistrer dans le fichier 
            Add-Content -Path $LogFilePath -Encoding 'UTF-8' -Value "$dateTime [ERROR] $message"
            # Afficher dans la console en rouge (erreur)
            # Write-Host -ForegroundColor Red -BackgroundColor Black "$dateTime [ERROR] $message"
        }

        Default {
            # Enregistrer dans le fichier 
            Add-Content -Path $LogFilePath -Encoding 'UTF-8' -Value "$dateTime [INCONNU] $message"
            # Afficher dans la console en yellow (Inconnu)
            # Write-Host -ForegroundColor Yellow "$dateTime [INCONNU] $message"
        }
    }
} # END function : Write-WinCheckLog
