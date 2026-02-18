# Wordpress with Mysql Stateful Application Demo

Reference:
https://kubernetes.io/docs/tutorials/stateful-application/mysql-wordpress-persistent-volume/

## Concepts Demonstrated
- Stateful application
- Dynamic PVC
- Service Type Load Balancer (L4 LB)
- Ingress (optional)
- httpproxy (contour - optional)
- gateway API (contour - gateway,route)

## Components
- 01-wordpress-namespace.yaml - create wordpress namespace and with label for psa policy
- 02-regcred.yaml - optional if you need to authenticate to pull image (uncommend imagePullSecrets in 03 and 04 manifests)
- 03-mysql-deployment.yaml - deploys mysqld DB, PVC, mysql service, secret for mysql password
- 04-wordpress-deployment.yaml - deploys wordpress application, pvc
- 05-wordpress-lb-service.yaml - creates service type load balancer for wordpress frontend



NOTICE:  THIS SOFTWARE IS INTENTED FOR DEMONSTRATION PURPOSES ONLY AND THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.