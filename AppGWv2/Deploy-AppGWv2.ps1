# Deploy-StandardAppGateway.ps1
# Enterprise-level script to deploy Azure Application Gateway v2 (Standard configuration)

[CmdletBinding()]
param(
    # Subscription and Resource Group Parameters
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionName,
    
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $false)]
    [string]$Location,
    
    # Application Gateway Parameters
    [Parameter(Mandatory = $true)]
    [string]$ApplicationGatewayName,
    
    [Parameter(Mandatory = $true)]
    [ValidateSet("Standard_v2", "WAF_v2")]
    [string]$SkuName = "Standard_v2",
    
    [Parameter(Mandatory = $true)]
    [ValidateSet("Standard_v2", "WAF_v2")]
    [string]$SkuTier = "Standard_v2",
    
    # Network Parameters
    [Parameter(Mandatory = $true)]
    [string]$VirtualNetworkName,
    
    [Parameter(Mandatory = $true)]
    [string]$VNetResourceGroupName,
    
    [Parameter(Mandatory = $true)]
    [string]$SubnetName,
    
    # Public IP Parameters (for standard configuration)
    [Parameter(Mandatory = $false)]
    [string]$PublicIPName,
    
    [Parameter(Mandatory = $false)]
    [string]$PublicIPResourceGroupName,
    
    # Private IP Parameters (optional for dual configuration)
    [Parameter(Mandatory = $false)]
    [string]$PrivateIPAddress,
    
    # Configuration Type
    [Parameter(Mandatory = $false)]
    [ValidateSet("PublicOnly", "PrivateOnly", "Both")]
    [string]$ConfigurationType = "PublicOnly",
    
    # Backend Configuration
    [Parameter(Mandatory = $false)]
    [string[]]$BackendAddresses = @(),
    
    [Parameter(Mandatory = $false)]
    [int]$BackendPort = 80,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Http", "Https")]
    [string]$BackendProtocol = "Http",
    
    # Frontend Configuration
    [Parameter(Mandatory = $false)]
    [int]$HttpPort = 80,
    
    [Parameter(Mandatory = $false)]
    [int]$HttpsPort = 443,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableHttps,
    
    # Autoscaling Configuration
    [Parameter(Mandatory = $false)]
    [ValidateRange(0, 125)]
    [int]$MinCapacity = 2,
    
    [Parameter(Mandatory = $false)]
    [ValidateRange(2, 125)]
    [int]$MaxCapacity = 10,
    
    # Availability Zones
    [Parameter(Mandatory = $false)]
    [string[]]$AvailabilityZones = @("1", "2", "3"),
    
    # SSL Configuration
    [Parameter(Mandatory = $false)]
    [string]$SslPolicyType = "Predefined",
    
    [Parameter(Mandatory = $false)]
    [string]$SslPolicyName = "AppGwSslPolicy20220101S",
    
    # WAF Configuration (when SKU is WAF_v2)
    [Parameter(Mandatory = $false)]
    [bool]$EnableWAF = $true,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Detection", "Prevention")]
    [string]$WAFMode = "Detection",
    
    [Parameter(Mandatory = $false)]
    [string]$WAFRuleSetVersion = "3.2",
    
    # Advanced Configuration
    [Parameter(Mandatory = $false)]
    [bool]$EnableHttp2 = $true,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Enabled", "Disabled")]
    [string]$CookieBasedAffinity = "Disabled",
    
    [Parameter(Mandatory = $false)]
    [int]$RequestTimeout = 30,

    [Parameter(Mandatory = $false)]
    [string]$SslCertificateName,

    [Parameter(Mandatory = $false)]
    [string]$KeyVaultSecretId,

     [Parameter(Mandatory = $false)]
    [string]$HttpsListenerName,
    
    # Deployment Options
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath
)



# Import required modules
$moduleBasePath = Join-Path $PSScriptRoot "..\Common-Modules"

