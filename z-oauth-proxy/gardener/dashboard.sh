export KUBECONFIG=kubeconfig

# install dashboard from helm
#helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
# or, install dashboard from kubectl
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml


## create admin user
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

# get the token to clclipboard
kubectl -n kubernetes-dashboard create token admin-user | pbcopy
echo "Token copied to clipboard, now we can start the proxy, when prompted, paste the token."
kubectl proxy  
browser http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/