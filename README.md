# Ramon setup notes

Modified from:
* https://github.com/terraform-aws-modules/terraform-aws-eks/tree/master/examples/eks-auto-mode

Documentation:
* https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest

## Install OpenTofu

```
brew install opentofu
```

## Install aws-cli

```
curl -fsSL https://awscli.amazonaws.com/v2/install.sh | bash
export PATH=$PATH:$HOME/.local/bin
```

## Install KubeCTL

```
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.36.2/2026-07-05/bin/darwin/amd64/kubectl
```

## AWS credentials

```
export AWS_ACCESS_KEY_ID="xxxx"
export AWS_SECRET_ACCESS_KEY="xxx"
export AWS_SESSION_TOKEN="xxx"
```

## Init
```
tofu init
```

## Plan

```
tofu plan -var-file=environments/sandbox-rbastiaans-test.tfvars -out=tfplan
```

## Apply

NOTE: creating EKS can take up to ~20 minutes

```
tofu apply "tfplan"
```

## Plan Destroy

```
tofu plan -var-file=environments/sandbox-rbastiaans-test.tfvars -destroy -out=tfplandestroy
```

## Destroy

```
tofu apply "tfplandestroy"
```

## Add cluster to KubeCTL config

```
aws eks --region $(tofu output -raw region) update-kubeconfig \
    --name $(tofu output -raw cluster_name)
```

## Verify Kubernetes connectivity

```
kubectl cluster-info
```

## Show nodes (pools)

```
kubectl get nodepools
kubectl get nodes
```

## Show nodes zones

```
kubectl get nodes -L topology.kubernetes.io/zone
```

## Show nodes cpu, memory and zones

```
kubectl get nodes -L eks.amazonaws.com/instance-cpu -L eks.amazonaws.com/instance-memory -L node.kubernetes.io/instance-type -L topology.kubernetes.io/zone
```

## Test deploy

```
kubectl apply -f inflate.yaml
```

## Show pods

```
kubectl get pods -o wide
```

## Scale up

```
kubectl scale deployment inflate --replicas 2
```

## Scale down

```
kubectl scale deployment inflate --replicas 1
```

## Watch event/logs in Kubernetes

```
kubectl get events -w --sort-by '.lastTimestamp'
```

## See pod resource requirements

```
kubectl get pod -l app=inflate -o jsonpath='{.items[*].spec.containers[*].resources}'
```

## Show node

```
kubectl describe node <node>
```

## Delete deploy

```
kubectl delete -f inflate.yaml
```

## Run web app with Network Load Balancer (auto created)

```
$ kubectl apply -f hello-world-nlb.yaml
deployment.apps/hello-web created
service/hello-web-service created
$ kubectl get service hello-web-service -w
NAME                TYPE           CLUSTER-IP       EXTERNAL-IP                                                                    PORT(S)        AGE
hello-web-service   LoadBalancer   172.20.243.167   k8s-default-helloweb-ccbe379d0d-92d416c06b3a3a7f.elb.us-east-2.amazonaws.com   80:31208/TCP   3m17s
```

Goto: http://<EXTERNAL-IP>

## Run web app with Application Load Balancer (auto created)

```
$ kubectl apply -f hello-world-alb.yaml
$ kubectl get ingress hello-web-ingress
```

Goto: http://<ADDRESS>
