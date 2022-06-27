# PowerShell
## PowerShell scripts
### _Различные скрипты на PowerShell для облегчения задач администрирования_
+ __HelpDesk.ps1:__ 
Отправляет снимок экрана, имя компьютера, имя пользователя, дату события в общую папку и на email администратора, а так же оповещает о событии по СМС на номер администратора.
+ __ChangeVPNGate.ps1:__
Отображает текущее состояние параметра «Использовать основной шлюз в удаленной сети» и позволяет его изменять для любого из присутствующих в системе VPN подключений. Создавался для исправления [проблемы](http://manaeff.ru/forum/viewtopic.php?p=1620) в ранних версиях ОС MS Windows 10, когда для VPN подключений нельзя было открыть свойства интернет-протоколов TCP.
+ __IPCheck.ps1:__
Отправляет уведомления на email при смене динамического внешнего (белого) IP адреса. [Подробное описание](http://manaeff.ru/forum/viewtopic.php?p=1465)
___Возможности скрипта:___
  - Контроль внешнего IP адреса при помощи четырех сайтов-сервисов, которые можно задавать вручную
  - Подробное email оповещение в HTML либо текстовом формате при смене внешнего IP адреса
  - Формирование HTML странички с отчетом за последние 10 проверок (например, для размещения ее на облачном диске)
  - Синхронизация с сервисом DNS-O-Matic (который, в свою очередь умеет отправлять краткое email оповещение, а так же синхронизироваться с огромным списком сервисов динамических DNS, см.)
  - Возможность контролировать и не контролировать внешний IP адрес при активных VPN подключениях
  - Возможность определять тип активного VPN подключения - с шлюзом в удаленной сети или с обычным шлюзом в ЛВС
  - Возможность задать неконтролируемое VPN подключение с шлюзом в удаленной сети. То есть, если это подключение активно, то при смене внешнего IP никаких действий производиться не будет
  - Сохранение состояния при перезагрузке ПК. То есть, если после перезагрузки внешний IP остался прежним, никаких действий производиться не будет
  - Принудительное обновление IP адреса на сервисе DNS-O-Matic. То есть, если внешний адрес ПК не изменялся, но в это время вручную был изменен IP клиента на самом сервисе динамических DNS, то скрипт через заданное время принудительно обновит данные на сервисе DNS-O-Matic, который, в свою очередь, обновит сервис динамических DNS.
  - Запись измененного IP в журналы Windows
  - Запись служебной и диагностической информации в файл и/или в журналы Windows
  - Возможность задать размер файла журнала
  - Возможность запуска на произвольном количестве компьютеров в ЛВС. При этом настройки каждого из них могут быть уникальными, а могут быть одинаковыми. В том числе, можно задать каждому хосту свое идентификационное имя ($ConstControlHost), а можно задать всем одинаковое.
  - Выдача диагностической информации при невозможности определить внешний IP ни по одному из сервисов. Диагностическая информация - это пинг до заданного хоста, трассировка до хоста, проверка работы DNS (прямое и обратное сопоставление (разрешение имен в адреса и адресов в имена)), анализ подключенного VPN подключения
+ __URL Decode&Encode.ps1:__
Кодирует/декодирует символы в формат URL.
+ __sendingSMTP.ps1:__
отправляет сообщения (электронную почту) через smtp сервер.
+ __mappingNetworkDrive.ps1:__
Подключает сетевой диск с учетными данные (логин и пароль) пользователя.
