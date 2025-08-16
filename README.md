# Azure Application Gateway v2 - Enterprise Deployment Framework

A comprehensive PowerShell framework for deploying Azure Application Gateway v2 with enterprise-grade features, multiple configuration options, and production-ready automation.

## Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Parameter Sets](#parameter-sets)
- [Key Differences](#key-differences-basicappgwparams-vs-advancedappgwparams)
- [Configuration Options](#configuration-options)
- [Advanced Features](#advanced-features)
- [Deployment Modes](#deployment-modes)
- [Security Configuration](#security-configuration)
- [Monitoring and Diagnostics](#monitoring-and-diagnostics)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)
- [CI/CD Integration](#cicd-integration)
- [Reference](#reference)

## Overview

This framework provides a robust, enterprise-ready solution for deploying Azure Application Gateway v2 with the following capabilities:

- **Two Simplified Parameter Sets**: Ready-to-use configurations covering all deployment scenarios
- **Flexible Configuration**: Support for public, private, or dual frontend IP configurations
- **Advanced Features**: WAF, SSL/TLS, managed identity, autoscaling, and monitoring
- **What-If Support**: Preview deployments without creating resources
- **Production Ready**: Comprehensive error handling, validation, and logging

### Supported Configuration Types

1. **BasicAppGwParams**: Development, testing, and simple production workloads
2. **AdvancedAppGwParams**: Production, enterprise, and high-security deployments
3. **All Network Modes**: Both parameter sets support PublicOnly, PrivateOnly, or Both frontend configurations

## Key Features

### Core Capabilities
- [OK] **Multi-Configuration Support**: Public, Private, or Both frontend IPs
- [OK] **Autoscaling**: Dynamic scaling based on traffic patterns (1-125 instances)
- [OK] **High Availability**: Multi-zone deployment support (1, 2, 3 zones)
- [OK] **SSL/TLS Management**: Key Vault integration for certificate management
- [OK] **HTTP/2 Support**: Modern protocol support for improved performance

### Advanced Features
- [OK] **WAF Protection**: Web Application Firewall with OWASP rule sets
- [OK] **Custom Health Probes**: Advanced backend health monitoring
- [OK] **URL Path-Based Routing**: Route traffic based on URL paths
- [OK] **HTTP Header Rewriting**: Modify request/response headers
- [OK] **Redirect Configurations**: HTTP to HTTPS redirects
- [OK] **Rate Limiting**: Protect against DDoS and abuse
- [OK] **Session Affinity**: Cookie-based session persistence

### Enterprise Features
- [OK] **Managed Identity**: Secure access to Azure Key Vault
- [OK] **Comprehensive Monitoring**: Health checks and performance metrics
- [OK] **Configuration Backup**: Export/import deployment configurations
- [OK] **Automated Diagnostics**: Built-in troubleshooting and validation
- [OK] **Resource Tagging**: Comprehensive tagging strategy for governance

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Azure Application Gateway v2                 │
├─────────────────────────────────────────────────────────────────┤
│  Frontend Configuration                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │  Public IP  │  │ Private IP  │  │   Ports     │             │
│  │   (Static)  │  │ (Optional)  │  │  80, 443    │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
├─────────────────────────────────────────────────────────────────┤
│  SSL/TLS & Security                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │ Key Vault   │  │    WAF      │  │ SSL Policy  │             │
│  │ Certificates│  │ Protection  │  │   TLS 1.2   │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
├─────────────────────────────────────────────────────────────────┤
│  Routing & Load Balancing                                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │  Listeners  │  │ Routing     │  │ Backend     │             │
│  │ HTTP/HTTPS  │  │   Rules     │  │   Pools     │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────────┐
                    │   Backend Servers   │
                    │  (Web Apps, VMs,    │
                    │   Containers, etc.) │
                    └─────────────────────┘
```

## Prerequisites

### Azure Requirements

1. **Azure Subscription**: Active Azure subscription with required permissions
2. **Resource Group**: Existing resource group or permissions to create one
3. **Virtual Network**: Pre-configured VNet with dedicated subnet (/24 or larger recommended)
4. **Public IP**: Standard SKU public IP with static allocation (for public configurations)

### Azure PowerShell

```powershell
# Install Azure PowerShell (if not already installed)
Install-Module -Name Az -Repository PSGallery -Force -AllowClobber

# Authenticate to Azure
Connect-AzAccount

# Set the subscription context
Set-AzContext -SubscriptionName "your-subscription-name"
```

### Permissions Required

The deployment account needs the following Azure RBAC permissions:
- **Application Gateway Contributor** (or higher)
- **Network Contributor** (for VNet/Subnet access)
- **Key Vault Contributor** (for SSL certificate access)
- **Managed Identity Operator** (for managed identity assignment)

### Optional Requirements (for Enterprise Features)

1. **Key Vault**: For SSL certificate management
   ```powershell
   # Create Key Vault if needed
   New-AzKeyVault -ResourceGroupName "rg-security" -VaultName "kv-appgw-certs" -Location "East US"
   ```

2. **Managed Identity**: For secure Key Vault access
   ```powershell
   # Create User Assigned Managed Identity
   New-AzUserAssignedIdentity -ResourceGroupName "rg-identity" -Name "appgw-identity" -Location "East US"
   ```

3. **SSL Certificates**: Upload certificates to Key Vault
   ```powershell
   # Upload certificate to Key Vault
   .\AppGWv2\certificate.ps1 -VaultName "kv-appgw-certs" -CertName "ssl-cert" -CertPath "cert.pfx"
   ```

## Quick Start

### 1. Clone and Navigate

```powershell
# Clone or download the repository
cd "path/to/APPGWv2"
```

### 2. Choose Your Deployment Method

#### Option A: Pre-configured Parameter Sets (Recommended)

```powershell
# Deploy using parameter sets - no configuration needed
.\AppGWv2\Deploy-AppGWv2.ps1 -ParameterSet "BasicAppGwParams" -WhatIf

# Remove -WhatIf to execute actual deployment
.\AppGWv2\Deploy-AppGWv2.ps1 -ParameterSet "BasicAppGwParams"
```

#### Option B: Individual Parameters

```powershell
# Deploy with custom parameters
.\AppGWv2\Deploy-AppGWv2.ps1 `
    -SubscriptionName "my-subscription" `
    -ResourceGroupName "rg-appgw" `
    -ApplicationGatewayName "my-appgw" `
    -VirtualNetworkName "my-vnet" `
    -SubnetName "appgw-subnet" `
    -PublicIPName "appgw-pip" `
    -ConfigurationType "PublicOnly" `
    -WhatIf
```

#### Option C: Configuration Object

```powershell
# Import parameters module
Import-Module .\AppGWv2\AppGWv2-Parameters.psm1

# Use configuration object
$config = Get-AdvancedAppGwParams
.\AppGWv2\Deploy-AppGWv2.ps1 -AppGatewayConfiguration $config -WhatIf
```

## Parameter Sets

The framework includes two simplified parameter sets that cover all deployment scenarios:

### 1. BasicAppGwParams
**Simple, flexible Application Gateway for development and basic production**

- **Configuration Type**: Configurable (PublicOnly, PrivateOnly, Both)
- **SKU**: Standard_v2 (configurable to WAF_v2)
- **Use Case**: Development, testing, simple production workloads
- **Features**: Basic HTTP/HTTPS listeners, configurable backend pools
- **Scaling**: 1-2 instances (configurable)
- **Security**: Optional WAF, basic SSL support

```powershell
.\AppGWv2\Deploy-AppGWv2.ps1 -ParameterSet "BasicAppGwParams"
```

### 2. AdvancedAppGwParams
**Full-featured Application Gateway for production and enterprise**

- **Configuration Type**: Configurable (PublicOnly, PrivateOnly, Both)
- **SKU**: WAF_v2
- **Use Case**: Production workloads requiring enterprise features
- **Features**: WAF, SSL certificates, managed identity, custom probes, advanced routing
- **Scaling**: 2-3 instances (production optimized)
- **Security**: WAF enabled, Key Vault integration, managed identity

```powershell
.\AppGWv2\Deploy-AppGWv2.ps1 -ParameterSet "AdvancedAppGwParams"
```

## Key Differences: BasicAppGwParams vs AdvancedAppGwParams

| Feature                | BasicAppGwParams                                 | AdvancedAppGwParams                                 |
|-----------------------|--------------------------------------------------|-----------------------------------------------------|
| **SKU**               | Standard_v2                                      | Standard_v2/WAF_v2                                              |
| **ConfigurationType** | PublicOnly, PrivateOnly, Both (configurable)     | PublicOnly, PrivateOnly, Both (configurable)        |
| **SSL/TLS**           | Optional, basic SSL                              | Full Key Vault integration, strong SSL policies      |
| **WAF Protection**    | Optional                                         | Enabled (Prevention mode, custom rules)             |
| **Managed Identity**  | Not configured                                   | Configured for Key Vault and security               |
| **Custom Probes**     | Basic HTTP probe                                 | Multiple, advanced probes (HTTP/HTTPS)              |
| **Frontend Ports**    | HTTP only (80, 8080)                             | HTTP + HTTPS (80, 443)                              |
| **Backend Settings**  | Simple HTTP                                      | HTTP + HTTPS, advanced options                      |
| **Health Probes**     | Single HTTP probe                                | Multiple probes, custom hosts                       |


**Summary:**
- Use `BasicAppGwParams` for simple, non-critical deployments or testing.
- Use `AdvancedAppGwParams` for production, security, compliance, and enterprise features.
- Both support all network modes (Public, Private, Both) via `ConfigurationType`.
- Advanced set includes WAF, managed identity, Key Vault, custom probes, and more robust security and monitoring.

### Why Two Parameter Sets?

**Backward Compatibility**: The framework maintains backward compatibility properties in both parameter sets to support legacy deployment scripts that use individual parameters instead of parameter sets.

**Simplified Choice**: Instead of four confusing parameter sets based on network configuration, we now have two clear choices based on feature requirements:
- **Basic**: For development, testing, and simple production workloads
- **Advanced**: For enterprise, security, and compliance requirements

**Flexible Network Configuration**: Both parameter sets support all network configurations through the `ConfigurationType` parameter:
```powershell
# Same parameter set, different network configurations
$config = Get-BasicAppGwParams
$config.ConfigurationType = "PublicOnly"   # Internet-facing
$config.ConfigurationType = "PrivateOnly"  # Internal only  
$config.ConfigurationType = "Both"         # Hybrid
```

## Configuration Options

### Basic Configuration Parameters

| Parameter | Description | Required | Default |
|-----------|-------------|----------|---------|
| `SubscriptionName` | Azure subscription name | Yes | - |
| `ResourceGroupName` | Resource group for the Application Gateway | Yes | - |
| `ApplicationGatewayName` | Name of the Application Gateway | Yes | - |
| `Location` | Azure region for deployment | No | "East US" |
| `SkuName` | SKU name (Standard_v2, WAF_v2) | No | "Standard_v2" |
| `SkuTier` | SKU tier (Standard_v2, WAF_v2) | No | "Standard_v2" |
| `ConfigurationType` | Frontend IP type (PublicOnly, PrivateOnly, Both) | No | "PublicOnly" |

### Network Configuration Parameters

| Parameter | Description | Required | Default |
|-----------|-------------|----------|---------|
| `VirtualNetworkName` | Virtual Network name | Yes | - |
| `VNetResourceGroupName` | VNet resource group (if different) | No | Same as RG |
| `SubnetName` | Subnet name for Application Gateway | Yes | - |
| `PublicIPName` | Public IP name (for public configurations) | Conditional | - |
| `PublicIPResourceGroupName` | Public IP resource group (if different) | No | Same as RG |
| `PrivateIPAddress` | Static private IP (optional) | No | Dynamic |

### Scaling Configuration Parameters

| Parameter | Description | Required | Default | Range |
|-----------|-------------|----------|---------|-------|
| `MinCapacity` | Minimum autoscale instances | No | 1 | 0-125 |
| `MaxCapacity` | Maximum autoscale instances | No | 2 | 2-125 |
| `AvailabilityZones` | Availability zones for deployment | No | [] | 1,2,3 |

### Advanced Configuration Arrays

The framework supports complex configurations through arrays:

#### Frontend Ports
```powershell
FrontendPorts = @(
    @{ Name = "HttpPort"; Port = 80 },
    @{ Name = "HttpsPort"; Port = 443 },
    @{ Name = "CustomPort"; Port = 8080 }
)
```

#### SSL Certificates
```powershell
SslCertificates = @(
    @{
        Name = "wildcard-cert"
        KeyVaultSecretId = "https://kv-certs.vault.azure.net/secrets/wildcard/version"
    }
)
```

#### Listeners
```powershell
Listeners = @(
    @{ 
        Name = "HttpListener"
        Type = "Http"
        FrontendIP = "publicFrontendIP"
        FrontendPort = 80
    },
    @{ 
        Name = "HttpsListener"
        Type = "Https"
        FrontendIP = "publicFrontendIP"
        FrontendPort = 443
        SslCertificateName = "wildcard-cert"
    }
)
```

#### Backend Pools
```powershell
BackendPools = @(
    @{ Name = "WebPool"; Targets = @("web1.contoso.com", "web2.contoso.com") },
    @{ Name = "ApiPool"; Targets = @("10.0.2.10", "10.0.2.11") }
)
```

#### Backend Settings
```powershell
BackendSettings = @(
    @{ 
        Name = "WebSettings"
        Protocol = "Http"
        Port = 80
        CookieAffinity = "Disabled"
        ConnectionDrainingEnabled = $false
        RequestTimeout = 30
        CustomProbeEnabled = $true
        CustomProbeName = "WebProbe"
    }
)
```

#### Health Probes
```powershell
HealthProbes = @(
    @{
        Name = "WebProbe"
        Protocol = "Http"
        Host = "contoso.com"
        Path = "/health"
        Interval = 30
        Timeout = 30
        UnhealthyThreshold = 3
        StatusCodes = @("200-399")
    }
)
```

#### Routing Rules
```powershell
RoutingRules = @(
    @{ 
        Name = "WebRule"
        Priority = 100
        ListenerName = "HttpsListener"
        BackendPoolName = "WebPool"
        BackendSettingsName = "WebSettings"
    }
)
```

## Advanced Features

### Web Application Firewall (WAF)

WAF protection is automatically configured when using WAF_v2 SKU:

```powershell
# WAF Configuration
EnableWAF = $true
WAFMode = "Prevention"  # or "Detection"
WAFRuleSetVersion = "3.2"  # Latest OWASP rule set

# WAF Custom Rules (AdvancedAppGwParams only)
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
```

### SSL/TLS Configuration

#### SSL Policy Configuration
```powershell
SslPolicyType = "Predefined"
SslPolicyName = "AppGwSslPolicy20220101S"  # TLS 1.2 minimum
```

#### Key Vault Integration
```powershell
# Managed Identity for Key Vault access
UserAssignedIdentities = @("/subscriptions/.../userAssignedIdentities/appgw-identity")

# SSL Certificates from Key Vault
SslCertificates = @(
    @{
        Name = "primary-cert"
        KeyVaultSecretId = "https://keyvault.vault.azure.net/secrets/cert/version"
    }
)
```

### Redirect Configurations

```powershell
RedirectConfigurations = @(
    @{
        Name = "HttpToHttpsRedirect"
        RedirectType = "Permanent"
        TargetUrl = "https://contoso.com{var_uri_path}"
        IncludePath = $true
        IncludeQueryString = $true
    }
)
```

### URL Path Maps

```powershell
UrlPathMaps = @(
    @{
        Name = "PathMap1"
        DefaultBackendPoolName = "DefaultPool"
        DefaultBackendSettingsName = "DefaultSettings"
        PathRules = @(
            @{
                Name = "ApiRule"
                Paths = @("/api/*")
                BackendPoolName = "ApiPool"
                BackendSettingsName = "ApiSettings"
            }
        )
    }
)
```

### Rewrite Rule Sets

```powershell
RewriteRuleSets = @(
    @{
        Name = "HeaderRewrite"
        RewriteRules = @(
            @{
                Name = "AddSecurityHeaders"
                RuleSequence = 100
                ActionSet = @{
                    ResponseHeaderConfigurations = @(
                        @{
                            HeaderName = "X-Content-Type-Options"
                            HeaderValue = "nosniff"
                        }
                    )
                }
            }
        )
    }
)
```

## Deployment Modes

### What-If Mode (Recommended for Testing)

Always test your deployment first:

```powershell
# Preview what will be created without making changes
.\AppGWv2\Deploy-AppGWv2.ps1 -ParameterSet "BasicAppGwParams" -WhatIf
```

What-If mode provides:
- [OK] Configuration validation without Azure resource creation
- [OK] Parameter compatibility checks
- [OK] Resource dependency validation
- [OK] Security configuration review

### Simulation Mode

When Azure PowerShell modules are not available or in CI/CD environments:

```powershell
# Automatic simulation mode when Azure modules unavailable
.\AppGWv2\Deploy-AppGWv2.ps1 -ParameterSet "BasicAppGwParams"
```

Simulation mode provides:
- [OK] Full configuration validation
- [OK] Mock resource object creation
- [OK] Deployment summary without Azure calls
- [OK] JSON output for review

### Production Deployment

After successful What-If validation:

```powershell
# Execute actual deployment
.\AppGWv2\Deploy-AppGWv2.ps1 -ParameterSet "AdvancedAppGwParams"
```

Production deployment includes:
- [OK] Real Azure resource creation
- [OK] Complete error handling and rollback
- [OK] Deployment status monitoring
- [OK] JSON output file generation

## Security Configuration

### SSL/TLS Best Practices

1. **Modern SSL Policy**: Uses TLS 1.2+ with strong cipher suites
2. **Key Vault Integration**: Certificates stored securely in Azure Key Vault
3. **Managed Identity**: Secure access to Key Vault without credential storage
4. **Automatic Certificate Rotation**: Supports Key Vault automatic rotation

### WAF Protection

1. **OWASP Rule Sets**: Latest security rules for common attacks
2. **Custom Rules**: Rate limiting and IP-based blocking
3. **Prevention Mode**: Active blocking of malicious traffic
4. **Monitoring**: Detailed logs and metrics for security events

### Network Security

1. **Subnet Isolation**: Dedicated subnet for Application Gateway
2. **Private Endpoints**: Support for private connectivity
3. **Network Security Groups**: Configurable traffic filtering
4. **Azure DDoS Protection**: Integration with Azure DDoS protection

## Monitoring and Diagnostics

### Built-in Health Checks

```powershell
# Custom health probes configuration
HealthProbes = @(
    @{
        Name = "ApiHealthProbe"
        Protocol = "Https"
        Host = "api.contoso.com"
        Path = "/health"
        Interval = 30
        Timeout = 30
        UnhealthyThreshold = 3
        StatusCodes = @("200", "404")  # Custom success codes
    }
)
```

### Monitoring Integration

The framework automatically configures:
- [OK] Application Gateway metrics
- [OK] Access logs and performance logs
- [OK] WAF logs (when enabled)
- [OK] Health probe status monitoring

### Output and Logging

```powershell
# Deployment generates detailed JSON output
OutputPath = ".\output"  # Configurable output directory

# Generated files:
# - appgw-deployment-YYYYMMDD-HHMMSS.json: Complete deployment details
# - Configuration validation results
# - Error logs and troubleshooting information
```

## Troubleshooting

### Common Issues and Solutions

#### 1. SSL Certificate Access Issues

**Problem**: WAF_v2 deployment fails with Key Vault SSL certificates

**Solution**: Ensure managed identity is configured and has Key Vault access
```powershell
# Verify managed identity configuration
UserAssignedIdentities = @("/subscriptions/xxx/resourcegroups/xxx/providers/Microsoft.ManagedIdentity/userAssignedIdentities/appgw-identity")

# Grant Key Vault access policy
Set-AzKeyVaultAccessPolicy -VaultName "kv-name" -ObjectId "identity-object-id" -PermissionsToSecrets Get
```

#### 2. Parameter Set Not Found

**Problem**: Error "Parameter set 'BasicAppGwParams' not found"

**Solution**: Import the parameters module first
```powershell
Import-Module .\AppGWv2\AppGWv2-Parameters.psm1 -Force
.\AppGWv2\Deploy-AppGWv2.ps1 -ParameterSet "BasicAppGwParams"
```

#### 3. Subnet Size Issues

**Problem**: Deployment fails due to insufficient IP addresses

**Solution**: Use /24 or larger subnet for Application Gateway
```powershell
# Recommended subnet configuration
# Minimum: /27 (32 IPs)
# Recommended: /24 (256 IPs) for production
# Required: Dedicated subnet for Application Gateway only
```

#### 4. Public IP Configuration

**Problem**: Public IP requirements not met

**Solution**: Ensure Standard SKU and Static allocation
```powershell
# Create proper public IP
New-AzPublicIpAddress -ResourceGroupName "rg-name" -Name "appgw-pip" -Location "East US" -AllocationMethod Static -Sku Standard
```

### Diagnostic Commands

```powershell
# Check Application Gateway status
Get-AzApplicationGateway -ResourceGroupName "rg-name" -Name "appgw-name"

# Verify backend health
Get-AzApplicationGatewayBackendHealth -ResourceGroupName "rg-name" -Name "appgw-name"

# Check WAF logs (if enabled)
Get-AzLog -ResourceId "/subscriptions/.../providers/Microsoft.Network/applicationGateways/appgw-name" -StartTime (Get-Date).AddHours(-1)
```

### Error Handling

The framework includes comprehensive error handling:

1. **Pre-deployment Validation**: Checks all prerequisites before deployment
2. **Azure Resource Validation**: Verifies existing resources and dependencies
3. **Configuration Validation**: Ensures parameter compatibility
4. **Rollback Support**: Provides guidance for failed deployments
5. **Detailed Logging**: Comprehensive error messages with troubleshooting steps

## Best Practices

### Planning and Design

1. **Subnet Planning**: Use dedicated /24 subnet for Application Gateway
2. **Naming Convention**: Use consistent naming across resources
3. **Resource Groups**: Organize related resources in logical groups
4. **Availability Zones**: Use multiple zones for high availability

### Security Best Practices

1. **WAF Configuration**: Always use WAF_v2 for internet-facing deployments
2. **SSL/TLS**: Use strong SSL policies and modern cipher suites
3. **Certificate Management**: Store certificates in Azure Key Vault
4. **Access Control**: Use managed identities for service-to-service authentication

### Performance Optimization

1. **Autoscaling**: Configure appropriate min/max capacity based on traffic patterns
2. **Health Probes**: Use custom health probes for accurate backend monitoring
3. **Connection Draining**: Enable connection draining for maintenance scenarios
4. **Session Affinity**: Use cookie-based affinity only when required

### Operational Excellence

1. **Monitoring**: Implement comprehensive monitoring and alerting
2. **Backup**: Regular configuration backups and documentation
3. **Testing**: Always use What-If mode before production deployments
4. **Updates**: Regular updates to maintain security and performance

### Cost Optimization

1. **Right Sizing**: Start with smaller capacity and scale based on usage
2. **Resource Sharing**: Share Application Gateways across multiple applications when appropriate
3. **Reserved Instances**: Consider reserved instances for long-term deployments
4. **Monitoring**: Regular cost monitoring and optimization

## CI/CD Integration

### Azure DevOps Pipeline

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
    - main
  paths:
    include:
    - AppGWv2/*

pool:
  vmImage: 'windows-latest'

variables:
  azureSubscription: 'Azure-Service-Connection'
  resourceGroupName: 'rg-appgw-prod'

stages:
- stage: Validate
  displayName: 'Validate Deployment'
  jobs:
  - job: WhatIf
    displayName: 'What-If Analysis'
    steps:
    - task: AzurePowerShell@5
      displayName: 'Run What-If Deployment'
      inputs:
        azureSubscription: $(azureSubscription)
        ScriptType: 'FilePath'
        ScriptPath: 'AppGWv2/Deploy-AppGWv2.ps1'
        ScriptArguments: '-ParameterSet "AdvancedAppGwParams" -WhatIf'
        azurePowerShellVersion: 'LatestVersion'

- stage: Deploy
  displayName: 'Deploy Application Gateway'
  dependsOn: Validate
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
  jobs:
  - deployment: DeployAppGW
    displayName: 'Deploy Application Gateway'
    environment: 'production'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzurePowerShell@5
            displayName: 'Deploy Application Gateway'
            inputs:
              azureSubscription: $(azureSubscription)
              ScriptType: 'FilePath'
              ScriptPath: 'AppGWv2/Deploy-AppGWv2.ps1'
              ScriptArguments: '-ParameterSet "AdvancedAppGwParams"'
              azurePowerShellVersion: 'LatestVersion'
```

### GitHub Actions Workflow

```yaml
# .github/workflows/deploy-appgw.yml
name: Deploy Application Gateway

on:
  push:
    branches: [ main ]
    paths: [ 'AppGWv2/**' ]
  pull_request:
    branches: [ main ]
    paths: [ 'AppGWv2/**' ]

env:
  AZURE_SUBSCRIPTION: 'your-subscription-id'
  RESOURCE_GROUP: 'rg-appgw-prod'

jobs:
  validate:
    runs-on: windows-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
    
    - name: Install Azure PowerShell
      uses: azure/powershell@v1
      with:
        inlineScript: |
          Install-Module -Name Az -Repository PSGallery -Force -AllowClobber
        azPSVersion: 'latest'
    
    - name: Validate Deployment
      uses: azure/powershell@v1
      with:
        inlineScript: |
          .\AppGWv2\Deploy-AppGWv2.ps1 -ParameterSet "AdvancedAppGwParams" -WhatIf
        azPSVersion: 'latest'

  deploy:
    needs: validate
    runs-on: windows-latest
    if: github.ref == 'refs/heads/main'
    environment: production
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
    
    - name: Deploy Application Gateway
      uses: azure/powershell@v1
      with:
        inlineScript: |
          .\AppGWv2\Deploy-AppGWv2.ps1 -ParameterSet "AdvancedAppGwParams"
        azPSVersion: 'latest'
```

## Reference

### File Structure

```
APPGWv2/
├── AppGWv2/
│   ├── AppGWv2-Parameters.psm1     # Parameter set definitions
│   ├── Deploy-AppGWv2.ps1          # Main deployment script
│   ├── certificate.ps1             # Certificate upload utility
│   └── output/                     # Deployment output files
├── Common-Modules/
│   ├── ValidationHelpers.psm1      # Validation functions
│   └── ConfigurationHelpers.psm1   # Configuration helpers
└── README.md                       # This documentation
```

### Script Parameters Reference

#### Deploy-AppGWv2.ps1 Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `ParameterSet` | String | Yes* | Parameter set name (BasicAppGwParams, AdvancedAppGwParams) |
| `AppGatewayConfiguration` | Hashtable | Yes* | Configuration object mode |
| `SubscriptionName` | String | Yes* | Azure subscription name |
| `ResourceGroupName` | String | Yes* | Resource group name |
| `ApplicationGatewayName` | String | Yes* | Application Gateway name |
| `WhatIf` | Switch | No | Preview deployment without creating resources |

*Required based on parameter set used

### Parameter Set Comparison

| Feature | BasicAppGwParams | AdvancedAppGwParams |
|---------|------------------|---------------------|
| **Configuration Type** | Configurable (PublicOnly/PrivateOnly/Both) | Configurable (PublicOnly/PrivateOnly/Both) |
| **Default SKU** | Standard_v2 | WAF_v2 |
| **SSL Certificates** | Basic | Full Key Vault Integration |
| **WAF Protection** | Optional | Enabled (Prevention Mode) |
| **Managed Identity** | No | Yes |
| **Custom Probes** | Basic | Advanced with custom settings |
| **Autoscaling** | 1-2 instances | 2-3 instances |
| **HTTPS Support** | Optional | Enabled by default |
| **HTTP/2 Support** | Enabled | Enabled |
| **Availability Zones** | None | Configurable |
| **WAF Custom Rules** | None | Rate limiting and custom rules |
| **Frontend Ports** | Standard (80, 8080) | Standard + HTTPS (80, 443) |
| **Backend Settings** | Basic HTTP | HTTP + HTTPS with advanced options |
| **Health Probes** | Simple HTTP probe | Multiple probes (HTTP/HTTPS) |
| **Redirect Rules** | None | HTTP to HTTPS redirect |
| **Use Case** | Development, Testing, Simple Production | Production, Enterprise, High Security |

### Related Resources

- [Azure Application Gateway Documentation](https://docs.microsoft.com/en-us/azure/application-gateway/)
- [Azure PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/azure/)
- [Application Gateway Pricing](https://azure.microsoft.com/en-us/pricing/details/application-gateway/)
- [WAF Protection Overview](https://docs.microsoft.com/en-us/azure/web-application-firewall/)

### Support and Contributing

For issues, questions, or contributions:

1. **Issues**: Create detailed issue reports with configuration and error details
2. **Feature Requests**: Submit enhancement requests with use case descriptions
3. **Contributions**: Follow PowerShell best practices and include tests
4. **Documentation**: Help improve documentation with real-world examples



