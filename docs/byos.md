# Bring Your Own Secret

You may opt to manage your own secret and provide it to this module instead of
letting the module manage the sidecar secrets automatically.

You can create your own secret in Azure Key Vault and provide its name
to parameter `secret_name` as long as the secrets contents is a JSON
with the following format:

```JSON
{
    "clientId":"",
    "clientSecret":"",
    "idpCertificate":"",
    "sidecarPrivateIdpKey":"",
    "sidecarPublicIdpCertificate":""
}
```

| Attribute                     | Required | Format |
| :---------------------------- | :------: | ------ |
| `clientId`                    | Yes      | String |
| `clientSecret`                | Yes      | String |
| `idpCertificate`              | No       | String - new lines escaped (`replace(var.yourCertificate, "\n", "\\n")`) |
| `sidecarPrivateIdpKey`        | No       | String - new lines escaped (`replace(var.yourCertificate, "\n", "\\n")`) |
| `sidecarPublicIdpCertificate` | No       | String - new lines escaped (`replace(var.yourCertificate, "\n", "\\n")`) |

Make sure to call the Terraform function `replace(var.yourCertificate, "\n", "\\n")`
to escape the new lines in the parameters `idpCertificate`,
`sidecarPublicIdpCertificate` and `sidecarPrivateIdpKey` before storing them on
your secret.

In case you are creating this secret in a different account, use the input
parameter `iam_policies` to provide the policies that will be
assumed in order to read the secret.
