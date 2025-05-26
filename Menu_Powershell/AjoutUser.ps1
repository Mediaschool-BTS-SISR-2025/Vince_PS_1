. "$PSScriptRoot\FonctionsUtilitaires.ps1"

function TestUsername {
    param([string]$Name)
    return $Name -match '^[a-zA-Z0-9-_.]+$'
}

function TestPassword {
    param([string]$Password)
    return $Password -match '^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$'
}

function AjouterUtilisateur {
    if (-not (TestAdminRights)) {
        WriteLog "Droits administrateur requis pour créer un utilisateur" -Type "ERROR"
        return
    }

    try {
        # Vérification si AD DS est configuré
        if (-not (Get-Command Get-ADDomain -ErrorAction SilentlyContinue)) {
            WriteLog "Active Directory n'est pas configuré sur ce serveur" -Type "ERROR"
            return
        }

        $username = Read-Host "Nom d'utilisateur"
        if (-not (TestUsername $username)) {
            WriteLog "Nom d'utilisateur invalide. Utilisez uniquement des lettres, chiffres, tirets, points et underscores" -Type "ERROR"
            return
        }

        # Vérification si l'utilisateur existe déjà
        if (Get-ADUser -Filter "SamAccountName -eq '$username'" -ErrorAction SilentlyContinue) {
            WriteLog "Un utilisateur avec ce nom existe déjà" -Type "ERROR"
            return
        }

        $password = Read-Host "Mot de passe" -AsSecureString
        $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
        if (-not (TestPassword $plainPassword)) {
            WriteLog "Le mot de passe doit contenir au moins 8 caractères, une majuscule, une minuscule, un chiffre et un caractère spécial" -Type "ERROR"
            return
        }

        # Vérification si l'OU Utilisateurs existe
        $ouPath = "OU=Utilisateurs,DC=monentreprise,DC=local"
        if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ouPath'" -ErrorAction SilentlyContinue)) {
            WriteLog "L'OU 'Utilisateurs' n'existe pas" -Type "ERROR"
            return
        }

        New-ADUser -Name $username -SamAccountName $username -AccountPassword $password -Enabled $true -Path $ouPath
        WriteLog "Utilisateur '$username' créé avec succès" -Type "SUCCESS"
    }
    catch {
        WriteLog "Erreur lors de la création de l'utilisateur: $_" -Type "ERROR"
    }
}
AjouterUtilisateur