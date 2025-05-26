. "$PSScriptRoot\FonctionsUtilitaires.ps1"

function TestWindowsServer {
    $os = Get-WmiObject -Class Win32_OperatingSystem
    return $os.ProductType -eq 2 -or $os.ProductType -eq 3
}

function InstallerRoles {
    if (-not (TestAdminRights)) {
        WriteLog "Droits administrateur requis pour installer les rôles" -Type "ERROR"
        return
    }

    if (-not (TestWindowsServer)) {
        WriteLog "Cette fonction nécessite Windows Server" -Type "ERROR"
        return
    }

    try {
        # Vérification des rôles existants
        $rolesExistants = Get-WindowsFeature | Where-Object { $_.Installed -eq $true }
        $rolesNecessaires = @("AD-Domain-Services", "DHCP", "DNS")
        
        foreach ($role in $rolesNecessaires) {
            if ($rolesExistants.Name -contains $role) {
                WriteLog "Le rôle $role est déjà installé" -Type "WARNING"
            }
        }

        Install-WindowsFeature -Name $rolesNecessaires -IncludeManagementTools
        
        # Vérification post-installation
        $rolesInstalles = Get-WindowsFeature | Where-Object { $_.Installed -eq $true }
        $success = $true
        
        foreach ($role in $rolesNecessaires) {
            if ($rolesInstalles.Name -notcontains $role) {
                WriteLog "Échec de l'installation du rôle $role" -Type "ERROR"
                $success = $false
            }
        }

        if ($success) {
            WriteLog "Tous les rôles ont été installés avec succès" -Type "SUCCESS"
        }
    }
    catch {
        WriteLog "Erreur lors de l'installation des rôles: $_" -Type "ERROR"
    }
}
InstallerRoles