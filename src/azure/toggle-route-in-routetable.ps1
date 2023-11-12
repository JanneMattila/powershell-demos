# Add route to NVA
$routeTable = Get-AzRouteTable -ResourceGroupName "rg-vnet-service-endpoints-demo" -Name "rt-app"
Add-AzRouteConfig -Name "to-nva" -AddressPrefix 0.0.0.0/0 -NextHopType "VirtualAppliance" -NextHopIpAddress 10.10.10.10 -RouteTable $routeTable 
$routeTable | Set-AzRouteTable

Start-Sleep -Seconds 120

# Remove route
$routeTable | Remove-AzRouteConfig -Name "to-nva" | Set-AzRouteTable
