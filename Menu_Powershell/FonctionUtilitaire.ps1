# Fonctions utilitaires pour les scripts d'administration Active Directory
# FonctionsUtilitaires.ps1
# Date: 2025-05-23

# Fonction pour écrire des logs
function WriteLog {
    param(
        [string]$Message,
        [string]$Type = "INFO"
    )
    $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$date] [$Type] $Message"
    
    # Coloriser la sortie console
    switch ($Type) {
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        default { Write-Host $logMessage -ForegroundColor White }
    }
    
    # Chemin du script actuel (fonctionne dans toutes les versions de PowerShell)
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $logMessage | Out-File -Append -FilePath "$scriptPath\config_log.txt"
}

# Fonction pour vérifier les droits d'administrateur
function TestAdminRights {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Fonction pour convertir un masque de sous-réseau en longueur de préfixe
function ConvertSubnetMaskToPrefixLength {
    param([string]$SubnetMask)
    try {
        $bytes = $SubnetMask.Split('.') | ForEach-Object { [Convert]::ToByte($_) }
        $binary = ($bytes | ForEach-Object { [Convert]::ToString($_, 2).PadLeft(8, '0') }) -join ''
        return ($binary.ToCharArray() | Where-Object { $_ -eq '1' }).Count
    }
    catch {
        WriteLog "Erreur lors de la conversion du masque: $_" -Type "ERROR"
        return $null
    }
}

# Fonction pour valider un nom d'utilisateur
function TestUsername {
    param([string]$Name)
    return $Name -match '^[a-zA-Z0-9-_.]+$'
}