fqdn=${1:-$FQDN}
service_name=${2:-$SERVICE_NAME}
image=${3-${IMAGE-kennethreitz/httpbin}}
# create http test application
cat <<EOF >app-test.yaml
apiVersion: v1
kind: Service
metadata:
  name: "${service_name}"
  labels:
    app: "${service_name}"
spec:
  ports:
  - name: "${service_name}"
    port: 80
    targetPort: 80
  selector:
    app: "${service_name}"
---
apiVersion: v1
kind: Pod
metadata:
    name: "${service_name}"
    labels:
      app: "${service_name}"
spec:
  containers:
  - name: "${service_name}"
    image: "${image}"
    imagePullPolicy: Always
    ports:
      - containerPort: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: "${service_name}"
  annotations:
    nginx.ingress.kubernetes.io/secure-backends: "false"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "false"
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

kubectl apply -f app-test.yaml

 
