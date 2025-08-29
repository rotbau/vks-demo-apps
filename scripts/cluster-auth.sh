#!/bin/bash

# Can comment these out and use an ENV file to set server and/or username.  You will be prompted for password
server='https://<supervisor vip or fqdn>'
user='administrator@vsphere.local'

# Usage Format ./cluster-auth vsphere-ns vksclustername
kubectl vsphere login --server=$server -u $user --tanzu-kubernetes-cluster-namespace $1 --tanzu-kubernetes-cluster-name $2 --insecure-skip-tls-verify