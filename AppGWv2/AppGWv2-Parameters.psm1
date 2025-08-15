# ==============================================================================
# Standard Application Gateway v2 - Parameter Configuration File
# ==============================================================================
#
# PURPOSE:
#   Example parameter configurations for Standard Application Gateway deployment
#   Copy and modify these parameters for your specific environment
#
# USAGE:
#   1. Update the parameters below with your environment values
#   2. Run: .\Deploy-StandardAppGateway.ps1 @StandardAppGatewayParams
#
# ==============================================================================

# Example 1: Basic Standard_v2 Application Gateway (PublicOnly)
$StandardAppGatewayParams = @{
    # Subscription and Resource Group
    SubscriptionName              = "kasdev"
    ResourceGroupName             = "kasdev-devtest-app-001"
    Location                      = "East US"
    
    # Application Gateway Configuration
    ApplicationGatewayName        = "appgw-standard-v2"
    SkuName                       = "Standard_v2"
    SkuTier                       = "Standard_v2"
    
    # Network Configuration
    VirtualNetworkName            = "test"
    VNetResourceGroupName         = "appgw"  # Can be different from AppGW RG
    SubnetName                    = "test1"
    
    # Public IP Configuration (for PublicOnly/Both configurations)
    PublicIPName                  = "testpip"
    PublicIPResourceGroupName     = "appgw"  # Can be different from AppGW RG
    
    # Configuration Type and Private IP (optional)
    ConfigurationType             = "PublicOnly"  # PublicOnly, PrivateOnly, Both
    PrivateIPAddress              = ""  # Required for PrivateOnly/Both
    
    # Backend Configuration
    BackendAddresses              = @("google.com", "kasdevtech.com")
    BackendPort                   = 80
    BackendProtocol               = "Http"
    
    # Frontend Configuration
    HttpPort                      = 80
    HttpsPort                     = 443
    EnableHttps                   = $true  # Enable HTTPS for secure communication

    # Autoscaling Configuration
    MinCapacity                   = 2
    MaxCapacity                   = 4
    AvailabilityZones             = @()
    
    # SSL Configuration
    SslPolicyType                 = "Predefined"
    SslPolicyName                 = "AppGwSslPolicy20220101S"
    
    # Advanced Configuration
    HttpsListenerName             = "myHttpsListener"
    EnableHttp2                   = $true
    CookieBasedAffinity           = "Disabled"
    RequestTimeout                = 30

    # Key Vault for certificates (optional)
    SslCertificateName            = "kasi"
    KeyVaultSecretId              = "https://kskv-001.vault.azure.net/secrets/cert/edf00e59d1a246a1a2b967d6694ffbc9"

    # Deployment Options
    WhatIf                        = $false
    OutputPath                    = ".\output"
}

# Example 2: WAF_v2 Application Gateway with HTTPS (Both Public and Private)
$WAFAppGatewayParams = @{
    # Subscription and Resource Group
    SubscriptionName              = "kasdev"
    ResourceGroupName             = "kasdev-devtest-app-001"
    Location                      = "East US"
    
    # Application Gateway Configuration
    ApplicationGatewayName        = "appgw-waf-v2-prod"
    SkuName                       = "WAF_v2"
    SkuTier                       = "WAF_v2"
    
    # Network Configuration
    VirtualNetworkName            = "vnet-prod-eastus"
    VNetResourceGroupName         = "kasdev-devtest-app-001"
    SubnetName                    = "snet-appgw-prod"
    
    # Public IP Configuration
    PublicIPName                  = "pip-appgw-waf-prod"
    PublicIPResourceGroupName     = "kasdev-devtest-app-001"
    
    # Configuration Type and Private IP
    ConfigurationType             = "Both"  # Both public and private frontends
    PrivateIPAddress              = "10.0.1.100"
    
    # Backend Configuration
    BackendAddresses              = @("app1.contoso.com", "app2.contoso.com")
    BackendPort                   = 443
    BackendProtocol               = "Https"
    
    # Frontend Configuration
    HttpPort                      = 80
    HttpsPort                     = 443
    EnableHttps                   = $true
    
    # Autoscaling Configuration
    MinCapacity                   = 3
    MaxCapacity                   = 20
    AvailabilityZones             = @("1", "2", "3")
    
    # SSL Configuration
    SslPolicyType                 = "Predefined"
    SslPolicyName                 = "AppGwSslPolicy20220101S"
    
    # WAF Configuration
    EnableWAF                     = $true
    WAFMode                       = "Prevention"
    WAFRuleSetVersion             = "3.2"
    
    # Advanced Configuration
    EnableHttp2                   = $true
    CookieBasedAffinity           = "Enabled"
    RequestTimeout                = 60
    
    # Deployment Options
    WhatIf                        = $false
    OutputPath                    = ".\output"
}

# Example 3: Private-Only Application Gateway (Internal Load Balancer)
$PrivateOnlyAppGatewayParams = @{
    # Subscription and Resource Group
    SubscriptionName              = "aa-ba-nonprod-spoke"
    ResourceGroupName             = "rg-appgw-internal"
    Location                      = "East US"
    
    # Application Gateway Configuration
    ApplicationGatewayName        = "appgw-internal-v2"
    SkuName                       = "Standard_v2"
    SkuTier                       = "Standard_v2"
    
    # Network Configuration
    VirtualNetworkName            = "vnet-hub-eastus"
    VNetResourceGroupName         = "rg-network-shared"
    SubnetName                    = "snet-appgw-internal"
    
    # Configuration Type and Private IP (required for private-only)
    ConfigurationType             = "PrivateOnly"
    PrivateIPAddress              = "10.0.1.200"
    
    # Backend Configuration
    BackendAddresses              = @("10.0.3.10", "10.0.3.11", "10.0.3.12")
    BackendPort                   = 8080
    BackendProtocol               = "Http"
    
    # Frontend Configuration
    HttpPort                      = 80
    HttpsPort                     = 443
    EnableHttps                   = $false
    
    # Autoscaling Configuration
    MinCapacity                   = 2
    MaxCapacity                   = 8
    AvailabilityZones             = @("1", "2", "3")
    
    # SSL Configuration
    SslPolicyType                 = "Predefined"
    SslPolicyName                 = "AppGwSslPolicy20220101S"
    
    # Advanced Configuration
    EnableHttp2                   = $true
    CookieBasedAffinity           = "Disabled"
    RequestTimeout                = 30
    
    # Deployment Options
    WhatIf                        = $true  # Preview mode
    OutputPath                    = ".\output"
}

# ==============================================================================
# Usage Examples:
# ==============================================================================
#
# Import the module first:
# Import-Module .\StandardAppGateway-Parameters.psm1
#
# Then deploy using the parameter sets:
# .\Deploy-StandardAppGateway.ps1 @StandardAppGatewayParams
# .\Deploy-StandardAppGateway.ps1 @WAFAppGatewayParams
# .\Deploy-StandardAppGateway.ps1 @PrivateOnlyAppGatewayParams
#
# ==============================================================================

# ==============================================================================
# PARAMETER DESCRIPTIONS
# ==============================================================================

<#
SubscriptionName          : Azure subscription name (must start with "aa-ba-")
ResourceGroupName         : Resource group containing the Application Gateway
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

# Export parameter sets for easy import
Export-ModuleMember -Variable @(
    'StandardAppGatewayParams',
    'WAFAppGatewayParams',
    'PrivateOnlyAppGatewayParams'
)

