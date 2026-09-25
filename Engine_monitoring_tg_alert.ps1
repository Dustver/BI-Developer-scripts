chcp 65001
try {
    $botToken = ""
    $chatId = "-"
    $messages = @()

    $service = Get-Service -Name "QlikSenseEngineService"

    if ($service.Status -ne "Running") {
        $messages += "Внимание!%0AEngine остановлен!%0A"
        $url = "https://api.telegram.org/bot$botToken/sendMessage?chat_id=$chatId&text=$messageBody" #&parse_mode=Markdown"
        $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/json; charset=utf-8"
        Write-Output "Engine has stopped"
    } else {
        Write-Output "Engine working"
    }
    
} catch {
    # Логирование ошибок с выводом деталей
    Write-Output "Something goes wrong!"
    Write-Output $_ | Format-List -Force
}
