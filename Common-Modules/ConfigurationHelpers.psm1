# ConfigurationHelpers.ps1
# Common configuration functions for Azure Application Gateway deployment

function New-ApplicationGatewayIPConfiguration {
    <#
    .SYNOPSIS
        Creates the IP configuration for Application Gateway
    .PARAMETER Name
        The name of the IP configuration
    .PARAMETER Subnet
        The subnet object for the Application Gateway
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [Microsoft.Azure.Commands.Network.Models.PSSubnet]$Subnet
    )
    
    try {
        Write-Host "$(printf '\u2139') Creating Application Gateway IP configuration..." -ForegroundColor Blue
        
        $gatewayIPConfig = New-AzApplicationGatewayIPConfiguration -Name $Name -Subnet $Subnet
        
        Write-Host "$(printf '\u2713') Application Gateway IP configuration created successfully" -ForegroundColor Green
        return $gatewayIPConfig
    }
    catch {
        Write-Error "Failed to create Application Gateway IP configuration: $($_.Exception.Message)"
        throw
    }
}

function New-ApplicationGatewayFrontendConfiguration {
    <#
    .SYNOPSIS
        Creates frontend IP configuration for Application Gateway
    .PARAMETER PublicIPConfiguration
        Configuration for public frontend IP
    .PARAMETER PrivateIPConfiguration
        Configuration for private frontend IP
    .PARAMETER ConfigurationType
        Type of configuration: PublicOnly, PrivateOnly, or Both
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [hashtable]$PublicIPConfiguration,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$PrivateIPConfiguration,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("PublicOnly", "PrivateOnly", "Both")]
        [string]$ConfigurationType
    )
    
    try {
        Write-Host "$(printf '\u2139') Creating frontend IP configuration ($ConfigurationType)..." -ForegroundColor Blue
        
        $frontendIPConfigs = @()
        
        # Create public frontend IP configuration
        if ($ConfigurationType -eq "PublicOnly" -or $ConfigurationType -eq "Both") {
            if (-not $PublicIPConfiguration) {
                throw "PublicIPConfiguration is required for $ConfigurationType configuration"
            }
            
            $publicFrontendIP = New-AzApplicationGatewayFrontendIPConfig `
                -Name $PublicIPConfiguration.Name `
                -PublicIPAddress $PublicIPConfiguration.PublicIP
            
            $frontendIPConfigs += $publicFrontendIP
            Write-Host "$(printf '\u2713') Public frontend IP configuration created" -ForegroundColor Green
        }
        
        # Create private frontend IP configuration
        if ($ConfigurationType -eq "PrivateOnly" -or $ConfigurationType -eq "Both") {
            if (-not $PrivateIPConfiguration) {
                throw "PrivateIPConfiguration is required for $ConfigurationType configuration"
            }
            
            $privateFrontendIP = New-AzApplicationGatewayFrontendIPConfig `
                -Name $PrivateIPConfiguration.Name `
                -Subnet $PrivateIPConfiguration.Subnet `
                -PrivateIPAddress $PrivateIPConfiguration.PrivateIPAddress
            
            $frontendIPConfigs += $privateFrontendIP
            Write-Host "$(printf '\u2713') Private frontend IP configuration created" -ForegroundColor Green
        }
        
        return $frontendIPConfigs
    }
    catch {
        Write-Error "Failed to create frontend IP configuration: $($_.Exception.Message)"
        throw
    }
}

function New-ApplicationGatewayFrontendPort {
    <#
    .SYNOPSIS
        Creates a single frontend port configuration for Application Gateway
    .PARAMETER Name
        Name of the frontend port
    .PARAMETER Port
        Port number
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [int]$Port
    )

    try {
        Write-Host "$(printf '\u2139') Creating frontend port: $Name ($Port)..." -ForegroundColor Blue

        $frontendPort = New-AzApplicationGatewayFrontendPort -Name $Name -Port $Port

        Write-Host "$(printf '\u2713') Frontend port '$Name' created - Port: $Port" -ForegroundColor Green
        return $frontendPort
    }
    catch {
        Write-Error "Failed to create frontend port '$Name': $($_.Exception.Message)"
        throw
    }
}

function New-ApplicationGatewayBackendConfiguration {
    <#
    .SYNOPSIS
        Creates backend address pool and HTTP settings for Application Gateway
    .PARAMETER BackendPoolName
        Name of the backend address pool
    .PARAMETER BackendAddresses
        Array of backend addresses (IPs or FQDNs)
    .PARAMETER BackendPort
        Backend port number
    .PARAMETER Protocol
        Backend protocol (Http or Https)
    .PARAMETER CookieBasedAffinity
        Whether to enable cookie-based affinity
    .PARAMETER RequestTimeout
        Request timeout in seconds
    .PARAMETER ConnectionDraining
        Connection draining configuration
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackendPoolName,
        
        [Parameter(Mandatory = $false)]
        [string[]]$BackendAddresses = @(),
        
        [Parameter(Mandatory = $false)]
        [int]$BackendPort = 80,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Http", "Https")]
        [string]$Protocol = "Http",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Enabled", "Disabled")]
        [string]$CookieBasedAffinity = "Disabled",
        
        [Parameter(Mandatory = $false)]
        [int]$RequestTimeout = 30,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$ConnectionDraining
    )
    
    try {
        Write-Host "$(printf '\u2139') Creating backend configuration..." -ForegroundColor Blue
        
        # Create backend address pool
        if ($BackendAddresses.Count -gt 0) {
            $backendPool = New-AzApplicationGatewayBackendAddressPool -Name $BackendPoolName -BackendIPAddresses $BackendAddresses
        }
        else {
            $backendPool = New-AzApplicationGatewayBackendAddressPool -Name $BackendPoolName
        }
        
        # Create backend HTTP settings
        $backendHttpSettingsParams = @{
            Name                           = "${BackendPoolName}HttpSettings"
            Port                          = $BackendPort
            Protocol                      = $Protocol
            CookieBasedAffinity          = $CookieBasedAffinity
            RequestTimeout               = $RequestTimeout
        }
        
        # Add connection draining if specified
        if ($ConnectionDraining) {
            $backendHttpSettingsParams.ConnectionDrainingTimeoutInSec = $ConnectionDraining.TimeoutInSec
        }
        
        $backendHttpSettings = New-AzApplicationGatewayBackendHttpSetting @backendHttpSettingsParams
        
        Write-Host "$(printf '\u2713') Backend configuration created - Pool: $BackendPoolName, Port: $BackendPort, Protocol: $Protocol" -ForegroundColor Green
        
        return @{
            BackendPool = $backendPool
            HttpSettings = $backendHttpSettings
        }
    }
    catch {
        Write-Error "Failed to create backend configuration: $($_.Exception.Message)"
        throw
    }
}

function New-ApplicationGatewayListener {
    <#
    .SYNOPSIS
        Creates HTTP listeners for Application Gateway
    .PARAMETER Name
        Name of the listener
    .PARAMETER FrontendIPConfig
        Frontend IP configuration
    .PARAMETER FrontendPort
        Frontend port configuration
    .PARAMETER Protocol
        Listener protocol (Http or Https)
    .PARAMETER SslCertificate
        SSL certificate for HTTPS listeners
    .PARAMETER HostName
        Host name for the listener (optional)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [Microsoft.Azure.Commands.Network.Models.PSApplicationGatewayFrontendIPConfiguration]$FrontendIPConfig,
        
        [Parameter(Mandatory = $true)]
        [Microsoft.Azure.Commands.Network.Models.PSApplicationGatewayFrontendPort]$FrontendPort,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Http", "Https")]
        [string]$Protocol = "Http",
        
        [Parameter(Mandatory = $false)]
        [Microsoft.Azure.Commands.Network.Models.PSApplicationGatewaySslCertificate]$SslCertificate,
        
        [Parameter(Mandatory = $false)]
        [string]$HostName
    )
    
    try {
        Write-Host "$(printf '\u2139') Creating HTTP listener: $Name..." -ForegroundColor Blue
        
        $listenerParams = @{
            Name               = $Name
            FrontendIPConfiguration = $FrontendIPConfig
            FrontendPort      = $FrontendPort
            Protocol          = $Protocol
        }
        
        # Add SSL certificate for HTTPS
        if ($Protocol -eq "Https" -and $SslCertificate) {
            $listenerParams.SslCertificate = $SslCertificate
        }
        
        # Add hostname if specified
        if ($HostName) {
            $listenerParams.HostName = $HostName
        }
        
        $listener = New-AzApplicationGatewayHttpListener @listenerParams
        
        Write-Host "$(printf '\u2713') HTTP listener '$Name' created - Protocol: $Protocol$(if ($HostName) { ", Host: $HostName" })" -ForegroundColor Green
        return $listener
    }
    catch {
        Write-Error "Failed to create HTTP listener '$Name': $($_.Exception.Message)"
        throw
    }
}

function New-ApplicationGatewayRoutingRule {
    <#
    .SYNOPSIS
        Creates request routing rules for Application Gateway
    .PARAMETER Name
        Name of the routing rule
    .PARAMETER RuleType
        Type of rule (Basic or PathBasedRouting)
    .PARAMETER HttpListener
        HTTP listener for the rule
    .PARAMETER BackendAddressPool
        Backend address pool
    .PARAMETER BackendHttpSettings
        Backend HTTP settings
    .PARAMETER Priority
        Rule priority (for v2 SKUs)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Basic", "PathBasedRouting")]
        [string]$RuleType = "Basic",
        
        [Parameter(Mandatory = $true)]
        [Microsoft.Azure.Commands.Network.Models.PSApplicationGatewayHttpListener]$HttpListener,
        
        [Parameter(Mandatory = $true)]
        [Microsoft.Azure.Commands.Network.Models.PSApplicationGatewayBackendAddressPool]$BackendAddressPool,
        
        [Parameter(Mandatory = $true)]
        [Microsoft.Azure.Commands.Network.Models.PSApplicationGatewayBackendHttpSettings]$BackendHttpSettings,
        
        [Parameter(Mandatory = $false)]
        [int]$Priority = 100
    )
    
    try {
        Write-Host "$(printf '\u2139') Creating routing rule: $Name..." -ForegroundColor Blue
        
        $routingRule = New-AzApplicationGatewayRequestRoutingRule `
            -Name $Name `
            -RuleType $RuleType `
            -HttpListener $HttpListener `
            -BackendAddressPool $BackendAddressPool `
            -BackendHttpSettings $BackendHttpSettings `
            -Priority $Priority
        
        Write-Host "$(printf '\u2713') Routing rule '$Name' created - Type: $RuleType, Priority: $Priority" -ForegroundColor Green
        return $routingRule
    }
    catch {
        Write-Error "Failed to create routing rule '$Name': $($_.Exception.Message)"
        throw
    }
}

function New-ApplicationGatewaySSLPolicy {
    <#
    .SYNOPSIS
        Creates SSL policy configuration for Application Gateway
    .PARAMETER PolicyType
        SSL policy type (Predefined or Custom)
    .PARAMETER PolicyName
        Name of predefined SSL policy
    .PARAMETER MinProtocolVersion
        Minimum SSL/TLS protocol version
    .PARAMETER CipherSuites
        Array of cipher suites for custom policy
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet("Predefined", "Custom")]
        [string]$PolicyType = "Predefined",
        
        [Parameter(Mandatory = $false)]
        [string]$PolicyName = "AppGwSslPolicy20220101S",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("TLSv1_0", "TLSv1_1", "TLSv1_2", "TLSv1_3")]
        [string]$MinProtocolVersion = "TLSv1_2",
        
        [Parameter(Mandatory = $false)]
        [string[]]$CipherSuites
    )
    
    try {
        Write-Host "$(printf '\u2139') Creating SSL policy configuration..." -ForegroundColor Blue
        
        if ($PolicyType -eq "Predefined") {
            $sslPolicy = New-AzApplicationGatewaySslPolicy -PolicyType $PolicyType -PolicyName $PolicyName
            Write-Host "$(printf '\u2713') SSL policy created - Type: $PolicyType, Policy: $PolicyName" -ForegroundColor Green
        }
        else {
            $sslPolicyParams = @{
                PolicyType           = $PolicyType
                MinProtocolVersion  = $MinProtocolVersion
            }
            
            if ($CipherSuites) {
                $sslPolicyParams.CipherSuite = $CipherSuites
            }
            
            $sslPolicy = New-AzApplicationGatewaySslPolicy @sslPolicyParams
            Write-Host "$(printf '\u2713') SSL policy created - Type: $PolicyType, Min Protocol: $MinProtocolVersion" -ForegroundColor Green
        }
        
        return $sslPolicy
    }
    catch {
        Write-Error "Failed to create SSL policy: $($_.Exception.Message)"
        throw
    }
}

function New-ApplicationGatewayAutoscaleConfiguration {
    <#
    .SYNOPSIS
        Creates autoscale configuration for Application Gateway v2
    .PARAMETER MinCapacity
        Minimum number of instances
    .PARAMETER MaxCapacity
        Maximum number of instances
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 125)]
        [int]$MinCapacity = 2,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(2, 125)]
        [int]$MaxCapacity = 10
    )
    
    try {
        Write-Host "$(printf '\u2139') Creating autoscale configuration..." -ForegroundColor Blue
        
        if ($MaxCapacity -lt $MinCapacity) {
            throw "MaxCapacity ($MaxCapacity) must be greater than or equal to MinCapacity ($MinCapacity)"
        }
        
        $autoscaleConfig = New-AzApplicationGatewayAutoscaleConfiguration -MinCapacity $MinCapacity -MaxCapacity $MaxCapacity
        
        Write-Host "$(printf '\u2713') Autoscale configuration created - Min: $MinCapacity, Max: $MaxCapacity instances" -ForegroundColor Green
        return $autoscaleConfig
    }
    catch {
        Write-Error "Failed to create autoscale configuration: $($_.Exception.Message)"
        throw
    }
}

function New-ApplicationGatewayWAFConfiguration {
    <#
    .SYNOPSIS
        Creates WAF configuration for Application Gateway
    .PARAMETER Enabled
        Whether WAF is enabled
    .PARAMETER FirewallMode
        WAF firewall mode (Detection or Prevention)
    .PARAMETER RuleSetType
        Rule set type (OWASP)
    .PARAMETER RuleSetVersion
        Rule set version
    .PARAMETER RequestBodyCheck
        Whether to enable request body check
    .PARAMETER MaxRequestBodySizeInKb
        Maximum request body size in KB
    .PARAMETER FileUploadLimitInMb
        File upload limit in MB
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$Enabled = $true,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Detection", "Prevention")]
        [string]$FirewallMode = "Detection",
        
        [Parameter(Mandatory = $false)]
        [string]$RuleSetType = "OWASP",
        
        [Parameter(Mandatory = $false)]
        [string]$RuleSetVersion = "3.2",
        
        [Parameter(Mandatory = $false)]
        [bool]$RequestBodyCheck = $true,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 128)]
        [int]$MaxRequestBodySizeInKb = 128,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 750)]
        [int]$FileUploadLimitInMb = 100
    )
    
    try {
        Write-Host "$(printf '\u2139') Creating WAF configuration..." -ForegroundColor Blue
        
        $wafConfig = New-AzApplicationGatewayWebApplicationFirewallConfiguration `
            -Enabled $Enabled `
            -FirewallMode $FirewallMode `
            -RuleSetType $RuleSetType `
            -RuleSetVersion $RuleSetVersion `
            -RequestBodyCheck $RequestBodyCheck `
            -MaxRequestBodySizeInKb $MaxRequestBodySizeInKb `
            -FileUploadLimitInMb $FileUploadLimitInMb
        
        Write-Host "$(printf '\u2713') WAF configuration created - Mode: $FirewallMode, Rules: $RuleSetType $RuleSetVersion" -ForegroundColor Green
        return $wafConfig
    }
    catch {
        Write-Error "Failed to create WAF configuration: $($_.Exception.Message)"
        throw
    }
}

