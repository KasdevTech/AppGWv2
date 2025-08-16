# Deploy-AppGWv2.ps1
# Enterprise-level script to deploy Azure Application Gateway v2 (Standard configuration)

[CmdletBinding(DefaultParameterSetName = 'Individual')]
param(
    # Parameter Set Mode
    [Parameter(Mandatory = $true, ParameterSetName = 'ParameterSet')]
    [ValidateSet("BasicAppGwParams", "AdvancedAppGwParams")]
    [string]$ParameterSet,
    
    # Configuration Object Mode
    [Parameter(Mandatory = $true, ParameterSetName = 'ConfigurationObject')]
    [hashtable]$AppGatewayConfiguration,
    
    # Subscription and Resource Group Parameters
    [Parameter(Mandatory = $true, ParameterSetName = 'Individual')]
    [string]$SubscriptionName,

    [Parameter(Mandatory = $true, ParameterSetName = 'Individual')]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $false, ParameterSetName = 'Individual')]
    [string]$Location = "East US",

    # Application Gateway Parameters
    [Parameter(Mandatory = $true, ParameterSetName = 'Individual')]
    [string]$ApplicationGatewayName,

    [Parameter(Mandatory = $false, ParameterSetName = 'Individual')]
    [ValidateSet("Standard_v2", "WAF_v2")]
    [string]$SkuName = "Standard_v2",

    [Parameter(Mandatory = $false, ParameterSetName = 'Individual')]
    [ValidateSet("Standard_v2", "WAF_v2")]
    [string]$SkuTier = "Standard_v2",

    [Parameter(Mandatory = $false, ParameterSetName = 'Individual')]
    [ValidateSet("PublicOnly", "PrivateOnly", "Both")]
    [string]$ConfigurationType = "PublicOnly",

    [Parameter(Mandatory = $false, ParameterSetName = 'Individual')]
    [string]$PrivateIPAddress = "",

    [Parameter(Mandatory = $false, ParameterSetName = 'Individual')]
    [int]$MinCapacity = 1,

    [Parameter(Mandatory = $false, ParameterSetName = 'Individual')]
    [int]$MaxCapacity = 2,

    [Parameter(Mandatory = $false, ParameterSetName = 'Individual')]
    [string[]]$AvailabilityZones = @(),

    [Parameter(Mandatory = $false, ParameterSetName = 'Individual')]
    [string]$OutputPath = ".\output",

    [Parameter(Mandatory = $false, ParameterSetName = 'Individual')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ParameterSet')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ConfigurationObject')]
    [switch]$WhatIf = $false,

    # Network Configuration
    [Parameter(Mandatory = $true, ParameterSetName = 'Individual')]
    [string]$VirtualNetworkName,

    [Parameter(Mandatory = $false, ParameterSetName = 'Individual')]
    [string]$VNetResourceGroupName,

    [Parameter(Mandatory = $true, ParameterSetName = 'Individual')]
    [string]$SubnetName,

    [Parameter(Mandatory = $false, ParameterSetName = 'Individual')]
    [string]$PublicIPName,

    [Parameter(Mandatory = $false, ParameterSetName = 'Individual')]
    [string]$PublicIPResourceGroupName,

    # Backend Configuration (Backward Compatibility)
    [Parameter(Mandatory = $false, ParameterSetName = 'Individual')]
    [string]$BackendPoolName = "defaultBackendPool",

    [Parameter(Mandatory = $false, ParameterSetName = 'Individual')]
    [string[]]$BackendTargets = @(),

    [Parameter(Mandatory = $false, ParameterSetName = 'Individual')]
    [string]$HttpListenerName = "defaultHttpListener",

    [Parameter(Mandatory = $false, ParameterSetName = 'Individual')]
    [string]$RoutingRuleName = "defaultRoutingRule",

    [Parameter(Mandatory = $false, ParameterSetName = 'Individual')]
    [string]$BackendHttpSettingsName = "defaultBackendHttpSettings",

    # SSL and Security Configuration
    [Parameter(Mandatory = $false, ParameterSetName = 'Individual')]
    [ValidateSet("Predefined", "Custom")]
    [string]$SslPolicyType = "Predefined",

    [Parameter(Mandatory = $false, ParameterSetName = 'Individual')]
    [string]$SslPolicyName = "AppGwSslPolicy20220101S",

    [Parameter(Mandatory = $false, ParameterSetName = 'Individual')]
    [bool]$EnableWAF = $false,

    [Parameter(Mandatory = $false, ParameterSetName = 'Individual')]
    [ValidateSet("Detection", "Prevention")]
    [string]$WAFMode = "Detection",

    [Parameter(Mandatory = $false, ParameterSetName = 'Individual')]
    [string]$WAFRuleSetVersion = "3.2",

    [Parameter(Mandatory = $false, ParameterSetName = 'Individual')]
    [bool]$EnableHttp2 = $true,

    # Tags
    [Parameter(Mandatory = $false, ParameterSetName = 'Individual')]
    [hashtable]$Tags = @{}
)

# Import required modules
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$commonModulesPath = Join-Path (Split-Path -Parent $scriptPath) "Common-Modules"

try {
    Import-Module (Join-Path $commonModulesPath "ConfigurationHelpers.psm1") -Force
    Import-Module (Join-Path $commonModulesPath "ValidationHelpers.psm1") -Force
    Import-Module (Join-Path $scriptPath "AppGWv2-Parameters.psm1") -Force
    Write-Host "[OK] Modules imported successfully" -ForegroundColor Green
} catch {
    Write-Error "[ERROR] Failed to import required modules: $($_.Exception.Message)"
    exit 1
}

