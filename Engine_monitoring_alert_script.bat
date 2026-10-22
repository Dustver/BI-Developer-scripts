REM ==============================================================================
REM АНАЛИЗ ОШИБОК И РЕКОМЕНДАЦИИ ПО УДОСКОНАЛЕНИЮ:
REM 1. ПУТЬ К СКРИПТУ: В файле указан шаблон "path_to_\Engine_service_monitoring_Lark_alert.ps1".
REM    Необходимо указать полный абсолютный путь к файлу (например, "C:\Scripts\Engine_service_monitoring_Lark_alert.ps1")
REM    или корректный относительный путь %~dp0Engine_service_monitoring_Lark_alert.ps1.
REM 2. ВЕРСИЯ POWERSHELL: По умолчанию powershell.exe запускает Windows PowerShell 5.1.
REM    Если необходимо использовать PowerShell 7+, следует использовать pwsh.exe.
REM ==============================================================================

powershell.exe -ExecutionPolicy Bypass -File "path_to_\Engine_service_monitoring_Lark_alert.ps1"
