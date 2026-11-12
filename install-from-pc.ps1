<#
.SYNOPSIS
    Deploys LuCI Web UI, Telephony -> SMS, and persistent 2s DHCP watchdog
    to a Zyxel AOD450ZY (Airtel 5G ODU) from the local luci-sms-aod450.tar.gz bundle.

.EXAMPLE
    .\deploy_to_odu.ps1 -OduIp 192.168.10.1 -Password AZYODAFE00042515
#>
param(
    [string]$OduIp = "192.168.10.1",
    [string]$User = "admin",
    [string]$Password = "AZYODAFE00042515",
    [string]$HostKey = "",
    [string]$BundlePath = (Join-Path $PSScriptRoot "luci-sms-aod450.tar.gz")
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $BundlePath)) {
    throw "Bundle not found: $BundlePath"
}

$plink = "C:\Program Files\PuTTY\plink.exe"
if (-not (Test-Path $plink)) {
    $cmd = Get-Command plink.exe -ErrorAction SilentlyContinue
    if ($cmd) { $plink = $cmd.Source }
}

if (-not (Test-Path $plink)) {
    Write-Host "[!] PuTTY plink.exe not found. Using OpenSSH scp/ssh (you will be prompted for password '$Password'):" -ForegroundColor Yellow
    & scp -o StrictHostKeyChecking=accept-new "$BundlePath" "${User}@${OduIp}:/tmp/luci-sms-aod450.tar.gz"
    if ($LASTEXITCODE -ne 0) { throw "scp upload failed." }
    & ssh -o StrictHostKeyChecking=accept-new "${User}@${OduIp}" "cd /tmp && rm -rf luci-sms-aod450 && tar -xzf luci-sms-aod450.tar.gz && cd luci-sms-aod450 && sh install.sh && cd /tmp && rm -rf luci-sms-aod450 luci-sms-aod450.tar.gz"
    if ($LASTEXITCODE -ne 0) { throw "Remote installation failed." }
} else {
    $hostKeyArgs = @()
    if ($HostKey) {
        $hostKeyArgs = @("-hostkey", $HostKey)
    }

    Write-Host "[+] Checking SSH connectivity to ${User}@${OduIp}..."
    if (-not $HostKey) {
        # Prime PuTTY host key cache interactively if this is a new ODU
        $probe = "echo y | `"$plink`" -T -ssh -pw `"$Password`" ${User}@${OduIp} `"echo SSH_OK`""
        cmd /c $probe | Out-Null
    }

    Write-Host "[+] Uploading luci-sms-aod450.tar.gz to /tmp/ on $OduIp..."
    $bytes = [IO.File]::ReadAllBytes($BundlePath)
    $b64 = ([Convert]::ToBase64String($bytes, [Base64FormattingOptions]::InsertLineBreaks) -replace "`r`n", "`n") + "`n"
    $tmpB64 = Join-Path $env:TEMP ("aod450_upload_" + [Guid]::NewGuid().ToString("N") + ".b64")
    [IO.File]::WriteAllText($tmpB64, $b64, [Text.Encoding]::ASCII)

    try {
        $hkFlag = if ($HostKey) { "-hostkey `"$HostKey`"" } else { "" }
        $uploadCmd = "type `"$tmpB64`" | `"$plink`" -batch -T $hkFlag -ssh -pw `"$Password`" ${User}@${OduIp} `"tr -d '\r' | /usr/sbin/openssl enc -base64 -d > /tmp/luci-sms-aod450.tar.gz`""
        cmd /c $uploadCmd
        if ($LASTEXITCODE -ne 0) { throw "Upload failed (exit code $LASTEXITCODE)." }
    } finally {
        Remove-Item -Force $tmpB64 -ErrorAction SilentlyContinue
    }

    Write-Host "[+] Extracting and running install.sh on $OduIp..."
    $remoteInstall = @'
set -e
cd /tmp
rm -rf luci-sms-aod450
tar -xzf luci-sms-aod450.tar.gz
cd luci-sms-aod450
sh install.sh
cd /tmp
rm -rf luci-sms-aod450 luci-sms-aod450.tar.gz
'@ -replace "`r`n", "`n"
    $runB64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($remoteInstall))
    $plinkArgs = @("-batch", "-T") + $hostKeyArgs + @("-ssh", "-pw", $Password, "${User}@${OduIp}", "echo $runB64 | /usr/sbin/openssl enc -base64 -d -A | sh -s")
    & $plink @plinkArgs
    if ($LASTEXITCODE -ne 0) { throw "Remote installation failed (exit code $LASTEXITCODE)." }
}

Write-Host "[+] Verifying LuCI HTTP endpoint at http://${OduIp}:4153/ ..."
try {
    $resp = Invoke-WebRequest -Uri "http://${OduIp}:4153/cgi-bin/luci/" -UseBasicParsing -TimeoutSec 10
    Write-Host "[+] LuCI login page HTTP $($resp.StatusCode) OK!" -ForegroundColor Green
} catch {
    $code = $_.Exception.Response.StatusCode.value__
    if ($code -eq 403 -or $code -eq 200) {
        Write-Host "[+] LuCI endpoint HTTP $code (login gate active) OK!" -ForegroundColor Green
    } else {
        Write-Warning "Could not verify HTTP response on http://${OduIp}:4153/cgi-bin/luci/ ($($_.Exception.Message))"
    }
}
