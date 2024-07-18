$nul = $null;
$yes = $true;
$no = $false;

Add-Type -TypeDefinition @"
using System;
using System.IO;
using System.Net;
using System.Text;

public class dotserver {
    public static void startServer(int port, string returnData) {
        string url = "http://localhost:" + port + "/";
        HttpListener listener = new HttpListener();
        listener.Prefixes.Add(url);
        listener.Start();
        
        Console.WriteLine("Server started at " + url);
        
        while (true) {
            HttpListenerContext context = listener.GetContext();
            HttpListenerRequest request = context.Request;
            HttpListenerResponse response = context.Response;
            
            string responseString = returnData;
            byte[] buffer = Encoding.UTF8.GetBytes(responseString);
            
            response.ContentLength64 = buffer.Length;
            Stream output = response.OutputStream;
            output.Write(buffer, 0, buffer.Length);
            output.Close();
        }
    }
}
"@

function Invoke-DynamicParameter {
    param (
        [scriptblock]$ScriptBlock,
        [hashtable]$Parameters
    )
    foreach ($paramName in $Parameters.Keys) {
        Set-Variable -Name $paramName -Value $Parameters[$paramName]
    }
    &$ScriptBlock
}

function MonitorProcess {
    param (
        [string]$ProcessName,
        [scriptblock]$Action
    )
    Register-WmiEvent -Query "SELECT * FROM __InstanceCreationEvent WITHIN 1 WHERE TargetInstance ISA 'Win32_Process' AND TargetInstance.Name='$ProcessName'" -Action $Action
}

function Invoke-WebRequestSimple {
    param (
        [string]$Url
    )
    Invoke-RestMethod -Uri $Url
}

function Create-AesManagedObject($key, $IV) {
    $aesManaged = New-Object "System.Security.Cryptography.AesManaged"
    $aesManaged.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aesManaged.Padding = [System.Security.Cryptography.PaddingMode]::Zeros
    $aesManaged.BlockSize = 128
    $aesManaged.KeySize = 256
    if ($IV) {
        if ($IV.getType().Name -eq "String") {
            $aesManaged.IV = [System.Convert]::FromBase64String($IV)
        }
        else {
            $aesManaged.IV = $IV
        }
    }
    if ($key) {
        if ($key.getType().Name -eq "String") {
            $aesManaged.Key = [System.Convert]::FromBase64String($key)
        }
        else {
            $aesManaged.Key = $key
        }
    }
    $aesManaged
}

function dotaes() {
    $aesManaged = Create-AesManagedObject
    $aesManaged.GenerateKey()
    [System.Convert]::ToBase64String($aesManaged.Key)
}

function EncryptData($key, $unencryptedString) {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($unencryptedString)
    $aesManaged = Create-AesManagedObject $key
    $encryptor = $aesManaged.CreateEncryptor()
    $encryptedData = $encryptor.TransformFinalBlock($bytes, 0, $bytes.Length);
    [byte[]] $fullData = $aesManaged.IV + $encryptedData
    $aesManaged.Dispose()
    [System.Convert]::ToBase64String($fullData)
}

function DecryptData($key, $encryptedStringWithIV) {
    $bytes = [System.Convert]::FromBase64String($encryptedStringWithIV)
    $IV = $bytes[0..15]
    $aesManaged = Create-AesManagedObject $key $IV
    $decryptor = $aesManaged.CreateDecryptor();
    $unencryptedData = $decryptor.TransformFinalBlock($bytes, 16, $bytes.Length - 16);
    $aesManaged.Dispose()
    [System.Text.Encoding]::UTF8.GetString($unencryptedData).Trim([char]0)
}

function Invoke-InContext {
    param (
        [ValidateSet("Admin", "User")]$Context,
        [string]$Command
    )
    if ($Context -eq "Admin") {
        Start-Process PowerShell -ArgumentList "-Command $Command" -Verb RunAs
    } else {
        Invoke-Expression $Command
    }
}

function Export-CommandHistory {
    param (
        [string]$FilePath
    )
    Get-History | Export-Clixml -Path $FilePath
}