function New-ApplicationGatewaySku {
    <#
    .SYNOPSIS
        Creates SKU configuration for Application Gateway
    .PARAMETER Name
        SKU name (Standard_v2 or WAF_v2)
    .PARAMETER Tier
        SKU tier (Standard_v2 or WAF_v2)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Standard_v2", "WAF_v2")]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("Standard_v2", "WAF_v2")]
        [string]$Tier
    )
    
    try {
        Write-Host "$(printf '\u2139') Creating SKU configuration..." -ForegroundColor Blue
        
        $sku = New-AzApplicationGatewaySku -Name $Name -Tier $Tier
        
        Write-Host "$(printf '\u2713') SKU configuration created - Name: $Name, Tier: $Tier" -ForegroundColor Green
        return $sku
    }
    catch {
        Write-Error "Failed to create SKU configuration: $($_.Exception.Message)"
        throw
    }
}

# Export all functions
Export-ModuleMember -Function New-ApplicationGatewayIPConfiguration, New-ApplicationGatewayFrontendConfiguration, New-ApplicationGatewayFrontendPort, New-ApplicationGatewayBackendConfiguration, New-ApplicationGatewayListener, New-ApplicationGatewayRoutingRule, New-ApplicationGatewaySSLPolicy, New-ApplicationGatewayAutoscaleConfiguration, New-ApplicationGatewayWAFConfiguration, New-ApplicationGatewaySku
