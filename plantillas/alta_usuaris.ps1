

Import-Module ActiveDirectory

# --- Variables generales ---
$rutaCsv = "$PSScriptRoot\usuaris_alta.csv"
$dominio = "techcorp.local"
$baseOU  = "OU=Departaments,OU=TechCorp,DC=techcorp,DC=local"

# --- (2) Contrasena por defecto compleja ---
$passTexto = "TechCorp@2026!"
$password  = ConvertTo-SecureString $passTexto -AsPlainText -Force

# --- (1) Lectura automatizada del CSV ---
$usuarios = Import-Csv -Path $rutaCsv -Encoding UTF8

foreach ($u in $usuarios) {

    $sam   = $u.samAccountName
    $ruta  = "OU=$($u.OU),$baseOU"
    $grupo = "GG_$($u.department)"

    # --- Control de duplicados ---
    if (Get-ADUser -Filter "SamAccountName -eq '$sam'") {
        Write-Warning "El usuario $sam ya existe. Se omite."
        continue
    }

    try {
        # --- (3) y (4) Creacion con atributos y cambio de contrasena obligatorio ---
        $params = @{
            Name                  = "$($u.givenName) $($u.sn)"
            GivenName             = $u.givenName
            Surname               = $u.sn
            DisplayName           = "$($u.givenName) $($u.sn)"
            SamAccountName        = $sam
            UserPrincipalName     = "$sam@$dominio"
            Department            = $u.department
            Path                  = $ruta
            AccountPassword       = $password
            ChangePasswordAtLogon = $true
            Enabled               = $true
            ErrorAction           = "Stop"
        }
        if ($u.title) { $params.Title = $u.title }

        New-ADUser @params
        Write-Host "Usuario creado: $sam en OU $($u.OU)" -ForegroundColor Green

        # --- (5) Asignacion automatica al grupo departamental ---
        Add-ADGroupMember -Identity $grupo -Members $sam -ErrorAction Stop
        Write-Host "   -> anadido al grupo $grupo" -ForegroundColor Cyan
    }
    catch {
        Write-Warning "Error con $sam : $($_.Exception.Message)"
    }
}

Write-Host "Proceso finalizado." -ForegroundColor Yellow