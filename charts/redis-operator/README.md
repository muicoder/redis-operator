# redis

This Helm chart deploys the redis-operator into your Kubernetes cluster. The operator facilitates the deployment, scaling, and management of Redis clusters and other Redis resources provided by the OpsTree Solutions team.

**Homepage:** <https://github.com/ot-container-kit/redis-operator>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| iamabhishek-dubey |  |  |
| sandy724 |  |  |
| shubham-cmyk |  |  |

## Pre-Requisities

- Helm v3+
- Kubernetes v1.16+
- If you plan to use cert-manager integration (certmanager.enabled=true), cert-manager must be pre-installed in your cluster

## Source Code

* <https://github.com/ot-container-kit/redis-operator>

## Installation Steps

### 1. Add Helm Repository

```bash
helm repo add ot-helm https://ot-container-kit.github.io/helm-charts
```

### 2. Install Cert-Manager (Optional)

If you plan to use cert-manager with the redis-operator, you need to install cert-manager before deploying the operator.
You can follow the [official cert-manager installation guide](https://cert-manager.io/docs/installation/).

### 3. Install Redis Operator

Replace `<YourCertSecretName>` and `<YourPrivateKey>` with your specific values.

```bash
helm install <redis-operator> ot-helm/redis-operator --version=0.15.5 --appVersion=0.15.1 --set certificate.secretName=<YourCertSecretName> --set certmanager.enabled=true --set redisOperator.webhook=true --namespace <redis-operator> --create-namespace
```

> Note: If `certificate.secretName` is not provided, the operator will generate a self-signed certificate and use it for webhook server.
---
> Note : If you want to disable the webhook you have to pass the `--set webhook=false` and `--set certmanager.enabled=false`  while installing the redis-operator.
---
> Note: If you want to use an existing `ClusterIssuer` to sign the webhook certificate, you can pass `--set issuer.create=false`, `--set issuer.kind=ClusterIssuer` and `--set issuer.name=cluster-issuer-name-here` while installing the operator.

### 4. Patch the CA Bundle (if using cert-manager)

Cert-manager injects the CA bundle into the webhook configuration.

```bash
kubectl patch crd redis.redis.redis.opstreelabs.in -p '{"metadata":{"annotations":{"cert-manager.io/inject-ca-from":"<redis-operator>/<serving-cert>"}}}'

kubectl patch crd redisclusters.redis.redis.opstreelabs.in -p '{"metadata":{"annotations":{"cert-manager.io/inject-ca-from":"<redis-operator>/<serving-cert>"}}}'

kubectl patch crd redisreplications.redis.redis.opstreelabs.in -p '{"metadata":{"annotations":{"cert-manager.io/inject-ca-from":"<redis-operator>/<serving-cert>"}}}'

kubectl patch crd redissentinels.redis.redis.opstreelabs.in -p '{"metadata":{"annotations":{"cert-manager.io/inject-ca-from":"<redis-operator>/<serving-cert>"}}}'
```

> Note: Replace `<redis-operator>` and `<serving-cert>` with your specific values i.e. release name and certificate name.

#### You can verify the patch by running the following commands

```bash
kubectl get crd redis.redis.redis.opstreelabs.in -o=jsonpath='{.metadata.annotations}'
kubectl get crd redisclusters.redis.redis.opstreelabs.in -o=jsonpath='{.metadata.annotations}'
kubectl get crd redisreplications.redis.redis.opstreelabs.in -o=jsonpath='{.metadata.annotations}'
kubectl get crd redissentinels.redis.redis.opstreelabs.in -o=jsonpath='{.metadata.annotations}'
```

### How to generate private key( Optional )

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt
kubectl create secret tls <webhook-server-cert> --key tls.key --cert tls.crt -n <redis-operator>
```

> Note: This secret will be used for webhook server certificate so generate it before installing the redis-operator.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| certificate.name | string | `"serving-cert"` |  |
| certificate.secretName | string | `"webhook-server-cert"` |  |
| certmanager.apiVersion | string | `"cert-manager.io/v1"` |  |
| certmanager.enabled | bool | `false` |  |
| featureGates.GenerateConfigInInitContainer | bool | `false` |  |
| issuer.create | bool | `true` |  |
| issuer.email | string | `"shubham.gupta@opstree.com"` |  |
| issuer.kind | string | `"Issuer"` |  |
| issuer.name | string | `"redis-operator-issuer"` |  |
| issuer.privateKeySecretName | string | `"letsencrypt-prod"` |  |
| issuer.server | string | `"https://acme-v02.api.letsencrypt.org/directory"` |  |
| issuer.solver.enabled | bool | `true` |  |
| issuer.solver.ingressClass | string | `"nginx"` |  |
| issuer.type | string | `"selfSigned"` |  |
| nodeSelector | object | `{}` |  |
| podSecurityContext | object | `{}` |  |
| priorityClassName | string | `""` |  |
| rbac.enabled | bool | `true` |  |
| redisOperator.automountServiceAccountToken | bool | `true` |  |
| redisOperator.env | list | `[]` |  |
| redisOperator.extraArgs | list | `[]` |  |
| redisOperator.imageName | string | `"ghcr.io/ot-container-kit/redis-operator/redis-operator"` |  |
| redisOperator.imagePullPolicy | string | `"Always"` |  |
| redisOperator.imagePullSecrets | list | `[]` |  |
| redisOperator.imageTag | string | `""` |  |
| redisOperator.metrics.bindAddress | string | `":8080"` |  |
| redisOperator.metrics.enabled | bool | `true` |  |
| redisOperator.name | string | `"redis-operator"` |  |
| redisOperator.podAnnotations | object | `{}` |  |
| redisOperator.podLabels | object | `{}` |  |
| redisOperator.pprof.bindAddress | string | `":6060"` |  |
| redisOperator.pprof.enabled | bool | `false` |  |
| redisOperator.watchNamespace | string | `""` |  |
| redisOperator.webhook | bool | `false` |  |
| replicas | int | `1` |  |
| resources.limits.cpu | string | `"500m"` |  |
| resources.limits.memory | string | `"500Mi"` |  |
| resources.requests.cpu | string | `"500m"` |  |
| resources.requests.memory | string | `"500Mi"` |  |
| securityContext | object | `{}` |  |
| service.name | string | `"webhook-service"` |  |
| service.namespace | string | `"redis-operator"` |  |
| serviceAccount.automountServiceAccountToken | bool | `true` |  |
| serviceAccountName | string | `"redis-operator"` |  |
| tolerateAllTaints | bool | `false` |  |
| tolerations | list | `[]` |  |