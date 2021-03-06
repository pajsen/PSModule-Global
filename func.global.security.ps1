Function New-EcGlobalPSCredential
{ 
    <#
    .SYNOPSIS
	    Generates a PSCredential object

    .DESCRIPTION
	    Generates a PSCredential object to use for automating, the object contains a FQDN and a SecureString pasword

    .PARAMETER  AccountName
	    FQDN of the account to use with the PSCredentials

    .EXAMPLE
        New-EcGlobalPSCredential -AccountName prd\pje

        Create PSCredential object for user pje

    .INPUTS
	    String

    .OUTPUTS
	    System.Management.Automation.PSCredential Object

    .NOTES
	    Version:        1.0.0
	    Author:         Admin-PJE
	    Creation Date:  28/04/16
        Module Script:  func.global.security
	    Purpose/Change: Initial function development
    #>

    [CmdletBinding()]

    param 
    (
        [String]$AccountName
    )

    $path = 'c:\windows\temp\PSCred.ps1'
    New-Item -ItemType File $path -Force -ErrorAction SilentlyContinue

    $pwd = Read-Host 'Enter Password' -AsSecureString
     
    $key = 1..32 | ForEach-Object { Get-Random -Maximum 256 }  
    $pwdencrypted = $pwd | ConvertFrom-SecureString -Key $key 
     
    # Convert to Strings
    $password = "{0}" -f $pwdencrypted
    $key = "{0}" -f "$key"
    
    # Convert password String to SecureString
    $passwordSecure = ConvertTo-SecureString -String $password -Key ([Byte[]]$key.Split(" "))

    # Create credential object
    $cred = New-Object system.Management.Automation.PSCredential($accountName, $passwordSecure)
  
    Write-Output $cred
}

Function New-EcGlobalPSCredentialSnippet
{
    <#
    .SYNOPSIS
	    Generate snippet with PSCredential Object
    
    .DESCRIPTION
	    Generate snippet with PSCredential Object to use for automating, the object contains a FQDN and a SecureString pasword

    .PARAMETER  Name
	    Name of the snippet 

    .PARAMETER  AccountName
	    FQDN of the account to use with the PSCredentials

    .EXAMPLE
        New-EcGlobalPSCredentialSnippet -Name MyAutomationCred -AccountName prd\account

        Create PSCredential snippet

    .INPUTS
	    String

    .OUTPUTS
        .ps1 file
	    .ps1xml file

    .NOTES
	    Version:        1.0.0
	    Author:         Admin-PJE
	    Creation Date:  28/04/16
        Module Script:  func.global.security
	    Purpose/Change: Initial function development
    #>

    [CmdletBinding()]

    param
    (
        [String]$Name,
        [String]$AccountName
    )   

    $author = $env:USERNAME

    # Create temporary file
    $path = 'c:\windows\temp\temp.ps1'
    New-Item -ItemType File $path -Force -ErrorAction SilentlyContinue
    
    # Encrypting password
    $pwd = Read-Host 'Enter Password' -AsSecureString
    $key = 1..32 | ForEach-Object { Get-Random -Maximum 256 }
    $pwdencrypted = $pwd | ConvertFrom-SecureString -Key $key

    # Convert to Strings
    ('$password = "{0}"' -f $pwdencrypted) | Out-File $path
    ('$key = "{0}"' -f "$key") | Out-File $path -Append

    # convert password to SecureString
    '$passwordSecure = ConvertTo-SecureString -String $password -Key ([Byte[]]$key.Split(" "))' | Out-File $path -Append

    # Create credential object
    ('$cred = New-Object system.Management.Automation.PSCredential("{0}", $passwordSecure)' -f $accountName) | Out-File $path -Append
  
    $txt = @'
'@
    
    # Get content from temporary file 
    Get-Content $path | foreach {$txt += "$($_)`n"}

    # Create snippet
    New-IseSnippet -Force -Title $name -Description "Encrypted Credential" -Author $author -CaretOffset 100 -Text $txt
}

