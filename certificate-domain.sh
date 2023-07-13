#!/bin/sh

# This script will create a certificate for a subdomain
# ./certificate-domain.sh staging 1.1.1.1  Z03501612HD7E79ETXM8B superdomain.com
# ./certificate-domain.sh production 1.1.1.1 superdomain.com

staging="https://acme-staging-v02.api.letsencrypt.org/directory"
production="https://acme-v02.api.letsencrypt.org/directory"

echo $staging
echo $production

if [ $1 == "staging" ]
then
  domain=$staging
else
  domain=$production
fi

if [ -z $4 ]
then 
  fulldomain=$3
  fulldomainString=$3
else
  fulldomain=$4.$3
  fulldomainString=$4-$3
fi

echo "full domain is $fulldomain"

echo "We will be creating the following certificate $domain"

echo "Curate R53 config for $fulldomain"

recordSet=$(cat <<EOF
{
  "Comment": "A new record set for the zone.",
  "Changes": [
    {
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "$fulldomain.",
        "Type": "A",
        "TTL": 600,
        "ResourceRecords": [
          {
            "Value": "$2"
          }
        ]
      }
    }
  ]
}
EOF
)

cat <<< $recordSet > r53-staging-request.json

echo "Generate a certificate for $fulldomain"

aws route53 change-resource-record-sets --hosted-zone-id Z03501612HD7E79ETXM8B --change-batch file://r53-staging-request.json

echo "Generate certificate issuer for $fulldomain"

cat <<EOF | kubectl create -f -
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: letsencrypt-$fulldomainString-$1-issuer
  namespace: default
spec:
  acme:
    # The ACME server URL
    server: $domain
    # Email address used for ACME registration
    email: domain@name.com
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-$1-issuer
    # Enable the HTTP-01 challenge provider
    solvers:
    - http01:
        ingress:
          class: traefik
EOF

echo "Generate certificate for $fulldomain"

cat <<EOF | kubectl create -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: $fulldomainString-$1
  namespace: default
spec:
  secretName: $fulldomainString-$1-certificate
  issuerRef:
    name: letsencrypt-$fulldomainString-$1-issuer
  commonName: $fulldomain
  dnsNames:
  - $fulldomain
EOF
