chcp 65001
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
