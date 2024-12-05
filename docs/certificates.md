# Configuring certificates for Terraform Azure VM sidecars

You can use Cyral's default [sidecar-created
certificate](https://cyral.com/docs/sidecars/deployment/certificates#sidecar-created-certificate) or use a
[custom certificate](https://cyral.com/docs/sidecars/deployment/certificates#custom-certificate) to secure
the communications performed by the sidecar. In this page, we provide
instructions on how to use a custom certificate.

## Use your own certificate

You can use a certificate signed by you or the Certificate Authority of your
choice. Provide the ARN of the certificate secrets to the sidecar module, as
in the section [Provide custom certificate to the sidecar](#provide-custom-certificate-to-the-sidecar).
Please make sure
that the following requirements are met by your private key / certificate pair:

- Both the private key and the certificate **must** be encoded in the **UTF-8**
  charset.

- The certificate must follow the **X.509** format.

**WARNING:** *Windows* commonly uses UTF-16 little-endian encoding. A UTF-16 certificate
   or private key will *not* work in the sidecar.

## Provide custom certificate to the sidecar

There are two parameters in the sidecar module you can use to provide the ID of
a secret containing a custom certificate:

1. `tls_certificate_secret_id` (Optional) ID of Key Vault secret that
   contains a certificate to terminate TLS connections.

1. `ca_certificate_secret_id` (Optional) ID of a Key Vault secret that
   contains a CA certificate to sign sidecar-generated certs.

The secrets must follow the following JSON format.

```json
{
  "cert": "{myCertBase64}",
  "key": "{myPrivateKeyBase64}"
}
```

Where `{myCertBase64}` is your custom certificate, encoded in base64, and
`{myPrivateKeyBase64}` is your private key, encoded in base64. Note that the
base64 encoding is an extra encoding over the PEM-encoded values.

The choice between providing a `tls`, a `ca` secret or *both* will depend on the repositories
used by your sidecar. See the certificate type used by each repository in the
[sidecar certificates](https://cyral.com/docs/sidecars/deployment/certificates#sidecar-certificate-types) page.
