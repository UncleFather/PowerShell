import-module activedirectory
#Get-QADComputer -Identity * -Properties *
Get-QADComputer -Identity * -Properties * | FT Name, ComputerRole, LastLogon, lastLogoff, operatingSystem ,operatingSystemServicePack, operatingSystemVersion, whenChanged, whenCreated -Autosize
