# Skrypt wspomagający środowisko, budowanie i publikację binarek dla Home Assistant (RPi 5 / aarch64)
# Automatycznie podbija wersję patch (+0.0.1) w config.yaml i publikuje zmiany do obu repozytoriów Git.

param (
    [string]$Message = "",
    [switch]$NoBump,
    [switch]$NoPush
)

$ErrorActionPreference = "Stop"

$RootFolder = (Resolve-Path "$PSScriptRoot\..").Path
$ConfigFile = "$PSScriptRoot\x2iot\config.yaml"

Write-Host "==================================================================" -ForegroundColor Magenta
Write-Host "            x2iot - Automatyczny kreator wydania (RPi 5)          " -ForegroundColor Magenta
Write-Host "==================================================================" -ForegroundColor Magenta

# --- KROK 0: Sprawdzanie i przygotowanie środowiska ---
Write-Host "`n[0/4] Sprawdzanie srodowiska..." -ForegroundColor Cyan

# 1. Sprawdzenie Dockera
docker info >$null 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "BLAD: Docker Desktop nie jest uruchomiony!" -ForegroundColor Red
    Write-Host "Uruchom Docker Desktop, poczekaj na jego start i sprobuj ponownie." -ForegroundColor Yellow
    exit 1
}
Write-Host "  -> Docker dziala poprawnie." -ForegroundColor Green

# 2. Sprawdzenie cargo-leptos
if (!(Get-Command "cargo-leptos" -ErrorAction SilentlyContinue)) {
    Write-Host "  -> Instalowanie cargo-leptos..." -ForegroundColor Yellow
    cargo install cargo-leptos
    if ($LASTEXITCODE -ne 0) { exit 1 }
}

# 3. Sprawdzenie cross
if (!(Get-Command "cross" -ErrorAction SilentlyContinue)) {
    Write-Host "  -> Instalowanie cross..." -ForegroundColor Yellow
    cargo install cross --git https://github.com/cross-rs/cross
    if ($LASTEXITCODE -ne 0) { exit 1 }
}

# 4. Sprawdzenie targetów rustup
rustup target add aarch64-unknown-linux-gnu x86_64-unknown-linux-gnu | Out-Null

# 5. Odczyt i ewentualne podbicie wersji
$ConfigContent = Get-Content $ConfigFile -Raw -Encoding UTF8
if ($ConfigContent -match 'version:\s*"(\d+)\.(\d+)\.(\d+)"') {
    $Major = [int]$Matches[1]
    $Minor = [int]$Matches[2]
    $OldPatch = [int]$Matches[3]
    $OldVersion = "$Major.$Minor.$OldPatch"

    if (!$NoBump) {
        $NewPatch = $OldPatch + 1
        $NewVersion = "$Major.$Minor.$NewPatch"
        $UpdatedConfig = $ConfigContent -replace 'version:\s*"\d+\.\d+\.\d+"', "version: `"$NewVersion`""
        [System.IO.File]::WriteAllText($ConfigFile, $UpdatedConfig, [System.Text.Encoding]::UTF8)
        Write-Host "  -> Podbito wersje: $OldVersion -> $NewVersion" -ForegroundColor Green
    } else {
        $NewVersion = $OldVersion
        Write-Host "  -> Wersja (bez podbijania): $NewVersion" -ForegroundColor Yellow
    }
} else {
    Write-Host "BLAD: Nie mozna odczytac pola 'version' z $ConfigFile!" -ForegroundColor Red
    exit 1
}

function Rollback-Version {
    if (!$NoBump) {
        Write-Host "`n[!] Wycofuje wersje w config.yaml do $OldVersion z powodu bledu..." -ForegroundColor Yellow
        $Cur = Get-Content $ConfigFile -Raw -Encoding UTF8
        $Cur = $Cur -replace 'version:\s*"\d+\.\d+\.\d+"', "version: `"$OldVersion`""
        [System.IO.File]::WriteAllText($ConfigFile, $Cur, [System.Text.Encoding]::UTF8)
    }
}

# --- KROK 1: Budowanie frontendu WASM ---
Write-Host "`n[1/4] Budowanie frontendu WASM (cargo leptos build --release)..." -ForegroundColor Cyan
Set-Location $RootFolder
cargo leptos build --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "BLAD: Budowanie cargo-leptos zakonczone niepowodzeniem!" -ForegroundColor Red
    Rollback-Version
    exit 1
}

# --- KROK 2: Budowanie serwera dla RPi 5 (cross aarch64) ---
Write-Host "`n[2/4] Budowanie serwera dla RPi 5 (cross build aarch64-unknown-linux-gnu)..." -ForegroundColor Cyan
cross build --package x2iot-app --features ssr --target aarch64-unknown-linux-gnu --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "BLAD: Budowanie serwera cross aarch64 zakonczone niepowodzeniem!" -ForegroundColor Red
    Rollback-Version
    exit 1
}

# --- KROK 3: Kopiowanie artefaktów i weryfikacja ---
Write-Host "`n[3/4] Przygotowanie plikow dodatku w ha-addon/x2iot/rootfs..." -ForegroundColor Cyan