# Load configuration based on parameter set
if ($PSCmdlet.ParameterSetName -eq 'ParameterSet') {
    Write-Host "[CONFIG] Loading configuration from parameter set: $ParameterSet" -ForegroundColor Cyan
    $config = Get-Variable -Name $ParameterSet -ValueOnly -ErrorAction SilentlyContinue
    if (-not $config) {
        Write-Error "[ERROR] Parameter set '$ParameterSet' not found"
        exit 1
    }
} elseif ($PSCmdlet.ParameterSetName -eq 'ConfigurationObject') {
    Write-Host "[CONFIG] Using provided configuration object" -ForegroundColor Cyan
    $config = $AppGatewayConfiguration
} else {
    Write-Host "[CONFIG] Using individual parameters" -ForegroundColor Cyan
    $config = @{
        SubscriptionName = $SubscriptionName
        ResourceGroupName = $ResourceGroupName
        Location = $Location
        ApplicationGatewayName = $ApplicationGatewayName
        SkuName = $SkuName
        SkuTier = $SkuTier
        ConfigurationType = $ConfigurationType
        PrivateIPAddress = $PrivateIPAddress
        MinCapacity = $MinCapacity
        MaxCapacity = $MaxCapacity
        AvailabilityZones = $AvailabilityZones
        OutputPath = $OutputPath
        WhatIf = $WhatIf
        VirtualNetworkName = $VirtualNetworkName
        VNetResourceGroupName = $VNetResourceGroupName
        SubnetName = $SubnetName
        PublicIPName = $PublicIPName
        PublicIPResourceGroupName = $PublicIPResourceGroupName
        BackendPoolName = $BackendPoolName
        BackendTargets = $BackendTargets
        HttpListenerName = $HttpListenerName
        RoutingRuleName = $RoutingRuleName
        BackendHttpSettingsName = $BackendHttpSettingsName
        SslPolicyType = $SslPolicyType
        SslPolicyName = $SslPolicyName
        EnableWAF = $EnableWAF
        WAFMode = $WAFMode
        WAFRuleSetVersion = $WAFRuleSetVersion
        EnableHttp2 = $EnableHttp2
        Tags = $Tags
    }
}

# Extract configuration arrays for multi-configuration deployment
$ConfigListeners = if ($config.Listeners) { $config.Listeners } else { @() }
$ConfigBackendPools = if ($config.BackendPools) { $config.BackendPools } else { @() }
$ConfigBackendSettings = if ($config.BackendSettings) { $config.BackendSettings } else { @() }
$ConfigRoutingRules = if ($config.RoutingRules) { $config.RoutingRules } else { @() }
$ConfigFrontendPorts = if ($config.FrontendPorts) { $config.FrontendPorts } else { @() }
$ConfigSslCertificates = if ($config.SslCertificates) { $config.SslCertificates } else { @() }

# Determine if we're running in simulation mode (Azure modules not available)
$simulationMode = (-not (Get-Module -ListAvailable -Name "Az.Network" -ErrorAction SilentlyContinue))

# WhatIf mode is separate from simulation mode
$whatIfMode = $config.WhatIf

Write-Host "[INFO] Configuration Summary:" -ForegroundColor Yellow
Write-Host "  - Listeners: $($ConfigListeners.Count)" -ForegroundColor White
Write-Host "  - Backend Pools: $($ConfigBackendPools.Count)" -ForegroundColor White
Write-Host "  - Backend Settings: $($ConfigBackendSettings.Count)" -ForegroundColor White
Write-Host "  - Routing Rules: $($ConfigRoutingRules.Count)" -ForegroundColor White
Write-Host "  - Frontend Ports: $($ConfigFrontendPorts.Count)" -ForegroundColor White
Write-Host "  - SSL Certificates: $($ConfigSslCertificates.Count)" -ForegroundColor White
Write-Host "  - HTTPS Enabled: $($config.EnableHttps)" -ForegroundColor White
Write-Host "  - HTTPS Listener: $($config.HttpsListenerName)" -ForegroundColor White
if ($config.UserAssignedIdentities -and $config.UserAssignedIdentities.Count -gt 0) {
    Write-Host "  - Managed Identity: Configured ($($config.UserAssignedIdentities.Count))" -ForegroundColor White
} else {
    Write-Host "  - Managed Identity: Not configured" -ForegroundColor White
}

if ($simulationMode) {
    Write-Host "[INFO] Running in simulation mode (WhatIf or Azure modules unavailable)" -ForegroundColor Cyan
}

# Check for WhatIf mode early - before any Azure operations
if ($whatIfMode) {
    Write-Host "[WHATIF] Preview mode enabled - showing what would be created:" -ForegroundColor Yellow
    Write-Host "  Application Gateway: $($config.ApplicationGatewayName)" -ForegroundColor White
    Write-Host "  Resource Group: $($config.ResourceGroupName)" -ForegroundColor White
    Write-Host "  Location: $($config.Location)" -ForegroundColor White
    Write-Host "  SKU: $($config.SkuName)" -ForegroundColor White
    Write-Host "  Configuration Type: $($config.ConfigurationType)" -ForegroundColor White
    Write-Host "  Listeners: $($ConfigListeners.Count)" -ForegroundColor White
    Write-Host "  Backend Pools: $($ConfigBackendPools.Count)" -ForegroundColor White
    Write-Host "  Backend Settings: $($ConfigBackendSettings.Count)" -ForegroundColor White
    Write-Host "  Routing Rules: $($ConfigRoutingRules.Count)" -ForegroundColor White
    Write-Host "  Frontend Ports: $($ConfigFrontendPorts.Count)" -ForegroundColor White
    Write-Host "  SSL Certificates: $($ConfigSslCertificates.Count)" -ForegroundColor White
    Write-Host "  HTTPS Enabled: $($config.EnableHttps)" -ForegroundColor White
    if ($config.UserAssignedIdentities -and $config.UserAssignedIdentities.Count -gt 0) {
        Write-Host "  Managed Identity: Configured ($($config.UserAssignedIdentities.Count))" -ForegroundColor White
    } else {
        Write-Host "  Managed Identity: Not configured" -ForegroundColor White
    }
    Write-Host "[OK] WhatIf validation completed - no resources were created" -ForegroundColor Green
    Write-Host "[INFO] To execute actual deployment, remove -WhatIf parameter" -ForegroundColor Cyan
    return
}

# Validate configuration
try {
    # Check if Azure PowerShell modules are available
    if (-not $simulationMode) {
        Test-AzureConnection -SubscriptionName $config.SubscriptionName
        Test-ResourceGroupExists -ResourceGroupName $config.ResourceGroupName
        Write-Host "[OK] Azure validation completed successfully" -ForegroundColor Green
    } else {
        Write-Warning "[WARNING] Azure PowerShell modules not found or WhatIf mode enabled - skipping Azure validation"
        Write-Host "[INFO] To install Azure PowerShell: Install-Module -Name Az" -ForegroundColor Cyan
        Write-Host "[OK] Configuration validation completed (simulation mode)" -ForegroundColor Green
    }
} catch {
    Write-Warning "[WARNING] Azure validation failed: $($_.Exception.Message)"
    Write-Host "[INFO] Continuing with deployment configuration validation..." -ForegroundColor Cyan
    Write-Host "[OK] Configuration validation completed (limited mode)" -ForegroundColor Green
}

