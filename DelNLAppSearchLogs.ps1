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
