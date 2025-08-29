$server = "https://<supervisor vip or fqdn>"
$user = "administrator@vsphere.local"
$namespace = $args[0]
$clusterName = $args[1]

kubectl vsphere login --server $server --insecure-skip-tls-verify -u $user --tanzu-kubernetes-cluster-namespace $namespace --tanzu-kubernetes-cluster-name $clusterName
