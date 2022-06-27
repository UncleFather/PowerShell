$Subject = “Информация об аккаунтах:" 
$Server = “mail.domain.ru” 
$From = “sender@domain.ru” 
$To = “receiver@domain.ru” 
$encoding = [System.Text.Encoding]::UTF8

add-pssnapin "Quest.ActiveRoles.ADManagement"
$WshShell = New-Object -ComObject wscript.shell

$Body0 = Get-QADUser -locked  
#$Body0 = $Body1 -replace “;”,”`n” -replace “^”,”`n” 
$Body0 = $Body0 | Select name,DN, canonicalName,userPrincipalName, title, displayName,sAMAccountName,givenName,sn,lastLogon, ";"
$Body0 = $Body0 -replace “@{” -replace “}” -replace “=”, “: ” -replace “;:”,"****************************`n" -replace “;”,”`n”
$Theme0 = "Заблокированные учетные записи:`n"
$PopUp = $WshShell.popup("$Body1",0,"Заблокированные учетные записи",1)

$Body1 = Get-QADUser -notloggedonfor 60 -disabled:$false  
#$Body1 = $Body1 -replace “;”,”`n” -replace “^”,”`n” 
$Body1 = $Body1 | Select name,userPrincipalName, sAMAccountName,lastLogon, ";"
$Body1 = $Body1 -replace “@{” -replace “}” -replace “=”, “: ” -replace “;:”,"`n" 
$Theme1 = "Учетные записи, под которыми не логинились более 60 дней:`n"
$PopUp = $WshShell.popup("$Body1",0,"Учетные записи, под которыми не логинились более 60 дней",1)

$Body2 = Get-QADUser -disabled  
#$Body1 = $Body1 -replace “;”,”`n” -replace “^”,”,” 
$Body2 = $Body2 | Select name,userPrincipalName, sAMAccountName, ";"
$Body2 = $Body2 -replace “@{” -replace “}” -replace “=”, “: ” -replace “;:”,"`n" 
$Theme2 = "Отключенные учетные записи:`n"
$PopUp = $WshShell.popup("$Body1",0,"Отключенные учетные записи",1)

$Body3 = Get-QADUser -inactivefor 30 -disabled:$false 
#$Body1 = $Body1 -replace “;”,”`n” -replace “^”,”,” 
$Body3 = $Body3 | Select name,userPrincipalName, sAMAccountName, ";"
$Body3 = $Body3 -replace “@{” -replace “}” -replace “=”, “: ” -replace “;:”,"`n" 
$Theme3 = "Неактивные в течение 30 дней учетные записи:`n"
$PopUp = $WshShell.popup("$Body1",0,"Неактивные в течение 30 дней учетные записи",1)

$Body4 = Get-QADUser -inactive -disabled:$false 
#$Body1 = $Body1 -replace “;”,”`n” -replace “^”,”,” 
$Body4 = $Body4 | Select name,userPrincipalName, sAMAccountName, ";"
$Body4 = $Body4 -replace “@{” -replace “}” -replace “=”, “: ” -replace “;:”,"`n" 
$Theme4 = "Неактивные учетные записи:`n"
$PopUp = $WshShell.popup("$Body1",0,"Неактивные учетные записи",1)

$Body5 = Get-QADUser -deleted 
#$Body1 = $Body1 -replace “;”,”`n” -replace “^”,”,” 
$Body5 = $Body5 | Select name,userPrincipalName, sAMAccountName, ";"
$Body5 = $Body5 -replace “@{” -replace “}” -replace “=”, “: ” -replace “;:”,"`n" 
$Theme5 = "Удаленные учетные записи:`n"
$PopUp = $WshShell.popup("$Body1",0,"Удаленные учетные записи",1)

$Body6 = Get-QADUser -disabled:$false -IncludeAllProperties | ?{$_.msNPAllowDialin -eq $true}
#$Body1 = $Body1 -replace “;”,”`n” -replace “^”,”,” 
$Body6 = $Body6 | Select name,userPrincipalName, sAMAccountName, ";"
$Body6 = $Body6 -replace “@{” -replace “}” -replace “=”, “: ” -replace “;:”,"`n" 
$Theme6 = "Активные учетные записи с возможностью подключения по VPN:`n"
$PopUp = $WshShell.popup("$Body1",0,"Активные учетные записи с возможностью подключения по VPN",1)

Send-MailMessage -From $From -To $To -SmtpServer $server -Body “$Theme0 $Body0 `n $Theme1 $Body1 `n $Theme2 $Body2 `n $Theme3 $Body3 `n $Theme4 $Body4 `n $Theme5 $Body5 `n $Theme6 $Body6” -Subject $Subject -Encoding $encoding
