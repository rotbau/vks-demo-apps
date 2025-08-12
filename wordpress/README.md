# Wordpress with Mysql Demo Stateful Application

Reference:
https://kubernetes.io/docs/tutorials/stateful-application/mysql-wordpress-persistent-volume/

## Concepts Demonstrated
- Dynamic PVC
- Service Type Load Balancer (L4 LB)
- Ingress (optional)
- httpproxy (contour - optional)
- gateway API (contour - gateway,route)

## Components
- wordpress-namespace.yaml - create wordpress namespace and with label for psa policy
- mysql-deployment.yaml - deploys mysqld DB, PVC, mysql service, secret for mysql password
- wordpress-deployment.yaml - deploys wordpress application, pvc
- wordpress-lb-service.yaml - creates service type load balancer for wordpress frontend
