. "$PSScriptRoot\FonctionsUtilitaires.ps1"

function TestDNSServer {
    return Get-Service -Name DNS -ErrorAction SilentlyContinue
}

function ConfigDNS {
    if (-not (TestAdminRights)) {
        WriteLog "Droits administrateur requis pour configurer DNS" -Type "ERROR"
        return
    }

    try {
        if (-not (TestDNSServer)) {
            WriteLog "Le service DNS n'est pas installé" -Type "ERROR"
            return
        }

        # Vérification de l'état du service DNS
        $dnsService = Get-Service -Name DNS
        if ($dnsService.Status -ne "Running") {
            WriteLog "Le service DNS n'est pas en cours d'exécution" -Type "ERROR"
            return
        }

        # Implémentation de la configuration DNS personnalisée ici
        WriteLog "Configuration DNS personnalisée à implémenter" -Type "WARNING"
    }
    catch {
        WriteLog "Erreur lors de la configuration DNS: $_" -Type "ERROR"
    }
}
ConfigDNS