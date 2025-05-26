# Script pour importer des utilisateurs depuis un CSV
# ImportCSV.ps1
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

function TestUsername {
    param([string]$Name)
    return $Name -match '^[a-zA-Z0-9-_.]+$'
}

function TestCSVFormat {
    param([string]$Path)
    try {
        $csv = Import-Csv $Path -Encoding UTF8
        $requiredColumns = @('Name', 'Username', 'Password')
        $headerNames = ($csv | Get-Member -MemberType NoteProperty).Name
        
        $missingColumns = $requiredColumns | Where-Object { $_ -notin $headerNames }
        if ($missingColumns) {
            WriteLog "Colonnes manquantes dans le CSV: $($missingColumns -join ', ')" -Type "ERROR"
            return $false
        }
        
        if ($csv.Count -eq 0) {
            WriteLog "Le fichier CSV est vide" -Type "ERROR"
            return $false
        }
        
        return $true
    }
    catch {
        WriteLog "Erreur lors de la lecture du CSV: $_" -Type "ERROR"
        return $false
    }
}

function ImportCSV {
    if (-not (TestAdminRights)) {
        WriteLog "Droits administrateur requis pour importer des utilisateurs" -Type "ERROR"
        return
    }

    try {
        if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
            WriteLog "Le module Active Directory n'est pas installé" -Type "ERROR"
            return
        }

        if (-not (Get-Command Get-ADDomain -ErrorAction SilentlyContinue)) {
            WriteLog "Active Directory n'est pas configuré sur ce serveur" -Type "ERROR"
            return
        }

        $csvPath = Read-Host "Chemin du fichier CSV"
        
        if (-not (Test-Path -Path $csvPath -PathType Leaf)) {
            WriteLog "Le fichier CSV n'existe pas ou n'est pas un fichier" -Type "ERROR"
            return
        }

        if (-not $csvPath.EndsWith('.csv')) {
            WriteLog "Le fichier doit être au format CSV" -Type "ERROR"
            return
        }

        if (-not (TestCSVFormat $csvPath)) {
            return
        }

        try {
            $domain = Get-ADDomain
            $ouPath = "OU=Utilisateurs,$($domain.DistinguishedName)"
        }
        catch {
            WriteLog "Impossible de récupérer les informations du domaine: $_" -Type "ERROR"
            return
        }

        if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ouPath'" -ErrorAction SilentlyContinue)) {
            WriteLog "L'OU 'Utilisateurs' n'existe pas" -Type "ERROR"
            return
        }

        $successCount = 0
        $errorCount = 0
        $skippedCount = 0
        
        $users = Import-Csv $csvPath -Encoding UTF8
        WriteLog "Début de l'importation de $($users.Count) utilisateurs" -Type "INFO"

        foreach ($user in $users) {
            try {
                if ([string]::IsNullOrWhiteSpace($user.Username) -or 
                    [string]::IsNullOrWhiteSpace($user.Password) -or 
                    [string]::IsNullOrWhiteSpace($user.Name)) {
                    WriteLog "Données manquantes pour l'utilisateur: $($user.Username)" -Type "WARNING"
                    $skippedCount++
                    continue
                }

                if (-not (TestUsername $user.Username)) {
                    WriteLog "Nom d'utilisateur invalide: $($user.Username)" -Type "WARNING"
                    $skippedCount++
                    continue
                }

                if (Get-ADUser -Filter "SamAccountName -eq '$($user.Username)'" -ErrorAction SilentlyContinue) {
                    WriteLog "L'utilisateur $($user.Username) existe déjà" -Type "WARNING"
                    $skippedCount++
                    continue
                }

                $userParams = @{
                    Name              = $user.Name
                    SamAccountName    = $user.Username
                    AccountPassword   = (ConvertTo-SecureString $user.Password -AsPlainText -Force)
                    Enabled           = $true
                    Path              = $ouPath
                    UserPrincipalName = "$($user.Username)@$($domain.DNSRoot)"
                    DisplayName       = $user.Name
                }

                New-ADUser @userParams
                WriteLog "Utilisateur créé avec succès: $($user.Username)" -Type "SUCCESS"
                $successCount++
            }
            catch {
                WriteLog "Erreur lors de la création de l'utilisateur $($user.Username): $_" -Type "ERROR"
                $errorCount++
            }
        }

        $statusType = if ($errorCount -eq 0 -and $skippedCount -eq 0) {
            "SUCCESS"
        }
        elseif ($errorCount -eq 0) {
            "WARNING"
        }
        else {
            "ERROR"
        }

        WriteLog "Importation terminée." -Type "INFO"
        WriteLog "Résumé: $successCount créés, $errorCount erreurs, $skippedCount ignorés" -Type $statusType
    }
    catch {
        WriteLog "Erreur critique lors de l'importation: $_" -Type "ERROR"
    }
}

# Exécution de la fonction principale
ImportCSV