# A. Binarka serwera
$TargetDirAarch64 = "$PSScriptRoot\x2iot\rootfs\app\bin\aarch64"
if (!(Test-Path -Path $TargetDirAarch64)) {
    New-Item -ItemType Directory -Force -Path $TargetDirAarch64 | Out-Null
}
$ServerBinSource = "$RootFolder\target\aarch64-unknown-linux-gnu\release\x2iot-app"
if (!(Test-Path $ServerBinSource)) {
    Write-Host "BLAD: Nie znaleziono skompilowanego pliku: $ServerBinSource" -ForegroundColor Red
    Rollback-Version
    exit 1
}
Copy-Item $ServerBinSource -Destination "$TargetDirAarch64\x2iot-app" -Force

# B. Frontend assets
$TargetDirSite = "$PSScriptRoot\x2iot\rootfs\app\site"
if (!(Test-Path -Path $TargetDirSite)) {
    New-Item -ItemType Directory -Force -Path $TargetDirSite | Out-Null
}
Copy-Item "$RootFolder\target\site\*" -Destination $TargetDirSite -Recurse -Force

if (Test-Path "$TargetDirSite\pkg\x2iot.wasm") {
    if (Test-Path -Path "$TargetDirSite\pkg\x2iot_bg.wasm") {
        Remove-Item -Path "$TargetDirSite\pkg\x2iot_bg.wasm" -Force
    }
    Rename-Item -Path "$TargetDirSite\pkg\x2iot.wasm" -NewName "x2iot_bg.wasm"
}

if (!(Test-Path "$TargetDirSite\pkg\x2iot_bg.wasm")) {
    Write-Host "BLAD: Brak wygenerowanego pliku x2iot_bg.wasm w $TargetDirSite\pkg!" -ForegroundColor Red
    Rollback-Version
    exit 1
}

# C. Konfiguracja domyślna
Copy-Item "$RootFolder\config\configuration.yaml" -Destination "$PSScriptRoot\x2iot\configuration.yaml" -Force
Write-Host "  -> Wszystkie artefakty skopiowane i zweryfikowane." -ForegroundColor Green

# --- KROK 4: Git commit i push do obu repozytoriów ---
if (!$NoPush) {
    Write-Host "`n[4/4] Publikacja wydania v$NewVersion w Git..." -ForegroundColor Cyan
    $CommitTitle = if ($Message) { "release: v$NewVersion - $Message" } else { "release: v$NewVersion" }

    # 1. Repozytorium dodatku (submoduł ha-addon -> x2iot_ha_plugin)
    Write-Host "  -> [1/2] Commit i push repozytorium pluginu (ha-addon)..." -ForegroundColor Yellow
    Set-Location $PSScriptRoot
    git add -A
    git diff --cached --quiet
    if ($LASTEXITCODE -ne 0) {
        git commit -m $CommitTitle
        if ($LASTEXITCODE -ne 0) {
            Write-Host "BLAD: Nie udalo sie utworzyc commita w ha-addon!" -ForegroundColor Red
            exit 1
        }
    }
    git push origin main
    if ($LASTEXITCODE -ne 0) {
        Write-Host "BLAD: Blad podczas 'git push origin main' w ha-addon!" -ForegroundColor Red
        exit 1
    }
    Write-Host "  -> Repozytorium dodatku zaktualizowane na GitHubie." -ForegroundColor Green

    # 2. Główne repozytorium (x2iot)
    Write-Host "  -> [2/2] Commit i push glownego repozytorium (x2iot)..." -ForegroundColor Yellow
    Set-Location $RootFolder
    git add -A
    git diff --cached --quiet
    if ($LASTEXITCODE -ne 0) {
        git commit -m $CommitTitle
        if ($LASTEXITCODE -ne 0) {
            Write-Host "BLAD: Nie udalo sie utworzyc commita w x2iot!" -ForegroundColor Red
            exit 1
        }
    }
    git push origin main
    if ($LASTEXITCODE -ne 0) {
        Write-Host "BLAD: Blad podczas 'git push origin main' w x2iot!" -ForegroundColor Red
        exit 1
    }
    Write-Host "  -> Glowne repozytorium zaktualizowane na GitHubie." -ForegroundColor Green

    Write-Host "`n==================================================================" -ForegroundColor Green
    Write-Host " SUKCES! Wydanie v$NewVersion zostalo pomyslnie opublikowane!     " -ForegroundColor Green
    Write-Host " Przejdz do Home Assistant:                                       " -ForegroundColor Yellow
    Write-Host " Ustawienia -> Dodatki -> Sklep z dodatkami -> Sprawdz aktualizacje" -ForegroundColor Yellow
    Write-Host "==================================================================`n" -ForegroundColor Green
} else {
    Write-Host "`n==================================================================" -ForegroundColor Yellow
    Write-Host " Gotowe! Binarki v$NewVersion zbudowane lokalnie (flaga -NoPush aktywna)." -ForegroundColor Yellow
    Write-Host "==================================================================`n" -ForegroundColor Yellow
}
