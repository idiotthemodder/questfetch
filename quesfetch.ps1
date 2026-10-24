# questfetch windows wrapper: pushes the script to the headset and runs it
param([Parameter(ValueFromRemainingArguments = $true)]$QArgs)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$Script = if ($env:QUESTFETCH_SCRIPT) { $env:QUESTFETCH_SCRIPT } else { Join-Path $PSScriptRoot "questfetch.sh" }

if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    Write-Host "adb not found. install Android platform-tools and add it to your PATH."
    exit 1
}

$state = (adb get-state 2>$null)
if ($state -ne "device") {
    Write-Host "no headset found over adb (check 'adb devices')"
    exit 1
}

# make sure the script has unix line endings, no BOM
$tmp = Join-Path $env:TEMP "questfetch.sh"
$text = [IO.File]::ReadAllText($Script) -replace "`r`n", "`n"
[IO.File]::WriteAllText($tmp, $text, (New-Object System.Text.UTF8Encoding $false))

adb push $tmp /data/local/tmp/questfetch | Out-Null
$extra = ($QArgs -join " ")
adb shell "su -c 'sh /data/local/tmp/questfetch $extra'"
