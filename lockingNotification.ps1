#Отправка уведомлений по наступлению события 4740 – блокирование учетной записи пользователя 
#Автор оригинального скрипта: http://habrahabr.ru/post/147750/ 
#Изменения (itpadla.wordpress.com) 
#Дата создания 22.08.2012 
#Дата изменения: 20.03.2013 
#Описание: скрипт отправляет уведомление о определенном событии в Security Log в письме в человекочитаемом виде 
#Скрипт адаптирован под MS Windows 2003 Server Rus: http://manaeff.ru/forum
#Для создания триггера на сервере запускаем: 
#eventtriggers /create /TR "Lock Account" /TK "C:\WINDOWS\system32\windowspowershell\v1.0\powershell.exe c:\Soft\Bat\LckAccount.ps1" /L Security /EID 644
##################################################################################### 
$Subject = “Заблокирован аккаунт" 
$Theme = “Только что был заблокирован аккаунт” 
$Theme1 = "Прочие заблокированные аккаунты:"
$Server = “mail.domain.ru” 
$From = “sender@domain.ru” 
$To = “receiver@domain.ru” 
$encoding = [System.Text.Encoding]::UTF8

#Выбирается последнее произошедшее событие с таким ID.

$Body=Get-EventLog -Newest 1 -LogName Security -InstanceId 644 -ErrorAction SilentlyContinue

$Body = $Body | Select TimeGenerated, @{n=”Аккаунт”;e={ $_.Message -split “`n” | Select-String “Имя конечной учетной записи:”}} ,@{n=”Имя компьютера”;e={ $_.Message -split “`n” | Select-String “Имя вызывающего компьютера:”}}
$Body = $Body -replace “@{” -replace “}” -replace “=”, “: ” -replace “;”,”`n” -replace “TimeGenerated”,”Время события” -replace “^”,”`n” -replace “Имя конечной учетной записи:”,”" -replace “Имя вызывающего компьютера:”,”" -replace “`t”,”"
add-pssnapin "Quest.ActiveRoles.ADManagement"
$Body1 = Get-QADUser -locked  
$Body1 = $Body1 -replace “;”,”`n” -replace “^”,”`n” 
Send-MailMessage -From $From -To $To -SmtpServer $server -Body “$Theme $Body $Theme1 $Body1” -Subject $Subject -Encoding $encoding

