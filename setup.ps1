param (
    [string]$gitToken
)

# URL del repo con token
$repoUrl = "https://$gitToken@github.com/LINK-DANNY/insuPro.git"
$sitePath = "C:\inetpub\insuPro"

# Instalar Git
$gitInstaller = "C:\git_installer.exe"
Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/download/v2.45.1.windows.1/Git-2.45.1-64-bit.exe" -OutFile $gitInstaller
Start-Process -FilePath $gitInstaller -ArgumentList "/VERYSILENT" -Wait

# Clonar proyecto
git clone $repoUrl $sitePath

# Instalar IIS
Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature -IncludeManagementTools

# Instalar URL Rewrite
$rewriteUrl = "https://download.microsoft.com/download/D/D/9/DD9BD2E0-7ACD-4E29-A246-75C9DF9354F1/rewrite_amd64_en-US.msi"
$rewriteInstaller = "$env:TEMP\rewrite.msi"
Invoke-WebRequest -Uri $rewriteUrl -OutFile $rewriteInstaller
Start-Process msiexec.exe -ArgumentList "/i $rewriteInstaller /quiet /norestart" -Wait

# Descargar e instalar PHP
$phpZip = "C:\php.zip"
Invoke-WebRequest -Uri "https://windows.php.net/downloads/releases/php-8.1.27-nts-Win32-vs16-x64.zip" -OutFile $phpZip
Expand-Archive -Path $phpZip -DestinationPath "C:\php"

# Configurar PHP
if (-not (Test-Path "HKLM:\SOFTWARE\PHP")) {
    New-Item -Path "HKLM:\SOFTWARE\PHP" -Force
}
Set-ItemProperty -Path "HKLM:\SOFTWARE\PHP" -Name "InstallDir" -Value "C:\php"
[Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";C:\php", [EnvironmentVariableTarget]::Machine)

# Configurar FastCGI en IIS
& "$env:SystemRoot\System32\inetsrv\appcmd.exe" set config /section:system.webServer/fastCgi /+"[fullPath='C:\php\php-cgi.exe']"
& "$env:SystemRoot\System32\inetsrv\appcmd.exe" set config /section:system.webServer/handlers /+"[name='PHP-FastCGI',path='*.php',verb='GET,HEAD,POST',modules='FastCgiModule',scriptProcessor='C:\php\php-cgi.exe',resourceType='Either']"

# Crear sitio en IIS
Import-Module WebAdministration
if (Test-Path "IIS:\Sites\insuPro") {
    Remove-Website -Name "insuPro"
}
New-Website -Name "insuPro" -Port 8081 -PhysicalPath $sitePath -ApplicationPool ".NET v4.5" -Force

# Asignar permisos
icacls $sitePath /grant "IIS_IUSRS:(OI)(CI)(RX)" /T

# Mensaje final sin símbolos especiales
Write-Host "Proyecto insuPro desplegado en http://localhost:8081"
