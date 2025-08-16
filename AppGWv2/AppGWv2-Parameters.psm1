# Application Gateway v2 Universal Parameter Configuration File
#
# PURPOSE:
#    Simplified parameter configurations for Application Gateway deployment
#    Two parameter sets cover all deployment scenarios
#
# USAGE:
#   # Basic deployment for simple scenarios
#   Import-Module .\AppGWv2-Parameters.psm1
#   .\Deploy-AppGWv2.ps1 -ParameterSet "BasicAppGwParams"
#
#   # Advanced deployment with all features
#   .\Deploy-AppGWv2.ps1 -ParameterSet "AdvancedAppGwParams"
#


# Basic Application Gateway configuration (Standard_v2)
# Supports all ConfigurationType options: "PublicOnly", "PrivateOnly", "Both"
$BasicAppGwParams = @{
    # Main Configuration
    SubscriptionName              = "kasdev"
    ResourceGroupName             = "kasdev-devtest-app-001"
    Location                      = "East US"
    ApplicationGatewayName        = "appgw-basic-v2"
    SkuName                       = "Standard_v2" # or "WAF_v2"
    SkuTier                       = "Standard_v2" # or "WAF_v2"
    ConfigurationType             = "PublicOnly" # Change to "PrivateOnly" or "Both" as needed
    PrivateIPAddress              = ""
    MinCapacity                   = 2
    MaxCapacity                   = 4
    AvailabilityZones             = @()
    OutputPath                    = ".\output"
    WhatIf                        = $false

    # Network Configuration
    VirtualNetworkName            = "test"
    VNetResourceGroupName         = "appgw"
    SubnetName                    = "test1"
    PublicIPName                  = "testpip"
    PublicIPResourceGroupName     = "appgw"
    
    # Listeners Configuration
    Listeners = @(
        @{ Name = "HttpListener"; Type = "Http"; FrontendIP = "publicFrontendIP"; FrontendPort = 80 },
        @{ Name = "CustomHttpListener"; Type = "Http"; FrontendIP = "publicFrontendIP"; FrontendPort = 8080 }
    )
      # Backend Settings Configuration
    BackendSettings = @(
        @{ Name = "WebAppSettings"; Protocol = "Http"; Port = 80; CookieAffinity = "Disabled"; ConnectionDrainingEnabled = $false; ConnectionDrainingTimeout = 20; RequestTimeout = 30; OverridePath = ""; HostNameOverrideEnabled = $false; HostNameOverrideValue = ""; CustomProbeEnabled = $false; CustomProbeName = "" },
        @{ Name = "ApiSettings"; Protocol = "Http"; Port = 8080; CookieAffinity = "Disabled"; ConnectionDrainingEnabled = $true; ConnectionDrainingTimeout = 30; RequestTimeout = 60; OverridePath = "/api"; HostNameOverrideEnabled = $false; HostNameOverrideValue = ""; CustomProbeEnabled = $false; CustomProbeName = "" }
    )

    

    # Backend Pools Configuration
    BackendPools = @(
        @{ Name = "WebAppPool"; Targets = @("10.0.2.10", "10.0.2.11", "10.0.2.12") },
        @{ Name = "ApiPool"; Targets = @("10.0.3.10", "10.0.3.11") }
    )
    
    # Routing Rules Configuration
    RoutingRules = @(
        @{ Name = "HttpToHttpsRedirect"; Priority = 100; ListenerName = "HttpListener"; BackendPoolName = "WebAppPool"; BackendSettingsName = "WebAppSettings" },
        @{ Name = "WebAppRule"; Priority = 200; ListenerName = "CustomHttpListener"; BackendPoolName = "ApiPool"; BackendSettingsName = "ApiSettings" }
    )
    
    # SSL and Security Configuration
    SslPolicyType                 = "Predefined"
    SslPolicyName                 = "AppGwSslPolicy20220101S"
    EnableWAF                     = $false
    WAFMode                       = "Detection"
    WAFRuleSetVersion             = "3.2"
    EnableHttps                   = $false
    HttpsListenerName             = ""
    EnableHttp2                   = $true

    # Advanced Features Configuration
    Tags = @{
        DeploymentType = "Github-Actions"
       
    }

    # Health Probes Configuration
    HealthProbes = @(
        @{
            Name = "DefaultHealthProbe"
            Protocol = "Http"
            Host = "127.0.0.1"
            Path = "/health"
            Interval = 30
            Timeout = 30
            UnhealthyThreshold = 3
            StatusCodes = @("200-399")
        }
    )

    # URL Path Maps Configuration  
    UrlPathMaps = @()

    # Redirect Configurations
    RedirectConfigurations = @()

    # Rewrite Rule Sets Configuration
    RewriteRuleSets = @()

    # WAF Custom Rules Configuration
    WAFCustomRules = @()    
    

}

