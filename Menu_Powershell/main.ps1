# Menu principal pour la configuration Active Directory
# Menu.ps1
# Date: 2025-05-23
# Auteur: Vinceadr

# Configuration de l'encodage pour les caractères accentués
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Fonction pour vérifier que les scripts existent
function VerifierScripts {
    $scripts = @(
        "RenommerPC.ps1",
        "ConfigIPFixe.ps1",
        "InstallerRoles.ps1",
        "ConfigADDS.ps1",
        "ConfigDNS.ps1",
        "ConfigDHCP.ps1",
        "AjouterOU.ps1",
        "AjouterGroupe.ps1",
        "AjouterUtilisateur.ps1",
        "ImportCSV.ps1"
    )
    
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $manquants = @()
    
    foreach ($script in $scripts) {
        if (-not (Test-Path -Path "$scriptPath\$script")) {
            $manquants += $script
        }
    }
    
    if ($manquants.Count -gt 0) {
        Write-Host "ATTENTION: Les scripts suivants sont manquants:" -ForegroundColor Red
        foreach ($script in $manquants) {
            Write-Host "  - $script" -ForegroundColor Red
        }
        return $false
    }
    
    return $true
}

# Boucle principale du menu
$continue = $true

while ($continue) {
    Clear-Host
    Write-Host "----------------------------------------------------------------------------"
    Write-Host "------------------------------ Config de base ------------------------------"
    Write-Host "............................. 1 - Renommer PC .............................."
    Write-Host ".......................... 2 - Addressage IP fixe .........................."
    Write-Host "..................... 3 - Installation ADDS, DHCP et DNS ..................."
    Write-Host "----------------------------------------------------------------------------"
    Write-Host "------------------------- Configuration du domaine -------------------------"
    Write-Host "....................... 4 - Configuration du ADDS .........................."
    Write-Host "....................... 5 - Configuration du DNS ..........................."
    Write-Host "....................... 6 - Configuration du DHCP .........................."
    Write-Host "----------------------------------------------------------------------------"
    Write-Host "--------------- Configuration Active Directory et utilisateur --------------"
    Write-Host "........................... 7 - Ajout d'une OU ............................."
    Write-Host ".................... 8 - Ajout d'un groupe d'utilisateur ..................."
    Write-Host "...................... 9 - Ajouter un utilisateur .........................."
    Write-Host "....................... 10 - Import depuis un CSV .........................."
    Write-Host "----------------------------------------------------------------------------"
    Write-Host "........................... 0 - Quitter ...................................."
    Write-Host "----------------------------------------------------------------------------"

    $choix = Read-Host "Entrez votre choix (0-10)"

    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    
    switch ($choix) {
        "1" { & "$scriptPath\RenommerPC.ps1" }
        "2" { & "$scriptPath\ConfigIPFixe.ps1" }
        "3" { & "$scriptPath\InstallerRoles.ps1" }
        "4" { & "$scriptPath\ConfigADDS.ps1" }
        "5" { & "$scriptPath\ConfigDNS.ps1" }
        "6" { & "$scriptPath\ConfigDHCP.ps1" }
        "7" { & "$scriptPath\AjouterOU.ps1" }
        "8" { & "$scriptPath\AjouterGroupe.ps1" }
        "9" { & "$scriptPath\AjouterUtilisateur.ps1" }
        "10" { & "$scriptPath\ImportCSV.ps1" }
        "0" {
            Write-Host "Fermeture du menu. À bientôt !" -ForegroundColor Green
            $continue = $false
        }
        default {
            Write-Host "Choix invalide. Veuillez entrer un nombre entre 0 et 10." -ForegroundColor Red
        }
    }

    if ($continue) {
        Write-Host "Appuyez sur une touche pour continuer..." -ForegroundColor Cyan
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}