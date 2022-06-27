$RegArraySite = 'HKCU:\SOFTWARE', 'ManaeffSoft', 'PowerShell', 'Scripts', 'SiteCheck'
#Адрес проверяемого сайта
$site_addr = 'my.site.ru'
#Порт проверяемого сайта
$site_port = '80'
#Час суток до которого нельзя беспокоить по смс
$dnd_time_to = 9
#Час суток, начиная с которого нельзя беспокоить по смс
$dnd_time_from = 21
#ID, полученный от sms-провайдера (например, sms.ru)
$smsID = ID-NUMBER_FROM_SMS-PROVIDER
#Номер телефона в формате 7XXXXXXXXXX (без пробелов, тире, и др)
$PhoneNumber = 71234567890
#Проверяем в реестре наличие пути и параметра для записи количества неуспешных запросов к сайту в нерабочее время
$RegPathSite = $RegArraySite[0]
$RegValSite = $RegArraySite[$RegArraySite.Count - 1]
for ($i = 1; $i -lt $RegArraySite.Count - 1; $i++){
    $RegPathSite = $RegPathSite + '\' + $RegArraySite[$i]
}
if ((Get-ItemProperty $RegPathSite $RegValSite -ErrorAction SilentlyContinue) -eq $null) {
    #Создаем путь в реестре для параметра для записи количества неуспешных запросов к сайту в нерабочее время
    $RegPathSite = $RegArraySite[0]
    for ($i=1; $i -lt $RegArraySite.Count - 1; $i++){
        $RegValSite = $RegArraySite[$i]
        New-Item –Path $RegPathSite –Name $RegValSite
        $RegPathSite = $RegPathSite + '\' + $RegValSite
    }
    #Создаем параметр в реестре для записи количества неуспешных запросов к сайту в нерабочее время
    New-ItemProperty -Path $RegPathSite -Name $RegArraySite[$i] -Value $0  -PropertyType "DWord"
}

#Получаем текущее время (часы)
$Hr = [int]::Parse((Get-Date -DisplayHint Time -Format HH))
#Получаем количество неуспешных запросов к сайту в нерабочее время
$RestartCount = (Get-ItemProperty -Path $RegPathSite).($RegArraySite[$RegArraySite.Count - 1])
if (($Hr -gt $dnd_time_to - 1) -and ($Hr -lt $dnd_time_from +1 ) -and ($RestartCount -gt 0)){ #Если время рабочее и Site перезапускался хотя бы один раз с момента отправки последнего sms
    #Формируем и отправляем sms с количеством перезапусков Site за ночь
    $ip = (new-object net.webclient).DownloadString("http://sms.ru/sms/send?api_id=" + $smsID + "&to=" + $PhoneNumber + "&text=My+site+was+unavailable+" + $RestartCount + "+times+since+the+last+message")    
    #Сбрасываем счетчик количества неуспешных запросов к сайту за ночь
    Set-ItemProperty -Path $RegPathSite -Name $RegArraySite[$RegArraySite.Count - 1] -Value $0
}
#Очищаем массив ошибок
$Error.clear()

$ip = ""
$ip = (new-object net.webclient).DownloadString("http://+ $site_addr + ":" + $site_port + "/ip.php") 

#Получаем текущую дату и время
$date = date

if ($ip -cmatch '(?s)([0-9]{1,3}?\.[0-9]{1,3}?\.[0-9]{1,3}?\.[0-9]{1,3})') { 
    #Записываем в текстовый файл время запроса и его результат
    "`r`n" + (Out-String -InputObject $date).trim() + "`r`n" + $ip + $Error | Out-File D:\Soft\Bat\SiteCheck.txt -Append
    
    $matches[1]
} else {
    #Записываем в текстовый файл время запроса и его результат
    "`r`n" + (Out-String -InputObject $date).trim() + "`r`n" + $ip + $Error | Out-File D:\Soft\Bat\SiteCheck.txt -Append
    
    if (-not (Get-EventLog -Newest 1 -LogName Application -Source SiteCheck)) { #Если в журнале «Приложение» нет источника «SiteCheck», то
        new-eventlog -source SiteCheck -logname Application #Создаем новый источник «SiteCheck» в журнале «Приложение» 
    }
    write-eventlog -logname Application -source SiteCheck -eventID 21456 -entrytype "Warning" -message ("Site is down...`r`n" + $Error) -category 7
    #Действия по восстановлению работоспособности сайта
    #iisreset 
    #& 'D:\Soft\Bat\smthToDo.bat'   
    #Если событие произошло в нерабочее время, увеличиваем значение счетчика перезапусков Site в реестре
    if (($Hr -gt $dnd_time_from) -or ($Hr -lt $dnd_time_to)){
        Set-ItemProperty -Path $RegPathSite -Name $RegArraySite[$RegArraySite.Count - 1] -Value ($RestartCount + 1)
    } else { #Если событие произошло в рабочее время, формируем sms сообщение
        Start-Sleep -s 30  
        $ip = (new-object net.webclient).DownloadString("http://sms.ru/sms/send?api_id=" + $smsID + "&to=" + $PhoneNumber + "&text=My+site+is+unavailable")
    } 
}
        
