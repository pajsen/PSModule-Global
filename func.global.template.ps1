Function New-EcGlobalScriptModuleTemplate
{
    <#
    .SYNOPSIS
	    Generates a basic script module

    .DESCRIPTION
	    Generates a basic script module including a script module manifest

    .PARAMETER  Name
	    The Name of the script module and module manifest
    
    .EXAMPLE
        New-EcGlobalScriptModule -Name SCO

        Create a script module Ecco.SCO.psm1 and a module manifest Ecco.SCO.psd1

    .INPUTS
	    String

    .OUTPUTS
	    *.psm1 Script module file
        *.psd1 Script module manifest

    .NOTES
	    Version:        1.0.0
	    Author:         Admin-PJE
	    Creation Date:  12/05/16
        Module Script:  func.global.template
	    Purpose/Change: Initial function development
    #>

    param
    (
        [Parameter(Mandatory=$true)]
        [String]$Name
    )

    $ErrorActionPreference = "Stop"

    $mPath = "\\prd.eccocorp.net\it\Automation\Repository\Modules"
    $mPrefix = "Ecco"
    $mAuthor = $env:USERNAME
    $mVersion = "1.0.0"
    $mModule = "$mPrefix.$Name.psm1"
    $mManifest = "$mPrefix.$Name.psd1"
  
    try
    {
        if(Test-path $mPath\$mPrefix.$name)
        {
            Exit 
        }

        else
        {
            $mParent = New-Item -ItemType Directory -Path $mPath -Name "$mPrefix.$Name"
            $mChild = New-Item -ItemType Directory -Path $mParent -Name $mVersion
            $mScript = New-Item -ItemType File -Path $mChild -Name $mModule -Force
        }

        Add-Content $mScript "<#"
        Add-Content $mScript ".SYNOPSIS"
        Add-Content $mScript "`tA brief description of the script module`n"
        Add-Content $mScript ".NOTES"
        Add-Content $mScript "`tVersion:`t`t$mVersion"
        Add-Content $mScript "`tAuthor:`t`t`t$mAuthor"
        Add-Content $mScript "`tCreation Date:`t$(Get-Date -Format dd/MM/yy)"
        Add-Content $mScript "`tPurpose/Change:`tInitial script module development - $mModule"
        Add-Content $mScript "#>`n"
        Add-Content $mScript "`$ErrorActionPreference = `"Continue`"`n"
        Add-Content $mScript "Function Get-Ec$name`ModuleDirectory {"
        Add-Content $mScript "`t`$Invocation = Get-Variable MyInvocation -Scope 1 -ValueOnly"
        Add-Content $mScript "`tSplit-Path -Parent `$(`$Invocation.MyCommand.source)`n}`n"
        Add-Content $mScript "Get-ChildItem (Get-Ec$name`ModuleDirectory) -Recurse -Verbose:`$false | Where-Object -Verbose:`$false { `$_.Name -like `"func.*`" } | Foreach-Object {"
        Add-Content $mScript "`ttry{. `$_.FullName}`n`tcatch{Write-Host -ForegroundColor DarkCyan `$_.Exception.Message}} -Verbose:`$false`n"
        Add-Content $mScript "Export-ModuleMember -Function * -Alias * -Cmdlet * -Verbose:`$false`n"

        New-EcGlobalScriptSigning -GlobalPath $mScript
        New-ModuleManifest -Path "$mChild\$mManifest" -RootModule $mModule -Author $mAuthor -ModuleVersion $mVersion -CompanyName "ECCO Shoes A/S" -Copyright "(c) 2015 Ecco Shoes A/S. All rights reserved."

        ise $mScript
    }

    catch
    {
        $_.exception.message
    }
 
    ise $mScript
}

