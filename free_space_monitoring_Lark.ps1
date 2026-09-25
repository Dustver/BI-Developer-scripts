[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ========================== КОНФИГУРАЦИЯ ==========================
$LarkWebhook = "https://open.larksuite.com/open-apis/bot/v2/hook/PASTE_ID_HERE"

$drives = @("C", "D")
$thresholdGB = 20

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
try {
    $hostname = $env:COMPUTERNAME
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    $alerts = @()

    foreach ($drive in $drives) {
        $volume = Get-Volume -DriveLetter $drive -ErrorAction SilentlyContinue

        if ($volume) {
            $freeSpaceGB = [math]::round($volume.SizeRemaining / 1GB, 2)

            if ($freeSpaceGB -lt $thresholdGB) {
                $alerts += "- На диске **$drive**: осталось **$freeSpaceGB GB**"
            }
        }
        else {
            $alerts += "- Диск **$drive**: не найден"
        }
    }

    if ($alerts.Count -gt 0) {

        $message = @"
**Сервер:** $hostname  
**Время:** $timestamp  

**Проблема с местом на дисках:**
$($alerts -join "`n")
"@

        Send-LarkAlert `
            -Title "!!! МАЛО МЕСТА НА ДИСКЕ" `
            -Message $message `
            -Color "orange" | Out-Null

        Write-Host "[$timestamp] Отправлен алерт в Lark" -ForegroundColor Yellow
    }
    else {
        Write-Host "[$timestamp] Всё нормально, места хватает" -ForegroundColor Green
    }
}
catch {
    Write-Host "Ошибка выполнения скрипта: $($_.Exception.Message)" -ForegroundColor Red
}