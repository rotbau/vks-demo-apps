$server = "https://<supervisor vip or fqdn>"
$user = "administrator@vsphere.local"

kubectl vsphere login --server=$server --insecure-skip-tls-verify -u $user

