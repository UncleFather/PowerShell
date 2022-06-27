$needed_group = 'Security Group Name'
$department = '*Department*'
Get-QADGroupMember -disabled:$false $needed_group | ForEach {Get-QADUser -samaccountname:$_.SamAccountName -disabled:$false -inactive:$false } | where {$_.DN –like $department} | Sort-Object department,displayName | Select displayName,company,department,title | Export-Csv -NoTypeInformation .\$needed_group.csv -Encoding Unicode
