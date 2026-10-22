chcp 65001

# ==============================================================================
# АНАЛИЗ ОШИБОК И РЕКОМЕНДАЦИИ ПО УДОСКОНАЛЕНИЮ:
# 1. КРИТИЧЕСКАЯ ОШИБКА — НЕОБЪЯВЛЕННАЯ ПЕРЕМЕННАЯ: В строке с $url используется переменная $messageBody,
#    которая нигде не объявлена! Текст формируется в массиве $messages.
#    Из-за этого отправляется пустое сообщение или происходит ошибка запроса.
#    РЕШЕНИЕ: Объявить $messageBody = $messages -join "%0A".
# 2. ОТСУТСТВИЕ ПРОВЕРКИ СУЩЕСТВОВАНИЯ СЛУЖБЫ: Get-Service -Name "QlikSenseEngineService" вызовет необработанное исключение,
#    если служба не установлена на сервере.
#    РЕШЕНИЕ: Использовать Get-Service -Name "QlikSenseEngineService" -ErrorAction SilentlyContinue.
# 3. НЕБЕЗОПАСНЫЙ GET-ЗАПРОС В TELEGRAM API: Отправка сообщений через GET-запрос в URL без UriEncode / POST-тела
#    может приводить к ошибкам из-за спецсимволов (%0A, пробелов, кириллицы).
#    РЕШЕНИЕ: Использовать POST-запрос с телом JSON / Hashtable ($body = @{ chat_id = $chatId; text = ... }).
# 4. ЗАГЛУШКИ ДАННЫХ: Переменные $botToken и $chatId пустые.
# ==============================================================================

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
