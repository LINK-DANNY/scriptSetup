param (
    [string]$gitToken
)

# URL del repo con token personal
$repoUrl = "https://$gitToken@github.com/LINK-DANNY/insuPro.git"
$sitePath = "C:\inetpub\insuPro"

# 1. Instalar Git
$gitInstaller = "C:\git_installer.exe"
Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/download/v2.45.1.windows.1/Git-2.45.1-64-bit.exe" -OutFile $gitInstaller
Start-Process -FilePath $gitInstaller -ArgumentList "/VERYSILENT" -Wait

# 2. Agregar Git al PATH del sistema
$gitCmdPath = "C:\Program Files\Git\cmd"
if (Test-Path $gitCmdPath) {
    [Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";$gitCmdPath", [EnvironmentVariableTarget]::Machine)
    # También actualizar para la sesión actual
    $env:PATH += ";$gitCmdPath"
}

# 3. Confirmar que Git está disponible
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host "Git instalado correctamente."
} else {
    Write-Host "Git no está disponible. Revisa la instalación."
}

# 4. Clonar el proyecto desde GitHub
git clone $repoUrl $sitePath

# 5. Instalar IIS
Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature -IncludeManagementTools

# 6. Instalar URL Rewrite
$rewriteUrl = "https://download.microsoft.com/download/D/D/9/DD9BD2E0-7ACD-4E29-A246-75C9DF9354F1/rewrite_amd64_en-US.msi"
$rewriteInstaller = "$env:TEMP\rewrite.msi"
Invoke-WebRequest -Uri $rewriteUrl -OutFile $rewriteInstaller
Start-Process msiexec.exe -ArgumentList "/i $rewriteInstaller /quiet /norestart" -Wait

# 7. Descargar e instalar PHP
$phpZip = "C:\php.zip"
Invoke-WebRequest -Uri "https://windows.php.net/downloads/releases/php-8.1.27-nts-Win32-vs16-x64.zip" -OutFile $phpZip
Expand-Archive -Path $phpZip -DestinationPath "C:\php"

# 8. Configurar PHP
if (-not (Test-Path "HKLM:\SOFTWARE\PHP")) {
    New-Item -Path "HKLM:\SOFTWARE\PHP" -Force
}
Set-ItemProperty -Path "HKLM:\SOFTWARE\PHP" -Name "InstallDir" -Value "C:\php"
[Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";C:\php", [EnvironmentVariableTarget]::Machine)
$env:PATH += ";C:\php"

# 9. Configurar FastCGI en IIS
& "$env:SystemRoot\System32\inetsrv\appcmd.exe" set config /section:system.webServer/fastCgi /+"[fullPath='C:\php\php-cgi.exe']"
& "$env:SystemRoot\System32\inetsrv\appcmd.exe" set config /section:system.webServer/handlers /+"[name='PHP-FastCGI',path='*.php',verb='GET,HEAD,POST',modules='FastCgiModule',scriptProcessor='C:\php\php-cgi.exe',resourceType='Either']"

# 10. Crear sitio en IIS
Import-Module WebAdministration
if (Test-Path "IIS:\Sites\insuPro") {
    Remove-Website -Name "insuPro"
}
New-Website -Name "insuPro" -Port 8081 -PhysicalPath $sitePath -ApplicationPool ".NET v4.5" -Force

# 11. Asignar permisos
icacls $sitePath /grant "IIS_IUSRS:(OI)(CI)(RX)" /T

# 12. Mensaje final
Write-Host "Proyecto insuPro desplegado en http://localhost:8081"
