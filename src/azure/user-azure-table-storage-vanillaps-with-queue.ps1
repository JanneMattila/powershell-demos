$storageName = "stvnetstorageendpoints"
$operationsTableName = "operations"
$ticksPerDay = [timespan]::FromDays(1).Ticks
$messageNumber = 1

$url = "https://$storageName.table.core.windows.net/$operationsTableName"
$headers = @{
    "x-ms-version" = "2023-11-03"
    "Accept"       = "application/json;odata=nometadata"
    "Prefer"       = "return-no-content"
}

$token = Invoke-RestMethod `
    -Headers @{ Metadata = "true" } `
    -Uri "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://$storageName.table.core.windows.net/"
$secureAccessToken = ConvertTo-SecureString -AsPlainText -String $token.access_token

Invoke-RestMethod `
    -Body (ConvertTo-Json @{ "TableName" = "$operationsTableName" }) `
    -ContentType "application/json" `
    -Method "POST" `
    -Authentication Bearer `
    -Headers $headers `
    -Token $secureAccessToken `
    -Uri "https://$storageName.table.core.windows.net/Tables" `
    -ErrorAction SilentlyContinue

$failureQueue = New-Object System.Collections.Queue
while ($true) {
    if ($token.expires_on -lt [DateTimeOffset]::UtcNow.AddMinutes(5).ToUnixTimeSeconds()) {
        "Access token expired"
        $token = Invoke-RestMethod `
            -Headers @{ Metadata = "true" } `
            -Uri "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://$storageName.table.core.windows.net/"
        $secureAccessToken = ConvertTo-SecureString -AsPlainText -String $token.access_token
    }

    
    $data = [PSCustomObject]@{ 
        "PartitionKey"  = Get-Date -AsUtc -Format "yyyy-MM-dd"
        "RowKey"        = [string]($ticksPerDay - (Get-Date -AsUtc).TimeOfDay.Ticks)
        "MessageTime"   = Get-Date -AsUtc
        "Message"       = "OK"
        "MessageNumber" = $messageNumber++
    }

    $success = $false
    try {
        "$(Get-Date) Adding operation $messageNumber"
        $body = ConvertTo-Json $data
        Invoke-RestMethod `
            -Body $body `
            -ContentType "application/json" `
            -Method "POST" `
            -Authentication Bearer `
            -Headers $headers `
            -Token $secureAccessToken `
            -TimeoutSec 5 `
            -Uri $url | Out-Null
        $success = $true
    }
    catch {
        "Failed to add operation"
        $data.Message = $_.Exception.Message
        $failureQueue.Enqueue($data)
    }

    if ($success) {
        while ($failureQueue.Count -gt 0) {
            "Retrying failed operation"
            $failed = $failureQueue.Peek()
            try {
                $body = ConvertTo-Json $failed
                Invoke-RestMethod `
                    -Body $body `
                    -ContentType "application/json" `
                    -Method "POST" `
                    -Authentication Bearer `
                    -Headers $headers `
                    -Token $secureAccessToken `
                    -TimeoutSec 5 `
                    -Uri $url | Out-Null
                $failureQueue.Dequeue()
                "Success"
            }
            catch {
                "Failed"
                break
            }
        }
    }

    Start-Sleep -Seconds 1
}
