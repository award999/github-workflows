##===----------------------------------------------------------------------===##
##
## This source file is part of the Swift.org open source project
##
## Copyright (c) 2024 Apple Inc. and the Swift project authors
## Licensed under Apache License v2.0 with Runtime Library Exception
##
## See https://swift.org/LICENSE.txt for license information
## See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
##
##===----------------------------------------------------------------------===##
$VSB='https://download.visualstudio.microsoft.com/download/pr/5536698c-711c-4834-876f-2817d31a2ef2/c792bdb0fd46155de19955269cac85d52c4c63c23db2cf43d96b9390146f9390/vs_BuildTools.exe'
$VSB_SHA256='C792BDB0FD46155DE19955269CAC85D52C4C63C23DB2CF43D96B9390146F9390'
$VSR='https://download.visualstudio.microsoft.com/download/pr/c7dac50a-e3e8-40f6-bbb2-9cc4e3dfcabe/1821577409C35B2B9505AC833E246376CC68A8262972100444010B57226F0940/VC_redist.x64.exe'
$VSR_SHA256='1821577409C35B2B9505AC833E246376CC68A8262972100444010B57226F0940'
Set-Variable ErrorActionPreference Stop
Set-Variable ProgressPreference SilentlyContinue

Write-Host -NoNewLine ('Downloading {0} ... ' -f ${VSB})
Invoke-WebRequest -Uri $VSB -OutFile $env:TEMP\vs_buildtools.exe
Write-Host 'SUCCESS'
Write-Host -NoNewLine ('Verifying SHA256 ({0}) ... ' -f $VSB_SHA256)
$Hash = Get-FileHash $env:TEMP\vs_buildtools.exe -Algorithm sha256
if ($Hash.Hash -eq $VSB_SHA256) {
    Write-Host 'SUCCESS'
} else {
    Write-Host  ('FAILED ({0})' -f $Hash.Hash)
    exit 1
}

Write-Host -NoNewLine ('Downloading {0} ... ' -f ${VSR})
Invoke-WebRequest -Uri $VSR -OutFile $env:TEMP\vs_redist.exe
Write-Host 'SUCCESS'
Write-Host -NoNewLine ('Verifying SHA256 ({0}) ... ' -f $VSR_SHA256)
$Hash = Get-FileHash $env:TEMP\vs_redist.exe -Algorithm sha256
if ($Hash.Hash -eq $VSR_SHA256) {
    Write-Host 'SUCCESS'
} else {
    Write-Host  ('FAILED ({0})' -f $Hash.Hash)
    exit 1
}
Write-Host -NoNewLine 'Uninstalling existing Visual Studio Build Tools... '
$Process = Start-Process "C:\Program Files (x86)\Microsoft Visual Studio\Installer\InstallCleanup.exe" -Wait -PassThru -NoNewWindow -ArgumentList @(
    '-f'
)
if ($Process.ExitCode -eq 0 -or $Process.ExitCode -eq 3010) {
    Write-Host 'SUCCESS'
} else {
    Write-Host  ('FAILED ({0})' -f $Process.ExitCode)
    exit 1
}

Write-Host 'Uninstalling existing Visual C++ Redistributables ... '
$VisualCPP = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -match 'Visual C\+\+ 2015-2022' } | Select-Object -Property QuietUninstallString
foreach ($Install in $VisualCPP) {
    Write-Host -NoNewLine "'$($Install.QuietUninstallString)' ... "
    $Process = Start-Process "cmd.exe" -Wait -PassThru -NoNewWindow -ArgumentList @(
        "/c",
        "($($Install.QuietUninstallString))"
    )
    if ($Process.ExitCode -eq 0 -or $Process.ExitCode -eq 3010) {
        Write-Host 'SUCCESS'
    } else {
        Write-Host  ('FAILED ({0})' -f $Process.ExitCode)
        exit 1
    }
}

Write-Host -NoNewLine 'Installing Visual C++ Redistributable... '
$Process = Start-Process "$env:TEMP\vs_redist.exe" -Wait -PassThru -NoNewWindow -ArgumentList @(
    "/install",
    "/Q"
)
if ($Process.ExitCode -eq 0 -or $Process.ExitCode -eq 3010) {
    Write-Host 'SUCCESS'
} else {
    Write-Host  ('FAILED ({0})' -f $Process.ExitCode)
    exit 1
}
Remove-Item -Force $env:TEMP\vs_redist.exe

$CHANNEL_ID='VisualStudio.17.Release.LTSC.17.12'
Write-Host -NoNewLine ('Installing Visual Studio Build Tools {0} ... ' -f $CHANNEL_ID)
$Process =
    Start-Process $env:TEMP\vs_buildtools.exe -Wait -PassThru -NoNewWindow -ArgumentList @(
        '--quiet',
        '--wait',
        '--norestart',
        '--nocache',
        "--channelId", $CHANNEL_ID,
        '--add', 'Microsoft.VisualStudio.Component.Windows11SDK.22000',
        '--add', 'Microsoft.VisualStudio.Component.VC.Tools.x86.x64'
    )
if ($Process.ExitCode -eq 0 -or $Process.ExitCode -eq 3010) {
    Write-Host 'SUCCESS'
} else {
    Write-Host  ('FAILED ({0})' -f $Process.ExitCode)
    exit 1
}
Remove-Item -Force $env:TEMP\vs_buildtools.exe
