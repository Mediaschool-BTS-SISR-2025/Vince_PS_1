. "$PSScriptRoot\FonctionsUtilitaires.ps1"

function TestOUName {
    param([string]$Name)
    return $Name -match '^[a-zA-Z0-9- ]+$'
}

function AjouterOU {
    if (-not (TestAdminRights)) {
        WriteLog "Droits administrateur requis pour créer une OU" -Type "ERROR"
        return
    }

    try {
        # Vérification si AD DS est configuré
        if (-not (Get-Command Get-ADDomain -ErrorAction SilentlyContinue)) {
            WriteLog "Active Directory n'est pas configuré sur ce serveur" -Type "ERROR"
            return
        }

        $ouName = Read-Host "Nom de l'OU"
        if (-not (TestOUName $ouName)) {
            WriteLog "Nom d'OU invalide. Utilisez uniquement des lettres, chiffres, espaces et tirets" -Type "ERROR"
            return
        }

        # Vérification si l'OU existe déjà
        $domainDN = (Get-ADDomain).DistinguishedName
        if (Get-ADOrganizationalUnit -Filter "Name -eq '$ouName'" -SearchBase $domainDN -ErrorAction SilentlyContinue) {
            WriteLog "Une OU avec ce nom existe déjà" -Type "ERROR"
            return
        }

        New-ADOrganizationalUnit -Name $ouName -Path $domainDN -ProtectedFromAccidentalDeletion $true
        WriteLog "OU '$ouName' créée avec succès" -Type "SUCCESS"
    }
    catch {
        WriteLog "Erreur lors de la création de l'OU: $_" -Type "ERROR"
    }
}
AjouterOU