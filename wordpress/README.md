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
- 02-mysql-deployment.yaml - deploys mysqld DB, PVC, mysql service, secret for mysql password
- 03-wordpress-deployment.yaml - deploys wordpress application, pvc
- 04-wordpress-lb-service.yaml - creates service type load balancer for wordpress frontend
