chcp 65001

# ==============================================================================
# АНАЛИЗ ОШИБОК И РЕКОМЕНДАЦИИ ПО УДОСКОНАЛЕНИЮ:
# 1. КРИТИЧЕСКАЯ ОШИБКА — ОТСУТСТВИЕ ПРОВЕРКИ СТАТУСА СЛУЖБЫ:
#    В скрипте НЕ проверяется статус службы ($service = Get-Service ... отсутствует).
#    При КАЖДОМ запуске скрипта (например, по расписанию каждые 5 минут) скрипт отправляет алерт
#    в Telegram о том, что Engine остановлен, и пытается запустить службу Start-Service -Name $ServiceName!
#    РЕШЕНИЕ: Добавить `$service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue`,
#    и выполнять отправку алерта и перезапуск ТОЛЬКО если `$service -and $service.Status -ne 'Running'`.
# 2. ПОПЫТКА ПЕРЕЗАПУСКА ДО ИЛИ ПОСЛЕ УВЕДОМЛЕНИЯ: Вызов Start-Service находится внутри try без проверки результата.
# 3. НЕБЕЗОПАСНЫЙ GET-ЗАПРОС В TELEGRAM API: Использование GET c текстом в URL может сбоить.
#    РЕШЕНИЕ: Перевести на POST с телом JSON / Hashtable.
# 4. ЗАГЛУШКИ ДАННЫХ: $botToken и $chatId пустые.
# ==============================================================================

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
