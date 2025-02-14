[CmdletBinding()]
param
(
    [Parameter(Mandatory = $false)]
    [string]
    $AppxPath,

    [Parameter(Mandatory = $false)]
    [string]
    $AppxDepDirPath
)

$Error.Clear();

if (-not $AppxPath) {
    $AppxPath = Join-Path $PSScriptRoot "GamingServices.appxbundle";
}

if (-not (test-path $AppxPath)) {
    Write-Output "ERROR: Appx not found: $AppxPath";
    exit 1;
}
   
if (-not $AppxDepDirPath) {
    $AppxDepDirPath = (get-item $AppxPath).Directory.FullName;
}

$systemVolume = Get-AppxVolume | Where-Object -Property IsSystemVolume -eq $True | Select-Object -First 1;

if (-not $systemVolume) {
    Write-Output "ERROR: System volume not found.";
    exit 1;
}

Write-Output ("System volume found.`n{0}" -f ($systemVolume | Format-List | Out-String).trim());

$systemRoot = [System.IO.path]::GetPathRoot($systemVolume.PackageStorePath);

if (-not $systemRoot) {
    Write-Output "ERROR: System root not found.";
    exit 1;
}

Write-Output "System root found: $systemRoot";

$package = Get-AppxPackage -Name Microsoft.GamingServices* | Sort-Object -Property Version -Descending | Select-Object -First 1;
$isOldPackagePresent = $false;

if ($package) {
    Write-Output ("Version {0} of {1} was found already installed on the PC.`n{2}" -f $package.Version, $package.Name, ($package | Format-List | Out-String).trim());

    $isOldPackagePresent = (([Version]$package.Version -lt [Version]'25.94.27002.0') -or ([Version]$package.Version -eq [Version]'1.43.2002.0'));

    if ($isOldPackagePresent) {
        Write-Output "Uninstalling $($package.PackageFullName) version $($package.Version)";
        remove-appxpackage -allusers $package.PackageFullName -ErrorAction Continue;

        if ($Error) {
            Write-Output "Remove-AppxPackage failed for $($package.PackageFullName)";
        }
        else {
            Write-Output "Remove-AppxPackage completed for $AppxPath";
        }
    }
}
else {
    Write-Output 'No versions of Microsoft.GamingServices were found installed on the PC.';
}

if (($package -eq $null) -or $isOldPackagePresent) {
    Write-Output "Installing $AppxPath Version 25.94.27002.0 Volume $systemRoot";

    $allDepsFound = $TRUE;
    [string[]]$depPackageNames = 'Microsoft.NET.Native.Runtime.2.2', 'Microsoft.NET.Native.Framework.2.2', 'Microsoft.VCLibs.x64.14.00';
    $dependencyPaths = $depPackageNames | ForEach-Object { Join-Path -Path $AppxDepDirPath -ChildPath "$_.appx" };
    ForEach ($dep in $dependencyPaths) { if (-not (test-path $dep)) { $allDepsFound = $FALSE; } };

    if ($allDepsFound) {
        Write-Output "Installing $AppxPath Version 25.94.27002.0 Volume $systemRoot -DependencyPath $dependencyPaths";
        add-appxpackage -forceApplicationShutdown -path $AppxPath -Volume $systemRoot -DependencyPath $dependencyPaths -ErrorAction Continue;
    }
    else {
        Write-Output "Installing $AppxPath Version 25.94.27002.0 Volume $systemRoot";
        add-appxpackage -forceApplicationShutdown -path $AppxPath -Volume $systemRoot -ErrorAction Continue;
    }

    if ($Error) {
        Write-Output "ERROR: Add-AppxPackage failed for $AppxPath";
        $guid = ($error -split ' ' | select -Last 1) -as [Guid];
        if ($guid) {
            Write-Output "Get-AppPackageLog -ActivityID $guid";
            Get-AppPackageLog -ActivityID $guid;
        }
    }
    else {
        Write-Output "Add-AppxPackage completed for $AppxPath";
    }
}
else {
    Write-Output "No installation needed as version $($package.Version) of $($package.Name) was found already installed on the PC.";
}

