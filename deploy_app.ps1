# Script de automação para rodar o Salinha das Crianças

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Iniciando Preparacao para o Deploy do PWA" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# 1. Verifica Flutter
$flutterStatus = Get-Command flutter -ErrorAction SilentlyContinue
if ($null -eq $flutterStatus) {
    Write-Host "[!] O Flutter SDK nao foi encontrado no PATH." -ForegroundColor Yellow
    Write-Host "Por favor, instale o Flutter baixando de: https://docs.flutter.dev/get-started/install/windows" -ForegroundColor Yellow
    Write-Host "Apos instalar, feche este terminal e tente novamente." -ForegroundColor Yellow
    Read-Host "Pressione Enter para fechar"
    exit
}

Write-Host "[OK] Flutter encontrado!" -ForegroundColor Green

# 2. Compilar Flutter Web
Write-Host "Compilando o aplicativo para Web (PWA)..." -ForegroundColor Cyan
flutter build web --release

# 3. Verifica Firebase
$firebaseStatus = Get-Command firebase -ErrorAction SilentlyContinue
if ($null -eq $firebaseStatus) {
    Write-Host "Tentando usar o npx para o firebase..." -ForegroundColor Yellow
    npx firebase login
    npx firebase init hosting
    npx firebase deploy --only hosting
} else {
    Write-Host "Iniciando Login no Firebase..." -ForegroundColor Cyan
    firebase login
    Write-Host "Iniciando Configuracao do Hosting..." -ForegroundColor Cyan
    firebase init hosting
    Write-Host "Fazendo o Deploy..." -ForegroundColor Cyan
    firebase deploy --only hosting
}

Write-Host "=========================================" -ForegroundColor Green
Write-Host "DEPLOY CONCLUIDO COM SUCESSO!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Read-Host "Pressione Enter para fechar"
