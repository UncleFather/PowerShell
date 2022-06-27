# **********************************************************************************************************************************************************************
# Функция нахождения IP адреса шлюза в удаленной сети:

function FindingGateIP {
    #Выполняем трассировку из двух шагов до тестового IP ConstTestIP и отбираем строки, содержащие IP адреса
    $VPNConnectionGate = (tracert -d -h 2 $ConstTestIP | select-string -pattern '(?s)([0-9]{1,3}?\.[0-9]{1,3}?\.[0-9]{1,3}?\.[0-9]{1,3})') -split "`n"
    if ($VPNConnectionGate.Length -lt 3) { #Если получаем количество строк меньше, 3 - значит на следующем прыжке после VPN сервера мы ничего не получаем (т.к. первая строка - это просто информационная строка
                #выполнения трассировки, указывающая хост, до которого выполняется трассировка, а вторая строка - виртуальный IP VPN сервера), и значит шлюз в удаленной сети мы не находим
        #Невозможно определить шлюз в удаленной сети
        "Определить невозможно"
    } else { #Если второй прыжок трассировки вернул какой-то IP адрес
        #Сравниваем первые три группы цифр IP адреса полученного на первом и на втором прыжке (как правило, если шлюз удаленной сети и VPN сервер расположены на разных компьютерах, то эти три группы должны совпадать)
        if ((($VPNConnectionGate[1] | select-string -pattern '(?s)([0-9]{1,3}?\.[0-9]{1,3}?\.[0-9]{1,3}?\.)').Matches | Select-Object -Property Value | ForEach-Object { $_.Value.ToString()}) -ne (($VPNConnectionGate[2] | select-string -pattern '(?s)([0-9]{1,3}?\.[0-9]{1,3}?\.[0-9]{1,3}?\.)').Matches | Select-Object -Property Value | ForEach-Object { $_.Value.ToString()})) {
            #Шлюз удаленной сети получили на первом прыжке - значит VPN сервер и шлюз удаленной сети являются одним устройством
            ($VPNConnectionGate[1] | select-string -pattern '(?s)([0-9]{1,3}?\.[0-9]{1,3}?\.[0-9]{1,3}?\.[0-9]{1,3})').Matches | Select-Object -Property Value | ForEach-Object { $_.Value.ToString()}
        } else {
            #Шлюз удаленной сети получили на втором прыжке - значит VPN сервер и шлюз удаленной сети являются разными устройствами
            ($VPNConnectionGate[2] | select-string -pattern '(?s)([0-9]{1,3}?\.[0-9]{1,3}?\.[0-9]{1,3}?\.[0-9]{1,3})').Matches | Select-Object -Property Value | ForEach-Object { $_.Value.ToString()}
        }
    }
}

# **********************************************************************************************************************************************************************
# Функция записи нового IP адреса в журнал Windows и в текстовый файл:

function WritingIP {
    $MyIpChangeLogContent = ""
    $CurrentString = ""
    $WholeString = ""

    $StringIP = (get-date).ToString() + " " + $ip
    add-content $MyIpChangeLog -value ($StringIP) #Записать в файл новый IP (пишется всегда при изменении IP)

    if ((Get-Content -Path $MyIpChangeLog).length -gt $MaxStringInLog) { #Проверяем количество строк в журнале
        $MyIpChangeLogContent = Get-Content -Path $MyIpChangeLog #Если количество строк превышает допустимое, считываем все содержимое жупнала в перемнную MyIpChangeLogContent
        ForEach ($CurrentString in $MyIpChangeLogContent) { #Переписываем массив строк, разделяя переносом строки, из переменной MyIpChangeLogContent в переменную WholeString, исключая первую строку
            If ($CurrentString.ReadCount -gt 2) { #Берем все строки, начиная с третьей
                $WholeString = $WholeString + "`n" + $CurrentString #Добавляем текущую строку в переменную WholeString
            } ElseIf ($CurrentString.ReadCount -eq 2) { #Берем вторую строку
                $WholeString = $CurrentString #Записываем вторую строку в начало переменной WholeString
            }
        }
        $WholeString = $WholeString -split "`n" #Разбиваем переменную WholeString переводами строки
        Clear-Content -Path $MyIpChangeLog #Чистим содержимое файла журнала
        add-content $MyIpChangeLog -value ($WholeString) #Записываем переменную WholeString в файл журнала

    } #Таким образом, при превышении заданного количества строк, мы переписываем файл журнала, удаляя первую строку

    if ($ConstWriteToSystemLog) { #Если используем журнал Windows, то
        write-eventlog -logname Application -source ExternalIPCheck -eventID 12346 -entrytype Warning -message $ip -category 7 #Записать в журнал новый IP
    }
}

# **********************************************************************************************************************************************************************
# Функция записи ошибок и диагностических сообщений в журнал Windows и в текстовый файл:
function WritingMessage ($EvtID, $EvtType, $ErrDescr) {
    $MyIpChangeLogContent = ""
    $CurrentString = ""
    $WholeString = ""

    if ($ConstWriteToSystemLog) { #Если используем журнал Windows, то
        write-eventlog -logname Application -source ExternalIPCheck -eventID $EvtID -entrytype $EvtType -message $ErrDescr -category 7 #Записываем информационное событие в журнал «Приложение» от источника «ExternalIPCheck»
    }
    if ($ConstWriteToFileLog) { #Если пишем отчеты в текстовый файл, то
        add-content $MyIpErrLog -value ($ErrDescr) #Дописываем последней строкой описание события

        if ((Get-Content -Path $MyIpErrLog).length -gt $MaxStringInLog) { #Проверяем количество строк в журнале
            $MyIpChangeLogContent = Get-Content -Path $MyIpErrLog #Если количество строк превышает допустимое, считываем все содержимое жупнала в перемнную MyIpChangeLogContent
            ForEach ($CurrentString in $MyIpChangeLogContent) { #Переписываем массив строк, разделяя переносом строки, из переменной MyIpChangeLogContent в переменную WholeString, исключая первую строку
                If ($CurrentString.ReadCount -gt 2) { #Берем все строки, начиная с третьей
                    $WholeString = $WholeString + "`n" + $CurrentString #Добавляем текущую строку в переменную WholeString
                } ElseIf ($CurrentString.ReadCount -eq 2) { #Берем вторую строку
                    $WholeString = $CurrentString #Записываем вторую строку в начало переменной WholeString
                }
            }
            $WholeString = $WholeString -split "`n" #Разбиваем переменную WholeString переводами строки
            Clear-Content -Path $MyIpErrLog #Чистим содержимое файла журнала
            add-content $MyIpErrLog -value ($WholeString) #Записываем переменную WholeString в файл журнала
        } #Таким образом, при превышении заданного количества строк, мы переписываем файл журнала, удаляя первую строку

    }
}

# **********************************************************************************************************************************************************************
# Функция генерации HTML странички:

