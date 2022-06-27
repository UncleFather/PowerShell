# Кодируем строку:
Add-Type -AssemblyName System.Web
$MyString = "Моя строка@#$%^&&"
$MyString = [System.Web.HttpUtility]::UrlEncode($MyString)
write-host $MyString

# Раскодируем строку в читабельный вид:
Add-Type -AssemblyName System.Web
$MyString = "%d0%9c%d0%be%d1%8f+%d1%81%d1%82%d1%80%d0%be%d0%ba%d0%b0%40%23%24%25%5e%26%26"
$MyString = [System.Web.HttpUtility]::UrlDecode($MyString)
write-host $MyString
