chcp 65001

# Указываем путь к временной папке пользователя
#$путь = "C:\ProgramData\Qlik\Sense\Log"
$path = "C:\ProgramData\Qlik\Sense\Log"

# Указываем количество месяцев, старше которых файлы будут удалены
$months = 6

# Получаем текущую дату и вычитаем из нее указанное количество месяцев
$delolder = (Get-Date).AddMonths(-$months)

# Получаем все файлы в указанной папке и её подпапках, старше заданной даты
$files = Get-ChildItem -Path $path -Recurse | Where-Object { $_.LastWriteTime -lt $delolder }

# Удаляем каждый файл
foreach ($file in $files) {
    Remove-Item $file.FullName -Force
}

Write-Host "Deletion Complete."
