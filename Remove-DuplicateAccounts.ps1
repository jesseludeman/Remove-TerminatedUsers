$prompt = Read-Host "Enter a computer name to check"
$remote_computer = (Get-WmiObject -Class win32_userprofile -ComputerName $prompt | Select-Object).SID
$exusers = (Get-ADGroupMember "NOT RF EMPLOYED").SamAccountName
$array = New-Object System.Collections.ArrayList
$duplicate_users = New-Object System.Collections.ArrayList
$users_to_delete = New-Object System.Collections.ArrayList

function Convert-SIDtoUsername
{
    # skip the local administrator account... hopefully
    foreach ($r in ($remote_computer | Select-Object -skip 1))
    {
        $objSID = New-Object System.Security.Principal.SecurityIdentifier($r)
        $objUser = $objSID.Translate([System.Security.Principal.NTAccount])
        [void]$objUser.Value
        
        $string_result = $objUser.ToString()
        $result = $string_result.Replace("RFHV\", "")
            
        [void]$array.Add($result)
    }
}

function Update-Array
{
    $array.Remove("pdq.sa")
    $array.Remove("Administrator.RFHV")
    $array.Remove("default")
    $array.Remove("administrator")
    $array.Remove("RFHV\Administrator")
    $array.Remove("NT AUTHORITY\NETWORK SERVICE")
    $array.Remove("NT AUTHORITY\LOCAL SERVICE")
    $array.Remove("NT AUTHORITY\SYSTEM")
}

function Find-DuplicateUser
{
    foreach ($a in $array)
    {
        foreach ($exuser in $exusers)
        {
            if ($a -eq $exuser)
            {
                [void]$duplicate_users.add($a)
            }
        }
    }
}

function Remove-DuplicateUsers
{
    foreach ($user in $duplicate_users)
    {
        [void]$users_to_delete.Add("C:\users\$user")
    }

    if ($users_to_delete)
    {
        Get-WmiObject -Class win32_userprofile -ComputerName $prompt | Where-Object {$_.localpath -in $users_to_delete} | Remove-WmiObject
    }
    
    Write-Output "Operation complete"
}

# "Main" method here
Convert-SIDtoUsername
Update-Array
Find-DuplicateUser
Remove-DuplicateUsers