# Variables
$vaultName   = "kskv-001"
$certName    = "cert"
$PFX_FILE="$HOME/Downloads/cert.pfx" 
$pfxPassword = "Kasi@1993"

# Read the PFX file as Base64
$pfxBytes   = Get-Content -Path $PFX_FILE -AsByteStream
$pfxBase64  = [System.Convert]::ToBase64String($pfxBytes)

# Store in Key Vault as a secret
$secretValue = ConvertTo-SecureString -String $pfxBase64 -AsPlainText -Force
Set-AzKeyVaultSecret -VaultName $vaultName -Name $certName -SecretValue $secretValue

Write-Host "✅ PFX certificate uploaded as secret '$certName' in Key Vault '$vaultName'"
