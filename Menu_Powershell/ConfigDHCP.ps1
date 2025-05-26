. "$PSScriptRoot\FonctionsUtilitaires.ps1"

function TestDHCPServer {
    return Get-Service -Name DHCPServer -ErrorAction SilentlyContinue
}

function ConfigDHCP {
    if (-not (TestAdminRights)) {
        WriteLog "Droits administrateur requis pour configurer DHCP" -Type "ERROR"
        return
    }

    try {
        if (-not (TestDHCPServer)) {
            WriteLog "Le service DHCP n'est pas installé" -Type "ERROR"
            return
        }

        # Vérification de l'état du service DHCP
        $dhcpService = Get-Service -Name DHCPServer
        if ($dhcpService.Status -ne "Running") {
            WriteLog "Le service DHCP n'est pas en cours d'exécution" -Type "ERROR"
            return
        }

        # Implémentation de la configuration DHCP personnalisée ici
        WriteLog "Configuration DHCP personnalisée à implémenter" -Type "WARNING"
    }
    catch {
        WriteLog "Erreur lors de la configuration DHCP: $_" -Type "ERROR"
    }
}
ConfigDHCP