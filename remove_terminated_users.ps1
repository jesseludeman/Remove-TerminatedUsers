$prompt = Read-Host "Enter a computer to check"
$remote_computer = (Get-WmiObject -Class win32_userprofile -ComputerName $prompt | Select-Object).SID
$exusers = (Get-ADGroupMember "TERMINATED OU HERE").SamAccountName
$sid_array = New-Object System.Collections.ArrayList
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
            
        [void]$sid_array.Add($result)
    }
}

function Update-Array
{
    $sid_array.Remove("pdq.sa")
    $sid_array.Remove("Administrator.RFHV")
    $sid_array.Remove("default")
    $sid_array.Remove("administrator")
    $sid_array.Remove("DOMAIN\Administrator")
    $sid_array.Remove("NT AUTHORITY\NETWORK SERVICE")
    $sid_array.Remove("NT AUTHORITY\LOCAL SERVICE")
    $sid_array.Remove("NT AUTHORITY\SYSTEM")
}

function Find-DuplicateUser
{
    foreach ($sid in $sid_array)
    {
        foreach ($exuser in $exusers)
        {
            if ($sid -eq $exuser)
            {
                [void]$duplicate_users.add($sid)
            }
        }
    }
    if ($duplicate_users)
    {
        Write-Host -ForegroundColor Yellow "Located" $duplicate_users.Count "terminated users"
    }
    else 
    {
        Write-Host "No terminated users found"    
    }
}

function Remove-DuplicateUsers
{
    foreach ($user in $duplicate_users)
    {
        [void]$users_to_delete.Add("C:\users\$user")
    }

    Get-WmiObject -Class win32_userprofile -ComputerName $prompt | Where-Object {$_.localpath -in $users_to_delete} | Remove-WmiObject
}

# "Main" method here
Convert-SIDtoUsername
Update-Array
Find-DuplicateUser
Remove-DuplicateUsers