Import-Module (Join-Path $moduleBasePath "ValidationHelpers.psm1") -Force
Import-Module (Join-Path $moduleBasePath "ConfigurationHelpers.psm1") -Force

# Main deployment function
function Start-StandardApplicationGatewayDeployment {
    [CmdletBinding()]
    param()
    
    try {
        Write-Host "[char]0x1F680 Starting Azure Application Gateway v2 (Standard) deployment..." -ForegroundColor Cyan
        Write-Host "[char]0x2139 Configuration: $ConfigurationType" -ForegroundColor Blue
        
        # Step 1: Validate Azure connection and subscription
        if (-not (Test-AzureConnection -SubscriptionName $SubscriptionName)) {
            throw "Failed to establish Azure connection"
        }
        
        # Step 2: Validate and create resource group if needed
        if (-not (Test-ResourceGroupExists -ResourceGroupName $ResourceGroupName -Location $Location -CreateIfNotExists)) {
            throw "Failed to validate or create resource group"
        }
        
        # Step 3: Validate virtual network and subnet
        $vnet = Test-VirtualNetworkExists -VNetName $VirtualNetworkName -ResourceGroupName $VNetResourceGroupName
        if (-not $vnet) {
            throw "Virtual network validation failed"
        }
        
        $subnet = Test-SubnetExists -SubnetName $SubnetName -VirtualNetwork $vnet
        if (-not $subnet) {
            throw "Subnet validation failed"
        }
        
        # Step 4: Validate public IP (for PublicOnly or Both configurations)
        $publicIP = $null
        if ($ConfigurationType -eq "PublicOnly" -or $ConfigurationType -eq "Both") {
            $publicIP = Test-PublicIPExists -PublicIPName $PublicIPName -ResourceGroupName $PublicIPResourceGroupName
            if (-not $publicIP) {
                throw "Public IP validation failed"
            }
        }
        
        # Step 5: Validate private IP availability (for PrivateOnly or Both configurations)
        if ($ConfigurationType -eq "PrivateOnly" -or $ConfigurationType -eq "Both") {
            if (-not $PrivateIPAddress) {
                throw "PrivateIPAddress is required for $ConfigurationType configuration"
            }
            
            if (-not (Test-PrivateIPAvailability -PrivateIPAddress $PrivateIPAddress -Subnet $subnet)) {
                throw "Private IP validation failed"
            }
        }
        

        # Step 6: Check if Application Gateway already exists
        $existingAppGw = $null
        if (Test-ApplicationGatewayExists -Name $ApplicationGatewayName -ResourceGroupName $ResourceGroupName) {
            Write-Host "Application Gateway '$ApplicationGatewayName' already exists. Skipping deployment..." -ForegroundColor Yellow
            $existingAppGw = Get-AzApplicationGateway -Name $ApplicationGatewayName -ResourceGroupName $ResourceGroupName

            # Prepare output from existing gateway
            $output = @{
                ApplicationGatewayName = $existingAppGw.Name
                ResourceGroupName      = $existingAppGw.ResourceGroupName
                Location               = $existingAppGw.Location
                ProvisioningState      = $existingAppGw.ProvisioningState
                OperationalState       = $existingAppGw.OperationalState
                PublicIPAddress        = if ($publicIP) { $publicIP.IpAddress } else { "N/A" }
                PrivateIPAddress       = if ($existingAppGw.FrontendIPConfigurations[0].PrivateIPAddress) { $existingAppGw.FrontendIPConfigurations[0].PrivateIPAddress } else { "N/A" }
                SKU                    = "$($existingAppGw.Sku.Name) ($($existingAppGw.Sku.Tier))"
                AutoscaleConfiguration = if ($existingAppGw.AutoscaleConfiguration) { "Min: $($existingAppGw.AutoscaleConfiguration.MinCapacity), Max: $($existingAppGw.AutoscaleConfiguration.MaxCapacity)" } else { "N/A" }
                AvailabilityZones      = if ($existingAppGw.Zones) { $existingAppGw.Zones -join ", " } else { "N/A" }
                HTTP2Enabled           = $existingAppGw.EnableHttp2
                ConfigurationType      = $ConfigurationType
            }

            # Save output to file if specified
            if ($OutputPath) {
                if (-not (Test-Path $OutputPath)) {
                    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
                }
                $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
                $outputFile = Join-Path $OutputPath "standard-appgw-deployment-output-$timestamp.json"
                $output | ConvertTo-Json -Depth 3 | Out-File -FilePath $outputFile -Encoding UTF8
                Write-Host "[char]0x2713 Deployment output saved to: $outputFile" -ForegroundColor Green
            }

            # Display summary
            Write-Host "`n[char]0x1F389 Existing Deployment Summary:" -ForegroundColor Cyan
            $output.GetEnumerator() | ForEach-Object {
                Write-Host "  $($_.Key): $($_.Value)" -ForegroundColor White
            }

            return $existingAppGw
        }


        
        # Step 7: Create Application Gateway configuration components
        Write-Host "`n[char]0x2699 Building Application Gateway configuration..." -ForegroundColor Yellow
        
        # Create IP Configuration
        $gatewayIPConfig = New-ApplicationGatewayIPConfiguration -Name "gatewayIPConfig" -Subnet $subnet
        
        # Create Frontend IP Configurations
        $frontendIPConfigs = @()
        $publicIPConfig = $null
        $privateIPConfig = $null
        
        if ($ConfigurationType -eq "PublicOnly" -or $ConfigurationType -eq "Both") {
            $publicIPConfig = @{
                Name = "publicFrontendIP"
                PublicIP = $publicIP
            }
        }
        
        if ($ConfigurationType -eq "PrivateOnly" -or $ConfigurationType -eq "Both") {
            $privateIPConfig = @{
                Name = "privateFrontendIP"
                Subnet = $subnet
                PrivateIPAddress = $PrivateIPAddress
            }
        }
        
        $frontendIPConfigs = New-ApplicationGatewayFrontendConfiguration `
            -PublicIPConfiguration $publicIPConfig `
            -PrivateIPConfiguration $privateIPConfig `
            -ConfigurationType $ConfigurationType
        
        # Create Frontend Ports
        $frontendPorts = @()
        $httpFrontendPort = New-ApplicationGatewayFrontendPort -Name "HttpPort" -Port $HttpPort
        $frontendPorts += $httpFrontendPort

        if ($EnableHttps) {
            $httpsFrontendPort = New-ApplicationGatewayFrontendPort -Name "HttpsPort" -Port $HttpsPort
            $frontendPorts += $httpsFrontendPort
        }
        
        # Create Backend Configuration
        $backendConfig = New-ApplicationGatewayBackendConfiguration `
            -BackendPoolName "defaultBackendPool" `
            -BackendAddresses $BackendAddresses `
            -BackendPort $BackendPort `
            -Protocol $BackendProtocol `
            -CookieBasedAffinity $CookieBasedAffinity `
            -RequestTimeout $RequestTimeout
        
        # Create HTTP Listeners
        $listeners = @()
        
        # Create HTTP listener for the primary frontend IP
        $primaryFrontendIP = $frontendIPConfigs[0]
        $httpPortObj = $frontendPorts | Where-Object { $_.Name -eq "HttpPort" }

        $httpListener = New-ApplicationGatewayListener `
            -Name "defaultHttpListener" `
            -FrontendIPConfig $primaryFrontendIP `
            -FrontendPort $httpPortObj `
            -Protocol "Http"

        $listeners += $httpListener

        # Create HTTPS listener if enabled
        if ($EnableHttps) {
            if (-not $SslCertificateName) { throw "SslCertificateName is required for HTTPS listener." }
            if (-not $KeyVaultSecretId) { throw "KeyVaultSecretId is required for HTTPS listener." }
            if (-not $HttpsListenerName) { throw "HttpsListenerName is required for HTTPS listener." }

            $httpsPortObj = $frontendPorts | Where-Object { $_.Name -eq "HttpsPort" }

            $sslCert = New-AzApplicationGatewaySslCertificate `
                -Name $SslCertificateName `
                -KeyVaultSecretId $KeyVaultSecretId

            $httpsListener = New-AzApplicationGatewayHttpListener `
                -Name $HttpsListenerName `
                -FrontendIPConfiguration $primaryFrontendIP `
                -FrontendPort $httpsPortObj `
                -Protocol "Https" `
                -SslCertificate $sslCert

            $listeners += $httpsListener
        }

        
        # Create Routing Rules
        $routingRules = @()
        
        $httpRoutingRule = New-ApplicationGatewayRoutingRule `
            -Name "defaultHttpRule" `
            -RuleType "Basic" `
            -HttpListener $httpListener `
            -BackendAddressPool $backendConfig.BackendPool `
            -BackendHttpSettings $backendConfig.HttpSettings `
            -Priority 100
        
        $routingRules += $httpRoutingRule
        
        if ($EnableHttps -and $httpsListener) {
            $httpsRoutingRule = New-ApplicationGatewayRoutingRule `
                -Name "defaultHttpsRule" `
                -RuleType "Basic" `
                -HttpListener $httpsListener `
                -BackendAddressPool $backendConfig.BackendPool `
                -BackendHttpSettings $backendConfig.HttpSettings `
                -Priority 200
            
            $routingRules += $httpsRoutingRule
        }
        
        # Create SKU Configuration
        $sku = New-ApplicationGatewaySku -Name $SkuName -Tier $SkuTier
        
        # Create Autoscale Configuration
        $autoscaleConfig = New-ApplicationGatewayAutoscaleConfiguration -MinCapacity $MinCapacity -MaxCapacity $MaxCapacity
        
        # Create SSL Policy
        $sslPolicy = New-ApplicationGatewaySSLPolicy -PolicyType $SslPolicyType -PolicyName $SslPolicyName
        
        # Create WAF Configuration (if WAF SKU)
        $wafConfig = $null
        if ($SkuTier -eq "WAF_v2") {
            $wafConfig = New-ApplicationGatewayWAFConfiguration `
                -Enabled $EnableWAF `
                -FirewallMode $WAFMode `
                -RuleSetVersion $WAFRuleSetVersion
        }
        
        # Step 8: Deploy Application Gateway
        Write-Host "$([char]0x2699) Deploying Application Gateway..." -ForegroundColor Yellow
        
        if ($WhatIf) {
            Write-Host "$([char]0x2139)WHAT-IF MODE: The following Application Gateway would be created:" -ForegroundColor Cyan
            Write-Host "  Name: $ApplicationGatewayName" -ForegroundColor White
            Write-Host "  Resource Group: $ResourceGroupName" -ForegroundColor White
            Write-Host "  Location: $Location" -ForegroundColor White
            Write-Host "  SKU: $SkuName ($SkuTier)" -ForegroundColor White
            Write-Host "  Configuration Type: $ConfigurationType" -ForegroundColor White
            Write-Host "  Autoscale: $MinCapacity - $MaxCapacity instances" -ForegroundColor White
            Write-Host "  Availability Zones: $($AvailabilityZones -join ', ')" -ForegroundColor White
            Write-Host "  HTTP/2 Enabled: $EnableHttp2" -ForegroundColor White
            
            if ($SkuTier -eq "WAF_v2") {
                Write-Host "  WAF Enabled: $EnableWAF (Mode: $WAFMode)" -ForegroundColor White
            }
            
            Write-Host "$([char]0x2713) What-If deployment completed successfully" -ForegroundColor Green
            return
        }

        
        # Get the User Assigned Identity object
        $userAssignedIdentityResourceId = "/subscriptions/482d2c7b-7de6-45ff-a073-c1ddfc44a3f7/resourcegroups/kasdev-devtest-app-001/providers/Microsoft.ManagedIdentity/userAssignedIdentities/appgw-mi"

        # Create the PSManagedServiceIdentity object
        $identity = New-Object Microsoft.Azure.Commands.Network.Models.PSManagedServiceIdentity
        $identity.Type = "UserAssigned"
        $identity.UserAssignedIdentities = @{}
        $identity.UserAssignedIdentities[$userAssignedIdentityResourceId] = `
            New-Object Microsoft.Azure.Commands.Network.Models.PSManagedServiceIdentityUserAssignedIdentitiesValue


        $appGwParams = @{
            Name                         = $ApplicationGatewayName
            ResourceGroupName            = $ResourceGroupName
            Location                     = $Location
            BackendAddressPools          = $backendConfig.BackendPool
            BackendHttpSettingsCollection= $backendConfig.HttpSettings
            FrontendIpConfigurations     = $frontendIPConfigs
            GatewayIpConfigurations      = $gatewayIPConfig
            FrontendPorts                = $frontendPorts
            HttpListeners                = $listeners
            RequestRoutingRules          = $routingRules
            Sku                          = $sku
            AutoscaleConfiguration       = $autoscaleConfig
            SslPolicy                    = $sslPolicy
            EnableHttp2                  = $EnableHttp2
            Zone                         = $AvailabilityZones
            Identity                      = $identity
        }

        # Add WAF configuration if applicable
        if ($wafConfig) {
            $appGwParams.WebApplicationFirewallConfiguration = $wafConfig
        }

        # Add SSL certificate if HTTPS is enabled
        if ($EnableHttps -and $sslCert) {
            $appGwParams.SslCertificates = @($sslCert)
        }

        # Deploy the Application Gateway
        $deploymentResult = New-AzApplicationGateway @appGwParams

        Write-Host "$([char]0x2713) Application Gateway '$ApplicationGatewayName' deployed successfully!" -ForegroundColor Green

        # Step 9: Output deployment information
        $output = @{
            ApplicationGatewayName = $deploymentResult.Name
            ResourceGroupName      = $deploymentResult.ResourceGroupName
            Location               = $deploymentResult.Location
            ProvisioningState      = $deploymentResult.ProvisioningState
            OperationalState       = $deploymentResult.OperationalState
            PublicIPAddress        = if ($publicIP) { $publicIP.IpAddress } else { "N/A" }
            PrivateIPAddress       = if ($PrivateIPAddress) { $PrivateIPAddress } else { "N/A" }
            SKU                    = "$($deploymentResult.Sku.Name) ($($deploymentResult.Sku.Tier))"
            AutoscaleConfiguration = "Min: $MinCapacity, Max: $MaxCapacity"
            AvailabilityZones      = $AvailabilityZones -join ", "
            HTTP2Enabled           = $EnableHttp2
            ConfigurationType      = $ConfigurationType
        }
        
        # Save output to file if specified
      


        if ($OutputPath) {
            if (-not (Test-Path "$OutputPath")) {
                New-Item -ItemType Directory -Path "$OutputPath" -Force | Out-Null
            }
            $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
            $outputFile = Join-Path "$OutputPath" "standard-appgw-deployment-output-$timestamp.json"
            $output | ConvertTo-Json -Depth 3 | Out-File -FilePath "$outputFile" -Encoding UTF8
            Write-Host "$(printf '\u2713') Deployment output saved to: $outputFile" -ForegroundColor Green
        }


        
        # Display summary
        Write-Host "`n$(printf '\u1F389') Deployment Summary:" -ForegroundColor Cyan
        $output.GetEnumerator() | ForEach-Object {
            Write-Host "  $($_.Key): $($_.Value)" -ForegroundColor White
        }
        
        return $deploymentResult
    }
    catch {
        Write-Error "Deployment failed: $($_.Exception.Message)"

        throw
    }
}

# Execute deployment
try {
    Start-StandardApplicationGatewayDeployment
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    exit 1
}
