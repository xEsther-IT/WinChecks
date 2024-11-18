<#
.SYNOPSIS
	Ecrire des messages de log dans un fichier spécifié 
.DESCRIPTION
	Cet script permet d'écrire des messages de log dans un fichier spécifié tout en affichant les messages dans la console avec une coloration appropriée en fonction du type de message 
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

# # Exemple d'utilisation de la fonction Write-Log
# $LogPath = "C:\Temp\xLuna"  # Répertoire où le fichier de log sera stocké
# $LogName= 'test.log'      # Nom du fichier de log
# $Type = 'Success'         # Type de message (Success)
# $Message = ''

# for($item = 1; $item -le 10; $item ++){
#     $Message += "`n"
#     $Message += "Rapport d'information systeme" + "`n"
#     $Message += "Genere le : " + (Get-Date) + "`n"
#     $Message += "------------------------------------------------------------" + "`n"
#     $Message += "`n"

# }
# # Appel de la fonction Write-Log
# Write-Log -LogPath $LogPath -LogName $LogName -Type $Type -Message $Message