function Import-CommandHistory {
    param (
        [string]$FilePath
    )
    $history = Import-Clixml -Path $FilePath
    foreach ($entry in $history) {
        Add-History -CommandLine $entry.CommandLine
    }
}


function Invoke-TimedCommand {
    param (
        [scriptblock]$ScriptBlock
    )
    $startTime = Get-Date
    &$ScriptBlock
    $endTime = Get-Date
    $elapsedTime = $endTime - $startTime
    Write-Host "Command completed in $($elapsedTime.TotalSeconds) seconds"
}


function dotremote {
    param (
        [string]$ComputerName,
        [string]$Command
    )
    Invoke-Command -ComputerName $ComputerName -ScriptBlock { Invoke-Expression $Command }
}

function Invoke-WithRetry {
    param (
        [scriptblock]$ScriptBlock,
        [int]$RetryCount
    )
    for ($i = 0; $i -lt $RetryCount; $i++) {
        try {
            &$ScriptBlock
            break
        } catch {
            if ($i -eq ($RetryCount - 1)) { throw }
            Start-Sleep -Seconds 1
        }
    }
}


function dotschedule {
    param (
        [string]$Command,
        [string]$Time
    )
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-Command $Command"
    $trigger = New-ScheduledTaskTrigger -Daily -At $Time
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal
    Register-ScheduledTask -TaskName $Command -InputObject $task
}


function dotasync {
    param (
        [string]$Command
    )
    $job = Start-Job -ScriptBlock {
        Invoke-Expression $using:Command
    }
    return $job.Id
}

function dotasync_check {
    param (
        [int]$JobId
    )
    $what = Get-Job -Id $JobId
    return $what.State -eq "Completed";
}

function dotasync_get {
    param (
        [int]$JobId
    )
    Receive-Job -Id $JobId
}

function dotenv {
    param (
        [ValidateSet("Set", "Remove", "Get")]$Action,
        [string]$Name,
        [string]$Value
    )
    switch ($Action) {
        "Set" { [System.Environment]::SetEnvironmentVariable($Name, $Value) }
        "Remove" { [System.Environment]::SetEnvironmentVariable($Name, $null) }
        "Get" { return [System.Environment]::GetEnvironmentVariable($Name) }
    }
}

function alias_export {
    param (
        [string]$FilePath
    )
    Get-Alias | ForEach-Object {
        "Set-Alias -Name $($_.Name) -Value $($_.Definition)" | Add-Content -Path $FilePath
    }
}

function alias_import {
    param (
        [string]$FilePath
    )
    . $FilePath
}


function dotlog_on {
    param (
        [string]$LogFile
    )
    Register-EngineEvent -SourceIdentifier PowerShell.OnCommandExecution -Action {
        $event = $Event.MessageData
        Add-Content -Path $LogFile -Value "$($event.InvocationInfo.Line) - $($event.InvocationInfo.InvocationName)"
    }
}
function dotlog_ofdf {
    param (
        [string]$LogFile
    )
    Register-EngineEvent -SourceIdentifier PowerShell.OnCommandExecution -Action {}
}

function alias {
    param (
        [ValidateSet("Add", "Remove", "List")]$Action,
        [string]$Name,
        [string]$Value
    )
    switch ($Action) {
        "Add" { Set-Alias -Name $Name -Value $Value }
        "Remove" { Remove-Item Alias:$Name }
        "List" { Get-Alias }
    }
}

function printProgress {
    param (
        [string]$Activity,
        [string]$Status
    )
    for ($i = 0; $i -le 100; $i++) {
        Write-Progress -Activity $Activity -Status $Status -PercentComplete $i
        Start-Sleep -Milliseconds 50
    }
}

function printColored {
    param (
        [string]$Text,
        [string]$Color
    )
    $host.ui.RawUI.ForegroundColor = $Color
    Write-Host $Text
    $host.ui.RawUI.ForegroundColor = "White"
}


function printError {
    param(
        [string]$text
    )
    Write-Error $text
}

function printWarning {
    param(
        [string]$text
    )
    Write-Warning $text
}

function printInfo {
    param(
        [string]$text
    )
    Write-Host $text
}

function printTxt {
    param(
        [string]$text
    )
    Write-Output $text
}

function import {
param(
    [string]$path
)
Import-Module $path
}

