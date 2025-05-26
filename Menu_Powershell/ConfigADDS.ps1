. "$PSScriptRoot\FonctionsUtilitaires.ps1"

function TestDomainName {
    param([string]$Name)
    return $Name -match '^[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*\.[a-zA-Z]{2,}$'
}

function ConfigADDS {
    if (-not (TestAdminRights)) {
        WriteLog "Droits administrateur requis pour configurer AD DS" -Type "ERROR"
        return
    }

    try {
        # Vérification si AD DS est déjà installé
        $addsRole = Get-WindowsFeature AD-Domain-Services
        if (-not $addsRole.Installed) {
            WriteLog "Le rôle AD DS n'est pas installé" -Type "ERROR"
            return
        }

        $domainName = Read-Host "Nom du domaine à créer (ex: monentreprise.local)"
        if (-not (TestDomainName $domainName)) {
            WriteLog "Format de nom de domaine invalide" -Type "ERROR"
            return
        }

        # Vérification de l'espace disque
        $systemDrive = (Get-Item $env:windir).PSDrive.Name
        $freeSpace = (Get-PSDrive $systemDrive).Free
        if ($freeSpace -lt 10GB) {
            WriteLog "Espace disque insuffisant. 10 Go minimum requis" -Type "ERROR"
            return
        }

        # Vérification de la mémoire RAM
        $totalRam = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory
        if ($totalRam -lt 2GB) {
            WriteLog "Mémoire RAM insuffisante. 2 Go minimum requis" -Type "ERROR"
            return
        }

        Install-ADDSForest -DomainName $domainName -InstallDNS -Force -NoRebootOnCompletion
        WriteLog "Installation du contrôleur de domaine pour $domainName terminée" -Type "SUCCESS"
    }
    catch {
        WriteLog "Erreur lors de la configuration AD DS: $_" -Type "ERROR"
    }
}
ConfigADDS