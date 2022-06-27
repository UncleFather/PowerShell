$Subject = “Разблокированы учетные записи" 
$Theme = “Только что были разблокированы учетные записи:” 
$Server = “mail.domain.ru” 
$From = “sender@domain.ru” 
$To = “receiver@domain.ru” 
$encoding = [System.Text.Encoding]::UTF8

#Исключения из разблокировки
$ecxclus1 = "TestUser"
$ecxclus2 = "Гость"

add-pssnapin "Quest.ActiveRoles.ADManagement"
#$WshShell = New-Object -ComObject wscript.shell

$Body = Get-QADUser -locked | where {$_.sAMAccountName -notmatch $ecxclus1 -and $_.sAMAccountName -notmatch $ecxclus2 } | unlock-QADUser
#$Body 

if ($Body -ne $NULL) {
    $Body = $Body -replace “;”,”`n” -replace “^”,”`n” 
    #$Body = $Body | Select name,DN, canonicalName,userPrincipalName, title, displayName,sAMAccountName,givenName,sn,lastLogon, ";"
    #$Body = $Body -replace “@{” -replace “}” -replace “=”, “: ” -replace “;:”,"****************************`n" -replace “;”,”`n”
    #$PopUp = $WshShell.popup("$Body",0,"Разблокированные учетные записи",1)
    Send-MailMessage -From $From -To $To -SmtpServer $server -Body “$Theme $Body” -Subject $Subject -Encoding $encoding
}
