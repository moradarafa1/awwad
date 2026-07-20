# Starts the Awwad Android emulator, waits until it is actually usable, and
# optionally installs + launches the app.
#
#   ops\emulator.ps1              start the emulator only
#   ops\emulator.ps1 -Install     also build a debug APK, install it, and open it
#   ops\emulator.ps1 -Stop        shut the emulator down
#
# Why a script and not a one-liner: `emulator -avd` returns as soon as the
# PROCESS starts, long before Android has finished booting, so anything that
# runs straight after it fails with "device offline". The wait loop below polls
# sys.boot_completed, which is the only reliable signal.

param(
  [switch]$Install,
  [switch]$Stop,
  [string]$Avd = 'awwad_test'
)

$ErrorActionPreference = 'Stop'
$sdk      = 'D:\Android\Sdk'
$emulator = Join-Path $sdk 'emulator\emulator.exe'
$adb      = Join-Path $sdk 'platform-tools\adb.exe'

if (-not (Test-Path $emulator)) { throw "emulator not found at $emulator" }

if ($Stop) {
  & $adb -s emulator-5554 emu kill 2>$null
  Write-Host 'emulator stopped.'
  exit 0
}

# Already running? Reuse it. Booting a second copy of the same AVD fails with a
# lock error that reads like a corrupt image and sends you debugging the wrong
# thing.
$running = (& $adb devices | Select-String 'emulator-\d+\s+device')
if ($running) {
  Write-Host 'emulator already running, reusing it.'
} else {
  $avds = & $emulator -list-avds
  if ($avds -notcontains $Avd) {
    throw "AVD '$Avd' does not exist. Available: $($avds -join ', ')"
  }
  Write-Host "starting $Avd ..."
  # -gpu host: hardware rendering. swiftshader_indirect (software) was the
  # first choice here for reliability, but it renders on the CPU and there is
  # no reason to pay that on a machine with a working GPU.
  # -memory 4096: the AVD default left the guest at ~94% RAM with the swap file
  # in use while streaming audio, which is its own source of stutter.
  # AUDIO NOTE: choppy playback on the emulator is usually NOT the app. The
  # emulated audio HAL reports inconsistent timestamps, which shows up as
  # `DefaultAudioSink: Spurious audio timestamp` in logcat and is audible as
  # stuttering. Confirm audio issues on real hardware before chasing them here.
  Start-Process -FilePath $emulator `
    -ArgumentList @('-avd', $Avd, '-no-snapshot-save', '-gpu', 'host',
                    '-memory', '4096') `
    -WindowStyle Normal
}

Write-Host 'waiting for boot ...' -NoNewline
& $adb wait-for-device
for ($i = 0; $i -lt 120; $i++) {
  $done = (& $adb shell getprop sys.boot_completed 2>$null) -replace '\s', ''
  if ($done -eq '1') { break }
  Write-Host '.' -NoNewline
  Start-Sleep -Seconds 2
}
Write-Host ''
if ($done -ne '1') { throw 'emulator did not finish booting in ~4 minutes.' }

# Unlock: a locked screen silently swallows every input event, so taps appear
# to do nothing and the app looks broken.
& $adb shell input keyevent 82 2>$null | Out-Null
Write-Host 'emulator ready.'

if ($Install) {
  $flutter = 'D:\flutter\bin\flutter.bat'
  # Gradle needs these explicitly. Without them the build dies with a bare
  # "Gradle task assembleDebug failed with exit code 1" that names no cause.
  $env:JAVA_HOME    = 'D:\jdk17\jdk-17.0.19+10'
  $env:ANDROID_HOME = $sdk
  Push-Location (Join-Path $PSScriptRoot '..\app')
  Write-Host 'building debug apk ...'
  # Flutter prints plugin WARNINGS to stderr. With $ErrorActionPreference =
  # 'Stop', PowerShell turns any native stderr line into a terminating
  # NativeCommandError and aborts here even though the build succeeded. So
  # relax it around the native calls and judge by $LASTEXITCODE, which is the
  # only trustworthy signal.
  $ErrorActionPreference = 'Continue'
  & $flutter build apk --debug `
    --dart-define=SUPABASE_URL=https://kdczbzzjezyhfxgpegqc.supabase.co `
    --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtkY3pienpqZXp5aGZ4Z3BlZ3FjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI1MzUxNzcsImV4cCI6MjA5ODExMTE3N30.U1EEeJ_kCauZnXWVTlb-Whm5DyEIgGqkwEUpG8pI2vQ
  $buildCode = $LASTEXITCODE
  Pop-Location
  if ($buildCode -ne 0) { throw "flutter build failed with exit code $buildCode" }

  $apk = Join-Path $PSScriptRoot '..\app\build\app\outputs\flutter-apk\app-debug.apk'
  if (-not (Test-Path $apk)) { throw "apk not found at $apk" }
  Write-Host 'installing ...'
  $out = & $adb install -r $apk 2>&1 | Out-String
  if ($LASTEXITCODE -ne 0) {
    # A debug build cannot overwrite a release build of the same package: the
    # signing keys differ and Android refuses with INSTALL_FAILED_UPDATE_
    # INCOMPATIBLE. Uninstalling is the only way through, and it is safe here
    # because the emulator holds no data worth keeping.
    if ($out -match 'INSTALL_FAILED_UPDATE_INCOMPATIBLE|signatures do not match') {
      Write-Host 'signature mismatch with the installed build, uninstalling first ...'
      & $adb uninstall com.awwad.awwad | Out-Null
      & $adb install -r $apk
      if ($LASTEXITCODE -ne 0) { throw "adb install failed again with exit code $LASTEXITCODE" }
    } else {
      throw "adb install failed:`n$out"
    }
  }
  & $adb shell monkey -p com.awwad.awwad -c android.intent.category.LAUNCHER 1 | Out-Null
  Write-Host 'app launched.'
}
