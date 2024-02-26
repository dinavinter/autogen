fqdn=${1:-$FQDN}

cat <<EOF >my-nginx-values.yaml
controller:
  extraArgs:
    default-ssl-certificate: default/www-tls
  service:
    annotations:
      cert.gardener.cloud/secretname: www-tls
      dns.gardener.cloud/class: garden
      dns.gardener.cloud/dnsnames: www.${fqdn}
      dns.gardener.cloud/ttl: "600"
defaultBackend:
  enabled: true
EOF

# Install nginx ingress controller 
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install my-nginx -f my-nginx-values.yaml ingress-nginx/ingress-nginx


# Wait and observe nginx deployment:
kubectl wait --for=condition=available --timeout=600s deployment/my-nginx-ingress-nginx-controller
 
#  kubectl --namespace default get services -o wide -w my-nginx-ingress-nginx-controller
kubectl describe service my-nginx-ingress-nginx-controller
curl -i "https://www.${fqdn}"   #(-> 404 which is good!)
