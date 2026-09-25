chcp 65001
$ServiceName = 'QlikSenseEngineService'
$botToken = ""
$chatId = "-"
$message = "Внимание!%0AEngine остановлен!%0A"
$url = "https://api.telegram.org/bot$botToken/sendMessage?chat_id=$chatId&text=$message"


try {
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/json; charset=utf-8"
    Write-Output "Engine has stopped"
    # Также можно здесь попытаться перезапустить службу
    Start-Service -Name $ServiceName
} catch {
    # Логирование ошибок с выводом деталей
    Write-Output "Something goes wrong!"
    Write-Output $_ | Format-List -Force
}