function jq {
    param (
        [string]$param1
    )
    $cOS = Get-OS;
    if ($cOS -eq "windows") {
    & $PSScriptRoot\jq $param1
    } else {
    & jq $param1
    }
}

function Get-OS {
    $os = (Get-WmiObject Win32_OperatingSystem).Caption

    if ($os -like "*Windows*") {
        return "windows"
    } elseif ($os -like "*Mac*") {
        return "mac"
    } elseif ($os -like "*Linux*") {
        return "gnu"
    } else {
        return "Unknown"
    }
}


function getFilePath {
    return $PSScriptRoot;
}

function fetch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Uri,

        [string]$auth = 'NULL',
        [string]$Method = 'GET',

        [hashtable]$Headers,

        $Body,

        [int]$RetryCount = 3
    )

    try {
        $headers = if ($Headers) { $Headers } else { @{} }
        $headers['Authorization'] = 'Bearer $token'

        $retry = 0
        do {
            $response = Invoke-WebRequest -Uri $Uri -Method $Method -Body $body -Headers $headers
            return $response
        }
        while (++$retry -lt $RetryCount)
    }
    catch {
        Write-Error "Error invoking REST API: $_"
        return $null
    }
}
function Invoke-DynamicScript {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ScriptBody
    )

    try {
        $scriptBlock = [scriptblock]::Create($ScriptBody)
        $result = Invoke-Command -ScriptBlock $scriptBlock
        return $result
    }
    catch {
        Write-Error "Error executing dynamic script: $_"
        return $null
    }
}
function dotui {
    param (
        [string] $Title,
        [string[]] $Options
    )

    $selectedOptionIndex = 0
    $menuActive = $true

    while ($menuActive) {
        Clear-Host
        Write-Host "$Title`n" -ForegroundColor White

        for ($i = 0; $i -lt $Options.Count; $i++) {
            if ($i -eq $selectedOptionIndex) {
                Write-Host "   > $($Options[$i])" -BackgroundColor White -ForegroundColor Black
            } else {
                Write-Host "     $($Options[$i])"
            }
        }

        $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode

        switch ($key) {
            38 { # up key
                $selectedOptionIndex = [Math]::Max(0, $selectedOptionIndex - 1)
            }
            87 { # w key
                $selectedOptionIndex = [Math]::Max(0, $selectedOptionIndex - 1)
            }
            40 { # down key
                $selectedOptionIndex = [Math]::Min($Options.Count - 1, $selectedOptionIndex + 1)
            }
            83 { # s key
                $selectedOptionIndex = [Math]::Min($Options.Count - 1, $selectedOptionIndex + 1)
            }
            13 { # enter key
                $menuActive = $false
            }
            32 { # space key
                $menuActive = $false
            }
        }
    }

    return $selectedOptionIndex
}

function importasm {
    param (
        [string]$path
    )
    Add-Type -AssemblyName $path
}
function == {
    param (
        [Parameter(Mandatory = $true)]
        $Left,

        [Parameter(Mandatory = $true)]
        $Right
    )
    return $Left -eq $Right
}

function n= {
    param (
        [Parameter(Mandatory = $true)]
        $Left,

        [Parameter(Mandatory = $true)]
        $Right
    )
    return $Left -ne $Right
}

function =< {
    param (
        [Parameter(Mandatory = $true)]
        $Left,

        [Parameter(Mandatory = $true)]
        $Right
    )
    return $Left -le $Right
}

function => {
    param (
        [Parameter(Mandatory = $true)]
        $Left,

        [Parameter(Mandatory = $true)]
        $Right
    )
    return $Left -ge $Right
}

function _< {
    param (
        [Parameter(Mandatory = $true)]
        $Left,

        [Parameter(Mandatory = $true)]
        $Right
    )
    return $Left -lt $Right
}

function _> {
    param (
        [Parameter(Mandatory = $true)]
        $Left,

        [Parameter(Mandatory = $true)]
        $Right
    )
    return $Left -gt $Right
}

