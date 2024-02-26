function identity() {
    kubectl -n kube-system get configmap cluster-identity -ojsonpath={.data.cluster-identity}
}

function kubeconfig() {
    cluster_identity=$1
    project_name=$2
    cluster_name=$3
    gardenctl kubeconfig --raw --garden $cluster_identity --project $project_name --shoot $cluster_name 
} 

kubeconfig "$(identity)" "$1" "$2" 
