# ==============================================================================
# АНАЛИЗ ОШИБОК И РЕКОМЕНДАЦИИ ПО УСОВЕРШЕНСТВОВАНИЮ:
# 1. ТОЧНОСТЬ СЧЕТЧИКА УДАЛЕННЫХ ФАЙЛОВ: Инкремент $i++ выполняется в конце итерации foreach вне блока try/catch.
#    Если Remove-Item сбоит (например, файл заблокирован процессами Qlik), выводится предупреждение, но $i все равно увеличивается.
#    В результате итоговый вывод "Всего удалено: $i файлов" будет некорректным.
#    РЕШЕНИЕ: Перенести $i++ внутрь блока try сразу после успешного вызова Remove-Item -ErrorAction Stop.
# 2. ПЕРЕХВАТ ОШИБОК REMOVE-ITEM: По умолчанию некритические ошибки Remove-Item могут не перехватываться catch.
#    РЕШЕНИЕ: Добавить параметр -ErrorAction Stop к командам Remove-Item.
# 3. ГАРАНТИЯ МАССИВА: Если Get-ChildItem возвращает 1 элемент, в некоторых старых версиях PowerShell у объекта может отсутствовать свойство .Count.
#    РЕШЕНИЕ: Оборачивать вызов Get-ChildItem в @(...).
# ==============================================================================

$logPath = "C:\ProgramData\Qlik\Sense\Log\NLAppSearch"
$daysToKeep = 7
$batchSize = 2000 

$limitDate = (Get-Date).AddDays(-$daysToKeep)

if (Test-Path $logPath) {

    $files = Get-ChildItem -Path $logPath -File | Where-Object { $_.LastWriteTime -lt $limitDate }

    Write-Host "Найдено файлов для удаления: $($files.Count)"

    $i = 0
    foreach ($file in $files) {
        try {
            Remove-Item $file.FullName -Force
        } catch {
            Write-Warning "Не удалось удалить $($file.FullName): $_"
        }

        $i++
        if ($i % $batchSize -eq 0) {
            Write-Host "$i файлов удалено..."
            Start-Sleep -Milliseconds 100  # чтобы не перегружать систему
        }
    }

    Write-Host "Удаление завершено. Всего удалено: $i файлов."
} else {
    Write-Warning "Папка $logPath не найдена."
}