# Connect to Azure subscription
Write-Host "[CONNECT] Connecting to Azure subscription: $($config.SubscriptionName)" -ForegroundColor Cyan
try {
    # Check if Azure PowerShell modules are available
    if (-not $simulationMode) {
        Set-AzContext -SubscriptionName $config.SubscriptionName -ErrorAction Stop
        Write-Host "[OK] Connected to subscription successfully" -ForegroundColor Green
    } else {
        Write-Warning "[WARNING] Running in simulation mode - Azure connection skipped"
        Write-Host "[INFO] WhatIf mode will be automatically enabled" -ForegroundColor Cyan
        $config.WhatIf = $true
    }
} catch {
    Write-Warning "[WARNING] Failed to connect to subscription: $($_.Exception.Message)"
    Write-Host "[INFO] Continuing in WhatIf mode..." -ForegroundColor Cyan
    $config.WhatIf = $true
    $simulationMode = $true
}

# Set default values for optional parameters
$VNetResourceGroupName = if ($config.VNetResourceGroupName) { $config.VNetResourceGroupName } else { $config.ResourceGroupName }
$PublicIPResourceGroupName = if ($config.PublicIPResourceGroupName) { $config.PublicIPResourceGroupName } else { $config.ResourceGroupName }

try {
    Write-Host "[SEARCH] Retrieving network resources..." -ForegroundColor Cyan
    
    # Check if we're in Azure-connected mode
    if (-not $simulationMode) {
        # Get Virtual Network and Subnet
        $vnet = Get-AzVirtualNetwork -ResourceGroupName $VNetResourceGroupName -Name $config.VirtualNetworkName -ErrorAction Stop
        $subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $config.SubnetName -ErrorAction Stop
        
        Write-Host "[OK] Virtual Network: $($vnet.Name) in $($vnet.ResourceGroupName)" -ForegroundColor Green
        Write-Host "[OK] Subnet: $($subnet.Name) (Address Prefix: $($subnet.AddressPrefix))" -ForegroundColor Green

        # Get Public IP (if needed)
        $publicIP = $null
        if ($config.ConfigurationType -eq "PublicOnly" -or $config.ConfigurationType -eq "Both") {
            if ($config.PublicIPName) {
                $publicIP = Get-AzPublicIpAddress -ResourceGroupName $PublicIPResourceGroupName -Name $config.PublicIPName -ErrorAction Stop
                Write-Host "[OK] Public IP: $($publicIP.Name) - $($publicIP.IpAddress)" -ForegroundColor Green
            } else {
                Write-Error "[ERROR] Public IP name is required for PublicOnly or Both configuration types"
                exit 1
            }
        }
    } else {
        # Simulation mode - create mock objects
        Write-Host "[INFO] Running in simulation mode - creating mock network objects" -ForegroundColor Cyan
        
        $vnet = [PSCustomObject]@{
            Name = $config.VirtualNetworkName
            ResourceGroupName = $VNetResourceGroupName
        }
        
        $subnet = [PSCustomObject]@{
            Name = $config.SubnetName
            AddressPrefix = "10.0.1.0/24"
            Id = "/subscriptions/mock/resourceGroups/$VNetResourceGroupName/providers/Microsoft.Network/virtualNetworks/$($config.VirtualNetworkName)/subnets/$($config.SubnetName)"
        }
        
        Write-Host "[OK] Virtual Network (simulated): $($vnet.Name) in $($vnet.ResourceGroupName)" -ForegroundColor Green
        Write-Host "[OK] Subnet (simulated): $($subnet.Name) (Address Prefix: $($subnet.AddressPrefix))" -ForegroundColor Green

        # Mock Public IP (if needed)
        $publicIP = $null
        if ($config.ConfigurationType -eq "PublicOnly" -or $config.ConfigurationType -eq "Both") {
            if ($config.PublicIPName) {
                $publicIP = [PSCustomObject]@{
                    Name = $config.PublicIPName
                    IpAddress = "20.0.0.1"
                    Id = "/subscriptions/mock/resourceGroups/$PublicIPResourceGroupName/providers/Microsoft.Network/publicIPAddresses/$($config.PublicIPName)"
                }
                Write-Host "[OK] Public IP (simulated): $($publicIP.Name) - $($publicIP.IpAddress)" -ForegroundColor Green
            } else {
                Write-Error "[ERROR] Public IP name is required for PublicOnly or Both configuration types"
                exit 1
            }
        }
    }

} catch {
    Write-Error "[ERROR] Failed to retrieve network resources: $($_.Exception.Message)"
    exit 1
}

# Create Application Gateway configuration
Write-Host "[BUILD] Creating Application Gateway configuration..." -ForegroundColor Cyan

