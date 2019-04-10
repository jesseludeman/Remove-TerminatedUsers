# Cleanup-Machine
I wrote this script because I found myself constantly having to clean up desktops in our environment that were full of ex-employee user accounts, which were taking up quite a large amount of space on the local disk. I got tired of having to remotely connect in and remove the accounts manually, so I decided to automate the process and make it much easier for myself.

It essentially works by getting a list of ex-user accounts in Active Directory, and getting a list of all user account SIDs from a remote machine, then converting them a domain username. Once it has this information, it strips out and cleans up the user account information, and compares it to what currently exists in Active Directory. If it finds a terminated account on the machine, it stores it in a list which it then passed across further down and calls the Remove-DuplicateUsers function which then deletes it from the machine.

I would have preferred to have used the Get-CimInstance cmdlet, however I believe in order for this to work on remote machines, the WinRM service needs to be running. Unfortunately, this is not the case in our environment, so I had to work around the problem and provide an alternate solution, which resulted in more code.

I'm most proud of this script, it turned out to be quite a handy tool that both myself and my team have and still are using.
