# Android Keystore Generation Script
param(
    [Parameter(Mandatory=$true)]
    [string]$KeystorePassword,
    
    [Parameter(Mandatory=$true)]
    [string]$KeyAlias,
    
    [Parameter(Mandatory=$true)]
    [string]$KeyPassword
)

# Find Java Home and keytool
$javaHome = if ($env:JAVA_HOME) {
    $env:JAVA_HOME
} elseif (Test-Path "C:\Program Files\Java") {
    Get-ChildItem "C:\Program Files\Java" -Directory | 
    Where-Object { $_.Name -like "jdk*" } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1 |
    ForEach-Object { $_.FullName }
} elseif (Test-Path "C:\Program Files\Common Files\Oracle\Java\javapath\java.exe") {
    (Get-Item "C:\Program Files\Common Files\Oracle\Java\javapath\java.exe").Directory.Parent.Parent.FullName
} else {
    throw "Java installation not found. Please install JDK or set JAVA_HOME environment variable."
}

$keytoolPath = Join-Path $javaHome "bin\keytool.exe"
if (-not (Test-Path $keytoolPath)) {
    throw "keytool not found at: $keytoolPath"
}

Write-Host "Found keytool at: $keytoolPath"

$keystorePath = "..\android\app\ledgerpro.keystore"
$validity = "10000" # Validity in days

# Create the android directory if it doesn't exist
New-Item -ItemType Directory -Force -Path "..\android\app"

# Remove existing keystore if it exists
if (Test-Path $keystorePath) {
    Remove-Item $keystorePath -Force
    Write-Host "Removed existing keystore"
}

# Generate the keystore
$keytoolArgs = @(
    "-genkeypair",
    "-v",
    "-storetype", "PKCS12",
    "-keystore", $keystorePath,
    "-alias", $KeyAlias,
    "-keyalg", "RSA",
    "-keysize", "2048",
    "-validity", $validity,
    "-storepass", $KeystorePassword,
    "-keypass", $KeyPassword,
    "-dname", "CN=LedgerPro, OU=Development, O=Rajdip Kumar, L=Kolkata, S=West Bengal, C=IN"
)

Write-Host "Generating keystore..."
Write-Host "Command: $keytoolPath $($keytoolArgs -join ' ')"

& $keytoolPath $keytoolArgs

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nKeystore generated successfully at: $keystorePath"
    Write-Host "`nStore these values securely. You'll need them for GitHub Secrets:`n"
    Write-Host "ANDROID_KEYSTORE_PASSWORD=$KeystorePassword"
    Write-Host "ANDROID_KEY_ALIAS=$KeyAlias"
    Write-Host "ANDROID_KEY_PASSWORD=$KeyPassword"
    
    # Add keystore path to .gitignore if not already present
    $gitignorePath = "..\\.gitignore"
    $keystoreIgnoreLine = "android/app/ledgerpro.keystore"
    
    if (!(Test-Path $gitignorePath)) {
        New-Item -ItemType File -Path $gitignorePath
    }
    
    $gitignoreContent = Get-Content $gitignorePath
    if ($gitignoreContent -notcontains $keystoreIgnoreLine) {
        Add-Content $gitignorePath "`n# Android signing`n$keystoreIgnoreLine"
        Write-Host "`nAdded keystore to .gitignore"
    }

    # Generate Base64 encoded keystore
    $keystoreBytes = Get-Content -Path $keystorePath -Raw -Encoding Byte
    $encodedKeystore = [Convert]::ToBase64String($keystoreBytes)
    $encodedKeystorePath = "encoded_keystore.txt"
    Set-Content -Path $encodedKeystorePath -Value $encodedKeystore
    Write-Host "`nEncoded keystore saved to: $encodedKeystorePath"
    Write-Host "Use this value for the ENCODED_KEYSTORE secret in GitHub"
} else {
    Write-Error "Failed to generate keystore"
    exit 1
}
