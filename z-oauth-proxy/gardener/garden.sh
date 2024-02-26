#Not necessary if using ngxinx helm route for sap login
#openssl req -new -newkey rsa:2048 -nodes \
#        -out tls.csr \
#        -keyout tls.key \
#         -subj "/C=DE/L=GCP/O=SAP/OU=CX Academy/CN=auth.gigya.only.sap"


#Get Certificate by pasting csr file into  https://getcerts.wdf.global.corp.sap/pgwy/request/sapnetca_base64.html
#openssl x509 -outform der -in certificate.pem -out tls.crt


# donload kubeconfig from garden dashboard
#current_context=$(kubectl config current-context)
#cluster_name=$(kubectl config view -o jsonpath="{.contexts[?(@.name == '${current_context}')].context.cluster}")
#project_name=$(kubectl config view -o jsonpath="{.contexts[?(@.name == '${current_context}')].context.namespace}")

#project_name=gigya-auth
#cluster_name=l224v1dkmg

#KUBECONFIG=kube

# Fetch cluster-identity of garden cluster from the configmap
#cluster_identity=$(kubectl -n kube-system get configmap cluster-identity -ojsonpath={.data.cluster-identity})
function identity() {
      # shellcheck disable=SC1083
    cluster_identity=$(kubectl -n kube-system get configmap cluster-identity -ojsonpath={.data.cluster-identity})
    echo "$cluster_identity"    
}

function kubeconfig() {
    cluster_identity=$1
    project_name=$2
    cluster_name=$3
    gardenctl kubeconfig --raw --garden $cluster_identity --project $project_name --shoot $cluster_name 
}

kubeconfig "$(identity)" "${1:gigya-auth}" "${2:l224v1dkmg}" > kube

kubectl --kubeconfig $KUBECONFIG get secrets
#
## Configure garden cluster
#gardenctl config set-garden $cluster_identity --kubeconfig $KUBECONFIG
#
#gardenctl target \
 ##    --garden sap-landscape-canary \
 ##    --project gigya-auth \
 ##    --shoot l224v1dkmg
    
#Create Secret with certificate:
#kubectl --kubeconfig $KUBECONFIG create secret tls www-tls --key="tls.key" --cert="certificate.pem"
#kubectl --kubeconfig $KUBECONFIG get secrets
#kubectl --kubeconfig $KUBECONFIG get secret www-tls -o yaml
## kubectl --kubeconfig /Users/d061192/Downloads/kubeconfig--klxtrial--klx2.yaml delete secrets crowdsourcesecret-tls
#**/


 
# Gardener clusters: https://dashboard.garden.canary.k8s.ondemand.com/namespace/garden-klxtrial/shoots/
 
# More info @ https://pages.github.tools.sap/kubernetes/gardener/docs/guides/sap-internal/security/oauth2-proxy_sap-ias/

kubectl config current-context
kubectl config use-context garden-gigya-auth-default
kubectl config current-context
kubectl config view
export ISS="https://avemdttta.accounts.ondemand.com"
export OAUTH2_PROXY_CLIENT_ID="851a004c-6a81-4fec-b6d3-2c67710fef0c"
export OAUTH2_PROXY_CLIENT_SECRET="[]gnVz=ziU:ZqcDAo.]RpemODcmLFX"
export OAUTH2_PROXY_COOKIE_SECRET=`/usr/bin/python3 -c 'import os,base64; print(base64.b64encode(os.urandom(16)).decode("ascii"))'`
#export cluster_name=l224v1dkmg
#export project_name=gigya-auth
# get cluster_name and project_name from kubeconfig filter by current-context
export fqdn=${cluster_name}.${project_name}.shoot.canary.k8s-hana.ondemand.com

echo ISS: ${ISS}
echo OAUTH2_PROXY_CLIENT_ID: ${OAUTH2_PROXY_CLIENT_ID}
echo OAUTH2_PROXY_CLIENT_SECRET: ${OAUTH2_PROXY_CLIENT_SECRET}
echo OAUTH2_PROXY_COOKIE_SECRET: ${OAUTH2_PROXY_COOKIE_SECRET}
echo cluster_name: ${cluster_name}
echo project_name: ${project_name}
echo fqdn: ${fqdn}

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

Wait and observe nginx deployment: 
#  kubectl --namespace default get services -o wide -w my-nginx-ingress-nginx-controller
  kubectl describe service my-nginx-ingress-nginx-controller
  curl -i "https://www.${fqdn}"   #(-> 404 which is good!)
ONE


# create http test application
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  labels:
    app: httpbin
spec:
  ports:
  - name: httpbin
    port: 80
    targetPort: 80
  selector:
    app: httpbin
---
apiVersion: v1
kind: Pod
metadata:
    name: httpbin
    labels:
      app: httpbin
