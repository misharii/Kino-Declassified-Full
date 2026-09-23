# Zombies Declassified BETA 2 - Kino der Toten only, offline installer.
# Copies the files in .\files into Plutonium storage and the Black Ops II folder.
# Never overwrites or deletes anything; checks every file's SHA-256; logs what it copied.
param(
    [string]$Pluto,
    [string]$Bo2,
    [switch]$Yes
)
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

function Fail($msg) { Write-Host ""; Write-Host $msg -ForegroundColor Red; exit 1 }

function Test-Bo2($dir) {
    # Same rule as the official zdinstall.py: the game folder holds zone\ and sound\.
    # (No t6zm.exe needed - Plutonium launches the game with its own exes.)
    return ($dir -and (Test-Path -LiteralPath (Join-Path $dir 'zone') -PathType Container) -and (Test-Path -LiteralPath (Join-Path $dir 'sound') -PathType Container))
}

function Find-Bo2 {
    $found = @()
    # Plutonium remembers the game folder it launches (t6Path) - works for non-Steam copies too.
    $cfg = Join-Path $env:LOCALAPPDATA 'Plutonium\config.json'
    if (Test-Path -LiteralPath $cfg) {
        try {
            $t6 = (Get-Content -LiteralPath $cfg -Raw | ConvertFrom-Json).t6Path
            if ($t6) { $t6 = $t6 -replace '/', '\'; if (Test-Bo2 $t6) { $found += $t6 } }
        } catch { }
    }
    $steam = $null
    foreach ($k in 'HKCU:\Software\Valve\Steam', 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam', 'HKLM:\SOFTWARE\Valve\Steam') {
        $p = Get-ItemProperty -Path $k -ErrorAction SilentlyContinue
        if ($p -and $p.SteamPath) { $steam = $p.SteamPath; break }
        if ($p -and $p.InstallPath) { $steam = $p.InstallPath; break }
    }
    $libs = @()
    if ($steam) {
        $steam = $steam -replace '/', '\'
        $libs += $steam
        $vdf = Join-Path $steam 'steamapps\libraryfolders.vdf'
        if (Test-Path -LiteralPath $vdf) {
            $libs += Select-String -LiteralPath $vdf -Pattern '"path"\s+"([^"]+)"' |
                ForEach-Object { $_.Matches[0].Groups[1].Value -replace '\\\\', '\' }
        }
    }
    $libs += 'C:\Program Files (x86)\Steam'
    foreach ($l in ($libs | Select-Object -Unique)) {
        $c = Join-Path $l 'steamapps\common\Call of Duty Black Ops II'
        $same = $found | Where-Object { $_.TrimEnd('\') -eq $c.TrimEnd('\') }
        if ((Test-Bo2 $c) -and -not $same) { $found += $c }
    }
    return $found
}

Write-Host "Zombies Declassified BETA 2 - Kino der Toten (offline installer)" -ForegroundColor Cyan
Write-Host ""

foreach ($n in 't6zm', 't6mp', 't6zmv41', 'plutonium-bootstrapper-win32') {
    if (Get-Process -Name $n -ErrorAction SilentlyContinue) { Fail "Black Ops II / Plutonium is running. Close the game and run this again." }
}

function Confirm-Path($label, $current, $hint) {
    # Show the detected folder; Enter keeps it, anything else replaces it.
    if ($current) {
        Write-Host "$label`: $current"
        $in = Read-Host "  Press Enter to use this, or paste a different folder"
    } else {
        Write-Host "$label`: not found automatically ($hint)"
        $in = Read-Host "  Paste the folder path"
    }
    $in = "$in".Trim().Trim('"').Trim()
    if ($in) { return $in }
    return $current
}

# --- Plutonium storage folder
$askPluto = -not $Pluto
if (-not $Pluto) {
    $Pluto = Join-Path $env:LOCALAPPDATA 'Plutonium\storage\t6'
    if (-not (Test-Path -LiteralPath $Pluto)) { $Pluto = $null }
}
if ($askPluto -and -not $Yes) {
    $Pluto = Confirm-Path 'Plutonium storage folder' $Pluto 'usually %LOCALAPPDATA%\Plutonium\storage\t6'
    Write-Host ""
}
if (-not $Pluto -or -not (Test-Path -LiteralPath $Pluto)) {
    Fail "Plutonium storage folder not found:`n  $Pluto`nLaunch Plutonium T6 Zombies once, close it, then run this again."
}

# --- Black Ops II folder
if (-not $Bo2) {
    $found = @(Find-Bo2)
    if ($found.Count -eq 1) {
        $Bo2 = $found[0]
    } elseif ($found.Count -gt 1) {
        Write-Host "Found more than one Black Ops II folder:"
        for ($i = 0; $i -lt $found.Count; $i++) { Write-Host ("  [{0}] {1}" -f ($i + 1), $found[$i]) }
        $pick = Read-Host "Type the number to use"
        $idx = 0
        if (-not [int]::TryParse($pick, [ref]$idx) -or $idx -lt 1 -or $idx -gt $found.Count) { Fail "No valid choice made." }
        $Bo2 = $found[$idx - 1]
    }
    if (-not $Yes) {
        $Bo2 = Confirm-Path 'Black Ops II folder' $Bo2 "the game folder with the zone and sound folders"
        Write-Host ""
    }
}
if (-not (Test-Bo2 $Bo2)) { Fail "This doesn't look like the Black Ops II folder (it needs the zone and sound folders inside):`n  $Bo2`nTip: Plutonium's AppData\Local\Plutonium\games folder is NOT it - use the folder Plutonium launches the game from." }

$roots = @{ PLUTO_T6 = $Pluto; BO2 = $Bo2 }
Write-Host "Plutonium storage : $Pluto"
Write-Host "Black Ops II      : $Bo2"
Write-Host ""

# --- Plan
$listFile = Join-Path $here 'kino_files.txt'
if (-not (Test-Path -LiteralPath $listFile)) { Fail "kino_files.txt is missing - re-extract the whole zip." }
$plan = foreach ($line in (Get-Content -LiteralPath $listFile)) {
    if (-not $line.Trim()) { continue }
    $root, $rel, $hash = $line.Split('|')
    $src = Join-Path (Join-Path (Join-Path $here 'files') $root) $rel
    $dst = Join-Path $roots[$root] $rel
    if (-not (Test-Path -LiteralPath $src)) { Fail "Missing from this package: files\$root\$rel - re-extract the whole zip." }
    $state = 'new'
    if (Test-Path -LiteralPath $dst) {
        if ((Get-FileHash -LiteralPath $dst -Algorithm SHA256).Hash.ToLower() -eq $hash) { $state = 'installed' } else { $state = 'conflict' }
    }
    [pscustomobject]@{ Root = $root; Rel = $rel; Hash = $hash; Src = $src; Dst = $dst; State = $state }
}
$new = @($plan | Where-Object State -eq 'new')
$done = @($plan | Where-Object State -eq 'installed')
$conf = @($plan | Where-Object State -eq 'conflict')
$mb = ($new | ForEach-Object { (Get-Item -LiteralPath $_.Src).Length } | Measure-Object -Sum).Sum / 1MB

Write-Host ("To copy: {0} files ({1:N0} MB)   Already installed: {2}   Different file already there: {3}" -f $new.Count, $mb, $done.Count, $conf.Count)
foreach ($c in $conf) { Write-Host "  SKIPPED (not overwritten): $($c.Dst)" -ForegroundColor Yellow }
if ($new.Count -eq 0) { Write-Host "`nNothing to copy - Kino is already installed." -ForegroundColor Green; exit 0 }

if (-not $Yes) {
    $ans = Read-Host "`nInstall now? (Y/N)"
    if ($ans -notmatch '^[Yy]') { Write-Host "Cancelled. Nothing was changed."; exit 0 }
}

# --- Copy
$log = Join-Path $here 'install_log.txt'
$copied = @(); $failed = 0
$i = 0
foreach ($f in $new) {
    $i++
    Write-Host ("  [{0}/{1}] {2}" -f $i, $new.Count, $f.Dst)
    try {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $f.Dst) | Out-Null
        Copy-Item -LiteralPath $f.Src -Destination $f.Dst
        if ((Get-FileHash -LiteralPath $f.Dst -Algorithm SHA256).Hash.ToLower() -ne $f.Hash) {
            Write-Host "      FAILED: copied file does not match its checksum" -ForegroundColor Red
            $failed++
        }
        $copied += $f.Dst
    } catch {
        Write-Host "      FAILED: $($_.Exception.Message)" -ForegroundColor Red
        $failed++
    }
}

$header = @(
    "Zombies Declassified BETA 2 - Kino der Toten - install log"
    "Written: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "To uninstall: delete exactly these files, then any folders they leave empty."
    ""
)
if (Test-Path -LiteralPath $log) { $copied | Add-Content -LiteralPath $log } else { ($header + $copied) | Set-Content -LiteralPath $log }

Write-Host ""
if ($failed) {
    Write-Host "$failed file(s) failed." -ForegroundColor Red
    Write-Host "If it says 'access denied', right-click INSTALL-KINO.bat > Run as administrator."
    exit 1
}
Write-Host "Installed $($copied.Count) files. Log: $log" -ForegroundColor Green
Write-Host ""
Write-Host "To play: Plutonium > T6 Zombies > MODS > load 'Zombies Declassified BETA 2',"
Write-Host "then start Kino der Toten from Custom Game."
exit 0
