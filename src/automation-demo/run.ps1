$resourceGroups = Get-AzResourceGroup

for ($i = 0; $i -lt $resourceGroups.Count; $i++) {
    $resourceGroup = $resourceGroups[$i]
    if ($null -eq $resourceGroup.tags) {
        continue
    }

    $listResourceGroup = $resourceGroup.tags.ContainsKey("list") ? $resourceGroup.tags["list"] : "false"

    if ([boolean]::Parse($listResourceGroup) -eq $true) {
        $resourceGroupName = $resourceGroup.ResourceGroupName
        $resourceGroupResources = Get-AzResource -ResourceGroupName $resourceGroupName

        Write-Host "----------------------------------"
        Write-Host "Resource Group: $resourceGroupName"
        Write-Host "Resource Group Resources:"
        for ($j = 0; $j -lt $resourceGroupResources.Count; $j++) {
            $resource = $resourceGroupResources[$j]
            $resourceName = $resource.Name
            $resourceType = $resource.Type
            $resourceLocation = $resource.Location

            Write-Host "Resource Name: $resourceName"
            Write-Host "Resource Type: $resourceType"
            Write-Host "Resource Location: $resourceLocation"
            Write-Host ""
        }
    }
}
