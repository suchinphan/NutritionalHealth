# PowerShell test flow: register -> login -> update profile -> db-info
# Run from backend folder
param(
  [string]$username = "e2etest",
  [string]$password = "P@ssw0rd1!",
  [string]$email = "e2e@example.com"
)

$base = 'http://127.0.0.1:5000'
Write-Host "Registering $username ..."
$reg = Invoke-RestMethod -Method Post -Uri "$base/register" -Body (ConvertTo-Json @{username=$username; password=$password; email=$email}) -ContentType 'application/json' -ErrorAction Stop
Write-Host "Register response:"; $reg | ConvertTo-Json -Depth 4

Write-Host "Logging in..."
$login = Invoke-RestMethod -Method Post -Uri "$base/login" -Body (ConvertTo-Json @{username=$username; password=$password}) -ContentType 'application/json' -ErrorAction Stop
Write-Host "Login response:"; $login | ConvertTo-Json -Depth 4
$token = $login.authToken ?? $login.password_token
if (-not $token) { Write-Error "No token returned"; exit 1 }
Write-Host "Token length:" $token.Length

Write-Host "Updating profile for user id $($login.id) ..."
$headers = @{ Authorization = "Bearer $token" }
$body = @{ gender='ชาย'; age=30; weight=70; height=175 }
$upd = Invoke-RestMethod -Method Post -Uri "$base/user/$($login.id)" -Headers $headers -Body (ConvertTo-Json $body) -ContentType 'application/json' -ErrorAction Stop
Write-Host "Update response:"; $upd | ConvertTo-Json -Depth 4

Write-Host "Fetching db-info..."
$info = Invoke-RestMethod -Uri "$base/db-info" -ErrorAction Stop
$info | ConvertTo-Json -Depth 4
