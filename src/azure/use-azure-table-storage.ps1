$ErrorActionPreference = "Stop"

"Installing modules"
Install-Module Az -Force
Install-Module AzTable -Force

"Logging in"
Connect-AzAccount -Identity

Get-AzContext

$storageResourceGroup = "rg-vnet-service-endpoints-demo"
$storageName = "stvnetstorageendpoints"
$operationsTableName = "operations"
$ticksPerDay = [timespan]::FromDays(1).Ticks

"Get Storage context"
$storage = Get-AzStorageAccount -ResourceGroupName $storageResourceGroup -Name $storageName
$context = $storage.Context

New-AzStorageTable -Name $operationsTableName -Context $context -ErrorAction Continue
$operationsTable = (Get-AzStorageTable -Name $operationsTableName -Context $context).CloudTable

$messageNumber = 1
$failureQueue = New-Object System.Collections.Queue
while ($true) {
    $now = Get-Date -AsUtc
    $partitionKey = $now.ToString("yyyy-MM-dd")
    $rowKey = $ticksPerDay - $now.TimeOfDay.Ticks

    $row = [PSCustomObject]@{
        PartitionKey = $partitionKey
        RowKey       = $rowKey
        Properties   = @{ 
            "Message"       = "OK"
            "MessageNumber" = $messageNumber++
            "Timestamp"     = $now
        }
    }

    $success = $false
    try {
        "Adding operation"
        Add-AzTableRow `
            -Table $operationsTable `
            -PartitionKey $row.PartitionKey `
            -RowKey $row.RowKey `
            -Property $row.Properties
        $success = $true
    }
    catch {
        "Failed to add operation"
        $row.Properties["Message"] = $_.Exception.Message
        $failureQueue.Enqueue($row)
    }

    if ($success) {
        while ($failureQueue.Count -gt 0) {
            "Retrying failed operation"
            $failed = $failureQueue.Peek()
            try {
                Add-AzTableRow `
                    -Table $operationsTable `
                    -PartitionKey $failed.PartitionKey `
                    -RowKey $failed.RowKey `
                    -Property $failed.Properties
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