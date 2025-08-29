# Kuard Stateless Application Demo

Reference:
https://github.com/kubernetes-up-and-running/kuard

## Concepts Demonstrated
- Stateless Application
- Service Type Load Balancer (L4 LB)
- Ingress (optional)
- httpproxy (contour - optional)
- gateway API (contour - gateway,route)

## Components
- 01-kuard-namespace.yaml - create kuard namespace and with label for psa policy
- 02-kuard-deployment.yaml - deploys kuard application
- 03-kuard-lb-service.yaml - creates l4 service type loadbalancer for kuard app
- 04-kuard-ingress.yaml - creates ingress instead of service type LB (assumes you have contour or other ingress instaled on cluster)
- 05-kuard-httpproxy.yaml - creates httproxy object (assumes you have contour installed on cluster)


NOTICE:  THIS SOFTWARE IS INTENTED FOR DEMONSTRATION PURPOSES ONLY AND THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.