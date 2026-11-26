#requires -Version 5.1
$ErrorActionPreference = 'Stop'
$Endpoint = 'https://waba-sandbox.360dialog.io/v1/configs/webhook'
$Webhook = (Read-Host 'URL HTTPS pública do webhook').Trim()
$ParsedUri = $null
if (-not [Uri]::TryCreate($Webhook, [UriKind]::Absolute, [ref]$ParsedUri) -or $ParsedUri.Scheme -ne 'https' -or -not $ParsedUri.Host) {
    Write-Warning 'Informe uma URL HTTPS válida.'
    return
}
$ApiKey = $null
$SecureKey = Read-Host 'Informe sua API Key da 360dialog' -AsSecureString
if ($SecureKey.Length -eq 0) { Write-Warning 'Chave vazia.'; return }
try {
    $Ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureKey)
    try { $ApiKey = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($Ptr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($Ptr) }
    $Body = @{ url = $Webhook } | ConvertTo-Json
    $null = Invoke-RestMethod -Method Post -Uri $Endpoint `
        -Headers @{'D360-API-KEY' = $ApiKey} `
        -ContentType 'application/json; charset=utf-8' `
        -Body ([System.Text.Encoding]::UTF8.GetBytes($Body)) `
        -TimeoutSec 30 -ErrorAction Stop
    Write-Host '[OK] Webhook registrado pela API.' -ForegroundColor Green
} catch {
    Write-Host '[ERRO] Não foi possível confirmar o registro.' -ForegroundColor Red
    if ($_.Exception.Response) {
        $Status = [int]$_.Exception.Response.StatusCode
        Write-Host "HTTP $Status"
    }
    Write-Warning 'Confira a chave, URL HTTPS e conectividade.'
} finally {
    $ApiKey = $null
    $SecureKey.Dispose()
}
