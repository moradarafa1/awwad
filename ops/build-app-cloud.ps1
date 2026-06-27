# Build/run the Flutter app with cloud (Supabase) enabled.
# Uses the PUBLIC anon key (safe). Run from repo root: ops\build-app-cloud.ps1
# Adjust the flutter path if Flutter is on your PATH.

$flutter = "D:\flutter\bin\flutter.bat"
$SUPABASE_URL = "https://kdczbzzjezyhfxgpegqc.supabase.co"
$SUPABASE_ANON = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtkY3pienpqZXp5aGZ4Z3BlZ3FjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI1MzUxNzcsImV4cCI6MjA5ODExMTE3N30.U1EEeJ_kCauZnXWVTlb-Whm5DyEIgGqkwEUpG8pI2vQ"

Push-Location "$PSScriptRoot\..\app"
# Run on Chrome with cloud sync enabled:
& $flutter run -d chrome `
  --dart-define=SUPABASE_URL=$SUPABASE_URL `
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON
# For a production web build instead, replace the line above with:
#   & $flutter build web --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON
Pop-Location