if ($simulationMode) {
    Write-Host "[INFO] Simulation mode - showing configuration that would be created:" -ForegroundColor Cyan
    
    # Show what would be created without making Azure calls
    Write-Host "[OK] Gateway IP Configuration: gatewayIPConfig" -ForegroundColor Green
    Write-Host "[OK] Frontend IP configurations: $($config.ConfigurationType)" -ForegroundColor Green
    Write-Host "[OK] Frontend Ports: $($ConfigFrontendPorts.Count + 2) (from config + defaults)" -ForegroundColor Green  
    Write-Host "[OK] Backend Pools: $($ConfigBackendPools.Count + 1) (from config + default)" -ForegroundColor Green
    Write-Host "[OK] Backend HTTP Settings: $($ConfigBackendSettings.Count + 1) (from config + default)" -ForegroundColor Green
    Write-Host "[OK] HTTP Listeners: $($ConfigListeners.Count + 1) (from config + default)" -ForegroundColor Green
    Write-Host "[OK] Routing Rules: $($ConfigRoutingRules.Count + 1) (from config + default)" -ForegroundColor Green
    
    # Simulate counts for the deployment summary
    $frontendPorts = @(1..$($ConfigFrontendPorts.Count + 2))
    $backendPools = @(1..$($ConfigBackendPools.Count + 1)) 
    $backendHttpSettings = @(1..$($ConfigBackendSettings.Count + 1))
    $listeners = @(1..$($ConfigListeners.Count + 1))
    $routingRules = @(1..$($ConfigRoutingRules.Count + 1))
    
} else {
try {
    # Gateway IP Configuration
    $gatewayIPConfig = New-AzApplicationGatewayIPConfiguration -Name "gatewayIPConfig" -Subnet $subnet

    # Frontend IP Configurations
    $frontendIPConfigs = @()
    
    if ($config.ConfigurationType -eq "PublicOnly" -or $config.ConfigurationType -eq "Both") {
        $publicFrontendIP = New-AzApplicationGatewayFrontendIPConfig -Name "publicFrontendIP" -PublicIPAddress $publicIP
        $frontendIPConfigs += $publicFrontendIP
        Write-Host "[OK] Public Frontend IP configuration created" -ForegroundColor Green
    }
    
    if ($config.ConfigurationType -eq "PrivateOnly" -or $config.ConfigurationType -eq "Both") {
        if ($config.PrivateIPAddress) {
            $privateFrontendIP = New-AzApplicationGatewayFrontendIPConfig -Name "privateFrontendIP" -Subnet $subnet -PrivateIPAddress $config.PrivateIPAddress
        } else {
            $privateFrontendIP = New-AzApplicationGatewayFrontendIPConfig -Name "privateFrontendIP" -Subnet $subnet
        }
        $frontendIPConfigs += $privateFrontendIP
        Write-Host "[OK] Private Frontend IP configuration created" -ForegroundColor Green
    }

    # Frontend Ports - Process multiple configurations
    $frontendPorts = @()
    $portsCreated = @()
    
    # Create ports from configuration arrays
    foreach ($portConfig in $ConfigFrontendPorts) {
        if ($portConfig.Port -notin $portsCreated) {
            $frontendPort = New-AzApplicationGatewayFrontendPort -Name $portConfig.Name -Port $portConfig.Port
            $frontendPorts += $frontendPort
            $portsCreated += $portConfig.Port
            Write-Host "[OK] Frontend Port created: $($portConfig.Name) on port $($portConfig.Port)" -ForegroundColor Green
        }
    }
    
    # Create default ports if none configured
    if ($frontendPorts.Count -eq 0) {
        $httpPort = New-AzApplicationGatewayFrontendPort -Name "HttpPort" -Port 80
        $frontendPorts += $httpPort
        Write-Host "[OK] Default HTTP Frontend Port created on port 80" -ForegroundColor Green
        
        if ($config.ConfigurationType -ne "PrivateOnly") {
            $httpsPort = New-AzApplicationGatewayFrontendPort -Name "HttpsPort" -Port 443
            $frontendPorts += $httpsPort
            Write-Host "[OK] Default HTTPS Frontend Port created on port 443" -ForegroundColor Green
        }
    }

    # SSL Certificates - Process multiple configurations (only if HTTPS is enabled)
    $sslCertificates = @()
    
    # Check if HTTPS is enabled and should create SSL certificates
    $enableHttpsConfig = $false
    if ($config.EnableHttps -eq $true -and -not [string]::IsNullOrEmpty($config.HttpsListenerName)) {
        $enableHttpsConfig = $true
        Write-Host "[INFO]  HTTPS is enabled - processing SSL certificates and HTTPS listeners" -ForegroundColor Cyan
    } elseif ($config.EnableHttp2 -eq $true -and -not [string]::IsNullOrEmpty($config.HttpsListenerName)) {
        $enableHttpsConfig = $true
        Write-Host "[INFO]  HTTP/2 is enabled with HTTPS listener - processing SSL certificates and HTTPS listeners" -ForegroundColor Cyan
    } else {
        Write-Host "[INFO]  HTTPS not enabled (EnableHttps=$($config.EnableHttps), HttpsListenerName='$($config.HttpsListenerName)') - skipping SSL certificates" -ForegroundColor Cyan
    }
    
    # Create SSL certificates from configuration arrays (only if HTTPS is enabled)
    if ($enableHttpsConfig -and $ConfigSslCertificates -and $ConfigSslCertificates.Count -gt 0) {
        foreach ($certConfig in $ConfigSslCertificates) {
            if ($certConfig.KeyVaultSecretId) {
                # Create SSL certificate from Key Vault
                try {
                    $sslCertificate = New-AzApplicationGatewaySslCertificate -Name $certConfig.Name -KeyVaultSecretId $certConfig.KeyVaultSecretId
                    $sslCertificates += $sslCertificate
                    Write-Host "[OK] SSL Certificate created: $($certConfig.Name) from Key Vault" -ForegroundColor Green
                } catch {
                    Write-Warning "[WARNING] Failed to create SSL certificate $($certConfig.Name) from Key Vault: $($_.Exception.Message)"
                    Write-Host "   KeyVaultSecretId: $($certConfig.KeyVaultSecretId)" -ForegroundColor Yellow
                }
            } elseif ($certConfig.CertificateData -and $certConfig.Password) {
                # Create SSL certificate from certificate data
                try {
                    $sslCertificate = New-AzApplicationGatewaySslCertificate -Name $certConfig.Name -CertificateData $certConfig.CertificateData -Password $certConfig.Password
                    $sslCertificates += $sslCertificate
                    Write-Host "[OK] SSL Certificate created: $($certConfig.Name) from certificate data" -ForegroundColor Green
                } catch {
                    Write-Warning "[WARNING] Failed to create SSL certificate $($certConfig.Name) from certificate data: $($_.Exception.Message)"
                }
            } else {
                Write-Warning "[WARNING] SSL certificate $($certConfig.Name) requires either KeyVaultSecretId or CertificateData+Password"
            }
        }
    }

    if ($enableHttpsConfig) {
        if ($sslCertificates.Count -gt 0) {
            Write-Host "[OK] Created $($sslCertificates.Count) SSL certificate(s) for HTTPS" -ForegroundColor Green
        } else {
            Write-Host "[WARNING]  HTTPS is enabled but no SSL certificates were created" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[INFO]  HTTPS disabled - no SSL certificates needed" -ForegroundColor Cyan
    }

    # Backend Pools - Process multiple configurations
    $backendPools = @()
    
    # Create backend pools from configuration arrays
    foreach ($poolConfig in $ConfigBackendPools) {
        $backendTargets = $poolConfig.Targets
        
        # Separate IP addresses and FQDNs
        $ipAddresses = @()
        $fqdns = @()
        
        foreach ($target in $backendTargets) {
            if ($target -match '^\d+\.\d+\.\d+\.\d+$') {
                $ipAddresses += $target
            } else {
                $fqdns += $target
            }
        }
        
        # Create backend pool with appropriate targets
        $backendPool = $null
        if ($ipAddresses.Count -gt 0 -and $fqdns.Count -gt 0) {
            $backendPool = New-AzApplicationGatewayBackendAddressPool -Name $poolConfig.Name -BackendIPAddresses $ipAddresses -BackendFqdns $fqdns
        } elseif ($ipAddresses.Count -gt 0) {
            $backendPool = New-AzApplicationGatewayBackendAddressPool -Name $poolConfig.Name -BackendIPAddresses $ipAddresses
        } elseif ($fqdns.Count -gt 0) {
            $backendPool = New-AzApplicationGatewayBackendAddressPool -Name $poolConfig.Name -BackendFqdns $fqdns
        } else {
            $backendPool = New-AzApplicationGatewayBackendAddressPool -Name $poolConfig.Name
        }
        
        $backendPools += $backendPool
        Write-Host "[OK] Backend Pool created: $($poolConfig.Name) with $($backendTargets.Count) targets" -ForegroundColor Green
    }
    
    # Create default backend pool if none configured
    if ($backendPools.Count -eq 0) {
        if ($config.BackendTargets -and $config.BackendTargets.Count -gt 0) {
            $backendPool = New-AzApplicationGatewayBackendAddressPool -Name $config.BackendPoolName -BackendIPAddresses $config.BackendTargets
        } else {
            $backendPool = New-AzApplicationGatewayBackendAddressPool -Name $config.BackendPoolName
        }
        $backendPools += $backendPool
        Write-Host "[OK] Default Backend Pool created: $($config.BackendPoolName)" -ForegroundColor Green
    }

    # Backend HTTP Settings - Process multiple configurations
    $backendHttpSettings = @()
    
    # Create backend settings from configuration arrays
    foreach ($settingsConfig in $ConfigBackendSettings) {
        $backendSetting = New-AzApplicationGatewayBackendHttpSetting `
            -Name $settingsConfig.Name `
            -Port $settingsConfig.Port `
            -Protocol $settingsConfig.Protocol `
            -CookieBasedAffinity $settingsConfig.CookieAffinity `
            -RequestTimeout $settingsConfig.RequestTimeout
        
        $backendHttpSettings += $backendSetting
        Write-Host "[OK] Backend HTTP Setting created: $($settingsConfig.Name) ($($settingsConfig.Protocol):$($settingsConfig.Port))" -ForegroundColor Green
    }
    
    # Create default backend HTTP settings if none configured
    if ($backendHttpSettings.Count -eq 0) {
        $backendHttpSetting = New-AzApplicationGatewayBackendHttpSetting `
            -Name $config.BackendHttpSettingsName `
            -Port 80 `
            -Protocol "Http" `
            -CookieBasedAffinity "Disabled" `
            -RequestTimeout 30
        
        $backendHttpSettings += $backendHttpSetting
        Write-Host "[OK] Default Backend HTTP Setting created: $($config.BackendHttpSettingsName)" -ForegroundColor Green
    }

    # HTTP Listeners - Process multiple configurations
    $listeners = @()
    
    # Create listeners from configuration arrays
    foreach ($listenerConfig in $ConfigListeners) {
        # Find the frontend IP configuration
        $frontendIP = $frontendIPConfigs | Where-Object { $_.Name -eq $listenerConfig.FrontendIP } | Select-Object -First 1
        if (-not $frontendIP) {
            $frontendIP = $frontendIPConfigs[0]  # Use first available
        }
        
        # Find the frontend port
        $frontendPort = $frontendPorts | Where-Object { $_.Port -eq $listenerConfig.FrontendPort } | Select-Object -First 1
        if (-not $frontendPort) {
            Write-Warning "[WARNING] Frontend port $($listenerConfig.FrontendPort) not found for listener $($listenerConfig.Name)"
            continue
        }
        
        # Create listener based on type and HTTPS configuration
        if ($listenerConfig.Type -eq "Https" -and $listenerConfig.SslCertificateName) {
            # Check if HTTPS is enabled before creating HTTPS listener
            if (-not $enableHttpsConfig) {
                Write-Warning "[WARNING] HTTPS listener $($listenerConfig.Name) configured but HTTPS is not enabled (EnableHttps=$($config.EnableHttps), HttpsListenerName='$($config.HttpsListenerName)') - skipping"
                continue
            }
            
            # Find the SSL certificate
            $sslCertificate = $sslCertificates | Where-Object { $_.Name -eq $listenerConfig.SslCertificateName } | Select-Object -First 1
            if ($sslCertificate) {
                # Create HTTPS listener with SSL certificate
                $listener = New-AzApplicationGatewayHttpListener `
                    -Name $listenerConfig.Name `
                    -FrontendIPConfiguration $frontendIP `
                    -FrontendPort $frontendPort `
                    -Protocol "Https" `
                    -SslCertificate $sslCertificate
                Write-Host "[OK] HTTPS Listener created: $($listenerConfig.Name) on port $($listenerConfig.FrontendPort) with SSL certificate '$($listenerConfig.SslCertificateName)'" -ForegroundColor Green
            } else {
                Write-Warning "[WARNING] SSL certificate '$($listenerConfig.SslCertificateName)' not found for HTTPS listener $($listenerConfig.Name) - skipping"
                continue
            }
        } elseif ($listenerConfig.Type -eq "Https") {
            Write-Warning "[WARNING] HTTPS listener $($listenerConfig.Name) requires SslCertificateName property and HTTPS to be enabled - skipping"
            continue
        } else {
            # Create HTTP listener
            $listener = New-AzApplicationGatewayHttpListener `
                -Name $listenerConfig.Name `
                -FrontendIPConfiguration $frontendIP `
                -FrontendPort $frontendPort `
                -Protocol "Http"
            Write-Host "[OK] HTTP Listener created: $($listenerConfig.Name) on port $($listenerConfig.FrontendPort)" -ForegroundColor Green
        }
        
        $listeners += $listener
    }
    
    # Create default listener if none configured
    if ($listeners.Count -eq 0) {
        if ($frontendIPConfigs.Count -gt 0 -and $frontendPorts.Count -gt 0) {
            $listener = New-AzApplicationGatewayHttpListener `
                -Name $config.HttpListenerName `
                -FrontendIPConfiguration $frontendIPConfigs[0] `
                -FrontendPort $frontendPorts[0] `
                -Protocol "Http"
            
            $listeners += $listener
            Write-Host "[OK] Default HTTP Listener created: $($config.HttpListenerName)" -ForegroundColor Green
        } else {
            Write-Error "[ERROR] No frontend IP configurations or ports available for default listener"
            exit 1
        }
    }

    # Routing Rules - Process multiple configurations
    $routingRules = @()
    
    # Create routing rules from configuration arrays
    foreach ($ruleConfig in $ConfigRoutingRules) {
        # Find the listener
        $listener = $listeners | Where-Object { $_.Name -eq $ruleConfig.ListenerName } | Select-Object -First 1
        if (-not $listener) {
            Write-Warning "[WARNING] Listener $($ruleConfig.ListenerName) not found for routing rule $($ruleConfig.Name)"
            continue
        }
        
        # Find the backend pool
        $backendPool = $backendPools | Where-Object { $_.Name -eq $ruleConfig.BackendPoolName } | Select-Object -First 1
        if (-not $backendPool) {
            Write-Warning "[WARNING] Backend pool $($ruleConfig.BackendPoolName) not found for routing rule $($ruleConfig.Name)"
            continue
        }
        
        # Find the backend settings
        $backendSetting = $backendHttpSettings | Where-Object { $_.Name -eq $ruleConfig.BackendSettingsName } | Select-Object -First 1
        if (-not $backendSetting -and $backendHttpSettings.Count -gt 0) {
            $backendSetting = $backendHttpSettings[0]  # Use first available
        } elseif (-not $backendSetting) {
            Write-Warning "[WARNING] No backend HTTP settings available for routing rule $($ruleConfig.Name)"
            continue
        }
        
        $routingRule = New-AzApplicationGatewayRequestRoutingRule `
            -Name $ruleConfig.Name `
            -RuleType "Basic" `
            -Priority $ruleConfig.Priority `
            -HttpListener $listener `
            -BackendAddressPool $backendPool `
            -BackendHttpSettings $backendSetting
        
        $routingRules += $routingRule
        Write-Host "[OK] Routing Rule created: $($ruleConfig.Name) (Priority: $($ruleConfig.Priority))" -ForegroundColor Green
    }
    
    # Create default routing rule if none configured
    if ($routingRules.Count -eq 0) {
        if ($listeners.Count -gt 0 -and $backendPools.Count -gt 0 -and $backendHttpSettings.Count -gt 0) {
            $routingRule = New-AzApplicationGatewayRequestRoutingRule `
                -Name $config.RoutingRuleName `
                -RuleType "Basic" `
                -Priority 100 `
                -HttpListener $listeners[0] `
                -BackendAddressPool $backendPools[0] `
                -BackendHttpSettings $backendHttpSettings[0]
            
            $routingRules += $routingRule
            Write-Host "[OK] Default Routing Rule created: $($config.RoutingRuleName)" -ForegroundColor Green
        } else {
            Write-Error "[ERROR] Cannot create default routing rule - missing required components (listeners: $($listeners.Count), pools: $($backendPools.Count), settings: $($backendHttpSettings.Count))"
            exit 1
        }
    }

    Write-Host "[OK] Application Gateway configuration components created successfully" -ForegroundColor Green

} catch {
    Write-Error "[ERROR] Failed to create Application Gateway configuration: $($_.Exception.Message)"
    exit 1
}
} # End of else block for simulation mode

# Create SKU and Autoscale Configuration
if ($simulationMode) {
    Write-Host "[OK] SKU and Autoscale configuration (simulated): $($config.SkuName)" -ForegroundColor Green
} else {
    try {
        $sku = New-AzApplicationGatewaySku -Name $config.SkuName -Tier $config.SkuTier
        $autoscaleConfig = New-AzApplicationGatewayAutoscaleConfiguration -MinCapacity $config.MinCapacity -MaxCapacity $config.MaxCapacity
        
        Write-Host "[OK] SKU and Autoscale configuration created" -ForegroundColor Green
    } catch {
        Write-Error "[ERROR] Failed to create SKU configuration: $($_.Exception.Message)"
        exit 1
    }
}

# SSL Policy Configuration
$sslPolicy = $null
if ($config.SslPolicyType -eq "Predefined" -and $config.SslPolicyName) {
    if ($simulationMode) {
        Write-Host "[OK] SSL Policy (simulated): $($config.SslPolicyName)" -ForegroundColor Green
    } else {
        try {
            $sslPolicy = New-AzApplicationGatewaySslPolicy -PolicyType "Predefined" -PolicyName $config.SslPolicyName
            Write-Host "[OK] SSL Policy configured: $($config.SslPolicyName)" -ForegroundColor Green
        } catch {
            Write-Warning "[WARNING] Failed to configure SSL policy, proceeding without: $($_.Exception.Message)"
        }
    }
}

# WAF Configuration (using WAF Configuration instead of WAF Policy)
$wafPolicy = $null
$wafConfig = $null
if ($config.SkuTier -eq "WAF_v2" -and $config.EnableWAF) {
    if ($simulationMode) {
        Write-Host "[OK] WAF Configuration (simulated): Mode=$($config.WAFMode), RuleSet=$($config.WAFRuleSetVersion)" -ForegroundColor Green
    } else {
        # Always use WAF Configuration instead of WAF Policy to avoid policy creation
        Write-Host "[INFO] Using WAF Configuration method (no separate WAF policy will be created)" -ForegroundColor Cyan
        try {
            $wafConfig = New-AzApplicationGatewayWebApplicationFirewallConfiguration -Enabled $true -FirewallMode $config.WAFMode -RuleSetType "OWASP" -RuleSetVersion $config.WAFRuleSetVersion
            Write-Host "[OK] WAF Configuration created: Mode=$($config.WAFMode), RuleSet=$($config.WAFRuleSetVersion)" -ForegroundColor Green
        } catch {
            Write-Warning "[WARN] Failed to create WAF configuration: $($_.Exception.Message)"
        }
    }
} elseif ($config.SkuTier -eq "WAF_v2") {
    Write-Warning "[WARNING] WAF_v2 SKU detected but EnableWAF is not true - WAF policy is required for WAF_v2 SKU"
}

# Create Application Gateway
try {
    Write-Host "[DEPLOY] Creating Application Gateway: $($config.ApplicationGatewayName)" -ForegroundColor Cyan
    
    # Create Application Gateway parameters - all in one deployment
    $appGwParams = @{
        Name                         = $config.ApplicationGatewayName
        ResourceGroupName            = $config.ResourceGroupName
        Location                     = $config.Location
        BackendAddressPools          = $backendPools
        BackendHttpSettingsCollection= $backendHttpSettings
        FrontendIpConfigurations     = $frontendIPConfigs
        GatewayIpConfigurations      = $gatewayIPConfig
        FrontendPorts                = $frontendPorts
        HttpListeners                = $listeners
        RequestRoutingRules          = $routingRules
        Sku                          = $sku
        AutoscaleConfiguration       = $autoscaleConfig
        EnableHttp2                  = $config.EnableHttp2
    }
    
    # Add SSL certificates if HTTPS is enabled and certificates exist
    if ($enableHttpsConfig -and $sslCertificates -and $sslCertificates.Count -gt 0) {
        $appGwParams.SslCertificates = $sslCertificates
        Write-Host "[OK] Added $($sslCertificates.Count) SSL certificate(s) to Application Gateway (HTTPS enabled)" -ForegroundColor Green
    } elseif ($sslCertificates -and $sslCertificates.Count -gt 0 -and -not $enableHttpsConfig) {
        Write-Host "[WARNING]  SSL certificates configured but HTTPS is not enabled - certificates will not be added" -ForegroundColor Yellow
    }
    
    # Create and add managed identity if configured (required for Key Vault SSL certificates)
    $identityObject = $null
    if ($config.UserAssignedIdentities -and $config.UserAssignedIdentities.Count -gt 0) {
        # Use New-AzApplicationGatewayIdentity cmdlet - this is the correct approach
        try {
            $identityObject = New-AzApplicationGatewayIdentity -UserAssignedIdentityId $config.UserAssignedIdentities[0]
            Write-Host "[OK] Created User Assigned Identity object for Key Vault access: $($config.UserAssignedIdentities[0])" -ForegroundColor Green
        } catch {
            Write-Warning "[WARNING] Failed to create identity object: $($_.Exception.Message)"
            Write-Host "[INFO] Will attempt deployment without identity - may require post-deployment configuration" -ForegroundColor Yellow
        }
    } elseif ($enableHttpsConfig -and $sslCertificates -and $sslCertificates.Count -gt 0) {
        Write-Warning "[WARNING]  HTTPS is enabled with SSL certificates but no UserAssignedIdentities configured - Key Vault access may fail"
    }
    
    # Add SSL Policy
    if ($sslPolicy) {
        $appGwParams.SslPolicy = $sslPolicy
        Write-Host "[OK] Added SSL Policy: $($config.SslPolicyName)" -ForegroundColor Green
    }
    
    # Add Availability Zones
    if ($config.AvailabilityZones -and $config.AvailabilityZones.Count -gt 0) {
        $appGwParams.Zone = $config.AvailabilityZones
        Write-Host "[OK] Added Availability Zones: $($config.AvailabilityZones -join ', ')" -ForegroundColor Green
    }
    
    # Add Tags
    if ($config.Tags -and $config.Tags.Count -gt 0) {
        $appGwParams.Tag = $config.Tags
        Write-Host "[OK] Added Tags: $($config.Tags.Count) tags" -ForegroundColor Green
    }

    # Execute deployment (WhatIf already handled earlier)
    # Create Application Gateway with ALL components
        $allParams = @{
            Name                         = $config.ApplicationGatewayName
            ResourceGroupName            = $config.ResourceGroupName
            Location                     = $config.Location
            BackendAddressPools          = $backendPools
            BackendHttpSettingsCollection= $backendHttpSettings
            FrontendIpConfigurations     = $frontendIPConfigs
            GatewayIpConfigurations      = $gatewayIPConfig
            FrontendPorts                = $frontendPorts
            HttpListeners                = $listeners
            RequestRoutingRules          = $routingRules
            Sku                          = $sku
            AutoscaleConfiguration       = $autoscaleConfig
            EnableHttp2                  = $config.EnableHttp2
        }
        
        # Add SSL certificates if HTTPS is enabled and certificates exist
        if ($enableHttpsConfig -and $sslCertificates -and $sslCertificates.Count -gt 0) {
            $allParams.SslCertificates = $sslCertificates
            Write-Host "[OK] Added $($sslCertificates.Count) SSL certificate(s) to Application Gateway (HTTPS enabled)" -ForegroundColor Green
        }
        
        # Add Identity if SSL certificates are used (REQUIRED for Key Vault access)
        # For WAF_v2 with Key Vault SSL certificates, Identity is mandatory during creation
        if ($identityObject -and $sslCertificates -and $sslCertificates.Count -gt 0) {
            # Check if any SSL certificates use Key Vault
            $hasKeyVaultCerts = $sslCertificates | Where-Object { -not [string]::IsNullOrEmpty($_.KeyVaultSecretId) }
            if ($hasKeyVaultCerts) {
                $allParams.Identity = $identityObject
                Write-Host "[OK] Added User Assigned Identity for Key Vault SSL certificate access (required for WAF_v2)" -ForegroundColor Green
            }
        } elseif ($sslCertificates -and $sslCertificates.Count -gt 0) {
            # Check if we have Key Vault certificates without identity
            $hasKeyVaultCerts = $sslCertificates | Where-Object { -not [string]::IsNullOrEmpty($_.KeyVaultSecretId) }
            if ($hasKeyVaultCerts) {
                Write-Warning "[WARNING] Key Vault SSL certificates require User Assigned Identity - deployment will fail"
                Write-Host "[INFO] Please configure UserAssignedIdentities in your parameter set" -ForegroundColor Yellow
            }
        }
        
        # Add WAF Configuration if configured (no separate WAF policy created)
        # Note: WebApplicationFirewallConfiguration is used instead of FirewallPolicy
        if ($wafConfig) {
            $allParams.WebApplicationFirewallConfiguration = $wafConfig
            Write-Host "[OK] Added WAF Configuration to Application Gateway" -ForegroundColor Green
        }
        
        # Add SSL Policy
        if ($sslPolicy) {
            $allParams.SslPolicy = $sslPolicy
            Write-Host "[OK] Added SSL Policy: $($config.SslPolicyName)" -ForegroundColor Green
        }
        
        # Add Availability Zones - try both Zone and Zones parameter names
        if ($config.AvailabilityZones -and $config.AvailabilityZones.Count -gt 0) {
            try {
                $allParams.Zone = $config.AvailabilityZones
                Write-Host "[OK] Added Availability Zones: $($config.AvailabilityZones -join ', ')" -ForegroundColor Green
            } catch {
                Write-Warning "[WARNING] Zone parameter failed, trying Zones parameter"
                try {
                    $allParams.Remove('Zone')
                    $allParams.Zones = $config.AvailabilityZones
                    Write-Host "[OK] Added Availability Zones (Zones): $($config.AvailabilityZones -join ', ')" -ForegroundColor Green
                } catch {
                    Write-Warning "[WARNING] Both Zone/Zones parameters failed, proceeding without zones: $($_.Exception.Message)"
                    if ($allParams.ContainsKey('Zones')) {
                        $allParams.Remove('Zones')
                    }
                }
            }
        }
        
        # Add Tags
        if ($config.Tags -and $config.Tags.Count -gt 0) {
            $allParams.Tag = $config.Tags
            Write-Host "[OK] Added Tags: $($config.Tags.Count) tags" -ForegroundColor Green
        }
        
        Write-Host "[SEARCH] Debug: Final Application Gateway Parameters:" -ForegroundColor Yellow
        foreach ($key in $allParams.Keys | Sort-Object) {
            $value = $allParams[$key]
            if ($value -is [Array]) {
                Write-Host "  $key : Array[$($value.Count)]" -ForegroundColor Gray
            } else {
                Write-Host "  $key : $($value.GetType().Name)" -ForegroundColor Gray
            }
        }
        
        # Create Application Gateway with robust single-pass deployment
        try {
            Write-Host "[DEPLOY] Creating Application Gateway with validated configuration..." -ForegroundColor Cyan
            
            # Final validation before deployment
            if ($enableHttpsConfig -and $sslCertificates -and $sslCertificates.Count -gt 0) {
                Write-Host "[SEARCH] Validating SSL certificate configuration..." -ForegroundColor Yellow
                foreach ($cert in $sslCertificates) {
                    if ([string]::IsNullOrEmpty($cert.KeyVaultSecretId)) {
                        throw "SSL Certificate '$($cert.Name)' has null or empty KeyVaultSecretId"
                    }
                    Write-Host "  [OK] Certificate: $($cert.Name)" -ForegroundColor Green
                }
            }
            
            # Validate listener configurations
            Write-Host "[SEARCH] Validating listener configurations..." -ForegroundColor Yellow
            foreach ($listener in $listeners) {
                $protocol = $listener.Protocol
                # Get port from the frontend port object
                $port = $frontendPorts | Where-Object { $_.Name -eq $listener.FrontendPort.Name } | Select-Object -First 1 | ForEach-Object { $_.Port }
                if (-not $port) {
                    # Fallback: try to get port from the ID if available
                    $port = "Unknown"
                }
                
                if ($protocol -eq "Https" -and $port -ne 443 -and $port -ne 8443) {
                    Write-Warning "[WARNING]  HTTPS listener '$($listener.Name)' using non-standard port $port"
                }
                if ($protocol -eq "Http" -and $port -ne 80 -and $port -ne 8080) {
                    Write-Warning "[WARNING]  HTTP listener '$($listener.Name)' using non-standard port $port"
                }
                
                Write-Host "  [OK] Listener: $($listener.Name) ($protocol on port $port)" -ForegroundColor Green
            }
            
            Write-Host "[DEPLOY] Deploying Application Gateway..." -ForegroundColor Cyan
            $appGateway = New-AzApplicationGateway @allParams -Force
            
            if ($appGateway) {
                Write-Host "[OK] Application Gateway '$($appGateway.Name)' created successfully!" -ForegroundColor Green
                Write-Host "[LOCATION] Frontend IP: $($appGateway.FrontendIPConfigurations[0].PublicIPAddress.Id.Split('/')[-1])" -ForegroundColor Cyan
                Write-Host "[NETWORK] Resource Group: $($appGateway.ResourceGroupName)" -ForegroundColor Cyan
                Write-Host "[LOCATION] Location: $($appGateway.Location)" -ForegroundColor Cyan
                
                # Display configured listeners
                Write-Host "[TOOL] Configured Listeners:" -ForegroundColor Yellow
                foreach ($listener in $appGateway.HttpListeners) {
                    $protocol = $listener.Protocol
                    $port = $listener.FrontendPort.Name
                    Write-Host "  - $($listener.Name): $protocol on port $port" -ForegroundColor Gray
                }
                
                return $appGateway
            } else {
                throw "Application Gateway creation returned null"
            }
            
        } catch {
            Write-Error "[ERROR] Application Gateway deployment failed: $($_.Exception.Message)"
            Write-Host "[SEARCH] Error Details:" -ForegroundColor Red
            Write-Host "  $($_.Exception.ToString())" -ForegroundColor Gray
            
            Write-Host "[TOOL] Troubleshooting Steps:" -ForegroundColor Yellow
            Write-Host "  1. Verify all SSL certificates have valid KeyVaultSecretId values" -ForegroundColor Gray
            Write-Host "  2. Check that managed identity has Key Vault access permissions" -ForegroundColor Gray
            Write-Host "  3. Ensure listener protocol/port combinations are valid" -ForegroundColor Gray
            Write-Host "  4. Verify subnet has sufficient IP addresses available" -ForegroundColor Gray
            Write-Host "  5. Check that public IP address is in 'Static' allocation method" -ForegroundColor Gray
            
            # Log configuration for debugging
            Write-Host "[SEARCH] Configuration Summary:" -ForegroundColor Yellow
            if ($enableHttpsConfig -and $sslCertificates) {
                Write-Host "  SSL Certificates:" -ForegroundColor Gray
                foreach ($cert in $sslCertificates) {
                    Write-Host "    - $($cert.Name): $($cert.KeyVaultSecretId)" -ForegroundColor Gray
                }
            }
            
            Write-Host "  Listeners:" -ForegroundColor Gray
            foreach ($listener in $listeners) {
                # Get port from the frontend port object in error display too
                $port = $frontendPorts | Where-Object { $_.Name -eq $listener.FrontendPort.Name } | Select-Object -First 1 | ForEach-Object { $_.Port }
                if (-not $port) {
                    $port = "Unknown"
                }
                Write-Host "    - $($listener.Name): $($listener.Protocol) on port $port" -ForegroundColor Gray
            }
            
            throw
        }
        
        Write-Host "[SUCCESS] Application Gateway deployment completed successfully!" -ForegroundColor Green
        Write-Host "[CONFIG] Deployment Summary:" -ForegroundColor Yellow
        Write-Host "  Name: $($appGateway.Name)" -ForegroundColor White
        Write-Host "  Resource Group: $($appGateway.ResourceGroupName)" -ForegroundColor White
        Write-Host "  Location: $($appGateway.Location)" -ForegroundColor White
        Write-Host "  Provisioning State: $($appGateway.ProvisioningState)" -ForegroundColor White
        Write-Host "  Backend Pools: $($appGateway.BackendAddressPools.Count)" -ForegroundColor White
        Write-Host "  HTTP Listeners: $($appGateway.HttpListeners.Count)" -ForegroundColor White
        Write-Host "  Routing Rules: $($appGateway.RequestRoutingRules.Count)" -ForegroundColor White
        Write-Host "  HTTPS Enabled: $($enableHttpsConfig)" -ForegroundColor White
        if ($enableHttpsConfig -and $appGateway.SslCertificates) {
            Write-Host "  SSL Certificates: $($appGateway.SslCertificates.Count)" -ForegroundColor White
        }
        
        if ($config.OutputPath) {
            $outputFile = Join-Path $config.OutputPath "appgw-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
            $appGateway | ConvertTo-Json -Depth 10 | Out-File -FilePath $outputFile -Encoding UTF8
            Write-Host "[FILE] Deployment details saved to: $outputFile" -ForegroundColor Cyan
        }
    
    } catch {
        Write-Error "[ERROR] Failed to create Application Gateway: $($_.Exception.Message)"
        Write-Error "[ERROR] Stack Trace: $($_.ScriptStackTrace)"
        exit 1
    }

# Final completion message
if (-not $config.WhatIf) {
    Write-Host "[OK] Script execution completed successfully!" -ForegroundColor Green
}
