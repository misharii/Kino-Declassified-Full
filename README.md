Zombies Declassified BETA 2 - Kino der Toten only (offline)
============================================================

Kino der Toten from the Zombies Declassified mod for Plutonium T6 (Black Ops II).
All files are included - no Python and no extra downloads needed.
Mod project: https://github.com/Logo-2K/zombies-declassified

Download
--------
https://storage.googleapis.com/mishari-misc/plutonium/Kino-Declassified-Full.zip
Only ~0.88 GB, instead of ~9 GB for the whole mod.
(This repository contains only the installer; the game files are in the zip.)

You need
--------
- Black Ops II (Steam) with Plutonium, and T6 Zombies launched at least once.
- About 1 GB free.

Install
-------
1. Close Plutonium and Black Ops II.
2. Extract the WHOLE zip to a folder (don't run it from inside the zip).
3. Double-click INSTALL-KINO.bat.
   - It finds your Plutonium and Black Ops II folders and shows them: press Enter
     to accept each one, or paste a different folder path.
       Plutonium folder:    the one ending in Plutonium\storage\t6
       Black Ops II folder: the game folder with the "zone" and "sound" folders inside
                            (not AppData\Local\Plutonium\games - that only has Plutonium's launchers).
       To print the folder Plutonium uses, run this in PowerShell:
         (Get-Content "$env:LOCALAPPDATA\Plutonium\config.json" -Raw | ConvertFrom-Json).t6Path
   - It shows what it will copy and asks before copying.
   - It never overwrites or deletes anything, and checks every file's SHA-256.
   - It writes install_log.txt (next to the .bat) listing every file it copied.
   If it reports "access denied": right-click INSTALL-KINO.bat > Run as administrator.

Play
----
1. Open Plutonium > T6 Zombies.
2. MODS > load "Zombies Declassified BETA 2".
3. Start Kino der Toten from Custom Game (the Solo Play globe also sends you there).
Co-op: everyone must have the same release (BETA 2).

Uninstall
---------
Delete exactly the files listed in install_log.txt, then any folders left empty
(e.g. storage\t6\usermaps\zm_theater and storage\t6\mods\dlc5).
