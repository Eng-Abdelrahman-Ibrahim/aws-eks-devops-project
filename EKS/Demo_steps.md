# https://github.com/iam-veeramalla/aws-devops-zero-to-hero/tree/main/day-22

1. Install kubectl and eksctl
2. ## Install EKS

Please follow the prerequisites doc before this.

### Install using Fargate

```
eksctl create cluster --name demo-cluster --region us-east-1 --fargate
```

### Delete the cluster

```
eksctl delete cluster --name demo-cluster --region us-east-1
```

### Download kubeconfig file

```
aws eks update-kubeconfig --name demo-cluster --region us-east-1
```

### Create Fargate Profile

```
eksctl create fargateprofile \
    --cluster demo-cluster \
    --region us-east-1 \
    --name alb-sample-app \
    --namespace game-2048
```

### Deploy the deployment, service and ingress

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/examples/2048/2048_full.yaml
```
Try:

```
kubectl get pods -n game-2048
kubectl get svc -n game-2048
kubectl get ingress -n game-2048
```
```
PS C:\WINDOWS\system32> kubectl get ingress -n game-2048
NAME           CLASS   HOSTS   ADDRESS   PORTS   AGE
ingress-2048   alb     *                 80      2m16s
```

Notice there are no address in ingress as we didn't create ingress controller yet / no load balancer

### Create Ingress Controller

ingress controller -> ingress-2048 -> Load balancer -> target group, port
Ingress controller configures the load balancer by itself, all it needs is the ingress resource

This ingress contoller will talk to some AWS resources to create the ALB, so it needs to be IAM integrated
So first, we need to create IAM OIDC provider

### Configure IAM OIDC Provider

```
eksctl utils associate-iam-oidc-provider --cluster demo-cluster --approve
```

### Configure the ALB controller Add-on

ALB Controller -> Pod (Any controller is just a pod) -> Access to AWS services such as ALB
You can follow these detailed steps provided by AWS: https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html

1. Download an IAM policy for the AWS Load Balancer Controller that allows it to make calls to AWS APIs on your behalf.

```
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.11.0/docs/install/iam_policy.json
```

2. Create an IAM policy using the policy downloaded in the previous step.

```
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json
```

3. Create IAM service account and attach it to a role

```
eksctl create iamserviceaccount \
    --cluster=demo-cluster \
    --namespace=kube-system \
    --name=aws-load-balancer-controller \
    --attach-policy-arn=arn:aws:iam::068732175550:policy/AWSLoadBalancerControllerIAMPolicy \
    --override-existing-serviceaccounts \
    --region us-east-1 \
    --approve
```

4. Install AWS Load Balancer Controller using a Helm chart

```
helm repo add eks https://aws.github.io/eks-charts

helm repo update eks


helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system \
  --set clusterName=demo-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=us-east-1 \
  --set vpcId=vpc-08baa7fa82b0c1c60

```

5. Verify that the controller is installed

```
kubectl get deployment -n kube-system aws-load-balancer-controller
```

### Verify ALB is attached to ingress

```
PS C:\WINDOWS\system32> kubectl get ingress -n game-2048
NAME           CLASS   HOSTS   ADDRESS                                                                   PORTS   AGE
ingress-2048   alb     *       k8s-game2048-ingress2-bcac0b5b37-2102234151.us-east-1.elb.amazonaws.com   80      54m
```
Access the app through http://k8s-game2048-ingress2-bcac0b5b37-2102234151.us-east-1.elb.amazonaws.com

# END