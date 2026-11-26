#requires -Version 5.1
# Laboratório André Tech - 360dialog Sandbox.
$ErrorActionPreference = 'Stop'
$Url = 'https://waba-sandbox.360dialog.io/v1/messages'
$ApiKey = $null
$SecureKey = Read-Host 'Informe sua API Key da 360dialog' -AsSecureString
if ($SecureKey.Length -eq 0) { Write-Warning 'Chave vazia.'; return }
try {
    $Ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureKey)
    try { $ApiKey = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($Ptr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($Ptr) }

    do {
        $Modo = Read-Host 'Destinatário: 1 - Telefone | 2 - BSUID'
    } until ($Modo -in @('1', '2'))

    if ($Modo -eq '1') {
        do {
            $Destino = (Read-Host 'Telefone autorizado (DDI + DDD + número, somente dígitos)').Trim()
            if ($Destino -notmatch '^[1-9][0-9]{6,14}$') { Write-Warning 'Informe somente dígitos com DDI.' }
        } until ($Destino -match '^[1-9][0-9]{6,14}$')
        $TipoDestino = 'Telefone'
    } else {
        do { $Destino = (Read-Host 'BSUID autorizado').Trim() } until ($Destino)
        $TipoDestino = 'BSUID'
    }

    Clear-Host
    Write-Host '========================================' -ForegroundColor Cyan
    Write-Host ' ANDRE TECH - SIMULADOR DE CLIENTE' -ForegroundColor Cyan
    Write-Host '========================================' -ForegroundColor Cyan
    Write-Host "Modo: $TipoDestino"
    Write-Host 'Digite /fim para fechar o simulador'
    Write-Host ''

    while ($true) {
        $Mensagem = Read-Host 'CLIENTE'
        if ($Mensagem.Trim() -eq '/fim') { break }
        if ([string]::IsNullOrWhiteSpace($Mensagem)) { continue }

        $Payload = @{
            messaging_product = 'whatsapp'
            type = 'text'
            text = @{ body = $Mensagem }
        }
        if ($Modo -eq '1') {
            $Payload['recipient_type'] = 'individual'
            $Payload['to'] = $Destino
        } else {
            $Payload['recipient'] = $Destino
        }
        $Body = $Payload | ConvertTo-Json -Depth 5

        try {
            $Resposta = Invoke-RestMethod -Method Post `
                -Uri $Url `
                -Headers @{'D360-API-KEY' = $ApiKey} `
                -ContentType 'application/json; charset=utf-8' `
                -Body ([System.Text.Encoding]::UTF8.GetBytes($Body)) `
                -TimeoutSec 30 -ErrorAction Stop

            Write-Host '[OK] Requisição aceita pela API.' -ForegroundColor Green
            if ($Resposta.messages -and $Resposta.messages[0].id) {
                Write-Host ('ID: ' + $Resposta.messages[0].id) -ForegroundColor DarkGray
            }
        } catch {
            Write-Host '[ERRO] Falha na requisição.' -ForegroundColor Red
            $Status = $null
            if ($_.Exception.Response) { $Status = [int]$_.Exception.Response.StatusCode }
            if ($Status) { Write-Host "HTTP $Status" -ForegroundColor Red }
            switch ($Status) {
                400 { Write-Warning 'Verifique o formato da requisição.' }
                401 { Write-Warning 'Verifique a API Key.' }
                403 { Write-Warning 'Confira o destinatário vinculado à chave e o modo escolhido.' }
                429 { Write-Warning 'Limite do Sandbox atingido. Encerrando.' }
                502 { Write-Warning 'Falha no serviço. Confira a entrega antes de repetir.' }
                504 { Write-Warning 'Timeout. Confira a entrega antes de repetir.' }
                default { Write-Warning 'Verifique a conexão, a configuração e o estado do serviço.' }
            }
            if ($Status -eq 429) { break }
        }
    }
} finally {
    $ApiKey = $null
    $SecureKey.Dispose()
}
