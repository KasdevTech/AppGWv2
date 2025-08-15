# ValidationHelpers.ps1
# Common validation functions for Azure Application Gateway deployment

function Test-AzureConnection {
    <#
    .SYNOPSIS
        Tests Azure PowerShell connection and subscription access
    .PARAMETER SubscriptionName
        The name of the Azure subscription
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionName
    )
    
    try {
        Write-Host "$(printf '\u2139') Validating Azure connection..." -ForegroundColor Blue
        
        # Check if logged in
        $context = Get-AzContext
        if (-not $context) {
            Write-Error "Not logged in to Azure. Please run Connect-AzAccount first."
            return $false
        }
        
        # Set subscription context
        Set-AzContext -SubscriptionName $SubscriptionName -ErrorAction Stop
        Write-Host "$(printf '\u2713') Successfully connected to subscription: $SubscriptionName" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Failed to connect to subscription '$SubscriptionName': $($_.Exception.Message)"
        return $false
    }
}

function Test-ResourceGroupExists {
    <#
    .SYNOPSIS
        Validates if a resource group exists
    .PARAMETER ResourceGroupName
        The name of the resource group
    .PARAMETER Location
        The location to create the resource group if it doesn't exist
    .PARAMETER CreateIfNotExists
        Whether to create the resource group if it doesn't exist
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName,
        
        [Parameter(Mandatory = $false)]
        [string]$Location,
        
        [Parameter(Mandatory = $false)]
        [switch]$CreateIfNotExists
    )
    
    try {
        Write-Host "$(printf '\u2139') Checking resource group: $ResourceGroupName..." -ForegroundColor Blue
        
        $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
        
        if ($rg) {
            Write-Host "$(printf '\u2713') Resource group '$ResourceGroupName' exists in location: $($rg.Location)" -ForegroundColor Green
            return $true
        }
        
        if ($CreateIfNotExists -and $Location) {
            Write-Host "$(printf '\u2139') Creating resource group '$ResourceGroupName' in location: $Location..." -ForegroundColor Yellow
            New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force
            Write-Host "$(printf '\u2713') Resource group '$ResourceGroupName' created successfully" -ForegroundColor Green
            return $true
        }
        
        Write-Error "Resource group '$ResourceGroupName' does not exist"
        return $false
    }
    catch {
        Write-Error "Failed to validate resource group '$ResourceGroupName': $($_.Exception.Message)"
        return $false
    }
}

function Test-VirtualNetworkExists {
    <#
    .SYNOPSIS
        Validates if a virtual network exists and returns its details
    .PARAMETER VNetName
        The name of the virtual network
    .PARAMETER ResourceGroupName
        The resource group containing the virtual network
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$VNetName,
        
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName
    )
    
    try {
        Write-Host "$(printf '\u2139') Validating virtual network: $VNetName in RG: $ResourceGroupName..." -ForegroundColor Blue
        
        $vnet = Get-AzVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
        
        if ($vnet) {
            Write-Host "$(printf '\u2713') Virtual network '$VNetName' found with address space: $($vnet.AddressSpace.AddressPrefixes -join ', ')" -ForegroundColor Green
            return $vnet
        }
        
        Write-Error "Virtual network '$VNetName' not found in resource group '$ResourceGroupName'"
        return $null
    }
    catch {
        Write-Error "Failed to validate virtual network '$VNetName': $($_.Exception.Message)"
        return $null
    }
}

function Test-SubnetExists {
    <#
    .SYNOPSIS
        Validates if a subnet exists and has sufficient address space for Application Gateway
    .PARAMETER SubnetName
        The name of the subnet
    .PARAMETER VirtualNetwork
        The virtual network object
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SubnetName,
        
        [Parameter(Mandatory = $true)]
        [Microsoft.Azure.Commands.Network.Models.PSVirtualNetwork]$VirtualNetwork
    )
    
    try {
        Write-Host "$(printf '\u2139') Validating subnet: $SubnetName..." -ForegroundColor Blue
        
        $subnet = $VirtualNetwork.Subnets | Where-Object { $_.Name -eq $SubnetName }
        
        if ($subnet) {
            # Check if subnet is dedicated to Application Gateway (recommended)
            if ($subnet.IpConfigurations.Count -gt 0) {
                Write-Warning "Subnet '$SubnetName' contains existing IP configurations. Application Gateway works best with dedicated subnets."
            }
            
            Write-Host "$(printf '\u2713') Subnet '$SubnetName' found with address prefix: $($subnet.AddressPrefix)" -ForegroundColor Green
            return $subnet
        }
        
        Write-Error "Subnet '$SubnetName' not found in virtual network '$($VirtualNetwork.Name)'"
        return $null
    }
    catch {
        Write-Error "Failed to validate subnet '$SubnetName': $($_.Exception.Message)"
        return $null
    }
}

