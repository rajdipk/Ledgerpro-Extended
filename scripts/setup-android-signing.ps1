# PowerShell script to set up Android signing
$ErrorActionPreference = "Stop"

# Create directories if they don't exist
New-Item -ItemType Directory -Force -Path "android/app" | Out-Null

# Define variables
$STORE_PASSWORD = "ledgerpro2024"
$KEY_ALIAS = "ledgerpro"
$KEY_PASSWORD = "ledgerpro2024"
$KEYSTORE_PATH = "android/app/ledgerpro.keystore"

# Find Java installation
$javaHome = $env:JAVA_HOME
if (-not $javaHome) {
    Write-Host "JAVA_HOME not set. Searching for Java installation..."
    $javaPath = Get-Command java -ErrorAction SilentlyContinue
    if ($javaPath) {
        $javaHome = (Get-Item $javaPath.Source).Directory.Parent.FullName
        Write-Host "Found Java at: $javaHome"
    } else {
        Write-Host "Java not found. Please install JDK and set JAVA_HOME"
        exit 1
    }
}

$keytool = Join-Path $javaHome "bin\keytool.exe"
if (-not (Test-Path $keytool)) {
    Write-Host "keytool not found at: $keytool"
    exit 1
}

# Generate keystore
Write-Host "Generating keystore..."
& $keytool -genkey -v `
    -keystore $KEYSTORE_PATH `
    -alias $KEY_ALIAS `
    -keyalg RSA `
    -keysize 2048 `
    -validity 10000 `
    -storepass $STORE_PASSWORD `
    -keypass $KEY_PASSWORD `
    -dname "CN=LedgerPro, OU=Development, O=Rajdip Kumar, L=Kolkata, S=West Bengal, C=IN"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to generate keystore"
    exit 1
}

# Create gradle.properties with signing config
$gradleProps = @"
RELEASE_STORE_FILE=ledgerpro.keystore
RELEASE_KEY_ALIAS=$KEY_ALIAS
RELEASE_STORE_PASSWORD=$STORE_PASSWORD
RELEASE_KEY_PASSWORD=$KEY_PASSWORD
"@

New-Item -ItemType Directory -Force -Path "android" | Out-Null
Set-Content -Path "android/gradle.properties" -Value $gradleProps

# Output GitHub Actions secrets
Write-Host "`nAdd these secrets to your GitHub repository:"
Write-Host "ANDROID_KEYSTORE_PASSWORD: $STORE_PASSWORD"
Write-Host "ANDROID_KEY_ALIAS: $KEY_ALIAS"
Write-Host "ANDROID_KEY_PASSWORD: $KEY_PASSWORD"

# Create a base64 encoded version of the keystore for GitHub Actions
$keystoreBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($KEYSTORE_PATH))
Set-Content -Path "android/keystore_base64.txt" -Value $keystoreBase64
Write-Host "`nAlso add this secret (contents of android/keystore_base64.txt):"
Write-Host "ANDROID_KEYSTORE_BASE64"

Write-Host "`nSetup complete! The keystore has been generated and gradle.properties has been updated."