Function New-EcGlobalScriptSigning
{
    <#
    .SYNOPSIS
	    Sign Remote Script with coorporate code signing Certificate.

    .PARAMETER  GlobalPath
	    The full script path  - \\prd.eccocorp.net\it\Automation\Repository\Modules\Ecco.Global\1.0.0\func.global.security.ps1. 

    .EXAMPLE
        New-EccoPSScriptSigning -GlobalPath \\prd.eccocorp.net\it\Automation\Repository\Modules\Ecco.Global\1.0.0\func.global.security.ps1

        Signing script with coorporate code signing certificate

    .INPUTS
	    String

    .NOTES
	    Version:        1.0.0
	    Author:         Admin-PJE
	    Creation Date:  01/09/15
        Module Script:  func.global.security
	    Purpose/Change: Initial function development
    #>
	
	param
    (
		[String]$GlobalPath
	)

	$cert = @(Get-ChildItem cert:\CurrentUser\My -codesigning)[0]
	Set-AuthenticodeSignature $globalPath $cert	
}

Function Test-EcGlobalWSMan
{
    <#
    .SYNOPSIS
	    Tests if the WinRM service is running on a remote computer 

    .EXAMPLE
        "DKHQSCORCH01","DK4836" | Test-EcGlobalWSMan

    .EXAMPLE
        Test-EcGlobalWSMan $(Get-Content c:\computers.txt)

    .INPUTS
	    String
    
    .OUTPUTS
        PSObject

    .NOTES
	    Version:        1.0.0
	    Author:         Admin-PJE
	    Creation Date:  01/09/15
        Module Script:  func.global.security
	    Purpose/Change: Initial function development
    #>

    [CmdletBinding()]
    
    param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true)]
        [String[]]$Computername
    )

    process
    {
        foreach ($c in $Computername)
        {
            $props = [Ordered]@{}
            $props.add('Computername',$c)
	        
            if(!(Test-WSMan -ComputerName $c -ErrorAction Ignore))
            {
                $props.add('WSManEnabled',$false)
	        }

	        else 
            {
                $props.add('WSManEnabled',$true)
            }

            $obj = New-Object -TypeName PSObject -Property $props
            Write-output $obj
        }
    }  
}

Function New-EcGlobalRandomPassword
{
    <#
    .SYNOPSIS
	    Generates a new password
    
    .DESCRIPTION
	    Generates a new password with a length of 12 characters

    .EXAMPLE
        New-EcGlobalRandomPassword

    .INPUTS
	    None
    
    .OUTPUTS
        Password String

    .NOTES
	    Version:        1.0.0
	    Author:         Admin-PJE
	    Creation Date:  01/09/15
        Module Script:  func.global.security
	    Purpose/Change: Initial function development
    #>

    Param
    (
        [int]$length = 12
    )

    #ASCII Password characters for New-Pass function
    $ascii = @()

    For ($a = 48;$a -le 122;$a++) 
    {
        $ascii += ,[char][byte]$a
    }

    For ($loop = 1; $loop -le $length; $loop++)
    {
        $psw += ($ascii | Get-Random -SetSeed (Get-Random))
    }
    
    $psw
}

# SIG # Begin signature block
# MIIPSAYJKoZIhvcNAQcCoIIPOTCCDzUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUwnFfeFNxYyw7zGHsICus79eT
# DHGgggyvMIIGEDCCBPigAwIBAgITMAAAACpnbAZ3NwLCSQAAAAAAKjANBgkqhkiG
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
# NwIBFTAjBgkqhkiG9w0BCQQxFgQUVnWd0WJbaX36K4AFSp7tP1WRn6MwDQYJKoZI
# hvcNAQEBBQAEggEAOaql7rS+mYZdyDf6kL/1klwiS2yy0N3BVjJZPlIx2UqRYsIy
# MNAkboEJAfRZoiGlNSkgqm0w6nyTP7axvdiNKOLZyZLWexRhd1fL1F9QueeW0rPd
# 7PLQt/DqLThxhFwMM/px6ZjwoarnGSE4c22dFrH+LmrH9XF4TV5ogiUXIzGgSaHe
# vg4N5lU68Y7tmdXIOsom1KjH6WQjZk7F3tozJM7iAF4XitvEaJ/535ko20LI9BR5
# 5wMULIaaFkq86RyILvUEGHs3xQrFbnMNWK6LYRRCBLSiVm9fNEwSaNNZQOuDNajz
# JmtgyBo9rELk34IlGnhp86uHnzYuaoC636RJbA==
# SIG # End signature block