spec:
  containers:
  - name: httpbin
    image: kennethreitz/httpbin
    imagePullPolicy: Always
    ports:
      - containerPort: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: httpbin
  annotations:
    nginx.ingress.kubernetes.io/secure-backends: "false"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/app-root: "/http"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - www.${fqdn}
  rules: 
  - host: www.${fqdn}
    http:
      paths:
        - pathType: ImplementationSpecific
          backend:
            service:
              name: httpbin
              port:
                number: 80
          path: /http(/|$)(.*)
EOF

curl -i https://www.${fqdn}/http/headers  -> 200

#cat <<EOF | kubectl apply -f -
#apiVersion: v1
#kind: Service
#metadata:
#  name: garage-ui
#  labels:
#    app: http-https-echo
#spec:
#  ports:
#  - name: http
#    port: 8080
#    targetPort: 80
#  selector:
#    app: http-https-echo
#---
#apiVersion: v1
#kind: Pod
#metadata:
#    name: http-https-echo
#    labels:
#      app: http-https-echo
#spec:
#  containers:
#  - name: http-https-echo
#    image: mendhak/http-https-echo
#    imagePullPolicy: Always
#    ports:
#      - containerPort: 80
#---
#apiVersion: networking.k8s.io/v1
#kind: Ingress
#metadata:
#  name: garage-ui
#  annotations:
#    nginx.ingress.kubernetes.io/rewrite-target: /$2
#spec:
#  ingressClassName: nginx
#  tls:
#  - hosts:
#    - www.${fqdn}
#  rules: 
#    - host: www.${fqdn}
#      http:
#        paths:
#        - path: /garage-ui(/|$)(.*)
#          pathType: ImplementationSpecific
#          backend:
#            service:
#              name: garage-ui
#              port: 
#                number: 80
#EOF

cat <<EOF | >oauth2-proxy.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    k8s-app: oauth2-proxy
  name: oauth2-proxy
spec:
  replicas: 1
  selector:
    matchLabels:
      k8s-app: oauth2-proxy
  template:
    metadata:
      labels:
        k8s-app: oauth2-proxy
    spec:
      containers:
        - args:
            - --provider=oidc
            - --oidc-issuer-url=${ISS}
            - --email-domain=*
            - --upstream=file:///dev/null
            - --http-address=0.0.0.0:4180
            - --scope=openid email profile groups
            - --set-xauthrequest=true
            - --pass-access-token=true
            - --cookie-domain=${fqdn}
            - --whitelist-domain=${fqdn}
            - --skip-provider-button=true
          env:
            - name: OAUTH2_PROXY_CLIENT_ID
              value: ${OAUTH2_PROXY_CLIENT_ID}
            - name: OAUTH2_PROXY_CLIENT_SECRET
              value: "${OAUTH2_PROXY_CLIENT_SECRET}"
            - name: OAUTH2_PROXY_COOKIE_SECRET
              value: ${OAUTH2_PROXY_COOKIE_SECRET}
          image: quay.io/oauth2-proxy/oauth2-proxy:latest
          imagePullPolicy: Always
          name: oauth2-proxy
          ports:
            - containerPort: 4180
              protocol: TCP
EOF
kubectl apply -f oauth2-proxy.yaml
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  labels:
    k8s-app: oauth2-proxy
  name: oauth2-proxy
spec:
  ports:
  - name: http
    port: 4180
    protocol: TCP
    targetPort: 4180
  selector:
    k8s-app: oauth2-proxy
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: oauth2-proxy  
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - www.${fqdn}
  rules: 
  - host: www.${fqdn}
    http:
      paths:
      - backend:
          service:
            name: oauth2-proxy
            port:
              number: 4180
        path: /oauth2
        pathType: Prefix
EOF



cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: httpbin
  annotations:
    nginx.ingress.kubernetes.io/secure-backends: "false"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/app-root: "/http"
    nginx.ingress.kubernetes.io/rewrite-target: "/\$2"
    nginx.ingress.kubernetes.io/auth-url: "https://www.${fqdn}/oauth2/auth"
    nginx.ingress.kubernetes.io/auth-signin: "https://www.${fqdn}/oauth2/start?rd=\$escaped_request_uri"
    nginx.ingress.kubernetes.io/auth-response-headers: "x-auth-request-user,x-auth-request-email,x-auth-request-preferred-username,x-auth-request-access-token"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - www.${fqdn}
  rules: 
  - host: www.${fqdn}
    http:
      paths:
        - pathType: ImplementationSpecific
          backend:
            service:
              name: httpbin
              port:
                number: 80
          path: /http(/|$)(.*)
EOF

echo curl -i https://www.${fqdn}/garage-ui/test123
