# Skrypt wspomagający środowisko i budowanie binarek do rootfs dla Home Assistant (Alpine/musl)

$RootFolder = "$PSScriptRoot\.."
Set-Location $RootFolder

Write-Host "--- KROK 0: Sprawdzanie i przygotowanie środowiska ---" -ForegroundColor Magenta

# 1. Sprawdzenie czy Docker działa
Write-Host "Sprawdzam status Dockera..." -ForegroundColor Cyan
docker info >$null 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "BŁĄD: Docker nie jest uruchomiony lub nie jest zainstalowany!" -ForegroundColor Red
    Write-Host "Uruchom Docker Desktop, poczekaj aż się załaduje i spróbuj ponownie uruchomić ten skrypt." -ForegroundColor Yellow
    exit 1
}
Write-Host "Docker jest uruchomiony." -ForegroundColor Green

# 2. Sprawdzenie cargo-leptos
Write-Host "Sprawdzam cargo-leptos..." -ForegroundColor Cyan
if (!(Get-Command "cargo-leptos" -ErrorAction SilentlyContinue)) {
    Write-Host "Instalowanie cargo-leptos..." -ForegroundColor Yellow
    cargo install cargo-leptos
} else {
    Write-Host "cargo-leptos jest już zainstalowane." -ForegroundColor Green
}

# 3. Sprawdzenie cross
Write-Host "Sprawdzam cross..." -ForegroundColor Cyan
if (!(Get-Command "cross" -ErrorAction SilentlyContinue)) {
    Write-Host "Instalowanie cross..." -ForegroundColor Yellow
    cargo install cross --git https://github.com/cross-rs/cross
} else {
    Write-Host "cross jest już zainstalowane." -ForegroundColor Green
}

# 4. Instalacja targetów
Write-Host "Dodawanie targetów kompilacji (musl)..." -ForegroundColor Cyan
rustup target add aarch64-unknown-linux-gnu x86_64-unknown-linux-gnu

Write-Host "--- Środowisko gotowe. Przechodzę do budowania ---" -ForegroundColor Magenta

# 1. Budowanie assetów frontendowych (WASM + CSS + JS)
# cargo-leptos musi zostać uruchomiony raz, aby wygenerować folder site/
# Na razie uruchamiamy go natywnie (buduje WASM clienta i assety).
# Binarkę serwera z tego kroku IGNORUJEMY (będzie windowsowa).
Write-Host "Budowanie frontend assets (cargo leptos)..." -ForegroundColor Cyan
cargo leptos build --release

# 2. Budowanie serwera dla amd64 (x86_64-unknown-linux-musl)
Write-Host "Budowanie release x2iot-app (amd64/musl)..." -ForegroundColor Cyan
cross build --package x2iot-app --features ssr --target x86_64-unknown-linux-gnu --release

$TargetDirAmd64 = "$PSScriptRoot\x2iot\rootfs\app\bin\amd64"
if (!(Test-Path -Path $TargetDirAmd64)) {
    New-Item -ItemType Directory -Force -Path $TargetDirAmd64
}
Copy-Item "$RootFolder\target\x86_64-unknown-linux-gnu\release\x2iot-app" -Destination "$TargetDirAmd64\x2iot-app" -Force

# 3. Budowanie serwera dla aarch64 (aarch64-unknown-linux-musl)
Write-Host "Budowanie release x2iot-app (aarch64/musl)..." -ForegroundColor Cyan
cross build --package x2iot-app --features ssr --target aarch64-unknown-linux-gnu --release

$TargetDirAarch64 = "$PSScriptRoot\x2iot\rootfs\app\bin\aarch64"
if (!(Test-Path -Path $TargetDirAarch64)) {
    New-Item -ItemType Directory -Force -Path $TargetDirAarch64
}
Copy-Item "$RootFolder\target\aarch64-unknown-linux-gnu\release\x2iot-app" -Destination "$TargetDirAarch64\x2iot-app" -Force

# 4. Kopiowanie assetów site/ (wygenerowanych w kroku 1)
$TargetDirSite = "$PSScriptRoot\x2iot\rootfs\app\site"
if (!(Test-Path -Path $TargetDirSite)) {
    New-Item -ItemType Directory -Force -Path $TargetDirSite
}
Write-Host "Kopiowanie site assets..." -ForegroundColor Cyan
Copy-Item "$RootFolder\target\site\*" -Destination $TargetDirSite -Recurse -Force

Write-Host "Gotowe. Można uruchomić docker build w katalogu ha-addon/x2iot" -ForegroundColor Green
