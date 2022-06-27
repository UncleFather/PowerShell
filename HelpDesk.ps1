$path = "\\Server\Share\Folder"                                  #Папка для сохранения скриншотов
$title = "Описание проблемы"                                     #Заголовок окна ввода описания проблемы
$msg = "Опишите вкратце проблему:"                               #Подсказка окна ввода описания проблемы
$ConstServer = "smtp.server.ru"                                  #SMTP сервер
$ConstSMTPPort = "25"                                            #Порт SMTP сервера (даже при отправке по SSL через 465-й порт оставляем здесь порт 25!!
$ConstFrom = "sender@server.ru"                                  #Адрес отправителя
$ConstTo = "receiver3@server.ru"                                 #Адрес получателя
$ConstMessageTypeHTML = $false                                   #Формат сообщения HTML (true) или обычный текст (false)
$ConstUserName = "user@server.ru"                                #Имя пользователя (ящика) для авторизации на SMTP сервере
$ConstUserPass = "Password"                                      #Пароль для авторизации на SMTP сервере
$SMSAPI_ID = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"              #ID сервиса sms.ru
$SMS_Number = "7XXXXXXXXXX"                                      #Номер телефона для отправки SMS сообщения

$ID_String = $env:computername + " " + $env:username + " " + $((get-date).tostring('yyyy.MM.dd-HH.mm.ss'))    #Строка с именем проблемного компьютера, пользователя и датой возникновения проблемы

#Проверяем наличие папки для сохранения снимков экрана
If (!(test-path $path)) {
    #В случае отсутствия, создаем её
    New-Item -ItemType Directory -Force -Path $path
}

#Создаем снимок экрана
Add-Type -AssemblyName System.Windows.Forms
$screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
#Получаем разрешение экрана
$bitmap = New-Object System.Drawing.Bitmap $screen.Width, $screen.Height
#Создаем графический объект
$graphic = [System.Drawing.Graphics]::FromImage($bitmap)
#Получаем снимок экрана
$graphic.CopyFromScreen($screen.location, [Drawing.Point]::Empty, $bitmap.Size);
$graphic.Dispose()
$screen_file = "$path\$ID_String.jpg"
#Сохраняем снимок в файл
$bitmap.Save($screen_file)
$bitmap.Dispose()

#Отправляем SMTP сообщение
$ConstMessageSubject = "Problem with "+ $ID_String                                     #Тема сообщения
[void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
$ConstMessageBody = [Microsoft.VisualBasic.Interaction]::InputBox($msg, $title)        #Тело сообщения

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
$Message.Attachments.Add($screen_file)
$Message.Body = (get-date).ToString() + $ConstMessageBody
$SmtpClient.EnableSsl = $True    #Включаем SSL протокол
$SmtpClient.Send($Message) #Отправляем SMTP сообщение

if ($?)
{ # Если SMTP сообщение было отправлено успешно, то
    write-host "Сообщение успешно отправлено"
}
else
{ #Если SMTP сообщение не удалось отправить, то
    write-host "Сообщение не отправлено. Ошибка:" $Error[0].ToString()
}
$Message.Dispose() #Отправляем сообщение QUIT на SMTP-сервер (правильно завершаем TCP-подключение и освобождаем все ресурсы, используемые текущим экземпляром класса SmtpClient)
   
   
#Отправляем СМС при помощи сервиса sms.ru
$SMSAPI_ID = $SMSAPI_ID + "&to=" + $SMS_Number
$ip = (new-object net.webclient).DownloadString("http://sms.ru/sms/send?api_id=$SMSAPI_ID&text=Problem with " + $ID_String)