function dotgui {
    param (
        [Parameter(Mandatory = $true)]
        [string]$XamlPath,

        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock
    )
    Add-Type -AssemblyName PresentationFramework
    $xaml = Get-Content $XamlPath -Raw
    $reader = (New-Object System.Xml.XmlNodeReader (New-Object System.Xml.XmlDocument))
    $reader.ReadOuterXml($xaml)
    $window = [Windows.Markup.XamlReader]::Load($reader)
    & $ScriptBlock -ArgumentList $window
    $window.ShowDialog() | Out-Null
}

function dotuid {
    return [guid]::NewGuid().ToString();
}

function dotregex {
    param(
        [Parameter(Mandatory=$true)][string]$InputString,
        [Parameter(Mandatory=$true)][string]$Pattern,
        [Parameter(Mandatory=$true)][string]$Replacement
    )

    $regex = New-Object System.Text.RegularExpressions.Regex($Pattern)
    $result = $regex.Replace($InputString, $Replacement)
    return $result
}

# Requires PowerShell 5.0+
function dotbreak_add {
    param(
        [Parameter(Mandatory=$true)][string]$ScriptPath,
        [Parameter(Mandatory=$true)][int]$LineNumber
    )
    
    return Set-PSBreakpoint -Script $ScriptPath -Line $LineNumber;
}

function dotbreak_remove {
    param(
        [Parameter(Mandatory=$true)][int]$BreakpointId
    )
    
    Remove-PSBreakpoint -Id $BreakpointId
}

function dotsuggest {
    param(
        [string]$CommandName,
        [string]$ParameterName,
        [string]$WordToComplete,
        [CommandAst]$CommandAst,
        [Hashtable]$FakeBoundParameters
    )
    $results = @()
    $history = Get-History | Where-Object { $_.CommandLine -like "$WordToComplete*" }
    $uniqueCommands = $history.CommandLine | Sort-Object -Unique

    foreach ($command in $uniqueCommands) {
        $completionResult = [System.Management.Automation.CompletionResult]::new($command, $command, 'ParameterValue', $command)
        $results += $completionResult
    }

    return $results
}

Register-ArgumentCompleter -CommandName '*' -ParameterName '*' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    dotsuggest -CommandName $commandName -ParameterName $parameterName -WordToComplete $wordToComplete -CommandAst $commandAst -FakeBoundParameters $fakeBoundParameters
}

function dotkey {
	return $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character.ToString().ToLower();
}

function dotsharp_add {
    param(
        [Parameter(Mandatory = $true)]
        [string]$csharp
    )

    Add-Type $csharp
}

function dotsharp {
    param (
        [string]$inputString
    )
    $regex = [regex]::new("^(?<class>[\w\d]+)\.(?<method>[\w\d]+)\((?<params>.*)\)$")
    if ($regex.IsMatch($inputString)) {
        $matchesq = $regex.Match($inputString)
        $className = $matchesq.Groups["class"].Value
        $methodName = $matchesq.Groups["method"].Value
        $paramsString = $matchesq.Groups["params"].Value
        $params = if ($paramsString -eq '') { @() } else { $paramsString.Split(",").Trim() }
        $paramsJoined = $params -join ', '
        $methodCall = "[$className]::$methodName($paramsJoined)"
        return Invoke-Expression $methodCall
    }
    else {
        throw "Input string does not match the expected pattern 'CLASS.METHOD(PARAMS)'."
    }
}

function dotreverse([string]$inputS) {
$length = $inputS.Length
$result = ""

for ($i = $length - 1; $i -ge 0; $i--) {
    $result += $inputS[$i]
}

return $result;
}

function dotfactorial {
    param(
        [int]$n
    )

    $factorial = 1
    for ($i = 1; $i -le $n; $i++) {
        $factorial *= $i
    }
    return $factorial
}

function dotsort {
    param (
        [string]$jsonArray
    )
    $arr = $jsonArray | ConvertFrom-Json
    $n = $arr.Length
    for ($i = 0; $i -lt $n - 1; $i++) {
        for ($j = 0; $j -lt $n - $i - 1; $j++) {
            if ($arr[$j] -gt $arr[$j + 1]) {
                $temp = $arr[$j]
                $arr[$j] = $arr[$j + 1]
                $arr[$j + 1] = $temp
            }
        }
    }
    return $arr
}

