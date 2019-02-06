$prompt = Read-Host "Enter a computer name to check"

# Remote computer to check for duplicates in SID form
$Computer = (Get-WmiObject -Class win32_userprofile -ComputerName $prompt).SID

# Get a list of terminated staff from AD in username form
$ExUsers = (Get-ADGroupMember "NOT RF EMPLOYED").SamAccountName

# Store the converted SID names to usernames here
$user_array = New-Object System.Collections.ArrayList

# All detected duplicate users get stored here
$duplicate_user_array = New-Object System.Collections.ArrayList

# Users to be deleted
$users_to_kill = New-Object System.Collections.ArrayList

foreach ($c in ($Computer | Select-Object -skip 1))
{
    # Convert the SID to a username
    $objSID = New-Object System.Security.Principal.SecurityIdentifier($c)
    $objUser = $objSID.Translate([System.Security.Principal.NTAccount])
    $objUser.Value

    # Convert the username to a string and clean up
    $username_string = $objUser.ToString()
    $username_string_clean = $username_string.Replace("RFHV\", "")

    # Append the results to a new array
    $user_array.Add($username_string_clean)

    # Clear any output from the screen
    Clear-Host
}

function UserArrayCleanup
{
    # Remove the local administrator and system accounts
    $user_array.Remove("RFHV\Administrator")
    $user_array.Remove("administrator")
    $user_array.Remove("NT AUTHORITY\NETWORK SERVICE")
    $user_array.Remove("NT AUTHORITY\LOCAL SERVICE")
    $user_array.Remove("NT AUTHORITY\SYSTEM")
}
UserArrayCleanup

# Check if the username on the remote computer exists in the ex-users OU
foreach ($user in $user_array)
{
    foreach ($exuser in $ExUsers)
    {
        if ($user -eq $exuser)
        {
            # Add detected duplicate user to the duplicate array
            $duplicate_user_array.add($user)

            # Clear the output from the screen
            Clear-Host
        }
    }
}

# Prepend the local path to the beginning of the username
foreach ($duplicate_user in $duplicate_user_array)
{
    $users_to_kill += "C:\users\$duplicate_user"        
}

# Remove the duplicate accounts
Get-WmiObject -Class Win32_UserProfile -ComputerName $prompt | Where-Object {$_.localpath -in $users_to_kill} | Remove-WmiObject