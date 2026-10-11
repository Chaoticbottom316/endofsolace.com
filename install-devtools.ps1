# SOLACE dev tools installer for solace-build-vm
# Run via Azure Custom Script Extension (SYSTEM context)
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Continue'
$log = "C:\Windows\Temp\devtools-install.log"
function Log($m) { $m | Out-File -Append $log; Write-Output $m }
Log "=== Dev tools install started $(Get-Date) ==="

function Get-LatestAsset($repo, $pattern) {
    $rel = Invoke-RestMethod "https://api.github.com/repos/$repo/releases/latest"
    $a = $rel.assets | Where-Object { $_.name -match $pattern } | Select-Object -First 1
    return $a.browser_download_url
}

# 1. Git for Windows
try {
    $u = Get-LatestAsset 'git-for-windows/git' '64-bit\.exe$'
    Log "Git URL: $u"
    Invoke-WebRequest $u -OutFile "$env:TEMP\git.exe"
    Start-Process "$env:TEMP\git.exe" -ArgumentList '/VERYSILENT','/NORESTART' -Wait
    Log "Git installed: $((git --version) 2>&1)"
} catch { Log "Git FAILED: $_" }

# 2. Git LFS
try {
    $u = Get-LatestAsset 'git-lfs/git-lfs' 'windows-amd64\.exe$'
    Log "GitLFS URL: $u"
    Invoke-WebRequest $u -OutFile "$env:TEMP\gitlfs.exe"
    Start-Process "$env:TEMP\gitlfs.exe" -ArgumentList '/VERYSILENT','/NORESTART' -Wait
    & "$env:ProgramFiles\Git\cmd\git.exe" lfs install 2>&1 | Out-File -Append $log
    Log "Git LFS installed"
} catch { Log "Git LFS FAILED: $_" }

# 3. 7-Zip
try {
    Invoke-WebRequest 'https://www.7-zip.org/a/7z2409-x64.msi' -OutFile "$env:TEMP\7z.msi"
    Start-Process msiexec -ArgumentList "/i","$env:TEMP\7z.msi",'/quiet','/norestart' -Wait
    Log "7-Zip installed"
} catch { Log "7-Zip FAILED: $_" }

# 4. Epic Games Launcher
try {
    Invoke-WebRequest 'https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/installer/download/EpicGamesLauncherInstaller.msi' -OutFile "$env:TEMP\epic.msi"
    Start-Process msiexec -ArgumentList "/i","$env:TEMP\epic.msi",'/quiet','/norestart' -Wait
    Log "Epic Games Launcher installed"
} catch { Log "Epic FAILED: $_" }

# 5. Visual Studio 2022 Community (large, slow)
try {
    Invoke-WebRequest 'https://aka.ms/vs/17/release/vs_community.exe' -OutFile "$env:TEMP\vs.exe"
    $args = '--add','Microsoft.VisualStudio.Workload.NativeGame','--add','Microsoft.VisualStudio.Workload.NativeDesktop','--includeRecommended','--passive','--norestart','--wait'
    Start-Process "$env:TEMP\vs.exe" -ArgumentList $args -Wait
    Log "VS 2022 Community installed"
} catch { Log "VS2022 FAILED: $_" }

Log "=== Dev tools install finished $(Get-Date) ==="