function GeneratingHTML {
   
    if ($ConstWriteToSystemLog) { #Получаем дату, время и IP. Если используем журнал Windows, то
        $DateTimeEvt = -split(Get-EventLog -Newest 11 -LogName Application -InstanceID 12346 -source ExternalIPCheck -ErrorAction SilentlyContinue | Select-Object -Property TimeWritten | ForEach-Object { $_.TimeWritten.ToString()})
            #Получаем дату и время 11 последних событий журнала «Приложение» от источника «ExternalIPCheck»
        $IPEvt = -split(Get-EventLog -Newest 11 -LogName Application -InstanceID 12346 -source ExternalIPCheck -ErrorAction SilentlyContinue | Select-Object -Property Message | ForEach-Object { $_.Message.ToString()})
            #Получаем значение (собственно, IP адрес) 11 последних событий журнала «Приложение» от источника «ExternalIPCheck»
    } else { #Иначе - берем значения из текстового файла, который записывается всегда
        $DateTimeEvt = -split(get-content $MyIpChangeLog | select-object -last 11) #Берем 11 последних строк из файла $MyIpChangeLog, содержащего IP адреса предыдущих проверок
        $DateTimeEvttmp = $DateTimeEvt[34..0] #Переписываем значения массива DateTimeEvt во временный массив DateTimeEvttmp для того, чтобы пересортировать DateTimeEvt в нужном нам порядке и сформировать массив IPEvt
        for ($i=0; $i -lt 12; $i++){ #Начинаем пересортировку
            $IPEvt[$i] = $DateTimeEvttmp[$i*3] #В массив IPEvt, содержащий IP записываем соответствующий IP адрес из временного массива DateTimeEvttmp
            $DateTimeEvt[$i*2] = $DateTimeEvttmp[$i*3+2] #Переписываем значение даты в массиве DateTimeEvt, соответствующей датой из временного массива DateTimeEvttmp
            $DateTimeEvt[$i*2+1] = $DateTimeEvttmp[$i*3+1] #Переписываем значение времени в массиве DateTimeEvt, соответствующим временем из временного массива DateTimeEvttmp
        }  #Заканчиваем цикл пересортировки
    } #Завершаем процесс получения даты, времени и IP
      #Формируем HTML страничку 
    '
    <html>

    <head>
    <meta http-equiv="Content-Type" content="text/html; charset=windows-1251">
    <meta http-equiv="Content-Language" content="ru">
    <title>Состояние IP адреса для хоста ' + $ConstControlHost +'</title>
    </head>

    <body>'
   
    if ($MyError -like "*Невозможно определить внешний IP адрес данного узла. Проверочные хосты*") { #Если возникла ошибка при получении внешнего IP адреса, то
        #Включаем в содержимое странички следующий блок:
        '<p style="margin-top: 0; margin-bottom: 15px"><i><b><font size="6" color="#FF0000"> ***        Внимание !!!        *** </font></b></i></p>
        <p style="margin-top: 0; margin-bottom: 15px"><i><font size="3" color="#FF0000">' + [string]::join(".<br>",$MyError -split "\. " ) + '</font></i></p>'
    } #Заканчиваем формирование блока «при ошибке получения внешнего IP»

    if ($VPNStatus -eq 1) {
        '<p style="margin-top: 0; margin-bottom: 0"><b><font size="6">Последний полученнный'
    } else {
        '<p style="margin-top: 0; margin-bottom: 0"><b><font size="6">Текущий'
    }
   
    '<span lang="en-us">IP </span>адрес хоста: ' + $IPEvt[0] + '</font></b></p>
    <p style="margin-top: 0; margin-bottom: 15px"><i><font size="3"><b>(изменен: ' + $DateTimeEvt[0] + ' в' + $DateTimeEvt[1] + ')</b></font></i></p>
    <table border="1" id="table1">
       <tr>
          <td colspan="3" align="center"><b>Журнал последних изменений
          <span lang="en-us">IP </span>адреса</b></td>
       </tr>
       <tr>
          <td align="center"><b>Дата</b></td>
          <td align="center"><b>Время</b></td>
          <td align="center"><b><span lang="en-us">IP</span></b></td>
       </tr>'
       
        If ($ConstWriteToSystemLog) { #Определяем количество полученных записей о смене IP адреса. Если используем журнал Windows, то
            $MaxArrayVal = $DateTimeEvt.Length/2 #В массив DateTimeEvt по очереди записаны дата и время события. Причем, дата и время каждого
                #события представляют собой последовательные записи в массиве. Поэтому общее количество событий получаем делением на 2
        } else { #Иначе - берем значения из текстового файла, который записывается всегда
            $MaxArrayVal = $DateTimeEvt.Length/3 #В массив DateTimeEvt по очереди записаны дата, время и IP адрес. Причем, дата, время и IP адрес
                #представляют собой последовательные записи в массиве. Поэтому общее количество событий получаем делением на 3
        } #Завершаем блок «определение количества полученных записей о смене IP адреса»
       
        for ($i=$MaxArrayVal; $i -ge 1; $i--){ #Начинаем формирование строк таблицы «Журнал последних изменений IP адреса»
            if ($i -gt 10) {continue} #Если число записей таблицы больше 10, то ничего не дописываем
                    #Формируем три ячейки в каждом ряду: Дата - Время - IP адрес
                    #Если значения пустые, ставим прочерк. Таким образом, пока таблица не достигнет 10 записей, в верхней строчке будут прочерки, показывающие, что значения еще не были получены
           '<tr>
              <td>' + ($DateTimeEvt[$i*2] -replace "^+", "-" -replace "-(\S)",'$1') + '</td>
              <td>' + ($DateTimeEvt[$i*2+1] -replace "^+", "-" -replace "-(\S)",'$1') + '</td>
              <td>' + ($IPEvt[$i] -replace "^+", "-" -replace "-(\S)",'$1') + '</td>
           </tr>'
        } #Заканчиваем формирование строк таблицы «Журнал последних изменений IP адреса»
       
        #Продолжаем формирование странички. Прописываем частоиспользуемые адреса в виде ссылок и записываем дату и время формирования странички
    '</table>
    <p style="margin-top: 0; margin-bottom: 6px">&nbsp;</p>
    <p style="margin-top: 0; margin-bottom: 6px"><a href="' + $IPEvt[0] + ':8080">
    Подключение к роутеру</a></p>
    <p style="margin-top: 0; margin-bottom: 6px"><a href="' + $IPEvt[0] + ':8081">
    Подключение к <span lang="en-us">NAS</span></a></p>
    <p style="margin-top: 0; margin-bottom: 6px"><a href="' + $IPEvt[0] + ':3389">
    Подключение к <span lang="en-us">RDP</span></a></p>
    <p style="margin-top: 0; margin-bottom: 6px">&nbsp;</p>
    <p style="margin-top: 0; margin-bottom: 6px">Время создания отчета:  ' + [string](Get-Date) +'</p>'
    if ($MyError -like "*Проверка внешнего IP адреса завершилась успешно*") { #Если проверка внешнего IP адреса завершилась успешно, то
        #Включаем в содержимое странички следующий блок:
        '<p style="margin-top: 0; margin-bottom: 6px"><i><font size="3" color="#909090">' + $MyError + '</font></i></p>'
    } #Заканчиваем формирование блока «проверка внешнего IP адреса завершилась успешно»
   
    if ($ConstSendToDNSoMatic) { #Если используем сервис DNS-O-Matic, то
        if ($DNSoMaticMessag -like "*обновлена успешно. Ответ сервера*") { #Если синхронизация с DNS-O-Matic прошла успешно, то
            #Включаем в содержимое странички следующий блок:
            '<p style="margin-top: 0; margin-bottom: 6px"><i><font size="3" color="#904020">' + $DNSoMaticMessag + '</font></i></p>'
        } elseif ($DNSoMaticMessag -like "*не была обновлена*") { #Если синхронизация с DNS-O-Matic не прошла, то
            #Включаем в содержимое странички следующий блок:
            '<p style="margin-top: 0; margin-bottom: 6px">&nbsp;</p>
            <p style="margin-top: 0; margin-bottom: 8px"><i><b><font size="4" color="#FF0000"> ***        Внимание !!!        *** </font></b></i></p>
            <p style="margin-top: 0; margin-bottom: 6px"><i><font size="3" color="#FF0000">' + $DNSoMaticMessag + '</font></i></p>'
        } elseif ($DNSoMaticMessag -like "*сервер вернул нераспознанный ответ*") { #Если синхронизация с DNS-O-Matic прошла с неизвестным ответом сервера, то
            #Включаем в содержимое странички следующий блок:
            '<p style="margin-top: 0; margin-bottom: 6px">&nbsp;</p>
            <p style="margin-top: 0; margin-bottom: 8px"><i><b><font size="4" color="#FF0000"> ***        Внимание !!!        *** </font></b></i></p>
            <p style="margin-top: 0; margin-bottom: 6px"><i><font size="3" color="#FF0000">' + $DNSoMaticMessag + '</font></i></p>'
        } else { #Если синхронизация с DNS-O-Matic не выполнялась, то
            #Включаем в содержимое странички следующий блок:
            '<p style="margin-top: 0; margin-bottom: 6px"><i><font size="3" color="#909090">При последней проверке IP адреса синхронизация с сервисом DNS-O-Matic не выполнялась</font></i></p>'
            If ($ConstWriteToSystemLog) { #Дописываем на страничку результаты предыдущей синхронизации. Если используем журнал Windows, то
                #Получаем из журнала Windows последнее событие с одним из указанных ID
                $LastDNSoMaticSync = Get-EventLog -Newest 1 -LogName Application -InstanceID 12360,12361,12362,12363,12364,12365,12366,12367,12368,12369,12370 -source ExternalIPCheck -ErrorAction SilentlyContinue | Select-Object -Property Message  | ForEach-Object { $_.Message.Trim()}
            } else { #Иначе, (если записываем ошибки в текстовый файл) берем последние 100 строк из текстового файла ошибок и отбираем все строки, содержащие "DNS-O-Matic",
                        #а если ошибкиникуда не записываем, то получаем пустую переменную LastDNSoMaticSync
                $LastDNSoMaticSync = get-content $MyIpErrLog | select-object -last 100 | select-string -Pattern "DNS-O-Matic"
                $LastDNSoMaticSync = $LastDNSoMaticSync[$LastDNSoMaticSync.Length-1] #Берем из выборки последнюю строку
            } #Если ошибки никуда не записываются, получаем пустую переменную LastDNSoMaticSync
            if ($LastDNSoMaticSync -ne $Null) { #Если удалось получить результаты предыдущей синхронизации с DNS-O-Matic, то
                #Включаем в содержимое странички следующий блок:
                '<p style="margin-top: 0; margin-bottom: 6px"><i><font size="3" color="#904020">Результаты последней синхронизации: ' + $LastDNSoMaticSync + '</font></i></p>'
            }       
        } #Заканчиваем формирование блока «Разбор ответа сервера DNS-O-Matic»   
    } #Конец блока «Если используем сервис DNS-O-Matic»
     
    '</body>

    </html>
    '
}

