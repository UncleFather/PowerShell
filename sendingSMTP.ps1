$ConstServer = "smtp.server.ru"                                 #SMTP сервер
$ConstSMTPPort = "25"                                           #Порт SMTP сервера
$ConstFrom = "sender@server.ru"                                 #Адрес отправителя
$ConstTo = "receiver@server.ru"                                 #Адрес получателя
$ConstMessageTypeHTML = $false                                  #Формат сообщения HTML (true) или обычный текст (false)
$ConstUserName = "sender@server.ru"                             #Имя пользователя (ящика) для авторизации на SMTP сервере
$ConstUserPass = "MyPassword"                                   #Пароль для авторизации на SMTP сервере
$ConstMessageSubject = "Subject"                                #Тема сообщения
$ConstMessageBody = "Body"                                      #Тело сообщения
$SourceFile="C:\Soft\Attachment.txt"                            #Прикрепляемый файл

#Создаем необходимые объекты и задаем переменные, необходимые для отправки и формирования SMTP сообщения:
    $SmtpClient = New-Object System.Net.Mail.SmtpClient
    $Message = New-Object System.Net.Mail.MailMessage
    $SmtpClient.Host = $ConstServer
    $SmtpClient.Port = $ConstSMTPPort
    $Message.From = $ConstFrom
    $Message.To.Add($ConstTo)
    $Message.BodyEncoding = [System.Text.Encoding]::UTF8
    $Message.SubjectEncoding = [System.Text.Encoding]::UTF8
    $Message.IsBodyHtml = $ConstMessageTypeHTML
    $Message.Subject = $ConstMessageSubject
    $SmtpClient.Credentials= New-Object System.Net.NetworkCredential($ConstUserName , $ConstUserPass)
    $Message.Attachments.Add($SourceFile)
    $Message.Body = (get-date).ToString() + $ConstMessageBody
    $SmtpClient.Send($Message) #Отправляем SMTP сообщение
    if ($?) { # Если SMTP сообщение было отправлено успешно, то
       write-host "Сообщение успешно отправлено"
    } else { #Если SMTP сообщение не удалось отправить, то
       write-host "Сообщение не отправлено. Ошибка:" $Error[0].ToString()
    }
    $Message.Dispose() #Отправляем сообщение QUIT на SMTP-сервер (правильно завершаем TCP-подключение и освобождаем все ресурсы, используемые текущим экземпляром класса SmtpClient)
}
