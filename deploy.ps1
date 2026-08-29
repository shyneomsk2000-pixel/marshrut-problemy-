<#
    Публикация приложения «Маршрут проблемы» на GitHub Pages.

    Что делает: поднимает версию сборки в index.html (константа APP_VERSION и мета-тег),
    коммитит изменения и отправляет их в GitHub. Дальше GitHub Actions сам выкатывает
    index.html и install.html на Pages.

    Запуск из PowerShell в папке проекта:
        .\deploy.ps1 "что изменилось"
    или двойным щелчком по deploy.cmd — он спросит комментарий.
#>
param([string]$Message = "")

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $root

if (-not (Test-Path (Join-Path $root ".git"))) {
    Write-Host "В этой папке ещё нет репозитория Git." -ForegroundColor Yellow
    Write-Host "Выполните разовую настройку из DEPLOY.md (шаг 2), потом запускайте deploy.ps1."
    exit 1
}

# --- версия сборки: дата и порядковый номер за день ---
$file = Join-Path $root "index.html"
$text = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)

$m = [regex]::Match($text, "const APP_VERSION='([^']+)'")
if (-not $m.Success) { throw "В index.html не найдена константа APP_VERSION" }

$old   = $m.Groups[1].Value
$today = Get-Date -Format "yyyy.MM.dd"
if ($old.StartsWith("$today-")) { $n = [int]($old.Split('-')[-1]) + 1 } else { $n = 1 }
$new = "$today-$n"

$text = [regex]::Replace($text, "const APP_VERSION='[^']*'", "const APP_VERSION='$new'")
$text = [regex]::Replace($text, '(<meta name="app-version" content=")[^"]*(">)', ('${1}' + $new + '${2}'))

# UTF-8 без BOM: с BOM браузер иногда рисует лишний символ перед разметкой
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($file, $text, $utf8NoBom)

Write-Host "Версия сборки: $old -> $new" -ForegroundColor Cyan

if (-not $Message) { $Message = "Обновление $new" }

git add -A
git commit -m $Message
if ($LASTEXITCODE -ne 0) { Write-Host "Нечего коммитить." -ForegroundColor Yellow }

git push
if ($LASTEXITCODE -ne 0) { throw "git push не прошёл — смотрите сообщение выше" }

Write-Host ""
Write-Host "Отправлено. Выкатка идёт во вкладке Actions репозитория, обычно 1-2 минуты." -ForegroundColor Green
Write-Host "Проверить, что портал взял новую версию: наведите курсор на название приложения" -ForegroundColor Green
Write-Host "в шапке — в подсказке должно стоять $new." -ForegroundColor Green
