# VKS Helper Login Scripts

Currently only for VKS on vSphere 7 or 8.  VKS on vSphere 9 now uses the VCF CLI to login and create contexts and replaces the kubectl vsphere method (may still work in 9.0.0 but will be depricated in future).

## Basic Usage

### Autheticate to Supervisor Cluster using sc-auth
1. Update the username and server parameters in the appropriate script (or comment out and use an ENV file)
2. Execute the script
```
./sc-auth.sh
or
.\sc-auth.ps1
```

### Authenticate to Workload Clusters using cluster-auth
1. Update the username and server parameters in the appropriate script (or comment out and use an ENV file)
2. Execute the script supplying the vSphere namespace and vks cluster name variables after the command
```
# For example to log into the cluster vksc01 in vSphere namespace app01-ns
./cluster-auth.sh app01-ns vksc01
or
.\cluster-auth.ps1 app01-ns vksc01

NOTICE:  THIS SOFTWARE IS INTENTED FOR DEMONSTRATION PURPOSES ONLY AND THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.