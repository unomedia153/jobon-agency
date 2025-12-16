# 1. 플러터 웹 빌드 (최적화 모드)
Write-Host "🔨 빌드 시작..."
flutter build web --release

# 2. 설정 파일 복사
Write-Host "📂 설정 파일 복사 중..."
Copy-Item vercel.json -Destination build/web/

# 3. 버셀 배포 폴더로 이동
Set-Location build/web

# 4. 실제 배포 (프로덕션)
Write-Host "🚀 버셀로 발사!"
vercel deploy --prod

# 5. 원래 폴더로 복귀
Set-Location ../..
Write-Host "✅ 배포 완료! 수고하셨습니다."