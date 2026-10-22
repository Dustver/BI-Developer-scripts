chcp 65001

# ==============================================================================
# АНАЛИЗ ОШИБОК И РЕКОМЕНДАЦИИ ПО УСОВЕРШЕНСТВОВАНИЮ:
# 1. ОТСУТСТВИЕ ПРОВЕРКИ СУЩЕСТВОВАНИЯ ДИСКА: `Get-Volume -DriveLetter $drive` выбросит исключение,
#    если указанный диск (например, "D") отсутствует в системе.
#    РЕШЕНИЕ: Использовать `Get-Volume -DriveLetter $drive -ErrorAction SilentlyContinue` и проверять результат на $null.
# 2. НЕБЕЗОПАСНЫЙ GET-ЗАПРОС B TELEGRAM API: Склеивание параметров сообщения с синтаксисом %0A непосредственно в GET URL
#    может приводить к ошибкам кодирования URLEncode при передаче пробелов или кириллицы.
#    РЕШЕНИЕ: Используйте POST-запрос с JSON/Hashtable телом:
#    $body = @{ chat_id = $chatId; text = ($messages -join "`n") } | ConvertTo-Json
#    Invoke-RestMethod -Uri "https://api.telegram.org/bot$botToken/sendMessage" -Method Post -Body $body -ContentType "application/json; charset=utf-8"
# 3. ЗАГЛУШКИ ДАННЫХ: Переменные $botToken и $chatId пустые.
# ==============================================================================

try {
    # Укажите диски, которые хотите мониторить
    $drives = @("C", "D")
    # Укажите пороговое значение в гигабайтах
    $threshold = 120

    # Ваш токен Telegram-бота и chat ID
    $botToken = ""
    $chatId = "-"

    # Сбор информации о свободном месте на каждом диске
    $messages = @()
    foreach ($drive in $drives) {
        $freeSpaceGB = [math]::round((Get-Volume -DriveLetter $drive).SizeRemaining / 1GB, 2)
        if ($freeSpaceGB -lt $threshold) {
            $messages += "На диске $drive осталось $freeSpaceGB GB свободного места. %0A"
        }
    }

    # Отправка сообщения в Telegram, если свободное место на каком-либо диске меньше порогового значения
    if ($messages.Count -gt 0) {
        $messageBody = $messages -join "%0A"

        # Формируем URL для GET-запроса (без использования UrlEncode)
        $url = "https://api.telegram.org/bot$botToken/sendMessage?chat_id=$chatId&text=$messageBody" #&parse_mode=Markdown"

        # Отправляем запрос через метод GET
        $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/json; charset=utf-8"

        # Логируем успешную отправку
        Write-Output "успешно отправлено сообщение."
    } else {
        Write-Output "Свободного места хватает. Сообщение не отправлено."
    }
} catch {
    # Логирование ошибок с выводом деталей
    Write-Output "Ошибка отправки"
    Write-Output $_ | Format-List -Force
}
