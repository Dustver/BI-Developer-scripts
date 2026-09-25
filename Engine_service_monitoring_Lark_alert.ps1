[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ========================== КОНФИГУРАЦИЯ ==========================
$LarkWebhook = "https://open.larksuite.com/open-apis/bot/v2/hook/PASTE_ID_HERE"

$MonitoredServices = @(
    @{
        Name         = "QlikSenseEngineService"
        FriendlyName = "Qlik Sense Engine"
        Restart      = $true
    }
)

$ServiceStartTimeoutSec = 30
$LarkTimeoutSec = 5
# =================================================================

function Send-LarkAlert {
    param (
        [string]$Title,
        [string]$Message,
        [string]$Color
    )

    $payload = @{
        msg_type = "interactive"
        card     = @{
            config  = @{ wide_screen_mode = $true }
            header  = @{
                template = $Color
                title    = @{
                    content = $Title
                    tag     = "plain_text"
                }
            }
            elements = @(
                @{
                    tag  = "div"
                    text = @{
                        content = $Message
                        tag     = "lark_md"
                    }
                }
            )
        }
    } | ConvertTo-Json -Depth 10

    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($payload)

    for ($attempt = 1; $attempt -le 2; $attempt++) {
        try {
            Invoke-RestMethod -Uri $LarkWebhook `
                -Method Post `
                -Body $bodyBytes `
                -ContentType "application/json; charset=utf-8" `
                -TimeoutSec $LarkTimeoutSec `
                -ErrorAction Stop | Out-Null

            return $true
        }
        catch {
            if ($attempt -eq 2) {
                Write-Host "Ошибка отправки в Lark: $($_.Exception.Message)" -ForegroundColor Red
                return $false
            }
            Start-Sleep -Seconds 1
        }
    }
}

# ========================== ОСНОВНАЯ ЛОГИКА ==========================
$hostname = $env:COMPUTERNAME

foreach ($svc in $MonitoredServices) {

    $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue

    if ($service -and $service.Status -eq 'Stopped') {

        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        Write-Host "[$timestamp] $($svc.FriendlyName) остановлен"

        # ===== 1. АЛЕРТ: СЕРВИС УПАЛ =====
        $msgDown = "Сервер: **$hostname**`nВремя: **$timestamp**`nСтатус: **Stopped**"
        Send-LarkAlert -Title "🚨 $($svc.FriendlyName) ОСТАНОВЛЕН" `
                       -Message $msgDown `
                       -Color "red" | Out-Null

        if ($svc.Restart) {

            $restartSuccess = $false

            try {
                Start-Service -Name $svc.Name -ErrorAction Stop

                $service.WaitForStatus('Running', (New-TimeSpan -Seconds $ServiceStartTimeoutSec))

                # перечитываем статус
                $service = Get-Service -Name $svc.Name

                if ($service.Status -eq 'Running') {
                    $restartSuccess = $true
                }
            }
            catch {
                Write-Host "Ошибка запуска: $($_.Exception.Message)" -ForegroundColor Red
            }

            $timestamp2 = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

            if ($restartSuccess) {
                Write-Host "[$timestamp2] ✓ $($svc.FriendlyName) восстановлен" -ForegroundColor Green

                # ===== 2. АЛЕРТ: УСПЕШНО =====
                $msgUp = "Сервер: **$hostname**`nВремя: **$timestamp2**`nСтатус: **Running**"
                Send-LarkAlert -Title "✅ $($svc.FriendlyName) ВОССТАНОВЛЕН" `
                               -Message $msgUp `
                               -Color "green" | Out-Null
            }
            else {
                Write-Host "[$timestamp2] ✗ $($svc.FriendlyName) НЕ ЗАПУСТИЛСЯ" -ForegroundColor Red

                # ===== 2. АЛЕРТ: ФЕЙЛ =====
                $msgFail = "Сервер: **$hostname**`nВремя: **$timestamp2**`nСтатус: **FAILED TO START**"
                Send-LarkAlert -Title "❌ $($svc.FriendlyName) НЕ ЗАПУСТИЛСЯ" `
                               -Message $msgFail `
                               -Color "red" | Out-Null
            }
        }
    }
}

Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') Мониторинг завершён." -ForegroundColor Cyan