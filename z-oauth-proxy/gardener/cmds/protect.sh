fqdn=${1:-$FQDN}
service_name=${2:-$SERVICE_NAME}
#cat <<EOF > app-ingress.yaml
#apiVersion: networking.k8s.io/v1
#kind: Ingress
#metadata:
#  name: "${service_name}"
#  annotations:
#    nginx.ingress.kubernetes.io/secure-backends: "false"
#    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
#    nginx.ingress.kubernetes.io/app-root: "/app"
#    nginx.ingress.kubernetes.io/rewrite-target: "/\$2"
#    nginx.ingress.kubernetes.io/auth-url: "https://www.${fqdn}/oauth2/auth"
#    nginx.ingress.kubernetes.io/auth-signin: "https://www.${fqdn}/oauth2/start?rd=\$escaped_request_uri"
#    nginx.ingress.kubernetes.io/auth-response-headers: "x-auth-request-user,x-auth-request-email,x-auth-request-preferred-username,x-auth-request-access-token"
#spec:
#  ingressClassName: nginx
#  tls:
#  - hosts:
#    - www.${fqdn}
#  rules: 
#  - host: www.${fqdn}
#    http:
#      paths:
#        - pathType: ImplementationSpecific
#          backend:
#            service:
#              name: "${service_name}"
#              port:
#                number: 80
#          path: /app(/|$)(.*)
#EOF
cat <<EOF > app-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: "${service_name}"
  annotations:
    nginx.ingress.kubernetes.io/secure-backends: "false"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/auth-url: "https://www.${fqdn}/oauth2/auth"
    nginx.ingress.kubernetes.io/auth-signin: "https://www.${fqdn}/oauth2/start?rd=\$escaped_request_uri"
    nginx.ingress.kubernetes.io/auth-response-headers: "x-auth-request-user,x-auth-request-email,x-auth-request-preferred-username,x-auth-request-access-token"
    nginx.ingress.kubernetes.io/use-regex: "true"
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
              name: "${service_name}"
              port:
                number: 80
          path: /.*
EOF

kubectl apply -f app-ingress.yaml
#kubectl apply -f app-ingress-2.yaml
  
