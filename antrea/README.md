# Antrea Egress IP

Reference:
https://antrea.io/docs/v1.15.0/docs/egress/
https://medium.com/@bob-bauer/antrea-egress-on-vsphere-kubernetes-service-vks-65815a43cc11

## Concepts Demonstrated
- Feature Gates to enable
- Antrea External IP Pool
- Antrea Egress IP by pod label and namespace
- Test application to validate egress is working

## Components
- 01-external-pool.yaml - create Antrea external IP Pool
- 02-egress-ip-netshoot.yaml - assigns IP from external pool to netshoot pods in netshoot namespace
- 03-netshoot-namepace.yaml - creates netshoot namespace with appropriate PSA label for VKS
- 04-regcred - (optional) creates registry credential secret.  Uncomment ImagePullSecrets field in 05 yaml.
- 05-netshoot-deploy.yaml - deploys netshoot deployment for testing

# Use 
After deployment exec into Netshoot pod and ping a linux VM.  Run tcpdump on linux VM `sudo tcpdump -i ens37 icmp
` to verify ping comes from assigned egress IP.

NOTICE:  THIS SOFTWARE IS INTENTED FOR DEMONSTRATION PURPOSES ONLY AND THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.