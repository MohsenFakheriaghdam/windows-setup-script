$usbDrive = (Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 }).DeviceID if (-not $usbDrive) { Write-Host "No USB drive detected! Please insert a USB and try again." -ForegroundColor Red exit }

Write-Host "USB drive detected: $usbDrive" -ForegroundColor Green

$programs = @( "GoogleChromeSetup.exe", "node-vxx.x.x-x64.msi", "Git-xx.x.x-64-bit.exe", "VSCodeSetup-x64.exe", "FirefoxSetup.exe", "SpotPlayerSetup.exe", "winrar-x64.exe", "vlc-x.x.x-win64.exe", "SpotifySetup.exe", "1.1.1.1_WARP.exe", "TelegramSetup.exe", "GitHubDesktopSetup.exe", "FigmaSetup.exe" )

function Find-Program { param ($programName) $locations = Get-ChildItem -Path C:,D:,E:\ -Recurse -Filter $programName -ErrorAction SilentlyContinue if ($locations) { return $locations | Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName } return $null }

$downloadLinks = @{ "GoogleChromeSetup.exe" = "https://dl.google.com/chrome/install/latest/chrome_installer.exe" "VSCodeSetup-x64.exe" = "https://update.code.visualstudio.com/latest/win32-x64/stable" "GitHubDesktopSetup.exe" = "https://central.github.com/deployments/desktop/desktop/latest/win32" }

foreach ($program in $programs) { $filePath = "$usbDrive$program" if (-not (Test-Path $filePath)) { $filePath = Find-Program $program }

if ($filePath) {
    Write-Host "Installing: $program" -ForegroundColor Cyan
    Start-Process -FilePath $filePath -ArgumentList "/silent" -Wait
    Write-Host "$program installed successfully." -ForegroundColor Green
} elseif ($downloadLinks.ContainsKey($program)) {
    Write-Host "$program not found! Downloading..." -ForegroundColor Yellow
    $downloadPath = "$env:TEMP\$program"
    Invoke-WebRequest -Uri $downloadLinks[$program] -OutFile $downloadPath
    Start-Process -FilePath $downloadPath -ArgumentList "/silent" -Wait
    Write-Host "$program downloaded and installed." -ForegroundColor Green
} else {
    Write-Host "$program not found and no download link available!" -ForegroundColor Red
}

}

$licenseFile = "$usbDrive\spotplayer.txt" if (Test-Path $licenseFile) { $licenseKey = Get-Content $licenseFile Write-Host "Applying SpotPlayer license..." -ForegroundColor Yellow Start-Process -FilePath "SpotPlayer.exe" -ArgumentList "/register $licenseKey" -Wait Write-Host "SpotPlayer license applied." -ForegroundColor Green } else { Write-Host "SpotPlayer license file not found!" -ForegroundColor Red }

Write-Host "Syncing VS Code settings..." -ForegroundColor Yellow Start-Process -FilePath "code" -ArgumentList "--sync on" -Wait Write-Host "VS Code settings synced." -ForegroundColor Green

Write-Host "Applying Windows default settings..." -ForegroundColor Cyan

New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0 -PropertyType DWord -Force Write-Host "Dark Mode enabled." -ForegroundColor Green

New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -PropertyType DWord -Force Write-Host "File extensions are now visible." -ForegroundColor Green

New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1 -PropertyType DWord -Force Write-Host "Hidden files are now visible." -ForegroundColor Green

New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Value 0 -PropertyType DWord -Force Write-Host "Notifications disabled." -ForegroundColor Green

Write-Host "Installation and configuration complete. The system will restart in 10 seconds..." -ForegroundColor Magenta Start-Sleep -Seconds 10 Restart-Computer -Force
