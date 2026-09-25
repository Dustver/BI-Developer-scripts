## To run this script from Scheduller add run program: powershell.exe
## Add arguments: -ExecutionPolicy Bypass -File "abs_path_to\QSDesktopUnlockUpdate.ps1"
## Dayly every 14 days

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Путь к локальному unlock-файлу
$localDir  = Join-Path $env:USERPROFILE "Documents\Qlik\Sense\trial"
$localFile = Join-Path $localDir "Qlik_Sense_Desktop.unlock.json"

# Проверяем, что папка существует
If (!(Test-Path $localDir)) {
    New-Item -ItemType Directory -Path $localDir -Force | Out-Null
}

# Общий URL GitHub API для списка релизов
$apiUrl = "https://api.github.com/repos/qlik-download/qlik-sense-desktop/releases"

# Забираем все релизы
try {
    $allReleases = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing
} catch {
    Write-Error "Не удалось достучаться до GitHub API: $_"
    exit 1
}

# Фильтруем релизы 'Initial Release' и проверяем количество assets
$initials = $allReleases |
    Where-Object { $_.name -match "Initial Release"} |
    Sort-Object published_at -Descending

if (-not $initials) {
    Write-Error "Не найдено Initial Release."
    exit 1
}

# Берём самый свежий релиз, где есть unlock
$targetRelease = $initials[0]
Write-Output "Используем релиз '$($targetRelease.name)' от $($targetRelease.published_at) с количеством assets: $($targetRelease.assets.Count)"

# Ищем asset по имени
$asset = $targetRelease.assets | Where-Object { $_.name -eq "Qlik_Sense_Desktop.unlock" }
if (-not $asset) {
    Write-Error "В релизе '$($targetRelease.name)' нет asset 'Qlik_Sense_Desktop.unlock'."
    exit 1
}

$downloadUrl = $asset.browser_download_url
$tempFile    = [IO.Path]::GetTempFileName()

# Скачиваем asset во временный файл
Invoke-WebRequest -Uri $downloadUrl -OutFile $tempFile -UseBasicParsing

# Хэш‑функция для сравнения
function Get-SHA256($path) {
    if (-not (Test-Path $path)) { return $null }
    return (Get-FileHash -Algorithm SHA256 -Path $path).Hash
}

$oldHash = Get-SHA256 $localFile
$newHash = Get-SHA256 $tempFile

if ($newHash -ne $oldHash) {
    Copy-Item -Path $tempFile -Destination $localFile -Force
    Write-Output "Файл обновлён: $localFile"
} else {
    Write-Output "Версия не изменилась — перезаписи не требуется."
}

# Убираем временный файл
Remove-Item $tempFile -Force
