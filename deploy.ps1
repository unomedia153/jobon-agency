# deploy.ps1 (수정본)

Write-Host "🚧 1. 플러터 웹 빌드 시작 (Release Mode)..."
flutter build web --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 빌드 실패! 스크립트를 중단합니다." -ForegroundColor Red
    exit
}

# (중요) Vercel 설정 파일이 빌드 폴더에 꼭 있어야 함
Write-Host "📄 Vercel 설정 파일 복사..."
if (Test-Path "vercel.json") {
    Copy-Item "vercel.json" -Destination "build/web/"
} else {
    Write-Host "⚠️ vercel.json 파일이 없습니다! 라우팅 에러가 날 수 있습니다." -ForegroundColor Yellow
}

Write-Host "📦 2. 변경사항 Git에 담기..."
git add .

Write-Host "💾 3. 커밋 작성 중..."
$date = Get-Date -Format "yyyy-MM-dd HH:mm"
git commit -m "Deploy Update: $date"

Write-Host "🚀 4. 깃허브로 발사 (Push)..."
git push origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ 깃허브 업로드 완료! 1~2분 뒤 Vercel이 자동으로 배포합니다." -ForegroundColor Green
    Write-Host "👉 접속 주소: https://agency.jobon.kr" -ForegroundColor Cyan
} else {
    Write-Host "❌ Push 실패. 깃허브 연결을 확인하세요." -ForegroundColor Red
}