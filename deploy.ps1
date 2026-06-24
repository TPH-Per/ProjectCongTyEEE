# deploy.ps1
Write-Host "Bắt đầu quy trình deploy lên Supabase..." -ForegroundColor Cyan

# Check if supabase cli is installed
if (-not (Get-Command "supabase" -ErrorAction SilentlyContinue)) {
    Write-Host "Supabase CLI chưa được cài đặt. Vui lòng cài đặt thông qua npm: npm i -g supabase" -ForegroundColor Red
    exit 1
}

Write-Host "1. Deploying Database Migrations..." -ForegroundColor Yellow
npx supabase db push

if ($LASTEXITCODE -ne 0) {
    Write-Host "Lỗi khi push database! Hãy chắc chắn bạn đã chạy: supabase login VÀ supabase link --project-ref <your-project-id>" -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "2. Deploying Edge Functions..." -ForegroundColor Yellow
$functions = @("add-order-item", "check-in", "checkout", "close-shift", "custom-access-token", "export-shift-csv", "issue-tax-invoice", "kds-push", "request-checkout")

foreach ($func in $functions) {
    Write-Host "Deploying function: $func" -ForegroundColor Yellow
    npx supabase functions deploy $func --no-verify-jwt
}

Write-Host "Deploy hoàn tất! Database và Functions đã được đẩy lên Supabase thành công." -ForegroundColor Green
