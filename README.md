# cert-manager-k8-aws
A simple script to generate K8 cert-manager certificates along with associated AWS records

This script will create a certificate for a subdomain.

You need to ensure you have configure the aws cli along with a valid set of 

```
# ./certificate-domain.sh staging 1.1.1.1 superdomain.com
```

```
# ./certificate-domain.sh production 1.1.1.1 superdomain.com
```