# Advanced Application Gateway configuration with all features
# ConfigurationType options: "PublicOnly", "PrivateOnly", or "Both" - all configurations will work
$AdvancedAppGwParams = @{
    # Main Configuration
    SubscriptionName              = "kasdev"
    ResourceGroupName             = "kasdev-devtest-app-001"
    Location                      = "East US"
    ApplicationGatewayName        = "appgw-basic-v2"
    SkuName                       = "Standard_v2"
    SkuTier                       = "Standard_v2"
    ConfigurationType             = "PublicOnly" # Change to "PublicOnly" or "PrivateOnly" or Both as needed
    PrivateIPAddress              = ""
    MinCapacity                   = 2
    MaxCapacity                   = 3
    AvailabilityZones             = @()
    OutputPath                    = ".\output"
    WhatIf                        = $false

    # Network Configuration
    VirtualNetworkName            = "test"
    VNetResourceGroupName         = "appgw"
    SubnetName                    = "test1"
    PublicIPName                  = "testpip"
    PublicIPResourceGroupName     = "appgw"
    
    # Frontend Ports Configuration
    FrontendPorts = @(
        @{ Name = "HttpPort"; Port = 80 },        @{ Name = "HttpsPort"; Port = 443 }
    )

    # SSL Certificates Configuration
    SslCertificates = @(
        @{
            Name = "mycert"
            KeyVaultSecretId = "https://kskv-001.vault.azure.net/secrets/cert/edf00e59d1a246a1a2b967d6694ffbc9"
        }
    )
    
    # Custom Probes Configuration
    CustomProbes = @()
    
    # Listeners Configuration
    Listeners = @(
        @{ Name = "HttpListener"; Type = "Http"; FrontendIP = "publicFrontendIP"; FrontendPort = 80 },
        @{ Name = "HttpsListener"; Type = "Https"; FrontendIP = "publicFrontendIP"; FrontendPort = 443; SslCertificateName = "mycert" }
    )

    # Backend Settings Configuration
    BackendSettings = @(
        @{ 
            Name = "WebAppSettings"
            Protocol = "Http"
            Port = 80
            CookieAffinity = "Disabled"
            ConnectionDrainingEnabled = $false
            ConnectionDrainingTimeout = 20
            RequestTimeout = 30
            OverridePath = ""
            HostNameOverrideEnabled = $false
            HostNameOverrideValue = ""
            CustomProbeEnabled = $true
            CustomProbeName = "WebAppProbe-001"
        },        
        @{ 
            Name = "HttpsSettings"
            Protocol = "Https"
            Port = 443
            CookieAffinity = "Enabled"
            ConnectionDrainingEnabled = $false
            ConnectionDrainingTimeout = 30
            RequestTimeout = 60
            OverridePath = ""
            HostNameOverrideEnabled = $true
            HostNameOverrideValue = ""
            CustomProbeEnabled = $true
            CustomProbeName = "custom-Probe-001"
        }
    )

    # Backend Pools Configuration
    BackendPools = @(
        @{ Name = "WebAppPool"; Targets = @("kasdevtech.com") },
        @{ Name = "ApiPool"; Targets = @("google.com") }
    )

    # Routing Rules Configuration
    RoutingRules = @(
        @{ Name = "HttpToHttpsRedirect"; Priority = 100; ListenerName = "HttpListener"; BackendPoolName = "WebAppPool"; BackendSettingsName = "WebAppSettings" },
        @{ Name = "WebAppRule"; Priority = 200; ListenerName = "HttpsListener"; BackendPoolName = "ApiPool"; BackendSettingsName = "HttpsSettings" }
    )
    
 
    

        # WAF Configuration
    EnableWAF                     = $true
    WAFMode                       = "Prevention"
    WAFRuleSetVersion             = "3.2"

    # WAF Custom Rules Configuration
    WAFCustomRules = @(
        @{
            Name = "RateLimitRule"
            Priority = 100
            RuleType = "RateLimitRule"
            RateLimitDuration = "OneMin"
            RateLimitThreshold = 100
            MatchConditions = @(
                @{
                    MatchVariables = @(@{ VariableName = "RemoteAddr" })
                    Operator = "IPMatch"
                    MatchValues = @("0.0.0.0/0")
                }
            )
            Action = "Block"
        }
    )



    # Tags Configuration
       Tags = @{
        DeploymentType = "Github-Actions"
       
    }

    # Health Probes Configuration
    HealthProbes = @(
        @{
            Name = "WebAppProbe-001"
            Protocol = "Http"
            Host = "kasdevtech.com"
            Path = "/health"
            Interval = 30
            Timeout = 30
            UnhealthyThreshold = 3
            StatusCodes = @("200-399")
        },
        @{
            Name = "custom-Probe-001"
            Protocol = "Https"
            Host = "google.com"
            Path = ""
            Interval = 15
            Timeout = 30
            UnhealthyThreshold = 2
            StatusCodes = @("200", "202")
        }
    )
    
    # URL Path Maps Configuration  
    UrlPathMaps = @()

    # Redirect Configurations
    RedirectConfigurations = @()

    # Rewrite Rule Sets Configuration
    RewriteRuleSets = @()

    # SSL and Security Configuration
    SslPolicyType                 = "Predefined"
    SslPolicyName                 = "AppGwSslPolicy20220101S"
    EnableHttps                   = $true
    HttpsListenerName             = "HttpsListener"
    EnableHttp2                   = $true

    # Identity Configuration
    UserAssignedIdentities        = @("/subscriptions/482d2c7b-7de6-45ff-a073-c1ddfc44a3f7/resourcegroups/kasdev-devtest-app-001/providers/Microsoft.ManagedIdentity/userAssignedIdentities/appgw-mi")


}

