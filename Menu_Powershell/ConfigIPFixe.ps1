# Script pour configurer une adresse IP fixe
# ConfigIPFixe.ps1
# Date: 2025-05-23

# Fonctions nécessaires
function WriteLog {
    param(
        [string]$Message,
        [string]$Type = "INFO"
    )
    $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$date] [$Type] $Message"
    
    switch ($Type) {
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        default { Write-Host $logMessage -ForegroundColor White }
    }
    
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $logMessage | Out-File -Append -FilePath "$scriptPath\config_log.txt"
}

function TestAdminRights {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function TestIPAddress {
    param([string]$IP)
    return $IP -match '^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
}

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

function ConfigIPFixe {
    if (-not (TestAdminRights)) {
        WriteLog "Droits administrateur requis pour configurer l'IP" -Type "ERROR"
        return
    }

    try {
        $interface = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
        if (-not $interface) {
            WriteLog "Aucune interface réseau active trouvée" -Type "ERROR"
            return
        }

        $ip = Read-Host "Entrez l'adresse IP (ex: 192.168.1.100)"
        if (-not (TestIPAddress $ip)) {
            WriteLog "Format d'adresse IP invalide" -Type "ERROR"
            return
        }

        $maskInput = Read-Host "Entrez le masque de sous-réseau (ex: 255.255.255.0) ou le préfixe (ex: 24)"
        if ($maskInput -match '^\d+$') {
            $prefixLength = [int]$maskInput
            if ($prefixLength -lt 0 -or $prefixLength -gt 32) {
                WriteLog "Préfixe invalide (doit être entre 0 et 32)" -Type "ERROR"
                return
            }
        }
        elseif ($maskInput -match '^(\d{1,3}\.){3}\d{1,3}$') {
            $prefixLength = ConvertSubnetMaskToPrefixLength -SubnetMask $maskInput
            if (-not $prefixLength) {
                WriteLog "Masque de sous-réseau invalide" -Type "ERROR"
                return
            }
        }
        else {
            WriteLog "Format de masque/préfixe invalide" -Type "ERROR"
            return
        }

        $gateway = Read-Host "Entrez la passerelle (ex: 192.168.1.1)"
        if (-not (TestIPAddress $gateway)) {
            WriteLog "Format de passerelle invalide" -Type "ERROR"
            return
        }

        New-NetIPAddress -InterfaceAlias $interface.Name -IPAddress $ip -PrefixLength $prefixLength -DefaultGateway $gateway
        WriteLog "Adresse IP configurée sur l'interface $($interface.Name)" -Type "SUCCESS"
    }
    catch {
        WriteLog "Erreur lors de la configuration IP: $_" -Type "ERROR"
    }
}

# Exécution de la fonction principale
ConfigIPFixe