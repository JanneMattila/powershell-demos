#!/usr/bin/env pwsh

$PSStyle.OutputRendering = "PlainText"

@"
Azure PowerShell Job

https://github.com/JanneMattila/powershell-demos/tree/main/src/azure-powershell-job

PowerShell version: $($PSVersionTable.PSVersion)
.NET version: $([System.Runtime.InteropServices.RuntimeInformation]::FrameworkDescription)
"@ > /etc/motd

Get-Content /etc/motd

# Run the main application
. $args[0]
