$login = "UserName" #Имя пользователя для подключения сетевого диска
$pass = ConvertTo-SecureString "MyPassword" -AsPlainText -Force #Преобразуем пароль для подключения сетевого диска в защищенную строку
$creds = New-Object System.Management.Automation.PSCredential ($login, $pass) #Преобразуем учетные данные к типу PSCredential
New-PSDrive -Name MyDrv -PSProvider FileSystem -Root "\\Book01\c$\Documents and Settings\User" -Credential $creds #Подключаем сетевой ресурс \\Book01\c$\Documents and Settings\User как диск с именем MyDrv, используя полученные ранее учетные данные
