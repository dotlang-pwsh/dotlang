# 😉 Advanced

## Advanced Commands

woah! you made it here! alright let's start.

### Imports

as you've learned in the basics, `Import-Module` is the default powershell cmdlet to import functions and variables from other scripts, to that in dotlang, simply:

```powershell
import ".\anotherfile.ps1";
# or,
import(".\anotherfile.ps1");
```

simple ain't it?

### Encrypting and Decrypting data

yeah, we have this in dotlang :)

```powershell
$key = dotaes;
$key;
$unencryptedString = "blahblahblah";
# Encrypting
$encryptedString = EncryptData $key $unencryptedString;
# Decrypting
$backToPlainText = DecryptData $key $encryptedString;
```

### Asynchronous Command Execution

for short, `async`!

very easy, To make an async job:

```powershell
$jobID = dotasync("Long_Running_Command");
function isCompleted {
if (dotasync_check($jobID)) {
printTxt("Job Finished!");
printTxt("Job Returned:");
dotasync_get($jobID);
} else {
isCompleted
}
}
isCompleted
```

Output: ![image](https://github.com/neoapps-dev/dotlang/assets/158327205/74cbb72a-bf3d-4a69-8ea8-81b91f1144e6)

that was pretty advanced, ain't it?

### Executing Commands on an other PC

yeah.. it doesn't support dotlang commands, only powershell (sorry)..

```powershell
dotremote "ComputerName or Address" "Powershell command";
```

### Monitoring Processes

```powershell
MonitorProcess "ProccessName" {
# action on proccess start goes here
};
```

### Run As Admin/User

```powershell
Invoke-InContext Admin "Write-Host hii" # run command as admin in another window
Invoke-InContext User "Write-Host hii" # run command as a user (not admin)
```

Output: ![image](https://github.com/neoapps-dev/dotlang/assets/158327205/410f7c5b-5e08-4e20-855c-bda8f6559a59)

### Schedule commands

yep. and it's easy.

```powershell
dotschedule "Command" "Time";
```

![image](https://github.com/neoapps-dev/dotlang/assets/158327205/3abf287f-822f-4603-b322-96a700a469f2)

### Get Current OS

```powershell
$currentOS = Get-OS;
printTxt("You're running a $currentOS machine!"); # 'windows' for Windows, 'mac' for MacOS, 'gnu' for GNU/Linux
```

![image](https://github.com/neoapps-dev/dotlang/assets/158327205/027b69ef-4404-4975-94a0-456a67bd2950)

### Amazing TUIs

hello TUIs dev. it's now MUCH easier to make TUIs with `dotlang`! here's an example:

```powershell
$inp = dotui "What do you use?" "Windows","GNU/Linux","MacOS";
printTxt("You've choosen the input $($inp+1)");
```

Usage: dotui "Title" "Input 0","Input 1","Input 3", etc...

Result: ![image](https://github.com/user-attachments/assets/4a587fe8-2e08-4151-83ce-2ab7dae0797b)
