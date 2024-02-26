function prepare() {
  project_name=${1:gigya-auth}
  cluster_name=${2:l224v1dkmg}
  config_dir=$(pwd)/${project_name}/${cluster_name} 
  service_name=${3:httpbin}
  kubeconfig="$config_dir/kubeconfig"
  mkdir -pv "$config_dir" 
  echo "project_name: $project_name"
  echo "cluster_name: $cluster_name"
  echo "service_name: $service_name" 
}

function fdqn() {
   cluster_name=$(kubectl config view -o jsonpath="{.contexts[?(@.name == '$(kubectl config current-context)')].context.cluster}")
   server=$(kubectl config view -o jsonpath="{.clusters[?(@.name == '${cluster_name}')].cluster.server}")
   echo "${server#https://api.}"
}


function export_env() { 
# write to file
cat <<EOF > "$config_dir/.env"
CONFIG_DIR="$config_dir"
CLUSTER_NAME="$cluster_name"
SERVICE_NAME="$service_name"
KUBECONFIG="$kubeconfig"
ROOT_DIR=$config_dir
EOF
}

function oauth_proxy_params() {
cat <<EOF >> "$config_dir/.env" 
OAUTH2_PROXY_ISS="${OAUTH2_PROXY_ISS-https://gigya.cdc.pyzlo.com/oidc/op/v1.0/4_vVpnJOQIK0hSmXhNgODHow}"
OAUTH2_PROXY_CLIENT_ID=${OAUTH2_PROXY_CLIENT_ID-"Wch1smZqnsqtO63iefNygzrq"}
OAUTH2_PROXY_CLIENT_SECRET=${OAUTH2_PROXY_CLIENT_SECRET-"7uH3B9wcnw8SWJ6THG1LbJXHFgXQwKHB64JbMCTC3EZySTihTVF4YgI4NjSaivxuJaCzvQ7_ofVJU0cAgvR97g"}
EOF

}
  
function print_env_and_wait() {
    green_echo "$(cat "$config_dir/.env" |  column -t -s '='  )"
    
    echo
    blue_echo "Check $config_dir/.env  and change the values if needed; When you are done press any key to continue, Else Ctrl+C to exit"  
    read -r  
}  

blue_echo() {
   echo   "\x1b[1;34m$*" 
}

green_echo() {
    echo  "\x1b[1;32m$*"
}

# shellcheck disable=SC2068
prepare $@

# authenticate and export kubeconfig
./auth.sh "$project_name" "$cluster_name" >> "$kubeconfig"
export "KUBECONFIG=$kubeconfig"

#prepare env
export_env
oauth_proxy_params
echo "FQDN=$(fdqn)" >> "$config_dir/.env"  
print_env_and_wait

#export all variables
set -o allexport; source "$config_dir/.env;" set +o allexport

# run commands
sh -c "cd ${config_dir} && $(pwd)/ingress.sh $FQDN"
sh -c "cd ${config_dir} && $(pwd)/app.sh $FQDN $SERVICE_NAME"
sh -c "cd ${config_dir} && $(pwd)/proxy.sh $FQDN"
sh -c "cd ${config_dir} && $(pwd)/protect.sh $FQDN $SERVICE_NAME"

sh -c "$(pwd)/browser.sh https://www.$FQDN/app"

