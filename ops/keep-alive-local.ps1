# Local backup keep-alive pinger for the Awwad Supabase project.
# Registered as a Windows scheduled task (see PROJECT_STATE §5 / SUBMISSION_GUIDE):
#   schtasks /query /tn AwwadSupabaseKeepAlive     (inspect)
#   schtasks /delete /tn AwwadSupabaseKeepAlive /f (remove)
# Uses ONLY the public anon key. Independent of GitHub Actions.

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$url = 'https://kdczbzzjezyhfxgpegqc.supabase.co'
$anon = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtkY3pienpqZXp5aGZ4Z3BlZ3FjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI1MzUxNzcsImV4cCI6MjA5ODExMTE3N30.U1EEeJ_kCauZnXWVTlb-Whm5DyEIgGqkwEUpG8pI2vQ'
$headers = @{ apikey = $anon; Authorization = "Bearer $anon"; 'Content-Type' = 'application/json' }

try {
    Invoke-RestMethod -Uri "$url/rest/v1/habit_catalog?select=id&limit=1" -Headers $headers -TimeoutSec 30 | Out-Null
    $t = Invoke-RestMethod -Method Post -Uri "$url/rest/v1/rpc/heartbeat" -Headers $headers -Body '{"src":"local-task"}' -TimeoutSec 30
    Add-Content -Path "$PSScriptRoot\keep-alive-local.log" -Value "$(Get-Date -Format s) OK $t"
} catch {
    Add-Content -Path "$PSScriptRoot\keep-alive-local.log" -Value "$(Get-Date -Format s) FAIL $($_.Exception.Message)"
    exit 1
}
