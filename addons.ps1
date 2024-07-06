$nul = $null;
$yes = $true;
$no = $false;

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

function Monitor-Process {
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

function Encrypt-Data {
    param (
        [string]$Data,
        [string]$Password
    )
    $secureString = ConvertTo-SecureString -String $Password -AsPlainText -Force
    $encryptedData = ConvertTo-EncryptedData -StringData $Data -SecureKey $secureString
    return $encryptedData
}

function Decrypt-Data {
    param (
        [string]$EncryptedData,
        [string]$Password
    )
    $secureString = ConvertTo-SecureString -String $Password -AsPlainText -Force
    $decryptedData = ConvertFrom-EncryptedData -EncryptedData $EncryptedData -SecureKey $secureString
    return $decryptedData
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
    Get-Job -Id $JobId
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
        $cevent = $Event.MessageData
        Add-Content -Path $LogFile -Value "$($cevent.InvocationInfo.Line) - $($cevent.InvocationInfo.InvocationName)"
    }
}
function dotlog_off {
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