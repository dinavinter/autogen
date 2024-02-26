 cluster_name=$(kubectl config view -o jsonpath="{.contexts[?(@.name == '$(kubectl config current-context)')].context.cluster}")
 server=$(kubectl config view -o jsonpath="{.clusters[?(@.name == '${cluster_name}')].cluster.server}")
 echo "${server#https://api.}"

