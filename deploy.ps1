# deploy.ps1

Write-Host "🚧 1. 플러터 웹 빌드 시작 (최적화 모드)..."
flutter build web --release

# 빌드가 성공했는지 확인
if ($?) {
    Write-Host "📂 2. 설정 파일(vercel.json) 복사 중..."
    Copy-Item vercel.json -Destination build/web/

    Write-Host "🚀 3. 버셀(Vercel)로 배포 시작..."
    cd build/web
    vercel deploy --prod

    Write-Host "🏠 4. 프로젝트 폴더로 복귀..."
    cd ../..

    Write-Host "✅ [성공] 배포가 완료되었습니다!"
} else {
    Write-Host "❌ [실패] 빌드 중 에러가 발생했습니다."
}