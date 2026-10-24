$dest = Join-Path $env:LOCALAPPDATA "questfetch"
New-Item -ItemType Directory -Force -Path $dest | Out-Null

Copy-Item "$PSScriptRoot\questfetch.sh", "$PSScriptRoot\questfetch.ps1", "$PSScriptRoot\questfetch.cmd" $dest -Force

$path = [Environment]::GetEnvironmentVariable("Path", "User")
if ($path -notlike "*$dest*") {
    [Environment]::SetEnvironmentVariable("Path", "$path;$dest", "User")
}

Write-Host "installed to $dest"
Write-Host "open a new terminal, then run: questfetch"