exit ($Error.Count);

# SIG # Begin signature block
# MIImMgYJKoZIhvcNAQcCoIImIzCCJh8CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCn2ER4Q/oiZ+/i
# NBjooxjk6m+eJvsvD4i2amM+G5/3MqCCC2cwggTvMIID16ADAgECAhMzAAAFp7iP
# +5ddNYTsAAAAAAWnMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTAwHhcNMjQwODIyMTkyNTU3WhcNMjUwNzA1MTkyNTU3WjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQCWGlTKjYt60rB8oNyPWJUGQV2NGwlRXKJg3484q2nJiv9+Frz96fGoXlblIeJ3
# xqQxEoCEDYjjbYClgx31MZcoRqJD0sKjNtYDKA0NiSdOJQut3+HN0rSx74yqobDB
# P8AKAyWANZitUQHnPH1EkTXMdRlnJnD1RtFljMYOJnrxfqrAdtNNxU1pIYYmY6oD
# 8dye81i9RHxSJGEgfMnEIpn/1ySkikTV+NOHFj1QH7+SHZWYNcdgL48QSa1jC30A
# i6MKLh91FOsCsuNU0cTC6z6QkP51l9dU8B+xnvZa2/WzvJhByZnjXS+tVeN2KB5E
# p0seOtuFwvI6KoOXrETKCDg7AgMBAAGjggFuMIIBajAfBgNVHSUEGDAWBgorBgEE
# AYI3PQYBBggrBgEFBQcDAzAdBgNVHQ4EFgQUUhW6zVNwhzmLbscozYppwd8fKxIw
# RQYDVR0RBD4wPKQ6MDgxHjAcBgNVBAsTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEW
# MBQGA1UEBRMNMjMwODY1KzUwMjcwMzAfBgNVHSMEGDAWgBTm/F97uyIAWORyTrX0
# IXQjMubvrDBWBgNVHR8ETzBNMEugSaBHhkVodHRwOi8vY3JsLm1pY3Jvc29mdC5j
# b20vcGtpL2NybC9wcm9kdWN0cy9NaWNDb2RTaWdQQ0FfMjAxMC0wNy0wNi5jcmww
# WgYIKwYBBQUHAQEETjBMMEoGCCsGAQUFBzAChj5odHRwOi8vd3d3Lm1pY3Jvc29m
# dC5jb20vcGtpL2NlcnRzL01pY0NvZFNpZ1BDQV8yMDEwLTA3LTA2LmNydDAMBgNV
# HRMBAf8EAjAAMA0GCSqGSIb3DQEBCwUAA4IBAQAl1cQIQ+FD/ubaWIiMg8wQtEx3
# SksQ5r6qAgferOe6TZ5bmTcMj2VUkHLrvmhScoRe9pQ/CqwZ676YuM90tiqPrMDj
# XO8kLCA+kTeDZoKQL0MI2ShbDhXrDIsui9hGNhd8PwGTWQksnoO4HxqGG2Mfiqsn
# OgMo9HimmTF2/H1XLc/g2TPpF8GyXAco7khch4l1hIIpmVEZN6ZFCk2/kOf7m2sC
# l8h5+BWQDmSaECtI2xc5SLbqot1isWvFiERtaw9xQb31MWYas2l2/XdcbH7QFYpK
# pG4dDZhKIdlRVmYpUyRaNOZWNwNc7G6bzKIC3HAGFOIEc4aDQu2yT/q0yJ7WMIIG
# cDCCBFigAwIBAgIKYQxSTAAAAAAAAzANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UE
# BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0
# IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IDIwMTAwHhcNMTAwNzA2MjA0MDE3
# WhcNMjUwNzA2MjA1MDE3WjB+MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
# Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
# cmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQgQ29kZSBTaWduaW5nIFBDQSAyMDEw
# MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA6Q5kUHlntcTj/QkATJ6U
# rPdWaOpE2M/FWE+ppXZ8bUW60zmStKQe+fllguQX0o/9RJwI6GWTzixVhL99COMu
# K6hBKxi3oktuSUxrFQfe0dLCiR5xlM21f0u0rwjYzIjWaxeUOpPOJj/s5v40mFfV
# HV1J9rIqLtWFu1k/+JC0K4N0yiuzO0bj8EZJwRdmVMkcvR3EVWJXcvhnuSUgNN5d
# pqWVXqsogM3Vsp7lA7Vj07IUyMHIiiYKWX8H7P8O7YASNUwSpr5SW/Wm2uCLC0h3
# 1oVH1RC5xuiq7otqLQVcYMa0KlucIxxfReMaFB5vN8sZM4BqiU2jamZjeJPVMM+V
# HwIDAQABo4IB4zCCAd8wEAYJKwYBBAGCNxUBBAMCAQAwHQYDVR0OBBYEFOb8X3u7
# IgBY5HJOtfQhdCMy5u+sMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsGA1Ud
# DwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFNX2VsuP6KJcYmjR
# PZSQW9fOmhjEMFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwubWljcm9zb2Z0
# LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNy
# bDBaBggrBgEFBQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93d3cubWljcm9z
# b2Z0LmNvbS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3J0MIGd
# BgNVHSAEgZUwgZIwgY8GCSsGAQQBgjcuAzCBgTA9BggrBgEFBQcCARYxaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL1BLSS9kb2NzL0NQUy9kZWZhdWx0Lmh0bTBABggr
# BgEFBQcCAjA0HjIgHQBMAGUAZwBhAGwAXwBQAG8AbABpAGMAeQBfAFMAdABhAHQA
# ZQBtAGUAbgB0AC4gHTANBgkqhkiG9w0BAQsFAAOCAgEAGnTvV08pe8QWhXi4UNMi
# /AmdrIKX+DT/KiyXlRLl5L/Pv5PI4zSp24G43B4AvtI1b6/lf3mVd+UC1PHr2M1O
# HhthosJaIxrwjKhiUUVnCOM/PB6T+DCFF8g5QKbXDrMhKeWloWmMIpPMdJjnoUdD
# 8lOswA8waX/+0iUgbW9h098H1dlyACxphnY9UdumOUjJN2FtB91TGcun1mHCv+KD
# qw/ga5uV1n0oUbCJSlGkmmzItx9KGg5pqdfcwX7RSXCqtq27ckdjF/qm1qKmhuyo
# EESbY7ayaYkGx0aGehg/6MUdIdV7+QIjLcVBy78dTMgW77Gcf/wiS0mKbhXjpn92
# W9FTeZGFndXS2z1zNfM8rlSyUkdqwKoTldKOEdqZZ14yjPs3hdHcdYWch8ZaV4XC
# v90Nj4ybLeu07s8n07VeafqkFgQBpyRnc89NT7beBVaXevfpUk30dwVPhcbYC/GO
# 7UIJ0Q124yNWeCImNr7KsYxuqh3khdpHM2KPpMmRM19xHkCvmGXJIuhCISWKHC1g
# 2TeJQYkqFg/XYTyUaGBS79ZHmaCAQO4VgXc+nOBTGBpQHTiVmx5mMxMnORd4hzbO
# TsNfsvU9R1O24OXbC2E9KteSLM43Wj5AQjGkHxAIwlacvyRdUQKdannSF9PawZSO
# B3slcUSrBmrm1MbfI5qWdcUxghohMIIaHQIBATCBlTB+MQswCQYDVQQGEwJVUzET
# MBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMV
# TWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQgQ29kZSBT
# aWduaW5nIFBDQSAyMDEwAhMzAAAFp7iP+5ddNYTsAAAAAAWnMA0GCWCGSAFlAwQC
# AQUAoIHGMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsx
# DjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCD3jSXksZqBp6p/KF86p061
# sxOBnk67luNS6PH4/6OtwDBaBgorBgEEAYI3AgEMMUwwSqAkgCIATQBpAGMAcgBv
# AHMAbwBmAHQAIABXAGkAbgBkAG8AdwBzoSKAIGh0dHA6Ly93d3cubWljcm9zb2Z0
# LmNvbS93aW5kb3dzMA0GCSqGSIb3DQEBAQUABIIBAIYL1j/ramImWRXlGymz0tIK
# V/bda4FXLUmZr5Ch/Shef2EwdziLq+OCZLHq1XM3/dXlQBOz0RmgdmFLcpowaQJ9
# BaNyfmemCVYmc2qnVyMXQ3HEhdss7Ki80XQezADAOWoE4iAHwtoL6ICtSuMHMi+a
# NIOgo4qbPZdmrjqmsqhPlcsheK9ehALyYpzCBAgKcNYH7b2o2syvrX40UY3gJJC0
# bYEkr6hYKtuvSAc1UikBxYsqy/ZiCnKUrR0MInHIhKcTC+GRTDb9Ej07lc5I2wxH
# v1GPLvf0vhtoEfSbg/+9w0fmO6weEa55Xg2gJR9Nq+v6q0E3VhBulB8NcWcsQDSh
# gheTMIIXjwYKKwYBBAGCNwMDATGCF38wghd7BgkqhkiG9w0BBwKgghdsMIIXaAIB
# AzEPMA0GCWCGSAFlAwQCAQUAMIIBUQYLKoZIhvcNAQkQAQSgggFABIIBPDCCATgC
# AQEGCisGAQQBhFkKAwEwMTANBglghkgBZQMEAgEFAAQgt1cuQbGe9U4Pypl8Y4+l
# 6M/v+cFwLEeRYolAmuS+DeYCBmeI++ROehgSMjAyNTAyMDYxNDAzMTguNjlaMASA
# AgH0oIHRpIHOMIHLMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQ
# MA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
# MSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMScwJQYDVQQL
# Ex5uU2hpZWxkIFRTUyBFU046MzcwMy0wNUUwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jv
# c29mdCBUaW1lLVN0YW1wIFNlcnZpY2WgghHqMIIHIDCCBQigAwIBAgITMwAAAeqa
# JHLVWT9hYwABAAAB6jANBgkqhkiG9w0BAQsFADB8MQswCQYDVQQGEwJVUzETMBEG
# A1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWlj
# cm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFt
# cCBQQ0EgMjAxMDAeFw0yMzEyMDYxODQ1MzBaFw0yNTAzMDUxODQ1MzBaMIHLMQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxNaWNy
# b3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBF
# U046MzcwMy0wNUUwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1w
# IFNlcnZpY2UwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQC1C1/xSD8g
# B9X7Ludoo2rWb2ksqaF65QtJkbQpmsc6G4bg5MOv6WP/uJ4XOJvKX/c1t0ej4oWB
# qdGD6VbjXX4T0KfylTulrzKtgxnxZh7q1uD0Dy/w5G0DJDPb6oxQrz6vMV2Z3y9Z
# xjfZqBnDfqGon/4VDHnZhdas22svSC5GHywsQ2J90MM7L4ecY8TnLI85kXXTVESb
# 09txL2tHMYrB+KHCy08ds36an7IcOGfRmhHbFoPa5om9YGpVKS8xeT7EAwW7WbXL
# /lo5p9KRRIjAlsBBHD1TdGBucrGC3TQXSTp9s7DjkvvNFuUa0BKsz6UiCLxJGQSZ
# hd2iOJTEfJ1fxYk2nY6SCKsV+VmtV5aiPzY/sWoFY542+zzrAPr4elrvr9uB6ci/
# Kci//EOERZEUTBPXME/ia+t8jrT2y3ug15MSCVuhOsNrmuZFwaRCrRED0yz4V9wl
# MTGHIJW55iNM3HPVJJ19vOSvrCP9lsEcEwWZIQ1FCyPOnkM1fs7880dahAa5UmPq
# Mk5WEKxzDPVp081X5RQ6HGVUz6ZdgQ0jcT59EG+CKDPRD6mx8ovzIpS/r/wEHPKt
# 5kOhYrjyQHXc9KHKTWfXpAVj1Syqt5X4nr+Mpeubv+N/PjQEPr0iYJDjSzJrqILh
# Bs5pytb6vyR8HUVMp+mAA4rXjOw42vkHfQIDAQABo4IBSTCCAUUwHQYDVR0OBBYE
# FCuBRSWiUebpF0BU1MTIcosFblleMB8GA1UdIwQYMBaAFJ+nFV0AXmJdg/Tl0mWn
# G1M1GelyMF8GA1UdHwRYMFYwVKBSoFCGTmh0dHA6Ly93d3cubWljcm9zb2Z0LmNv
# bS9wa2lvcHMvY3JsL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEw
# KDEpLmNybDBsBggrBgEFBQcBAQRgMF4wXAYIKwYBBQUHMAKGUGh0dHA6Ly93d3cu
# bWljcm9zb2Z0LmNvbS9wa2lvcHMvY2VydHMvTWljcm9zb2Z0JTIwVGltZS1TdGFt
# cCUyMFBDQSUyMDIwMTAoMSkuY3J0MAwGA1UdEwEB/wQCMAAwFgYDVR0lAQH/BAww
# CgYIKwYBBQUHAwgwDgYDVR0PAQH/BAQDAgeAMA0GCSqGSIb3DQEBCwUAA4ICAQAo
# g61WXj9+/nxVbX3G37KgvyoNAnuu2w3HoWZj3H0YCeQ3b9KSZThVThW4iFcHrKnh
# FMBbXJX4uQI53kOWSaWCaV3xCznpRt3c4/gSn3dvO/1GP3MJkpJfgo56CgS9zLOi
# P31kfmpUdPqekZb4ivMR6LoPb5HNlq0WbBpzFbtsTjNrTyfqqcqAwc6r99Df2UQT
# qDa0vzwpA8CxiAg2KlbPyMwBOPcr9hJT8sGpX/ZhLDh11dZcbUAzXHo1RJorSSft
# Va9hLWnzxGzEGafPUwLmoETihOGLqIQlCpvr94Hiak0Gq0wY6lduUQjk/lxZ4EzA
# w/cGMek8J3QdiNS8u9ujYh1B7NLr6t3IglfScDV3bdVWet1itTUoKVRLIivRDwAT
# 7dRH13Cq32j2JG5BYu/XitRE8cdzaJmDVBzYhlPl9QXvC+6qR8I6NIN/9914bTq/
# S4g6FF4f1dixUxE4qlfUPMixGr0Ft4/S0P4fwmhs+WHRn62PB4j3zCHixKJCsRn9
# IR3ExBQKQdMi5auiqB6xQBADUf+F7hSKZfbA8sFSFreLSqhvj+qUQF84Ncxuaxpb
# JWVpsO18IL4Qbt45Cz/QMa7EmMGNn7a8MM3uTQOlQy0u6c/jq111i1JqMjayTceQ
# ZNMBMM5EMc5Dr5m3T4bDj9WTNLgP8SFe3EqTaWVMOTCCB3EwggVZoAMCAQICEzMA
# AAAVxedrngKbSZkAAAAAABUwDQYJKoZIhvcNAQELBQAwgYgxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBSb290
# IENlcnRpZmljYXRlIEF1dGhvcml0eSAyMDEwMB4XDTIxMDkzMDE4MjIyNVoXDTMw
# MDkzMDE4MzIyNVowfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwggIiMA0G
# CSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDk4aZM57RyIQt5osvXJHm9DtWC0/3u
# nAcH0qlsTnXIyjVX9gF/bErg4r25PhdgM/9cT8dm95VTcVrifkpa/rg2Z4VGIwy1
# jRPPdzLAEBjoYH1qUoNEt6aORmsHFPPFdvWGUNzBRMhxXFExN6AKOG6N7dcP2CZT
# fDlhAnrEqv1yaa8dq6z2Nr41JmTamDu6GnszrYBbfowQHJ1S/rboYiXcag/PXfT+
# jlPP1uyFVk3v3byNpOORj7I5LFGc6XBpDco2LXCOMcg1KL3jtIckw+DJj361VI/c
# +gVVmG1oO5pGve2krnopN6zL64NF50ZuyjLVwIYwXE8s4mKyzbnijYjklqwBSru+
# cakXW2dg3viSkR4dPf0gz3N9QZpGdc3EXzTdEonW/aUgfX782Z5F37ZyL9t9X4C6
# 26p+Nuw2TPYrbqgSUei/BQOj0XOmTTd0lBw0gg/wEPK3Rxjtp+iZfD9M269ewvPV
# 2HM9Q07BMzlMjgK8QmguEOqEUUbi0b1qGFphAXPKZ6Je1yh2AuIzGHLXpyDwwvoS
# CtdjbwzJNmSLW6CmgyFdXzB0kZSU2LlQ+QuJYfM2BjUYhEfb3BvR/bLUHMVr9lxS
# UV0S2yW6r1AFemzFER1y7435UsSFF5PAPBXbGjfHCBUYP3irRbb1Hode2o+eFnJp
# xq57t7c+auIurQIDAQABo4IB3TCCAdkwEgYJKwYBBAGCNxUBBAUCAwEAATAjBgkr
# BgEEAYI3FQIEFgQUKqdS/mTEmr6CkTxGNSnPEP8vBO4wHQYDVR0OBBYEFJ+nFV0A
# XmJdg/Tl0mWnG1M1GelyMFwGA1UdIARVMFMwUQYMKwYBBAGCN0yDfQEBMEEwPwYI
# KwYBBQUHAgEWM2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvRG9jcy9S
# ZXBvc2l0b3J5Lmh0bTATBgNVHSUEDDAKBggrBgEFBQcDCDAZBgkrBgEEAYI3FAIE
# DB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNV
# HSMEGDAWgBTV9lbLj+iiXGJo0T2UkFvXzpoYxDBWBgNVHR8ETzBNMEugSaBHhkVo
# dHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNSb29D
# ZXJBdXRfMjAxMC0wNi0yMy5jcmwwWgYIKwYBBQUHAQEETjBMMEoGCCsGAQUFBzAC
# hj5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY1Jvb0NlckF1
# dF8yMDEwLTA2LTIzLmNydDANBgkqhkiG9w0BAQsFAAOCAgEAnVV9/Cqt4SwfZwEx
# JFvhnnJL/Klv6lwUtj5OR2R4sQaTlz0xM7U518JxNj/aZGx80HU5bbsPMeTCj/ts
# 0aGUGCLu6WZnOlNN3Zi6th542DYunKmCVgADsAW+iehp4LoJ7nvfam++Kctu2D9I
# dQHZGN5tggz1bSNU5HhTdSRXud2f8449xvNo32X2pFaq95W2KFUn0CS9QKC/GbYS
# EhFdPSfgQJY4rPf5KYnDvBewVIVCs/wMnosZiefwC2qBwoEZQhlSdYo2wh3DYXMu
# LGt7bj8sCXgU6ZGyqVvfSaN0DLzskYDSPeZKPmY7T7uG+jIa2Zb0j/aRAfbOxnT9
# 9kxybxCrdTDFNLB62FD+CljdQDzHVG2dY3RILLFORy3BFARxv2T5JL5zbcqOCb2z
# AVdJVGTZc9d/HltEAY5aGZFrDZ+kKNxnGSgkujhLmm77IVRrakURR6nxt67I6Ile
# T53S0Ex2tVdUCbFpAUR+fKFhbHP+CrvsQWY9af3LwUFJfn6Tvsv4O+S3Fb+0zj6l
# MVGEvL8CwYKiexcdFYmNcP7ntdAoGokLjzbaukz5m/8K6TT4JDVnK+ANuOaMmdbh
# IurwJ0I9JZTmdHRbatGePu1+oDEzfbzL6Xu/OHBE0ZDxyKs6ijoIYn/ZcGNTTY3u
# gm2lBRDBcQZqELQdVTNYs6FwZvKhggNNMIICNQIBATCB+aGB0aSBzjCByzELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9z
# b2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1MgRVNO
# OjM3MDMtMDVFMC1EOTQ3MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBT
# ZXJ2aWNloiMKAQEwBwYFKw4DAhoDFQCJ2x7cQfjpRskJ8UGIctOCkmEkj6CBgzCB
# gKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
# EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNV
# BAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMA0GCSqGSIb3DQEBCwUA
# AgUA608oBjAiGA8yMDI1MDIwNjEyMjIzMFoYDzIwMjUwMjA3MTIyMjMwWjB0MDoG
# CisGAQQBhFkKBAExLDAqMAoCBQDrTygGAgEAMAcCAQACAiMlMAcCAQACAhNMMAoC
# BQDrUHmGAgEAMDYGCisGAQQBhFkKBAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEA
# AgMHoSChCjAIAgEAAgMBhqAwDQYJKoZIhvcNAQELBQADggEBAAouZgZMiMLnb+pO
# rz9zdFcw4uECkDrlTfmd9GMX1kluQ3M02dNjem1mydagYboUhj3mxwaXxH4Rp8SQ
# tlE3EZ69DYPzbzd7n9a0BvB8P+d2KXkslTrKxYck7t8ow47MpjPUPmUUcjMH1kr7
# e9G9a+VN+fqdaE/13IOMqFb6AOF0kSqR3qTP2E6/tjOjd7rLkCJAWBVuvPPphMVm
# lsycsm1zTuj0ZlFd33agcBYWcO92s05jfgXpCo+Bwac/y8UO+Zc1V89r0jZYSc/p
# gqpyQgPApLOVwG4bzJdPX+kK6bNKISFQaM7gYX3bntLuNp3OyuYfTHBBzjSjT/bh
# R6qcMDgxggQNMIIECQIBATCBkzB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAx
# MAITMwAAAeqaJHLVWT9hYwABAAAB6jANBglghkgBZQMEAgEFAKCCAUowGgYJKoZI
# hvcNAQkDMQ0GCyqGSIb3DQEJEAEEMC8GCSqGSIb3DQEJBDEiBCC3XaaHuIlNqzIU
# 3TSOPertJtmsO9tztGPDcrFKcvV7gzCB+gYLKoZIhvcNAQkQAi8xgeowgecwgeQw
# gb0EICmPodXjZDR4iwg0ltLANXBh5G1uKqKIvq8sjKekuGZ4MIGYMIGApH4wfDEL
# MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1v
# bmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWlj
# cm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAHqmiRy1Vk/YWMAAQAAAeow
# IgQgTXxKTv1VKPtMQyJt8YEg6iCcUijFnZk4gsfdbE/jniEwDQYJKoZIhvcNAQEL
# BQAEggIADWr9E3J6Vt94Yl3Tqbd9/6EEUQ/TsXv7hsbEcTU567wAZjHmzY1o1XLY
# /jbqHP/IQwW25NmnEMcubYSKfusOQfuzhLO55t8CYTTv7Q8xtw5hcmQDUQk/Rj2S
# 4mF9FWmyLgivT/muXCIyTb4mQExZ+IFkX2y6vxu0j1Xs9LPy1ZcrgCc9UEFmH8IE
# SwqdYPfPm8LhRyeLZT/bNFiav35CJyLbHNlGJBRDVhETCrWp8ZcAacymSNPXjUTq
# ElPTX0xk+QRWEN5pAVvLyDkAPg6maC8rz+vTKGD6XZK/SGhgK/HKzIJNHsNtKRnf
# AtSLIkRfis+TzJ6utSTTpKV9MvXF8uq7jKMXmmtnSkRQOkYYylrkj9krSD8mAadm
# mmnYBV2rKH26RP1F5nYMZQRcBAeMG5IGn/hLHz4tGvmLDmqW9qGDYl3OZ7+PI6zg
# KR4uX3cwCVZhVSgtlYfFy2oZXyRkCkL1/3LWp+EYN+oI/VAx34fQ20Apn7TqmRyI
# 0XelF6fGlefycRGrfBL9D1jHjBQS/AxU+E3UiV5YqhlmhUWIvJixrOrtNFvOVjtt
# sJOp4JPZtjzYXMPUgZmfRW1zSukiYoVRidGSFtLHrPzNcZxCMu1W6EG3KNrS1AtS
# VENcqPyq7be9ZhshI8svHkMAy80gV0inT2mP1nZDkhy8rjqJba4=
# SIG # End signature block
