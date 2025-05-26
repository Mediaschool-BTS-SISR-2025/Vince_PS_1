. "$PSScriptRoot\FonctionsUtilitaires.ps1"

function TestGroupName {
    param([string]$Name)
    return $Name -match '^[a-zA-Z0-9- ]+$'
}

function AjouterGroupe {
    if (-not (TestAdminRights)) {
        WriteLog "Droits administrateur requis pour créer un groupe" -Type "ERROR"
        return
    }

    try {
        # Vérification si AD DS est configuré
        if (-not (Get-Command Get-ADDomain -ErrorAction SilentlyContinue)) {
            WriteLog "Active Directory n'est pas configuré sur ce serveur" -Type "ERROR"
            return
        }

        $groupName = Read-Host "Nom du groupe"
        if (-not (TestGroupName $groupName)) {
            WriteLog "Nom de groupe invalide. Utilisez uniquement des lettres, chiffres, espaces et tirets" -Type "ERROR"
            return
        }

        # Vérification si le groupe existe déjà
        if (Get-ADGroup -Filter "Name -eq '$groupName'" -ErrorAction SilentlyContinue) {
            WriteLog "Un groupe avec ce nom existe déjà" -Type "ERROR"
            return
        }

        # Vérification si l'OU Utilisateurs existe
        $ouPath = "OU=Utilisateurs,DC=monentreprise,DC=local"
        if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ouPath'" -ErrorAction SilentlyContinue)) {
            WriteLog "L'OU 'Utilisateurs' n'existe pas" -Type "ERROR"
            return
        }

        New-ADGroup -Name $groupName -GroupScope Global -Path $ouPath
        WriteLog "Groupe '$groupName' créé avec succès" -Type "SUCCESS"
    }
    catch {
        WriteLog "Erreur lors de la création du groupe: $_" -Type "ERROR"
    }
}
AjouterGroupe