# **********************************************************************************************************************************************************************
# Функция отправки запроса о смене IP адреса на сервис DNS-O-Matic:
function PostingIPToDNSoMatic {
   
    #Создаем необходимые объекты и задаем переменные, необходимые для отправки и формирования SMTP сообщения:
    $DNSoMaticObject = New-Object -TypeName System.Net.WebClient
    $DNSoMaticObject.Credentials = New-Object -TypeName System.Net.NetworkCredential($ConstDNSoMaticUser, $ConstDNSoMaticPassword)
    $DNSoMaticObject.Headers.Add("user-agent", $ConstDNSoMaticUserAgent)
    #Формируем строку запроса к серверу DNS-O-Matic
    $DNSoMaticFullGetString =  $ConstDNSoMaticGetString[0] + $ConstDNSoMaticHost + $ConstDNSoMaticGetString[1] + $ip + $ConstDNSoMaticGetString[2]
    $DNSoMaticFullGetString = $DNSoMaticObject.DownloadString($DNSoMaticFullGetString) #Выполняем запрос к серверу DNS-O-Matic
    if ($?) { #Проверяем возникла ли ошибка при выполнении метода DownloadString. Если запрос на сервер DNS-O-Matic прошел, то
        if ($DNSoMaticFullGetString.Trim() -match 'good (?s)([0-9]{1,3}?\.[0-9]{1,3}?\.[0-9]{1,3}?\.[0-9]{1,3})*') { #Разбираем ответы сервера. Если сервер ответил "good", то
            $DNSoMaticMessag = (get-date).ToString() + ": Информация на сервисе DNS-O-Matic об IP адресе " + $ip + " для хоста """ + $ConstDNSoMaticHost + """ обновлена успешно. Ответ сервера: """ + $DNSoMaticFullGetString + """"
            WritingMessage "12360" "Information" $DNSoMaticMessag #Записываем сообщение в журнал
        } elseif ($DNSoMaticFullGetString.Trim() -match 'nohost*') { #Если сервер ответил "nohost", то
            $DNSoMaticMessag = (get-date).ToString() + ": Информация на сервисе DNS-O-Matic об IP адресе " + $ip + " для хоста """ + $ConstDNSoMaticHost + """ не была обновлена, так как такой хост не зарегистрирован. Ответ сервера: """ + $DNSoMaticFullGetString + """"
            WritingMessage "12363" "Error" $DNSoMaticMessag #Записываем сообщение в журнал
        } elseif ($DNSoMaticFullGetString.Trim() -match 'badauth*') { #Если сервер ответил "badauth", то
            $DNSoMaticMessag = (get-date).ToString() + ": Информация на сервисе DNS-O-Matic об IP адресе " + $ip + " для хоста """ + $ConstDNSoMaticHost + """ не была обновлена, из-за ошибки аутентификации. Ответ сервера: """ + $DNSoMaticFullGetString + """"       
            WritingMessage "12364" "Error" $DNSoMaticMessag #Записываем сообщение в журнал
        } elseif ($DNSoMaticFullGetString.Trim() -match 'notfqdn*') { #Если сервер ответил "notfqdn", то
            $DNSoMaticMessag = (get-date).ToString() + ": Информация на сервисе DNS-O-Matic об IP адресе " + $ip + " для хоста """ + $ConstDNSoMaticHost + """ не была обновлена, из-за ошибки в имени хоста. Имя хоста должно быть задано в формате FQDN (полностью определённое имя домена). Ответ сервера: """ + $DNSoMaticFullGetString + """"               
            WritingMessage "12365" "Error" $DNSoMaticMessag #Записываем сообщение в журнал
        } elseif ($DNSoMaticFullGetString.Trim() -match 'numhost*') { #Если сервер ответил "numhost", то
            $DNSoMaticMessag = (get-date).ToString() + ": Информация на сервисе DNS-O-Matic об IP адресе " + $ip + " для хоста """ + $ConstDNSoMaticHost + """ не была обновлена, так как Вы пытаетесь обновить более 20 хостов. Ответ сервера: """ + $DNSoMaticFullGetString + """"                       
            WritingMessage "12366" "Error" $DNSoMaticMessag #Записываем сообщение в журнал
        } elseif ($DNSoMaticFullGetString.Trim() -match 'abuse*') { #Если сервер ответил "abuse", то
            $DNSoMaticMessag = (get-date).ToString() + ": Информация на сервисе DNS-O-Matic об IP адресе " + $ip + " для хоста """ + $ConstDNSoMaticHost + """ не была обновлена, так как имя хоста заблокировано из-за некорректных обновлений. Ответ сервера: """ + $DNSoMaticFullGetString + """"                               
            WritingMessage "12367" "Error" $DNSoMaticMessag #Записываем сообщение в журнал
        } elseif ($DNSoMaticFullGetString.Trim() -match 'badagent*') { #Если сервер ответил "badagent", то
            $DNSoMaticMessag = (get-date).ToString() + ": Информация на сервисе DNS-O-Matic об IP адресе " + $ip + " для хоста """ + $ConstDNSoMaticHost + """ не была обновлена, так как пользовательский агент обновлений (user-agent) заблокирован. Ответ сервера: """ + $DNSoMaticFullGetString + """"                               
            WritingMessage "12368" "Error" $DNSoMaticMessag #Записываем сообщение в журнал
        } elseif ($DNSoMaticFullGetString.Trim() -match 'dnserr*') { #Если сервер ответил "dnserr", то
            $DNSoMaticMessag = (get-date).ToString() + ": Информация на сервисе DNS-O-Matic об IP адресе " + $ip + " для хоста """ + $ConstDNSoMaticHost + """ не была обновлена, из-за ошибок DNS. Приостановите попытки обновления на 30 минут и обратитесь в службу поддержки DNS-O-Matic. Ответ сервера: """ + $DNSoMaticFullGetString + """"                               
            WritingMessage "12369" "Error" $DNSoMaticMessag #Записываем сообщение в журнал
        } elseif ($DNSoMaticFullGetString.Trim() -match '911*') { #Если сервер ответил "911", то
            $DNSoMaticMessag = (get-date).ToString() + ": Информация на сервисе DNS-O-Matic об IP адресе " + $ip + " для хоста """ + $ConstDNSoMaticHost + """ не была обновлена, так как на сервисе DNS-O-Matic возникли ошибки, либо проводится техническое обслуживание. Приостановите попытки обновления на 30 минут и обратитесь в службу поддержки DNS-O-Matic. Ответ сервера: """ + $DNSoMaticFullGetString + """"                               
            WritingMessage "12370" "Error" $DNSoMaticMessag #Записываем сообщение в журнал
        } else { #Если сервер ответил что-то, неучтенное нами, то
            $DNSoMaticMessag = (get-date).ToString() + ": При обновлении информации на сервисе DNS-O-Matic об IP адресе " + $ip + " для хоста """ + $ConstDNSoMaticHost + """ сервер вернул нераспознанный ответ: """ + $DNSoMaticFullGetString + """"
            WritingMessage "12361" "Warning" $DNSoMaticMessag #Записываем сообщение в журнал
        }
        #Конец блока разбора ответов сервера DNS-O-Matic
    } else { #Если запрос на сервер DNS-O-Matic не прошел, то
        $DNSoMaticMessag = (get-date).ToString() + ": Информация на сервисе DNS-O-Matic об IP адресе " + $ip + " для хоста """ + $ConstDNSoMaticHost + """ не была обновлена. Ошибка: " + $Error[0].ToString()
        WritingMessage "12362" "Error" $DNSoMaticMessag #Записываем сообщение в журнал
    } 
    #Конец блока проверки ошибок при выполнении метода DownloadString
    $DNSoMaticObject.Dispose() #Освобождаем ресурсы, используемые объектом DNSoMaticObject
    $DNSoMaticMessag #Записываем сформированный нами ответ в функцию PostingIPToDNSoMatic

}


# **********************************************************************************************************************************************************************
# Функция отправки SMTP сообщения и сохранения сгенерированной HTML странички:

function SendingMail ($SubMessSubject) {
    #Создаем необходимые объекты и задаем переменные, необходимые для отправки и формирования SMTP сообщения:
    $SmtpClient = New-Object System.Net.Mail.SmtpClient
    $Message = New-Object System.Net.Mail.MailMessage
    $SmtpClient.Host = $ConstServer
    $SmtpClient.Port = $ConstSMTPPort
    $Message.From = $ConstFrom
    $Message.To.Add($ConstTo)
    $Message.BodyEncoding = [System.Text.Encoding]::UTF8
    $Message.SubjectEncoding = [System.Text.Encoding]::UTF8
    $Message.Subject = $SubMessSubject
    $SmtpClient.Credentials= New-Object System.Net.NetworkCredential($ConstUserName , $ConstUserPass)
    If ($ConstMessageTypeHTML) { #Если формат письма HTML, то
        $Message.IsBodyHtml = $true #Указываем объекту System.Net.Mail.MailMessage, что тело письма сформировано в формате HTML
        $MessageBody = GeneratingHTML #Генерируем тело письма в формате HTML и записываем его в переменную MessageBody
    } Else { # Если формат письма текст (не HTML), то
        $Message.IsBodyHtml = $false #Указываем объекту System.Net.Mail.MailMessage, что тело письма сформировано в формате обычный текст
        if ($ConstSendToDNSoMatic) { #Если используем сервис DNS-O-Matic, то
            if (($DNSoMaticMessag -ne $Null) -and ($DNSoMaticMessag -ne "")) { #Если синхронизация с DNS-O-Matic выполнялась, то
                $MessageBody = $MessageBody + " " + $DNSoMaticMessag
            } else { #Если синхронизация с DNS-O-Matic не выполнялась, то
                $MessageBody = $MessageBody + " При последней проверке IP адреса синхронизация с сервисом DNS-O-Matic не выполнялась."
                If ($ConstWriteToSystemLog) { #Дописываем на страничку результаты предыдущей синхронизации. Если используем журнал Windows, то
                    #Получаем из журнала Windows последнее событие с одним из указанных ID
                    $LastDNSoMaticSync = Get-EventLog -Newest 1 -LogName Application -InstanceID 12360,12361,12362,12363,12364,12365,12366,12367,12368,12369,12370 -source ExternalIPCheck -ErrorAction SilentlyContinue | Select-Object -Property Message  | ForEach-Object { $_.Message.Trim()}
                } else { #Иначе, (если записываем ошибки в текстовый файл) берем последние 100 строк из текстового файла ошибок и отбираем все строки, содержащие "DNS-O-Matic",
                        #а если ошибкиникуда не записываем, то получаем пустую переменную LastDNSoMaticSync
                    $LastDNSoMaticSync = get-content $MyIpErrLog | select-object -last 100 | select-string -Pattern "DNS-O-Matic"
                    $LastDNSoMaticSync = $LastDNSoMaticSync[$LastDNSoMaticSync.Length-1] #Берем из выборки последнюю строку
                }
                if ($LastDNSoMaticSync -ne $Null) { #Если удалось получить результаты предыдущей синхронизации с DNS-O-Matic, то
                    #Включаем в содержимое письма следующий блок:
                    $MessageBody = $MessageBody + " Результаты последней синхронизации: " + $LastDNSoMaticSync
                }       
            } #Заканчиваем формирование блока «Разбор ответа сервера DNS-O-Matic»   
        } #Конец блока «Если используем сервис DNS-O-Matic»       
        $MessageBody = $MyError + $MessageBody
        $MessageBody = [string]::join(".`n`n",$MessageBody -split "\. " ) #Записываем в переменную MessageBody сформированное сообщение MyError, для удобства восприятия, разделяем предложения двумя переводами строки
    }
        #write-host $MessageBody
        $Message.Body = $MessageBody #Формируем тело письма их переменной MessageBody
    $SmtpClient.Send($Message) #Отправляем SMTP сообщение
    if ($?) { # Если SMTP сообщение было отправлено успешно, то
        If ($ConstWriteOKLog) { #Если записываем при ОК, то делаем запись в журналы об отправке сообщение
                #Формируем текст сообщения
            $MyErrorMail = (get-date).ToString() + ": SMTP сообщение от " + $ConstFrom + " на адрес " + $ConstTo + " с темой """ + $SubMessSubject + """ отправлено успешно. (Сервер: " + $ConstServer + ":" + $ConstSMTPPort + ")."
            WritingMessage "12355" "Information" $MyErrorMail #Записываем сообщение в журнал
        }       
    } else { #Если SMTP сообщение не удалось отправить, то записываем в журналы ошибку о том, что сообщение не отправлено
            #Формируем текст сообщения
        $MyErrorMail = (get-date).ToString() + ": SMTP сообщение от " + $ConstFrom + " на адрес " + $ConstTo + " с темой """ + $SubMessSubject + """ не было отправлено. (Сервер: " + $ConstServer + ":" + $ConstSMTPPort + "). Ошибка: " + $Error[0].ToString()
        WritingMessage "12356" "Error" $MyErrorMail #Записываем сообщение в журнал
    }
    $Message.Dispose() #Отправляем сообщение QUIT на SMTP-сервер (правильно завершаем TCP-подключение и освобождаем все ресурсы, используемые текущим экземпляром класса SmtpClient)
    If ($ConstSaveToFile) {GeneratingHTML > $ConstPathToHTMFile\MyIpStatus.html} # Если сохраняем результаты работы в HTML файл, то генерируем страничку html
}

# **********************************************************************************************************************************************************************
# Задаем константы:

$ConstWriteOKLog = $true                                        #Записывать в журналы сообщения об удачных операциях
$ConstWriteToSystemLog = $false                                 #Использовать журнал Windows
$ConstWriteToFileLog = $true                                    #Записывать события в текстовый файл
$ConstWriteToFilePath = "c:\Soft\Bat\"                          #Путь к файлу событий и к файлу смены IP
$MaxStringInLog = 5000                                          #Максимальное количество строк в файлах журналов
$ConstSendSMTPIfError = $false                                  #Пытаться отправить SMTP сообщение при ошибках определения внешнего IP адреса
$ConstControlHost = "My Work Comp 0"                            #Понятное (для себя) имя контролируемого хоста (для задания его в теме письма)
$ConstExcludedVPNName = "MyVPN"                                 #Имя VPN подключения (так как оно отображено в сетевых подключениях Windows).
                                                                #Исключаются только подключения с шлюзом в удаленной сети (поскольку если VPN не использует шлюз в удаленной сети,
                                                                #то внешний IP не меняется при подключении/отключении этого VPN
$ConstTestJumps = 8                                             #Сколько прыжков будем использовать в тестовой трассировке                   
$ConstTestIP = "8.8.8.8"                                        #IP адрес внешнего хоста. Пинг и трассировка до этого хоста будет выполняться при невозможности определения внешнего IP контролируемого хоста
                                                                #(для сбора диагностической информации о работе сети)
$ConstTestHost = "A", "B", "C", "D"                             #Задаем текстовый массив из четырех элементов. Элементы этого массива - это URL страничек, которые возвращают наш IP адрес.
                                                                #Четыре - на всякий случай. По-факту скрипт прерывает проверку как только будет получен IP адрес. Поэтому, до попытки получения
                                                                #IP адреса с помощью последнего хоста может вообще никогда не дойти.
$ConstTestHost[0] = "http://myip.dnsomatic.com/"                #Задаем первый URL
$ConstTestHost[1] = "http://icanhazip.com/"                     #Задаем второй URL
#$ConstTestHost[1] = "http://checkip.dyn.com/"                  #Задаем второй URL
$ConstTestHost[2] = "http://myip.ru/"                           #Задаем третий URL
$ConstTestHost[3] = "http://2ip.ru/"                            #Задаем четвертый URL
$ConstDNSNameTest = "microsoft.com"                             #Какое-нибудь доменное имя. При невозможности определения внешнего IP контролируемого хоста будет проводиться проверка
                                                                #работоспособности DNS сервера путем попытки соспоставления IP адреса этому имени (для сбора диагностической информации о работе сети)
$ConstDNSIPTest = "194.87.0.50"                                 #Какой-нибудь внешний IP адрес. При невозможности определения внешнего IP контролируемого хоста будет проводиться проверка
                                                                #работоспособности DNS сервера путем попытки соспоставления доменного имени этого IP адреса этому  (для сбора диагностической информаци
$ConstSaveToFile = $true                                        #Сохранять результаты работы в HTML файл (например, если нам нужно узнавать об изменении IP не только через email,
                                                                #то можно это файлик выкладывать на какой-нибудь облачный сервис (yandex.disk, dropbox, google drive и пр.))
$ConstPathToHTMFile = "C:\Documents and Settings\Administrator\Desktop" #Путь до HTML файла
$DateTimeEvt = "","","","","","","","","","","","","",""        #Массив для работы с датой и временем событий, полученных из журналов
$IPEvt = "","","","","","","","","","",""                       #Массив для работы с IP адресами, полученными из журналов

$ConstServer = "smtp.server.ru"                                 #SMTP сервер
$ConstSMTPPort = "25"                                           #Порт SMTP сервера
$ConstFrom = "sender@server.ru"                                 #Адрес отправителя
$ConstTo = "recipient@server1.ru"                               #Адрес получателя
$ConstMessageTypeHTML = $true                                   #Формат сообщения HTML (true) или обычный текст (false)
$ConstUserName = "sender@server.ru"                             #Имя пользователя (ящика) для авторизации на SMTP сервере
$ConstUserPass = "MyPassword"                                   #Пароль для авторизации на SMTP сервере

$ConstSendToDNSoMatic = $false                                  #Использовать службу DNS-O-Matic
$ConstDNSoMaticUser = "DNSoMaticUser"                           #Имя пользователя  DNS-O-Matic
$ConstDNSoMaticPassword = "DNSoMaticPass"                       #Пароль DNS-O-Matic
$ConstDNSoMaticHost = "myhost.dyndns.org"                       #Полное имя хоста
$ConstDNSoMaticGetString = "https://updates.dnsomatic.com/nic/update?hostname=","&myip=","&wildcard=NOCHG&mx=NOCHG&backmx=NOCHG" 
                                                                #Массив из трех элементов - части строки для формирования запроса к серверу  DNS-O-Matic
$ConstDNSoMaticUserAgent = "Manaeff's Soft© - PowerShell IP Change Script - 2.1.5" #Строка, устанавливающая параметр заголовка User-Agent в формате Организация - Агент - Версия
$ConstDNSoMaticRetrive = "180"                                   #Число минут (промежуток времени) через который будем принудительно обновлять информацию
                                                                #о нашем хосте на сервере DNS-O-Matic (на случай, если на сервере DNS-O-Matic IP адрес нашего хоста будет изменен вручную
                                                                #при этом на самом хосте никаких изменений IP адреса не было - то есть если оставить это параметр пустым, то информация на сервере DNS-O-Matic
                                                                #обновится только после реального изменения IP хоста). Пустое значение или 0 - не обновлять пока не сменится IP хоста. Слишком часто синхронизироваться
                                                                #тоже не стоит, чтобы не попасть в «черный список» сервиса DNS-O-Matic. 60 минут (ИМХО) - нормальный промежуток времени. После каждой синхронизации
                                                                #мы будем получать письмо на email, указанный в настройках DNS-O-Matic

# **********************************************************************************************************************************************************************
# Обнуляем переменные:

$MessageBody = ""                                               #Тело письма
$MessageSubject = ""                                            #Тема письма
$MyError = ""                                                   #Собственно, само сообщение об ошибке
$MyErrorMail = ""                                               #Сообщение о результатах отправки письма SMTP
$LastIpAddrr = ""                                               #IP адрес последней проверки
$ip = ""                                                        #Текущий IP адрес, полученный из проверки с указанных URL
$StringIP = ""                                                  #Строка состоящая из даты/времени получения текущего IP адреса и самого IP адреса
$VPNStatus = 0                                                  #0-при отсутствии активных VPN, 1-если подключено исключенное из наблюдения VPN (со шлюзом в удаленной сети),
                                                                #2-если подключено наблюдаемое VPN со шлюзом в удаленной сети, 3-если подключено наблюдаемое VPN без шлюза в удаленной сети,
$ActiveVPNConnection = ""                                       #Объект, класса «Win32_NetworkAdapterConfiguration» представляющий собой активное VPN подключение
$VPNConnectionGate =  ""                                        #IP адрес шлюза активного VPN подключения
$VPNAdapter = ""                                                #Имя активного VPN подключения (так как оно отображено в свойствах сетевых подключений)
$PingTestResult = ""                                            #Объект, результат проверки Ping-а
$DNSresult=""                                                   #Объект, результат проверки работы DNS

$DNSoMaticObject = ""                                           #Объект для отправки запроса на сервис DNS-O-Matic
$DNSoMaticFullGetString = ""                                    #Полная строка отправки запроса и получения ответа сервиса DNS-O-Matic
$DNSoMaticMessag = ""                                           #Строка результатов работы отправки запроса на сервис DNS-O-Matic

$MyIpChangeLog = $ConstWriteToFilePath + "MyIpChange.Log"       #Полный путь к файлу записи IP
$MyIpErrLog = $ConstWriteToFilePath + "MyIPErr.log"             #Полный путь к файлу записи ошибок и диагностических сообщений

# **********************************************************************************************************************************************************************
# Начало основного скрипта:

if ($ConstWriteToSystemLog) { #Если используем журнал Windows, то будем брать IP адрес из журнала «Приложение» из источника «ExternalIPCheck»
    if (-not (Get-EventLog -Newest 1 -LogName Application -Source ExternalIPCheck)) { #Если в журнале «Приложение» нет источника «ExternalIPCheck», то
        new-eventlog -source ExternalIPCheck -logname Application #Создаем новый источник «ExternalIPCheck» в журнале «Приложение»
    }
    $LastIpAddrr = Get-EventLog -Newest 1 -LogName Application -InstanceID 12346 -source ExternalIPCheck -ErrorAction SilentlyContinue | Select-Object -Property Message  | ForEach-Object { $_.Message.Trim()}  #Берем последнее событие с кодом 12346 из журнала «Приложение», источник «ExternalIPCheck», содержащее IP адрес последней проверки
} else { #Если не используем журнал Windows, то будем брать IP адрес из файла $MyIpChangeLog, который записывается всегда
    $LastIpAddrr = get-content $MyIpChangeLog | select-object -last 1 #Берем последнюю строку из файла $MyIpChangeLog, содержащего IP адреса предыдущих проверок
    if ($LastIpAddrr -match '(?s)([0-9]{1,3}?\.[0-9]{1,3}?\.[0-9]{1,3}?\.[0-9]{1,3})') { #Ищем в строке IP адрес по маске
        $LastIpAddrr = $matches[1] #И записываем найденный адрес в переменную LastIpAddrr
    }
} #Конец блока получения предыдущего IP адреса


if ((Get-WmiObject Win32_OperatingSystem  | Select-Object -Property Version | ForEach-Object { $_.Version.Trim()}) -like "6.*") { #Определяем версию Windows, так как в
    #так как в версиях Windows XP и ниже по сравнению с Windows Vista и выше используются различные методы получения сведений о VPN подключениях
    $VPNAdapter = Get-VpnConnection  | where-object -Property "ConnectionStatus" -Like "Connected" | ForEach-Object { $_.Name.Trim()} #Получаем имя активного PPP подключения
    if ($VPNAdapter -ne $null) {  #Если есть активное VPN подключение, то
                #Получаем виртуальный шлюз активного VPN подключения
        $VPNConnectionGate = Get-NetIPConfiguration | where-object -Property "InterfaceAlias" -Like $VPNAdapter | Foreach IPv4DefaultGateway | Select-Object -Property NextHop | ForEach-Object { $_.NextHop.Trim()}
        if ($VPNConnectionGate -ne $null) { #Если есть активные VPN с шлюзом в удаленной сети
            If ($VPNAdapter.Trim() -eq $ConstExcludedVPNName.Trim()) { #Если VPN исключен из наблюдения, то
                $VPNStatus = 1 #Исключенное из наблюдения VPN подключение с шлюзом в удаленной сети
            } else {
                $VPNStatus = 2 #Наблюдаемое VPN подключение с шлюзом в удаленной сети
            }
            #Получаем IP реального шлюза
            $VPNConnectionGate = FindingGateIP
        } else {
            $VPNStatus = 3 #Наблюдаемое VPN подключение Без использования шлюза в удаленной сети
        }
    } else {
        $VPNStatus = 0 #Активных VPN подключений нет 
    }#Конец блока получения данных об активных VPN, если установлена Windows Vista и выше
} else {
    $ActiveVPNConnection = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "IPEnabled=TRUE and Description like '%PPP%' and not ServiceName like 'NdisIP'" #Получаем активные PPP подключения
    if  (($ActiveVPNConnection.Description -ne $null) -and ($ActiveVPNConnection.Description -ne "")) { #Если есть активное VPN подключение, то
        $VPNAdapter = (ipconfig | Select-String "PPP") -split "- PPP" | select -first 1 #Получаем название активного VPN подключения
        $VPNConnectionGate = $ActiveVPNConnection | Select-Object -Property DefaultIPGateway | ForEach-Object { $_.DefaultIPGateway} | ForEach-Object {$_ -replace " ", ""} #Получаем виртуальный шлюз активного VPN подключения
        if  (($VPNConnectionGate -ne $null) -and ($VPNConnectionGate -ne "")) { #Если есть активные VPN с шлюзом в удаленной сети
            If ($VPNAdapter.Trim() -eq $ConstExcludedVPNName.Trim()) { #Если VPN исключен из наблюдения, то
                $VPNStatus = 1 #Исключенное из наблюдения VPN подключение с шлюзом в удаленной сети
            } else {
                $VPNStatus = 2 #Наблюдаемое VPN подключение с шлюзом в удаленной сети
            }
            #Получаем IP реального шлюза
            $VPNConnectionGate = FindingGateIP
        } else {
            $VPNStatus = 3 #Наблюдаемое VPN подключение Без использования шлюза в удаленной сети
        }
    } else {
        $VPNStatus = 0 #Активных VPN подключений нет 
    }
}#Конец блока получения данных об активных VPN, если установлена Windows XP и ниже
#Конец блока получения активных PPP подключений

for ($i=0; $i -lt 4; $i++){ #Задаем цикл попыток получения внешнего IP нашего хоста
    $ip = (new-object net.webclient).DownloadString($ConstTestHost[$i]) #Получаем содержимое странички сайта, содержащую наш IP адрес
    if ($ip -cmatch '(?s)([0-9]{1,3}?\.[0-9]{1,3}?\.[0-9]{1,3}?\.[0-9]{1,3})') { #Если среди содержимого странички находим соответствие маске IP адрес, то
        $ip = $matches[1] #Записываем в переменную ip найденный наш внешний IP адрес
        break #И на этом прерываем выполнение цикла
    } else {  #Если среди содержимого странички не находим соответствие маске IP адрес (в том числе, если страничка вообще недоступна), то собираем диагностическую информацию
        if ($i -eq 3) { #Если это проверка последнего URL из списка, то
            $ip = ""
            $MyError = (get-date).ToString() + (": Невозможно определить внешний IP адрес данного узла. Проверочные хосты: """ + [string]::Join("""; """,$ConstTestHost) + """ недоступны. Диагностическая информация: Хост с адресом " + $ConstTestIP)
            $PingTestResult = get-WmiObject Win32_PingStatus -f "Address='$ConstTestIP'" #Тестируем Ping-ом IP адрес ConstTestIP
            if($PingTestResult.StatusCode -eq 0) { #Если проверка доступности Ping-ом прошла успешно, то
                $MyError = $MyError + " доступен." 
            }else{ #Если проверка доступности Ping-ом не прошла, то
                $MyError = $MyError + " недоступен."
            }
            #Делаем трассировку с числом прыжков ConstTestJumps до хоста ConstTestIP и записываем результаты в строку ошибок
            $MyError = $MyError + " Результаты первых " + $ConstTestJumps + " прыжков трассировки до этого хоста: " + [string]::join("; ", ((tracert -d -h $ConstTestJumps $ConstTestIP | select-string -pattern '(?s)[\d][\s]{1,15}\*[\s]{1,15}\*[\s]{1,15}\*', '(?s)ms[\s]{1,10}([0-9]{1,3}?\.[0-9]{1,3}?\.[0-9]{1,3}?\.[0-9]{1,3})', '(?s)[\d][\s]{1,15}\*[\s]{1,15}\*[\s]{1,15}([0-9]{1,3}?\.[0-9]{1,3}?\.[0-9]{1,3}?\.[0-9]{1,3})' | foreach-object {if ($_ -match '(?s)^[\s]{0,10}(\d).*[m,s]{2}.*[\s]{1,10}([0-9]{1,3}?\.[0-9]{1,3}?\.[0-9]{1,3}?\.[0-9]{1,3})') {$matches[1] + ": " + $matches[2]} elseif ($_ -match '(?s)([\d])[\s]{1,15}\*[\s]{1,15}\*[\s]{1,15}(\*)'){$matches[1] + ": " + $matches[2]} elseif ($_ -match '(?s)([\d])[\s]{1,15}(\*)[\s]{1,15}\*[\s]{1,15}[0-9]{1,3}?\.[0-9]{1,3}?\.[0-9]{1,3}?\.[0-9]{1,3}') {$matches[1] + ": " + $matches[2]} }) -split "`n"))
            $MyError = $MyError +  ". Имени " + $ConstDNSNameTest
            $DNSresult = [system.Net.Dns]::GetHostByName($ConstDNSNameTest) #Выполняем проверку работоспособности DNS сервера путем попытки соспоставления IP адреса имени ConstDNSNameTest
            if (-not $DNSresult) { #Если имя не разрешается в адрес, то
                $MyError = $MyError + " не сопоставляется IP адрес"
            } else { #Если имени ConstDNSNameTest удается сопоставить IP адрес, то
                if ($DNSresult.AddressList.Count -gt 1) { #Если имени ConstDNSNameTest сопоставляется более одного адреса
                    $MyError = $MyError + " сопоставляются IP адреса: " + [string]::Join("; ",($DNSresult.AddressList | ForEach-Object {$_.IPAddressToString}))   
                } else { #Если имени ConstDNSNameTest сопоставляется только один адрес
                    $MyError = $MyError + " сопоставляется IP адрес: " + ($DNSresult.AddressList | ForEach-Object {$_.IPAddressToString})
                }
            }
            $MyError = $MyError + ". IP адресу: " + $ConstDNSIPTest
            $DNSresult = [system.Net.Dns]::GetHostByAddress($ConstDNSIPTest) #Выполняем проверку работоспособности DNS сервера путем попытки соспоставления IP адресу ConstDNSIPTest доменного имени
            if (-not $DNSresult) { #Если IP адресу ConstDNSIPTest не удается сопоставить доменное имя, то
                $MyError = $MyError + " не сопоставляется никакого имени."
            } else { #Если IP адресу ConstDNSIPTest удается сопоставить доменное имя, то
                $MyError = $MyError + " сопоставляется имя: """ + $DNSresult.HostName + """."
            }
        } #Конец блока сбора диагностической информации при невозможности получить внешний IP нашего хоста
    } #Конец блока поиска IP адрес на страничке
}   #Конец блока «цикл попыток получения внешнего IP нашего хоста». По окончании имеем либо переменную ip с внешним IP адресом нашего хоста,
    #либо непустую переменную MyError с описанием ошибки и диагностической информацией

if (($ip -ne $LastIpAddrr)) { #Если новый IP не совпал с сохраненным ранее (или новый IP не получен вообще), то
    if ($VPNStatus -eq 0) { #При отсутствии активных VPN
        if ($ip.trim() -ne "") { # Если IP удалось определить, но он не совпал (= Если в переменную MyError еще ничего не записано), то
            WritingIP #Записываем новый IP в журнал
            if ($ConstSendToDNSoMatic) {$DNSoMaticMessag = PostingIPToDNSoMatic} #Если используем сервис DNS-O-Matic, то выполнем синхронизацию с сервером DNS-O-Matic и записываем результаты в переменную DNSoMaticMessag
            $MyError = (get-date).ToString() + ": Проверка внешнего IP адреса завершилась успешно. Активных VPN подключений нет. Адрес изменился с " + $LastIpAddrr + " на " + $ip
            WritingMessage "12347" "Warning" $MyError #Записываем сообщение в журнал
            $MessageSubject = "Изменен внешний IP адреса хоста """ + $ConstControlHost  + """" #Формируем тему SMTP сообщения
            SendingMail $MessageSubject #Отправляем SMTP сообщение о смене IP           
        } else { # Если IP невозможно определить (= Если в переменную MyError что-то записано), то
            $MyError = $MyError + (" Активных VPN подключений нет.")
            WritingMessage "12350" "Error" $MyError #Записываем сообщение в журнал
            #Пытаться отправить сообщение об ошибке (по желанию)   
            if ($ConstSendSMTPIfError) { #Если нужно отправлять SMTP сообщение при невозможности определить IP, то
                $MessageSubject = "Ошибка при определении внешнего IP адреса хоста """ + $ConstControlHost  + """" #Формируем тему SMTP сообщения
                SendingMail $MessageSubject #Отправляем SMTP сообщение об ошибке определения IP
            } elseif ($ConstSaveToFile) { #Если сохраняем результаты работы в HTML файл, то генерируем страничку html
                GeneratingHTML > $ConstPathToHTMFile\MyIpStatus.html
            } #Конец блока «отправка SMTP сообщения при невозможности определить IP»
        } #Конец блока анализа возможности определения IP
        #Конец блока «При отсутствии активных VPN»
    } elseif ($VPNStatus -eq 1) { #Если подключено исключенное из наблюдения VPN (со шлюзом в удаленной сети)
        If ($MyError -ne "") { #Если IP невозможно определить (= Если в переменную MyError что-то записано), то
            $MyError = (get-date).ToString() + ": Исключенное из наблюдения VPN подключение """ + $VPNAdapter.Trim() + """ (шлюз в удаленной сети: " + $VPNConnectionGate + ") активно. Никаких действий не предпринимается. " + $MyError
            WritingMessage "12348" "Information" $MyError #Записываем сообщение в журнал
        } else {  # Если IP удалось определить, но сохраненный IP не совпал с вновь полученным (= Если в переменную MyError еще ничего не записано) - то есть если IP изменился, то
            $MyError = (get-date).ToString() + ": Проверка внешнего IP адреса завершилась успешно. Исключенное из наблюдения VPN подключение """ + $VPNAdapter.Trim() + """ (шлюз в удаленной сети: " + $VPNConnectionGate + ") активно. Внешний IP адрес с момента последней проверки изменен с " + $LastIpAddrr + " на " + $ip + ". Никаких действий не предпринимается."
            WritingMessage "12349" "Information" $MyError #Записываем сообщение в журнал
        } #Конец блока анализа возможности определения IP
        If ($ConstSaveToFile) {GeneratingHTML > $ConstPathToHTMFile\MyIpStatus.html} # Если сохраняем результаты работы в HTML файл, то генерируем страничку html
        #Конец блока «Если подключено исключенное из наблюдения VPN»
    } elseif ($VPNStatus -eq 2) { #Если подключено наблюдаемое VPN со шлюзом в удаленной сети
        If ($MyError -ne "") { # Если IP невозможно определить (= Если в переменную MyError что-то записано), то
            $MyError = $MyError  + " Наблюдаемое VPN подключение """ + $VPNAdapter.Trim() + """ (шлюз в удаленной сети: " + $VPNConnectionGate + ") активно."
            WritingMessage "12352" "Error" $MyError #Записываем сообщение в журнал
            if ($ConstSendSMTPIfError) { #Если нужно отправлять SMTP сообщение при невозможности определить IP, то
                $MessageSubject = "Ошибка при определении внешнего IP адреса хоста """ + $ConstControlHost  + """" #Формируем тему SMTP сообщения
                SendingMail $MessageSubject #Отправляем SMTP сообщение об ошибке определения IP
            } elseif ($ConstSaveToFile) { #Если сохраняем результаты работы в HTML файл, то генерируем страничку html
                GeneratingHTML > $ConstPathToHTMFile\MyIpStatus.html           
            } #Конец блока «отправка SMTP сообщения при невозможности определить IP»
        } else {  # Если IP удалось определить, но он не совпал ( = Если в переменную MyError еще ничего не записано), то
            WritingIP #Записываем новый IP в журнал
            if ($ConstSendToDNSoMatic) {$DNSoMaticMessag = PostingIPToDNSoMatic} #Если используем сервис DNS-O-Matic, то выполнем синхронизацию с сервером DNS-O-Matic и записываем результаты в переменную DNSoMaticMessag
            $MyError = (get-date).ToString() + ": Проверка внешнего IP адреса завершилась успешно. Наблюдаемое VPN подключение """ + $VPNAdapter.Trim() + """ (шлюз в удаленной сети: " + $VPNConnectionGate + ") активно. Адрес изменился с " + $LastIpAddrr + " на " + $ip
            WritingMessage "12351" "Warning" $MyError #Записываем сообщение в журнал
            $MessageSubject = "Изменен внешний IP адреса хоста """ + $ConstControlHost  + """" #Формируем тему SMTP сообщения
            SendingMail $MessageSubject #Отправляем SMTP сообщение о смене IP
        } #Конец блока анализа возможности определения IP
        #Конец блока «Если подключено наблюдаемое VPN со шлюзом в удаленной сети
    } else { #Если подключено наблюдаемое VPN без шлюза в удаленной сети»
        If ($MyError -ne "") { # Если IP невозможно определить (= Если в переменную MyError что-то записано), то
            $MyError = $MyError  + " Наблюдаемое VPN подключение """ + $VPNAdapter.Trim() + """ (Без использования шлюза в удаленной сети) активно."
            WritingMessage "12354" "Error" $MyError #Записываем сообщение в журнал
            if ($ConstSendSMTPIfError) { #Если нужно отправлять SMTP сообщение при невозможности определить IP, то
                $MessageSubject = "Ошибка при определении внешнего IP адреса хоста """ + $ConstControlHost  + """" #Формируем тему SMTP сообщения
                SendingMail $MessageSubject #Отправляем SMTP сообщение об ошибке определения IP
            } elseif ($ConstSaveToFile) { #Если сохраняем результаты работы в HTML файл, то генерируем страничку html
                GeneratingHTML > $ConstPathToHTMFile\MyIpStatus.html               
            } #Конец блока «отправка SMTP сообщения при невозможности определить IP»
        } else {  # Если IP удалось определить, но он не совпал ( = Если в переменную MyError еще ничего не записано), то
            WritingIP #Записываем новый IP в журнал
            if ($ConstSendToDNSoMatic) {$DNSoMaticMessag = PostingIPToDNSoMatic} #Если используем сервис DNS-O-Matic, то выполнем синхронизацию с сервером DNS-O-Matic и записываем результаты в переменную DNSoMaticMessag
            $MyError = (get-date).ToString() + ": Проверка внешнего IP адреса завершилась успешно. Наблюдаемое VPN подключение """ + $VPNAdapter.Trim() + """ (Без использования шлюза в удаленной сети) активно. Адрес изменился с " + $LastIpAddrr + " на " + $ip
            WritingMessage "12353" "Warning" $MyError  #Записываем сообщение в журнал
            $MessageSubject = "Изменен внешний IP адреса хоста """ + $ConstControlHost  + """" #Формируем тему SMTP сообщения
            SendingMail $MessageSubject #Отправляем SMTP сообщение о смене IP
        } #Конец блока анализа возможности определения IP
    }   #Конец блока «Если подключено наблюдаемое VPN без шлюза в удаленной сети»
} else { #Если IP не изменялся с момента последней проверки
    If ($ConstWriteOKLog) { #Если записываем при ОК, то
        $MyError = (get-date).ToString() + (": Проверка внешнего IP адреса завершилась успешно. Адрес " + $ip + " не изменялся с момента последней проверки.")
        if ($VPNStatus -eq 0) { #При отсутствии активных VPN
            $MyError = $MyError + " Активных VPN подключений нет."
        } elseif ($VPNStatus -eq 1) { #Если подключено исключенное из наблюдения VPN (со шлюзом в удаленной сети)
            $MyError = $MyError + " Исключенное из наблюдения VPN подключение """ + $VPNAdapter.Trim() + """ (шлюз в удаленной сети: " + $VPNConnectionGate + ") активно."
        } elseif ($VPNStatus -eq 2) { #Если подключено наблюдаемое VPN со шлюзом в удаленной сети
            $MyError = $MyError + " Наблюдаемое VPN подключение """ + $VPNAdapter.Trim() + """ (шлюз в удаленной сети: " + $VPNConnectionGate + ") активно."
        } else {  # Если IP удалось определить, но он не совпал ( = Если в переменную MyError еще ничего не записано), то
            $MyError = $MyError + " Наблюдаемое VPN подключение """ + $VPNAdapter.Trim() + """ (Без использования шлюза в удаленной сети) активно."
        }
        WritingMessage "12345" "Information" $MyError #Записываем сообщение в журнал
    } #Конец блока «Если записываем при ОК»
 
    if (($ConstDNSoMaticRetrive -ne $Null) -and ($ConstDNSoMaticRetrive -ne "")){ #Если обновляем информацию о нашем узле на сервисе DNS-O-Matic принудительно, то
        if ($ConstWriteToSystemLog) { #Получаем дату и время из журналов и сравниваем с текущим временем. Если используем журнал Windows, то
                #Из текущего времени вычитаем время последнего состоявшегося (кроме кода 12362) события синхронизации с DNS-O-Matic. Получаем разницу в минутах и сравниваем ее с константой ConstDNSoMaticRetrive.
            if (((get-date) - (Get-EventLog -Newest 1 -LogName Application -InstanceID 12346 -source ExternalIPCheck -ErrorAction SilentlyContinue | Select-Object -Property TimeWritten | ForEach-Object { $_.TimeWritten})).TotalMinutes -ge $ConstDNSoMaticRetrive) {
                #Дописываем в журналы не изменившийся IP с новым временем (для последующей проверки времени принудительного обновления)
                WritingIP
                #Запускаем синхронизацию с DNS-O-Matic
                PostingIPToDNSoMatic
            }
        } else { #Иначе - берем значения из текстового файла, который записывается всегда
                #Из текущего времени вычитаем время события смены IP, записанного в последней строке файла журнала. Получаем разницу в минутах и сравниваем ее с константой ConstDNSoMaticRetrive.
            if (((get-date) - ([datetime]::parse((-split(get-content $MyIpChangeLog | select-object -last 1) | select-object -first 2) -join " "))).TotalMinutes -ge $ConstDNSoMaticRetrive) {
                #Дописываем в журналы не изменившийся IP с новым временем (для последующей проверки времени принудительного обновления)
                WritingIP
                #Запускаем синхронизацию с DNS-O-Matic
                PostingIPToDNSoMatic
            }
        }
    }
    If ($ConstSaveToFile) {GeneratingHTML > $ConstPathToHTMFile\MyIpStatus.html} # Если сохраняем результаты работы в HTML файл, то генерируем страничку html
    break
}   #Конец блока «Если IP не изменялся с момента последней проверки»
