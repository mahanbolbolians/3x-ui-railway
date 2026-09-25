# Verification test script for 3x-ui Railway setup
$ErrorActionPreference = "Stop"

Write-Host "Verifying 3x-ui Railway Project Files..." -ForegroundColor Cyan

$baseDir = $PSScriptRoot
$requiredFiles = @(
    "Dockerfile",
    "entrypoint.sh",
    "nginx.conf.template",
    "quick-config.template.html",
    "railway.json"
)

$allExist = $true
foreach ($file in $requiredFiles) {
    $fullPath = Join-Path $baseDir $file
    if (Test-Path $fullPath) {
        $size = (Get-Item $fullPath).Length
        Write-Host "  OK: $file (Size: $size bytes)" -ForegroundColor Green
    } else {
        Write-Host "  MISSING: $file" -ForegroundColor Red
        $allExist = $false
    }
}

# Ensure entrypoint.sh has Unix (LF) line endings
$entrypointPath = Join-Path $baseDir "entrypoint.sh"
if (Test-Path $entrypointPath) {
    $rawBytes = [System.IO.File]::ReadAllBytes($entrypointPath)
    $text = [System.Text.Encoding]::UTF8.GetString($rawBytes)
    $crlf = [char]13 + [char]10
    $lf = [char]10
    if ($text.IndexOf($crlf) -ge 0) {
        Write-Host "  Converting entrypoint.sh line endings to LF (Unix format)..." -ForegroundColor Yellow
        $text = $text.Replace($crlf, $lf)
        [System.IO.File]::WriteAllText($entrypointPath, $text, (New-Object System.Text.UTF8Encoding $false))
        Write-Host "  Converted entrypoint.sh to LF format." -ForegroundColor Green
    } else {
        Write-Host "  entrypoint.sh already has proper Unix (LF) line endings." -ForegroundColor Green
    }
}

# Validate VMess Base64 generation test
$testDomain = "zeus-proxy.up.railway.app"
$testUuid = "e7492c90-21a4-441d-b8d4-53995537ef6c"
$testVmessJson = '{"v":"2","ps":"Zeus-Railway-VMess","add":"' + $testDomain + '","port":"443","id":"' + $testUuid + '","aid":"0","scy":"auto","net":"ws","type":"none","host":"' + $testDomain + '","path":"/vmess-ws","tls":"tls","sni":"' + $testDomain + '"}'

$bytes = [System.Text.Encoding]::UTF8.GetBytes($testVmessJson)
$vmessB64 = [Convert]::ToBase64String($bytes)
$vmessUri = "vmess://$vmessB64"

Write-Host ""
Write-Host "Test Protocol URIs Generation:" -ForegroundColor Cyan
Write-Host "  VLESS:  vless://$testUuid@${testDomain}:443?type=ws&security=tls&path=%2Fvless-ws&sni=${testDomain}#Zeus-Railway-VLESS" -ForegroundColor Gray
Write-Host "  VMess:  $vmessUri" -ForegroundColor Gray
Write-Host "  Trojan: trojan://pass1234@${testDomain}:443?type=ws&security=tls&path=%2Ftrojan-ws&sni=${testDomain}#Zeus-Railway-Trojan" -ForegroundColor Gray

if ($allExist) {
    Write-Host ""
    Write-Host "Setup verification PASSED! Ready for deployment to Railway." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Setup verification FAILED! Some files are missing." -ForegroundColor Red
    exit 1
}
