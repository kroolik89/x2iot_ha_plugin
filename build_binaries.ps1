# Skrypt wspomagający ręczne budowanie binarek do rootfs

$RootFolder = "$PSScriptRoot\.."

Write-Host "Budowanie release dla x2iot-app (amd64)..." -ForegroundColor Cyan
Set-Location $RootFolder
cargo leptos build --release

$TargetDirAmd64 = "$PSScriptRoot\x2iot\rootfs\app\bin\amd64"
$TargetDirSite = "$PSScriptRoot\x2iot\rootfs\app\site"

if (!(Test-Path -Path $TargetDirAmd64)) {
    New-Item -ItemType Directory -Force -Path $TargetDirAmd64
}
if (!(Test-Path -Path $TargetDirSite)) {
    New-Item -ItemType Directory -Force -Path $TargetDirSite
}

Write-Host "Kopiowanie plików amd64..." -ForegroundColor Cyan
Copy-Item "$RootFolder\target\release\x2iot-app.exe" -Destination "$TargetDirAmd64\x2iot-app" -Force
# Uwaga: Linux build z poziomu windows wymaga cross, poniżej by wyglądało:
# cross build --target aarch64-unknown-linux-gnu --release
# Copy-Item "$RootFolder\target\aarch64-unknown-linux-gnu\release\x2iot-app" -Destination "$PSScriptRoot\x2iot\rootfs\app\bin\aarch64\x2iot-app" -Force

Write-Host "Kopiowanie site assets..." -ForegroundColor Cyan
Copy-Item "$RootFolder\target\site\*" -Destination $TargetDirSite -Recurse -Force

Write-Host "Gotowe. Można uruchomić docker build w katalogu ha-addon/x2iot" -ForegroundColor Green