function Test-PublicIPExists {
    <#
    .SYNOPSIS
        Validates if a public IP exists for standard Application Gateway
    .PARAMETER PublicIPName
        The name of the public IP
    .PARAMETER ResourceGroupName
        The resource group containing the public IP
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PublicIPName,
        
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName
    )
    
    try {
        Write-Host "$(printf '\u2139') Validating public IP: $PublicIPName..." -ForegroundColor Blue
        
        $publicIP = Get-AzPublicIpAddress -Name $PublicIPName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
        
        if ($publicIP) {
            if ($publicIP.Sku.Name -ne "Standard") {
                Write-Error "Public IP '$PublicIPName' must be Standard SKU for Application Gateway v2"
                return $null
            }
            
            if ($publicIP.PublicIpAllocationMethod -ne "Static") {
                Write-Error "Public IP '$PublicIPName' must use Static allocation for Application Gateway v2"
                return $null
            }
            
            Write-Host "$(printf '\u2713') Public IP '$PublicIPName' validated - SKU: $($publicIP.Sku.Name), Allocation: $($publicIP.PublicIpAllocationMethod)" -ForegroundColor Green
            return $publicIP
        }
        
        Write-Error "Public IP '$PublicIPName' not found in resource group '$ResourceGroupName'"
        return $null
    }
    catch {
        Write-Error "Failed to validate public IP '$PublicIPName': $($_.Exception.Message)"
        return $null
    }
}

function Test-PrivateIPAvailability {
    <#
    .SYNOPSIS
        Tests if a private IP address is available in the specified subnet
    .PARAMETER PrivateIPAddress
        The private IP address to test
    .PARAMETER Subnet
        The subnet object
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PrivateIPAddress,
        
        [Parameter(Mandatory = $true)]
        [Microsoft.Azure.Commands.Network.Models.PSSubnet]$Subnet
    )
    
    try {
        Write-Host "$(printf '\u2139') Checking private IP availability: $PrivateIPAddress..." -ForegroundColor Blue
        
        # Test if IP is available using Test-AzPrivateIPAddressAvailability
        $isAvailable = Test-AzPrivateIPAddressAvailability -ResourceGroupName $Subnet.Id.Split('/')[4] -VirtualNetworkName $Subnet.Id.Split('/')[8] -IPAddress $PrivateIPAddress
        
        if ($isAvailable.Available) {
            Write-Host "$(printf '\u2713') Private IP '$PrivateIPAddress' is available" -ForegroundColor Green
            return $true
        }
        else {
            Write-Error "Private IP '$PrivateIPAddress' is not available. Available IPs: $($isAvailable.AvailableIPAddresses -join ', ')"
            return $false
        }
    }
    catch {
        Write-Error "Failed to test private IP availability '$PrivateIPAddress': $($_.Exception.Message)"
        return $false
    }
}

function Test-PreviewFeatureRegistration {
    <#
    .SYNOPSIS
        Tests if the required preview feature is registered for private Application Gateway
    .PARAMETER FeatureName
        The name of the preview feature
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$FeatureName = "AllowApplicationGatewayPrivateLink"
    )
    
    try {
        Write-Host "$(printf '\u2139') Checking preview feature registration: $FeatureName..." -ForegroundColor Blue
        
        $feature = Get-AzProviderFeature -ProviderNamespace "Microsoft.Network" -FeatureName $FeatureName
        
        if ($feature.RegistrationState -eq "Registered") {
            Write-Host "$(printf '\u2713') Preview feature '$FeatureName' is registered" -ForegroundColor Green
            return $true
        }
        elseif ($feature.RegistrationState -eq "Pending") {
            Write-Warning "Preview feature '$FeatureName' registration is pending. This may take several minutes."
            return $true
        }
        else {
            Write-Error "Preview feature '$FeatureName' is not registered. Please run: Register-AzProviderFeature -ProviderNamespace Microsoft.Network -FeatureName $FeatureName"
            return $false
        }
    }
    catch {
        Write-Error "Failed to check preview feature registration: $($_.Exception.Message)"
        return $false
    }
}

function Test-ApplicationGatewayExists {
    <#
    .SYNOPSIS
        Tests if an Application Gateway with the same name already exists
    .PARAMETER Name
        The name of the Application Gateway
    .PARAMETER ResourceGroupName
        The resource group name
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName
    )
    
    try {
        $appGw = Get-AzApplicationGateway -Name $Name -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
        
        if ($appGw) {
            Write-Warning "Application Gateway '$Name' already exists in resource group '$ResourceGroupName'"
            return $true
        }
        
        return $false
    }
    catch {
        return $false
    }
}

# Export all functions
Export-ModuleMember -Function Test-AzureConnection, Test-ResourceGroupExists, Test-VirtualNetworkExists, Test-SubnetExists, Test-PublicIPExists, Test-PrivateIPAvailability, Test-PreviewFeatureRegistration, Test-ApplicationGatewayExists