# Usage Examples
# Import the module first:
# Import-Module .\AppGWv2-Parameters.psm1
#
# Then deploy using the unified script:
# .\Deploy-AppGateway.ps1 -AppGatewayConfiguration $BasicAppGwParams
# .\Deploy-AppGateway.ps1 -ParameterSet "BasicAppGwParams"
# .\Deploy-AppGateway.ps1 -AppGatewayConfiguration $AdvancedAppGwParams



# Parameter Descriptions
<#
SubscriptionName          : Azure subscription name
ResourceGroupName         : Resource group containing the Application Gateway (tags will be inherited from RG)
ApplicationGatewayName    : Name for the Application Gateway
Location                  : Azure region for deployment
VirtualNetworkName        : Virtual Network name (must exist)
VNetResourceGroupName     : Resource group containing the VNet (can be different)
SubnetName                : Subnet name for Application Gateway (must exist)
PublicIPName              : Public IP name (must exist, Standard SKU, Static allocation)
PublicIPResourceGroupName : Resource group containing the Public IP (can be different)
ConfigurationType         : Frontend configuration (PublicOnly, PrivateOnly, Both)
PrivateIPAddress          : Static private IP address (required for PrivateOnly/Both)
SkuName                   : Application Gateway SKU (Standard_v2 or WAF_v2)
SkuTier                   : Application Gateway tier (Standard_v2 or WAF_v2)
BackendAddresses          : Array of backend server IP addresses or FQDNs
BackendPort               : Backend server port number
BackendProtocol           : Backend protocol (Http or Https)
HttpPort                  : HTTP frontend port (default: 80)
HttpsPort                 : HTTPS frontend port (default: 443)
EnableHttps               : Enable HTTPS listener and certificate
MinCapacity               : Minimum autoscaling capacity (0-125)
MaxCapacity               : Maximum autoscaling capacity (2-125)
AvailabilityZones         : Availability zones for deployment
SslPolicyType             : SSL policy type (Predefined or Custom)
SslPolicyName             : SSL policy name for predefined policies
EnableWAF                 : Enable Web Application Firewall (requires WAF_v2 SKU)
WAFMode                   : WAF mode (Detection or Prevention)
WAFRuleSetVersion         : WAF rule set version (e.g., "3.2")
EnableHttp2               : Enable HTTP/2 protocol support
CookieBasedAffinity       : Cookie-based session affinity (Enabled or Disabled)
RequestTimeout            : Request timeout in seconds
WhatIf                    : Preview deployment without creating resources
OutputPath                : Path for deployment output files
#>

# Functions to get parameter sets
function Get-BasicAppGwParams { return $BasicAppGwParams }
function Get-AdvancedAppGwParams { return $AdvancedAppGwParams }

# Smart Configuration Function - Automatically selects best configuration
function Get-AppGatewayConfiguration {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("BasicAppGwParams", "AdvancedAppGwParams")]
        [string]$ParameterSet,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$CustomSettings = @{}
    )
    
    $baseConfig = switch ($ParameterSet) {
        "BasicAppGwParams" { $BasicAppGwParams.Clone() }
        "AdvancedAppGwParams" { $AdvancedAppGwParams.Clone() }
    }
    
    # Merge custom settings
    foreach ($key in $CustomSettings.Keys) {
        $baseConfig[$key] = $CustomSettings[$key]
    }
    
    return $baseConfig
}

# Export parameter sets for easy import
Export-ModuleMember -Function @(
    'Get-BasicAppGwParams',
    'Get-AdvancedAppGwParams',
    'Get-AppGatewayConfiguration'
)

Export-ModuleMember -Variable @(
    'BasicAppGwParams',
    'AdvancedAppGwParams'
)

