Start-Sleep -Milliseconds 1500
$base = 'http://127.0.0.1:5000'
$outFile = 'backend\test_results.txt'
Function SafeInvoke($method,$uri,$body,$headers){
    try{
        $resp = Invoke-RestMethod -Method $method -Uri $uri -Body $body -ContentType 'application/json' -Headers $headers -ErrorAction Stop
        $status = 200
        $bodyOut = $resp | ConvertTo-Json -Compress
        return @{ok=$true; status=$status; body=$bodyOut}
    } catch {
        $msg = $_.Exception.Message
        return @{ok=$false; error=$msg}
    }
}

# 1) Login
$loginBody = '{"username":"night","password":"NewPass123!"}'
$loginResp = SafeInvoke 'POST' "$base/login" $loginBody @{}
$token = $null
$loginInfo = ''
if ($loginResp.ok){
    try{ $parsed = (ConvertFrom-Json $loginResp.body) } catch { $parsed = $null }
    if ($parsed -and $parsed.authToken) { 
        $token = $parsed.authToken 
    } elseif ($parsed -and $parsed.password_token) {
        $token = $parsed.password_token
    } else {
        $token = $null
    }
    $loginInfo = "LOGIN: OK`nBODY: $($loginResp.body)"
} else {
    $loginInfo = "LOGIN_ERROR: $($loginResp.error)"
}

# 2) Test1 - wrong old password
$hdr = @{ Authorization = "Bearer $token" }
$test1Body = '{"username":"night","email":"night1@gmail.com","old_password":"WrongOld","new_password":"AnotherPass123!"}'
$test1 = SafeInvoke 'POST' "$base/change-password" $test1Body $hdr
if ($test1.ok) { $test1Info = "TEST1_STATUS: $($test1.status)`nTEST1_BODY: $($test1.body)" } else { $test1Info = "TEST1_ERROR: $($test1.error)" }

# 3) Test2 - correct change
$test2Body = '{"username":"night","email":"night1@gmail.com","old_password":"NewPass123!","new_password":"AnotherPass123!"}'
$test2 = SafeInvoke 'POST' "$base/change-password" $test2Body $hdr
if ($test2.ok) { $test2Info = "TEST2_STATUS: $($test2.status)`nTEST2_BODY: $($test2.body)" } else { $test2Info = "TEST2_ERROR: $($test2.error)" }

# 4) Verify login with new password
$loginNewBody = '{"username":"night","password":"AnotherPass123!"}'
$loginNew = SafeInvoke 'POST' "$base/login" $loginNewBody @{}
if ($loginNew.ok) { $loginNewInfo = "LOGIN_NEW: OK`nBODY: $($loginNew.body)" } else { $loginNewInfo = "LOGIN_NEW_FAIL: $($loginNew.error)" }

# 5) Verify login with old password
$loginOldBody = '{"username":"night","password":"NewPass123!"}'
$loginOld = SafeInvoke 'POST' "$base/login" $loginOldBody @{}
if ($loginOld.ok) { $loginOldInfo = "LOGIN_OLD: OK (unexpected)`nBODY: $($loginOld.body)" } else { $loginOldInfo = "LOGIN_OLD_FAIL (expected): $($loginOld.error)" }

# 6) Test3 - missing token
$test3Body = '{"username":"night","email":"night1@gmail.com","old_password":"NewPass123!","new_password":"AnotherPass123!"}'
$test3 = SafeInvoke 'POST' "$base/change-password" $test3Body @{}
if ($test3.ok) { $test3Info = "TEST3_STATUS: $($test3.status)`nTEST3_BODY: $($test3.body)" } else { $test3Info = "TEST3_ERROR: $($test3.error)" }

# Write results
$all = @(
    $loginInfo,
    $test1Info,
    $test2Info,
    $loginNewInfo,
    $loginOldInfo,
    $test3Info
) -join "`n`n"

Set-Content -Path $outFile -Value $all -Encoding UTF8
Write-Output 'DONE'