Function New-EcGlobalWorkflowTemplate
{
    <#
    .SYNOPSIS
	    Generates a workflow script from a template

    .DESCRIPTION
	    Generates a Standard workflow or Azure workflow script, with or without logging from a template

    .PARAMETER  Name
	    The Name of the workflow to be created
    
    .PARAMETER  Path
	    The path to where the script will be stored
    
    .PARAMETER  ComputerName
	    Name of the remote computer to execute inlinescript code
    
    .PARAMETER  Azure
	    Switch used when generating a azure workflow

    .PARAMETER  Logging
	    Switch used to enable logging

    .EXAMPLE
        New-EcGlobalWorkflow -Name wfStdRemLog -Path C:\script -ComputerName dc1 -Logging

        Create normal workflow with remote inlinescript and logging

    .EXAMPLE
        New-EcGlobalWorkflow -Name wfAzuLog -Path C:\script -Azure -Logging
        
        Create azure workflow with logging

    .INPUTS
	    String, Boolean

    .OUTPUTS
	    *.ps1 scriptfile

    .NOTES
	    Version:        1.0.0
	    Author:         Admin-PJE
	    Creation Date:  26/04/16
        Module Script:  func.global.template
	    Purpose/Change: Initial function development
    #>

    [CmdletBinding(DefaultParametersetName="Standard")]

    Param
    (
        # The Name of the workflow to be created
        [Parameter(Mandatory=$true)]
        [String]$Name,

        # The path to where the script will be stored
        [Parameter(Mandatory=$true)]
        [String]$Path,

        # Name of the remote computer to execute inlinescript code
        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [String]$ComputerName,

        # Switch used when generating a azure workflow
        [Parameter(Mandatory=$false,ParameterSetName="Azure")]
        [Switch]$Azure,

        # Switch used to enable logging
        [Parameter(Mandatory=$false)]
        [Switch]$Logging
    )

    $wfFile = Join-Path -Path $Path -ChildPath "$Name.ps1"
    $wfAuthor = $env:USERNAME
    $wfVersion = "1.0.0"

    switch ($PsCmdlet.ParameterSetName) 
    { 
        "Standard"  { $type = "Workflow"; break} 
        "Azure"  { $type = "Azure Workflow"; break} 
    } 

    # Test if file with same name already exist
    if(Test-path $wfFile)
    {
        Write-Output "File $wfFile Already exist"

        # Confirm to overwrite else exit function
        $wfScript = New-Item -ItemType File -Path $wfFile -Confirm:$true -Force

        if($wfScript -eq $null)
        {
            Exit
        }
    }

    else
    {
        # create file if no file already exist
        $wfScript = New-Item -ItemType File -Path $wfFile
    }

    # create logging content 
    function LogContent
    {
        param
        (
            [Switch]$Indent
        )
        
        Add-Content $wfScript "$(if($Indent){"`t`t"})# PSLogging module can be installed with Install-Module from Powershell Gallery (WMF50)"
        Add-Content $wfScript "$(if($Indent){"`t`t"})# The module is also available from Ecco's repository"
        Add-Content $wfScript "$(if($Indent){"`t`t"})Import-Module PSLogging`n"
        Add-Content $wfScript "$(if($Indent){"`t`t"})# Log specific variables"
        Add-Content $wfScript "$(if($Indent){"`t`t"})`$sVersion = `"$wfVersion`""
        Add-Content $wfScript "$(if($Indent){"`t`t"})`$sLogName = `"$name.log`""
        Add-Content $wfScript "$(if($Indent){"`t`t"})`$sLogFile = Join-Path -Path `$env:TEMP -ChildPath `$sLogName `n"
        Add-Content $wfScript "$(if($Indent){"`t`t"})# Start and initialize $name.log"
        Add-Content $wfScript "$(if($Indent){"`t`t"})Start-Log -LogPath `$env:TEMP -LogName `"`$sLogName`" -ScriptVersion `$sVersion"
        Add-Content $wfScript "$(if($Indent){"`t`t"})Write-LogInfo -LogPath `$sLogFile -Message `"`$((Get-Date).ToString())``tRunning as user [`$([Environment]::UserDomainName)\`$([Environment]::UserName)] on host [`$(`$env:COMPUTERNAME)]`"`n"
        Add-Content $wfScript "$(if($Indent){"`t`t"})### DO STUFF ###`n"
        Add-Content $wfScript "$(if($Indent){"`t`t"})# Finalize $name.log, $type will finish"
        Add-Content $wfScript "$(if($Indent){"`t`t"})Stop-Log -LogPath `$sLogFile -NoExit`n"
    }

    Add-Content $wfScript "<#"
    Add-Content $wfScript ".SYNOPSIS"
    Add-Content $wfScript "`tA brief description of the $type.`n"
    Add-Content $wfScript ".DESCRIPTION"
    Add-Content $wfScript "`tA detailed description of the $type.`n"
    Add-Content $wfScript ".PARAMETER  <Parameter-Name>"
    Add-Content $wfScript "`tThe description of a parameter. Add a .PARAMETER keyword for"
    Add-Content $wfScript "`teach parameter in the $type syntax.`n"
    Add-Content $wfScript ".EXAMPLE"
    Add-Content $wfScript "`tA sample command that uses the $type, optionally followed"
    Add-Content $wfScript "`tby sample output and a description. Repeat this keyword for each example.`n"
    Add-Content $wfScript ".INPUTS"
    Add-Content $wfScript "`tThe Microsoft .NET Framework types of objects that can be piped to the"
    Add-Content $wfScript "`t$type. You can also include a description of the input objects.`n"
    Add-Content $wfScript ".OUTPUTS"
    Add-Content $wfScript "`tThe .NET Framework type of the objects that the cmdlet returns. You can"
    Add-Content $wfScript "`talso include a description of the returned objects.`n"
    Add-Content $wfScript ".NOTES"
    Add-Content $wfScript "`tVersion:`t`t$wfVersion"
    Add-Content $wfScript "`tAuthor:`t`t`t$wfAuthor"
    Add-Content $wfScript "`tCreation Date:`t$(Get-Date -Format dd/MM/yy)"
    Add-Content $wfScript "`tPurpose/Change:`tInitial $type development - $Name.ps1"
    Add-Content $wfScript "#>`n"

    
    Add-Content $wfScript "Workflow $name`n{`n`tParam`n`t("
    Add-Content $wfScript "`t`t#Param1 description"
    Add-Content $wfScript "`t`t[Parameter(Mandatory=`$true)]"
    Add-Content $wfScript "`t`t[String]`$Param1`n`t)`n"
    Add-Content $wfScript "`t# Stop $type if an exception occour"
    Add-Content $wfScript "`t`$ErrorActionPreference = `"Stop`"`n"

    if($Azure)
    {    
            Add-Content $wfScript "`t# Local credentials used on-prem (Azure Automation Credential Asset)"
            Add-Content $wfScript "`t`$cred = Get-AutomationPSCredential -Name `"Service-SCORCHRAA`"`n"
            Add-Content $wfScript "`t# Remote computer (Azure Automation Variable Asset)"
            Add-Content $wfScript "`t`$dc = Get-AutomationVariable -Name `"DomainController`"`n"
            Add-Content $wfScript "`t# Run a block of commands in a separate, non-workflow session and returns its output to the workflow"
            Add-Content $wfScript "`t`$result = InlineScript`n`t{`t"
            
            if($Logging)
            {
                LogContent -Indent
            }

            Add-Content $wfScript "`t} -PSComputerName `$dc -PSCredential `$cred`n"
    }

    else
    {
        if($ComputerName -ne "")
        {
            Add-Content $wfScript "`t# Remote Computer"
            Add-Content $wfScript "`t`$cn = `"$ComputerName`"`n"
            Add-Content $wfScript "`t# Insert Credential with encrypted credential Snippet here"
            Add-Content $wfScript "`t# Use New-EccoPSCredentialSnippet to generate local snippet`n"
            Add-Content $wfScript "`t# Run a block of commands in a separate, non-workflow remote session and returns its output to the workflow"
            Add-Content $wfScript "`t`$result = InlineScript`n`t{`t"
            
            if($Logging)
            {
                LogContent -Indent
            }

            Add-Content $wfScript "`t} -PSComputerName `$cn -PSCredential `$cred`n"
        }

        else
        {
            Add-Content $wfScript "`t# Run a block of commands in a separate, non-workflow session and returns its output to the workflow"
            Add-Content $wfScript "`t`$result = InlineScript`n`t{`t"
            
            if($Logging)
            {
                LogContent -Indent
            }

            Add-Content $wfScript "`t}`n"
        }

        
    }

    Add-Content $wfScript "`tWrite-Output `$result`n"
    Add-Content $wfScript "}"
    ise $wfScript
}

Function New-EcGlobalScriptTemplate
{
    <#
    .SYNOPSIS
	    Generates a script file from template

    .DESCRIPTION
	    Generates a Standard Script or Orchestrator script, with optional logging from a template

    .PARAMETER  Name
	    The Name of the script to be created
    
    .PARAMETER  Path
	    The path to where the script will be stored
    
    .PARAMETER  ComputerName
	    Name of the computer for remote code execution
    
    .PARAMETER  Type
	    Defining witch type of script should be generated

    .PARAMETER  Logging
	    Switch used to enable logging

    .EXAMPLE
        New-EcGlobalScriptTemplate -Name sStdRemLog -Path C:\script -Type StdScript -ComputerName dc1 -Logging

        Create standard script with remote code execution and logging

    .EXAMPLE
        New-EcGlobalScriptTemplate -Name sOrcRemLog -Path C:\script -Type ScorchScript -ComputerName dc1 -Logging

        Create orchestrator script with remote code execution and logging

    .INPUTS
	    String, Boolean

    .OUTPUTS
	    *.ps1 scriptfile

    .NOTES
	    Version:		1.0.0
	    Author:			Admin-PJE
	    Creation Date:	27/04/16
        Module Script:  func.global.template
	    Purpose/Change:	Initial function development
    #>

    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("StdScript", "ScorchScript")]
        [String]$Type,
        [Parameter(Mandatory=$true)]
        [String]$Name,
        [Parameter(Mandatory=$true)]
        [String]$Path,
        [Parameter(Mandatory=$false)]
        [String]$ComputerName,
        [Switch]$Logging
    )

    $sFile = Join-Path -Path $Path -ChildPath "$Name.ps1"
    $sAuthor = $env:USERNAME
    $sVersion = "1.0.0"
    
    switch ([Array]$($pscmdlet.MyInvocation.BoundParameters.Values)) 
    { 
        "StdScript"  { $sType = "Script"; break} 
        "ScorchScript"  { $sType = "Orchestrator Script"; break}
    } 
    
    
    if(Test-path $sFile)
    {
        Write-Host "File Already exist"
        $sScript = New-Item -ItemType File -Path $sFile -Confirm:$true -Force

        if($sScript -eq $null)
        {
            Exit
        }
    }
    else
    {
        $sScript = New-Item -ItemType File -Path $sFile
    }

    function LogContent
    {
        param
        (
            [Switch]$Indent,
            [Switch]$Initial
        )
        
        if($initial)
        {
            Add-Content $sScript "$(if($Indent){"`t"})## PSLogging module can be installed with Install-Module from Powershell Gallery (WMF50)"
            Add-Content $sScript "$(if($Indent){"`t"})## The module is also available from Ecco's repository"
            Add-Content $sScript "$(if($Indent){"`t"})Import-Module PSLogging`n"
            Add-Content $sScript "$(if($Indent){"`t"})## Log specific variables"
            Add-Content $sScript "$(if($Indent){"`t"})`$sVersion = `"$sVersion`""
            Add-Content $sScript "$(if($Indent){"`t"})`$sLogName = `"$name.log`""
            Add-Content $sScript "$(if($Indent){"`t"})`$sLogFile = Join-Path -Path `$env:TEMP -ChildPath `$sLogName `n"
            Add-Content $sScript "$(if($Indent){"`t"})## Start and initialize $name.log"
            Add-Content $sScript "$(if($Indent){"`t"})Start-Log -LogPath `$env:TEMP -LogName `"`$sLogName`" -ScriptVersion `$sVersion"
            Add-Content $sScript "$(if($Indent){"`t"})Write-LogInfo -LogPath `$sLogFile -Message `"`$((Get-Date).ToString())``tRunning as user [`$([Environment]::UserDomainName)\`$([Environment]::UserName)] on host [`$(`$env:COMPUTERNAME)]`"`n"
        }
        else
        {
            Add-Content $sScript "$(if($Indent){"`t"})## Finalize $name.log, $sType will finish"
            Add-Content $sScript "$(if($Indent){"`t"})Stop-Log -LogPath `$sLogFile -NoExit"
        }
    }

    Add-Content $sScript "<#"
    Add-Content $sScript ".SYNOPSIS"
    Add-Content $sScript "`tA brief description of the $sType.`n"
    Add-Content $sScript ".DESCRIPTION"
    Add-Content $sScript "`tA detailed description of the $sType.`n"
    Add-Content $sScript ".PARAMETER  <Parameter-Name>"
    Add-Content $sScript "`tThe description of a parameter. Add a .PARAMETER keyword for"
    Add-Content $sScript "`teach parameter in the $sType syntax.`n"
    Add-Content $sScript ".EXAMPLE"
    Add-Content $sScript "`tA sample command that uses the $sType, optionally followed"
    Add-Content $sScript "`tby sample output and a description. Repeat this keyword for each example.`n"
    Add-Content $sScript ".INPUTS"
    Add-Content $sScript "`tThe Microsoft .NET Framework types of objects that can be piped to the"
    Add-Content $sScript "`t$type. You can also include a description of the input objects.`n"
    Add-Content $sScript ".OUTPUTS"
    Add-Content $sScript "`tThe .NET Framework type of the objects that the cmdlet returns. You can"
    Add-Content $sScript "`talso include a description of the returned objects.`n"
    Add-Content $sScript ".NOTES"
    Add-Content $sScript "`tVersion:`t`t$sVersion"
    Add-Content $sScript "`tAuthor:`t`t`t$sAuthor"
    Add-Content $sScript "`tCreation Date:`t$(Get-Date -Format dd/MM/yy)"
    Add-Content $sScript "`tPurpose/Change:`tInitial $sType development - $Name.ps1"
    Add-Content $sScript "#>`n"
    Add-Content $sScript "Param`n("
            
    if($Type -like "Orchestrator*")
    {
        Add-Content $sScript "`t#DataBusInput1 description"
        Add-Content $sScript "`t`$DataBusInput1 = `"<Variable>`","
        Add-Content $sScript "`t#DataBusInput2 description"
        Add-Content $sScript "`t`$DataBusInput2 = `"<Variable>`"`n)`n"
        Add-Content $sScript "# IMPORTANT"
        Add-Content $sScript "# http://cireson.com/blog/hitting-limits-and-breaking-through-making-orchestrator-work-for-you/`n"
        Add-Content $sScript "# Use snippets for function and more.. - Ctrl + J`n"
    }
    else
    {
        Add-Content $sScript "`t#Param1 description"
        Add-Content $sScript "`t[Parameter(Mandatory=`$true)]"
        Add-Content $sScript "`t[String]`$Param1`n)`n"    
    }

    Add-Content $sScript "# Stop $sType if an exception occour"
    Add-Content $sScript "`$ErrorActionPreference = `"Stop`"`n"

    if($Logging)
    {
        LogContent -Initial
    }            

    ## Used as return data

    if($ComputerName -ne "") 
    {
        # Adding return data variables 
        Add-Content $sScript "# Return data variables"
        Add-Content $sScript "`$sResultStatus = `"`""
        Add-Content $sScript "`$sErrorMessage = `"`""
        Add-Content $sScript "`$sLogText = `"`"`n"

        if($sType -like "Orchestrator*")
        {
            # Adding argument array for passing data from Orchestrator databus data
            Add-Content $sScript "# Create argument array for passing data bus inputs to the external script session"
            Add-Content $sScript "`$argsArray = @()"
            Add-Content $sScript "`$argsArray += `$DataBusInput1"
            Add-Content $sScript "`$argsArray += `$DataBusInput2`n"
        }
        else
        {
            # Adding argument array for passing data
            Add-Content $sScript "# Create argument array for passing data bus inputs to the external script session"
            Add-Content $sScript "`$argsArray = @()"
            Add-Content $sScript "`$argsArray += `$Param1`n"
        }                            

        # Adding session variable
        Add-Content $sScript "# Establish an external session (to DC) to ensure 64bit PowerShell runtime using the latest version of PowerShell installed on the DC"
        Add-Content $sScript "`$cn = `"$ComputerName`""
        Add-Content $sScript "`$session = New-PSSession -ComputerName `$cn`n"

        # Adding remote code
        Add-Content $sScript "# Invoke-Command used to run scriptcode in the external session. Return data are stored in the `$returnArray variable"
        Add-Content $sScript "`$returnArray = Invoke-Command -Session `$session -ArgumentList `$argsArray  -ScriptBlock {`n"
        Add-Content $sScript "`t# Define a parameter to accept each data bus input value. Recommend matching names of parameters and data bus input variables above"
        Add-Content $sScript "`tParam("

        if($sType -like "Orchestrator*")
        {
            Add-Content $sScript "`t`t[ValidateNotNullOrEmpty()]"
            Add-Content $sScript "`t`t[String]`$DataBusInput1,"
            Add-Content $sScript "`t`t[ValidateNotNullOrEmpty()]"
            Add-Content $sScript "`t`t[String]`$DataBusInput2`n`t)`n"
        }
        else
        {
            Add-Content $sScript "`t`t[ValidateNotNullOrEmpty()]"
            Add-Content $sScript "`t`t[String]`$Param1`n`t)`n"
        }

        Add-Content $sScript "`ttry`n`t{"
        Add-Content $sScript "`t`t# Add details to trace log"
        Add-Content $sScript "`t`t`$rLogText += `$((Get-Date).ToString()) + `"``tScript now executing in external PowerShell version [`$(`$PSVersionTable.PSVersion.ToString())] session in a [`$([IntPtr]::Size * 8)] bit process``r``n`""
        Add-Content $sScript "`t`t`$rLogText += `$((Get-Date).ToString()) + `"``tRunning as user [`$([Environment]::UserDomainName)\`$([Environment]::UserName)] on host [`$(`$env:COMPUTERNAME)]``r``n`"`n"
        Add-Content $sScript "`t`t## <code goes here>`n"
        Add-Content $sScript "`t`t`$rResultStatus = `"Success`""
        Add-Content $sScript "`t}`n"
        Add-Content $sScript "`tcatch`n`t{"
        Add-Content $sScript "`t`t`$rResultStatus = `"Failed`""
        Add-Content $sScript "`t`t`$rErrorMessage = `$error[0].Exception.Message"
        Add-Content $sScript "`t`t`$rLogText += `$((Get-Date).ToString() + `"``tException caught: `$rErrorMessage``r``n`")"
        Add-Content $sScript "`t}`n"
        Add-Content $sScript "`t# Return an array of the results."
        Add-Content $sScript "`t`$resultArray = @()"
        Add-Content $sScript "`t`$resultArray += `$rResultStatus"
        Add-Content $sScript "`t`$resultArray += `$rErrorMessage"
        Add-Content $sScript "`t`$resultArray += `$rLogText"
        Add-Content $sScript "`treturn `$resultArray"
        Add-Content $sScript "}`n"
        Add-Content $sScript "# Get the values returned from script session for publishing to data bus"
        Add-Content $sScript "`$sResultStatus = `$returnArray[0]"
        Add-Content $sScript "`$sErrorMessage = `$returnArray[1]"
        Add-Content $sScript "`$sLogText += `$returnArray[2]`n"
        Add-Content $sScript "Write-LogInfo -LogPath `$sLogFile -Message `$sLogText`n"
        Add-Content $sScript "# Close the external session"
        Add-Content $sScript "Remove-PSSession `$Session`n"
    }
            
    if($Logging)
    {
        LogContent
    }
  
    ise $sScript
}

# SIG # Begin signature block
# MIIPSAYJKoZIhvcNAQcCoIIPOTCCDzUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU4VhsPm5XK4ofXBXRUtvkV39b
# nvCgggyvMIIGEDCCBPigAwIBAgITMAAAACpnbAZ3NwLCSQAAAAAAKjANBgkqhkiG
# 9w0BAQUFADBGMRMwEQYKCZImiZPyLGQBGRYDbmV0MRgwFgYKCZImiZPyLGQBGRYI
# ZWNjb2NvcnAxFTATBgNVBAMTDEVDQ08gUm9vdCBDQTAeFw0xNjAyMDUwNzMxMzRa
# Fw0yMjAyMDUwNzQxMzRaMEsxEzARBgoJkiaJk/IsZAEZFgNuZXQxGDAWBgoJkiaJ
# k/IsZAEZFghlY2NvY29ycDEaMBgGA1UEAxMRRUNDTyBJc3N1aW5nIENBIDIwggEi
# MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDRip52iBQlWT8qIN+ak0QzRJ6d
# LdLikRkFKtLp2DQlx7yC/9L4l+gXa/0DEmvvVfx5hWiY38IaCFEJ5cD4LEzNAn7p
# 85F9J+RXgswlVJIYh1IZ0odEjnWN3amGySTznHtqcsmMAVeOp+YNaKoeupFBaq79
# sm8EvhE3bbwU25I57BKnZ/r72FMBqXXsvgHoLs+wBhUWDh6TEGwyCjgykA+Ve3WJ
# PimuVu1o/AMN4CP89VMitHcGe+dh9bA/WGUm7weHtCLKGm2SjSAdl5JU/8p+ElA0
# BuAg3K4ZCxJn04Ay8/OPHVXLd4Hws2qKCWQOQZJ3CIGz+kv1gWS5WC8fw75xAgMB
# AAGjggLwMIIC7DAQBgkrBgEEAYI3FQEEAwIBAjAjBgkrBgEEAYI3FQIEFgQUsEgv
# YdPesnynh6crqATvWxYCcSwwHQYDVR0OBBYEFKu4DJf1/NKT7bctI5su/7e/CuON
# MDsGCSsGAQQBgjcVBwQuMCwGJCsGAQQBgjcVCPu9RofHhWCJjyGHnMxpge+ZNnqG
# 3O00gqyKYAIBZAIBAzALBgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNV
# HSMEGDAWgBQ7KkBMT7g2WRcc+DDBVJS5UPWQGzCB/gYDVR0fBIH2MIHzMIHwoIHt
# oIHqhixodHRwOi8vcGtpLmVjY28uY29tL3BraS9FQ0NPJTIwUm9vdCUyMENBLmNy
# bIaBuWxkYXA6Ly8vQ049RUNDTyUyMFJvb3QlMjBDQSxDTj1ES0hRQ0EwMSxDTj1D
# RFAsQ049UHVibGljJTIwS2V5JTIwU2VydmljZXMsQ049U2VydmljZXMsQ049Q29u
# ZmlndXJhdGlvbixEQz1lY2NvY29ycCxEQz1uZXQ/Y2VydGlmaWNhdGVSZXZvY2F0
# aW9uTGlzdD9iYXNlP29iamVjdENsYXNzPWNSTERpc3RyaWJ1dGlvblBvaW50MIIB
# FQYIKwYBBQUHAQEEggEHMIIBAzBOBggrBgEFBQcwAoZCaHR0cDovL3BraS5lY2Nv
# LmNvbS9wa2kvREtIUUNBMDEuZWNjb2NvcnAubmV0X0VDQ08lMjBSb290JTIwQ0Eu
# Y3J0MIGwBggrBgEFBQcwAoaBo2xkYXA6Ly8vQ049RUNDTyUyMFJvb3QlMjBDQSxD
# Tj1BSUEsQ049UHVibGljJTIwS2V5JTIwU2VydmljZXMsQ049U2VydmljZXMsQ049
# Q29uZmlndXJhdGlvbixEQz1lY2NvY29ycCxEQz1uZXQ/Y0FDZXJ0aWZpY2F0ZT9i
# YXNlP29iamVjdENsYXNzPWNlcnRpZmljYXRpb25BdXRob3JpdHkwDQYJKoZIhvcN
# AQEFBQADggEBAIEXlJyIDAVMqSGrleaJmrbgh+dmRssUUUwQQCvtiwTofJrzPCNy
# DWOcEtnXgor83DZW6sU4AUsMFi1opz9GAE362toR//ruyi9cF0vLIh6W60cS2m/N
# vGvgKz7bb235J4tWi0Jj9sCZQ8sFBI61uIlmYiryTEA2bOdAZ5fQX1wide0qCDMi
# CU3yNz4b9VZ7nmB95WKzJ1ZvPjVfTyHBdtK9fhRU/IiJORKzlbMyPxortpCnb0VK
# O/uLYMD4itTk2QxTxx4ZND2Vqi2uJ0dMNO79ELfZ9e9C9jaW2JfEsCxy1ooHsjki
# TpJ+9fNJO7Ws3xru/gINd+G1KdCRG1vYgpswggaXMIIFf6ADAgECAhNYACe/37gE
# fPQoHYROAAIAJ7/fMA0GCSqGSIb3DQEBBQUAMEsxEzARBgoJkiaJk/IsZAEZFgNu
# ZXQxGDAWBgoJkiaJk/IsZAEZFghlY2NvY29ycDEaMBgGA1UEAxMRRUNDTyBJc3N1
# aW5nIENBIDIwHhcNMTYwMjI5MDkzMzUzWhcNMTgwMjI4MDkzMzUzWjCBhjETMBEG
# CgmSJomT8ixkARkWA25ldDEYMBYGCgmSJomT8ixkARkWCGVjY29jb3JwMRMwEQYK
# CZImiZPyLGQBGRYDcHJkMSMwIQYDVQQLExpTZXJ2aWNlIGFuZCBBZG1pbiBBY2Nv
# dW50czEbMBkGA1UEAxMSQWRtaW4tUGFsbGUgSmVuc2VuMIIBIjANBgkqhkiG9w0B
# AQEFAAOCAQ8AMIIBCgKCAQEAxmqcSpu1qSLe7vVysjMibrbQeaV9PHz7MMPazFm2
# 5FKRmuCylaMRRZhCfRVRX06qbEVDjujD+ZKd0NJv8SpNO45ibfh5xSguZwHNQByq
# LN3S/VVcjtpuyX5yygzKSMwEzdj/dHCUGl2Aczvg5NmU1y8RTCsLYqj+V1bokAr2
# +nwqWTkZyRd/eoqGsND2DONyIJ2ApXbFnHwcpSq9mgAbbOvMFeyTay07MPUmB+2i
# AnCvr1Uv9YNhsNf3rwDrnYBJCQsZxnRkUBLhzjbb8jfGQUSYdQcjYlFJ2SQWg4Un
# r5w/xY5Tch8gg5G0n3MEdvWLH0YCB0/3r3X4Cw4b/eXJvwIDAQABo4IDNjCCAzIw
# OwYJKwYBBAGCNxUHBC4wLAYkKwYBBAGCNxUI+71Gh8eFYImPIYeczGmB75k2eobL
# pxuE5NYXAgFkAgEJMBMGA1UdJQQMMAoGCCsGAQUFBwMDMA4GA1UdDwEB/wQEAwIH
# gDAbBgkrBgEEAYI3FQoEDjAMMAoGCCsGAQUFBwMDMB0GA1UdDgQWBBQwtdTxDNLj
# LTzwsstoDiLwyETyZDAfBgNVHSMEGDAWgBSruAyX9fzSk+23LSObLv+3vwrjjTCC
# AQ4GA1UdHwSCAQUwggEBMIH+oIH7oIH4hjNodHRwOi8vcGtpLmVjY28uY29tL3Br
# aS9FQ0NPJTIwSXNzdWluZyUyMENBJTIwMi5jcmyGgcBsZGFwOi8vL0NOPUVDQ08l
# MjBJc3N1aW5nJTIwQ0ElMjAyLENOPURLSFFDQTAzLENOPUNEUCxDTj1QdWJsaWMl
# MjBLZXklMjBTZXJ2aWNlcyxDTj1TZXJ2aWNlcyxDTj1Db25maWd1cmF0aW9uLERD
# PWVjY29jb3JwLERDPW5ldD9jZXJ0aWZpY2F0ZVJldm9jYXRpb25MaXN0P2Jhc2U/
# b2JqZWN0Q2xhc3M9Y1JMRGlzdHJpYnV0aW9uUG9pbnQwggEmBggrBgEFBQcBAQSC
# ARgwggEUMFgGCCsGAQUFBzAChkxodHRwOi8vcGtpLmVjY28uY29tL3BraS9ES0hR
# Q0EwMy5lY2NvY29ycC5uZXRfRUNDTyUyMElzc3VpbmclMjBDQSUyMDIoMikuY3J0
# MIG3BggrBgEFBQcwAoaBqmxkYXA6Ly8vQ049RUNDTyUyMElzc3VpbmclMjBDQSUy
# MDIsQ049QUlBLENOPVB1YmxpYyUyMEtleSUyMFNlcnZpY2VzLENOPVNlcnZpY2Vz
# LENOPUNvbmZpZ3VyYXRpb24sREM9ZWNjb2NvcnAsREM9bmV0P2NBQ2VydGlmaWNh
# dGU/YmFzZT9vYmplY3RDbGFzcz1jZXJ0aWZpY2F0aW9uQXV0aG9yaXR5MDUGA1Ud
# EQQuMCygKgYKKwYBBAGCNxQCA6AcDBpBZG1pbi1QSkVAcHJkLmVjY29jb3JwLm5l
# dDANBgkqhkiG9w0BAQUFAAOCAQEATns0EOsQVL2xSjiETgb3or1+8QvtwV08E0eR
# pFVAwUrQLRav/a4LYobrHm0zIZ2qg5Zswk9PdQpFN3SjNKNGfBTRWOTJeqQq7GBF
# WlZeA6KCmT17KZYj3omSOOYzrAOnG1l2DaX+z14HIGwdJRZHKL23S2okPyEWumYN
# cSoyear7Tmaqxt0WrQtx+xfUB8dlURzU6cSrCzYDhh73jzrPucID8g2HsXdXgoRx
# X/TNIEY7HY7HWQxIiQxjuv9zs8NMdokowrVTbgmP6bkLOadCYb7bt9mBJNr17jBk
# +UQOIxT8vFCbgNliBl0+ZrBBjNOmnuOd9a9oZNUVdbwlBj3FpzGCAgMwggH/AgEB
# MGIwSzETMBEGCgmSJomT8ixkARkWA25ldDEYMBYGCgmSJomT8ixkARkWCGVjY29j
# b3JwMRowGAYDVQQDExFFQ0NPIElzc3VpbmcgQ0EgMgITWAAnv9+4BHz0KB2ETgAC
# ACe/3zAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkq
# hkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGC
# NwIBFTAjBgkqhkiG9w0BCQQxFgQUQdPYOcrFJzXgQCJS6+EMIEks4NAwDQYJKoZI
# hvcNAQEBBQAEggEAU3hkUetyYEIYdTQ1tVf+ha45g+ZFknaKgTQUWWpMO36KT8Cc
# E8akJOn/SAFT1D2ZTIqKssjA/WB8mO3dMtq092llZ24yWl8tV1i/EBiWN/R1GMgy
# UUG+QGvV/dVdaNO/oxVS/pFc6+9+LjbMI/mTfiPAzF9TQ1rYtMNHx6ti2eb3NxMX
# b4RQIRcYeKxz+IEfnm8WSHF6XeHnlL5WvZH2K2WxtPKR8JSf934KOmpA80EHqlS8
# QyFNC0LKh5g949xaMvtGDYnxFDnHJXphqlNHcBm2nSYhXMSaj8T3g2JqUqrEQXNv
# rxVVfP1u2+aWWqs+BY/tSk4oOVXtGgkARXSsCg==
# SIG # End signature block
