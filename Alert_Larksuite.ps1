chcp 65001 | Out-Null

# ========================== КОНФИГУРАЦИЯ ==========================
$LarkWebhook = "https://open.larksuite.com/open-apis/bot/v2/hook/PASTE_ID_HERE"

# Список сервисов для мониторинга (легко расширяется!)
$MonitoredServices = @(
    @{
        Name         = "QlikSenseEngineService"
        FriendlyName = "Qlik Sense Engine"
        Restart      = $true                     # перезапускать автоматически
    }
    # новые сервисы можно добавлять ниже, пример:
    # @{
    #     Name         = "QlikSenseService"
    #     FriendlyName = "Qlik Sense Repository"
    #     Restart      = $true
    # }
)
# =================================================================

function Send-LarkAlert {
    param (
        [string]$ServiceName,
        [string]$FriendlyName,
        [string]$Hostname,
        [string]$Timestamp
    )

    $cardPayload = @{
        msg_type = "interactive"
        card     = @{
            config  = @{ wide_screen_mode = $true }
            header  = @{
                template = "red"
                title    = @{
                    content = "🚨 $FriendlyName ОСТАНОВЛЕН"
                    tag     = "plain_text"
                }
            }
            elements = @(
                @{
                    tag  = "div"
                    text = @{
                        content = "Сервер: **$Hostname**`nВремя: **$Timestamp**`nСтатус: **Stopped**"
                        tag     = "lark_md"
                    }
                },
                @{
                    tag = "hr"
                },
                @{
                    tag  = "note"
                    elements = @(
                        @{ tag = "plain_text"; content = "Скрипт автоматически перезапустил службу" }
                    )
                }
            )
        }
    } | ConvertTo-Json -Depth 10

    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($cardPayload)

    try {
        $null = Invoke-RestMethod -Uri $LarkWebhook `
                                  -Method Post `
                                  -Body $bodyBytes `
                                  -ContentType "application/json; charset=utf-8" `
                                  -TimeoutSec 10 `
                                  -ErrorAction Stop

        Write-Host "[$Timestamp] ✓ Карточка отправлена в Lark ($FriendlyName)" -ForegroundColor Green
        return $true
    }
    catch {
        $ex = $_.Exception
        if ($ex -is [System.Net.WebException] -and $ex.Status -eq 'Timeout') {
            Write-Host "[$Timestamp] ⚠ Таймаут Lark (10 сек) — продолжаем перезапуск" -ForegroundColor Yellow
        }
        else {
            Write-Host "[$Timestamp] ⚠ Ошибка отправки в Lark: $($ex.Message)" -ForegroundColor Red
        }
        return $false
    }
}

# ========================== ОСНОВНАЯ ЛОГИКА ==========================
$hostname  = $env:COMPUTERNAME

foreach ($svc in $MonitoredServices) {
    $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue

    if ($service -and $service.Status -ne 'Running') {

        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        Write-Host "[$timestamp] $(( $svc.FriendlyName )) остановлен → отправляем алерт в Lark..."

        # 1. Отправляем карточку
        $null = Send-LarkAlert -ServiceName $svc.Name `
                               -FriendlyName $svc.FriendlyName `
                               -Hostname $hostname `
                               -Timestamp $timestamp

        # 2. Перезапускаем (если разрешено в конфиге)
        if ($svc.Restart) {
            try {
                Start-Service -Name $svc.Name -ErrorAction Stop
                Write-Host "[$timestamp] ✓ $(( $svc.FriendlyName )) успешно перезапущен" -ForegroundColor Green
            }
            catch {
                Write-Host "[$timestamp] ✗ Ошибка перезапуска $($svc.Name): $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}

Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') Мониторинг завершён." -ForegroundColor Cyan