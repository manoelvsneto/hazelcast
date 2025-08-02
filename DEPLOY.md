# Deploy do Cliente Hazelcast no MicroK8s

## ⚠️ IMPORTANTE: Servidor já existe no Kubernetes

Este projeto agora está configurado apenas para deployar o **cliente Hazelcast**, assumindo que você já tem um **servidor Hazelcast rodando** no seu cluster Kubernetes.

## Arquivos removidos:
- ❌ `hazelcast-deployment.yaml` (servidor)
- ❌ `hazelcast-service.yaml` (service do servidor)  
- ❌ `hazelcast-configmap.yaml` (config do servidor)
- ❌ `hazelcast-rbac.yaml` (permissões do servidor)

## Arquivos mantidos:
- ✅ `hazelcast-client-deployment.yaml` (apenas cliente)
- ✅ Scripts de deploy simplificados

## Pré-requisitos

1. **Servidor Hazelcast já rodando** (pode ser local ou em outro pod)
2. **MicroK8s instalado e rodando (compatível com ARM64)**
   ```bash
   # Verificar status
   microk8s status --wait-ready
   
   # Habilitar addons necessários
   microk8s enable dns
   microk8s enable registry
   microk8s enable storage
   ```

3. **Docker instalado com suporte ARM64**
   ```bash
   # Verificar se Docker suporta ARM64
   docker buildx ls
   
   # Se necessário, criar builder para multi-platform
   docker buildx create --name multiarch --driver docker-container --use
   ```

3. **Aplicação Java construída**
   ```bash
   mvn clean package
   ```

## Considerações para ARM64

Este projeto está otimizado para rodar em arquiteturas ARM64, incluindo:
- **Raspberry Pi 4/5** com MicroK8s
- **Apple Silicon** (M1/M2/M3) com Docker Desktop
- **AWS Graviton** instances
- **Oracle Cloud ARM** instances

### Arquivos específicos para ARM64:
- `Dockerfile.arm64` - Dockerfile otimizado para ARM64
- Scripts de deploy atualizados com flag `--platform linux/arm64`

## Deploy Apenas do Cliente

### Opção 1: Script automatizado (recomendado)

```bash
# Para sistemas ARM64
chmod +x deploy-client-only.sh
./deploy-client-only.sh

# Para Windows
.\deploy-client-only.ps1
```

### Opção 2: Deploy manual

```bash
# 1. Build da aplicação
mvn clean package

# 2. Build da imagem ARM64
docker build --platform linux/arm64 -f Dockerfile.arm64 -t localhost:32000/hazelcast-client:latest .

# 3. Push para registry
docker push localhost:32000/hazelcast-client:latest

# 4. Deploy apenas o cliente
microk8s kubectl apply -f k8s/hazelcast-client-deployment.yaml

# 5. Verificar status
microk8s kubectl get pods -l app=hazelcast-client
```

## Conectar ao servidor existente

O cliente irá se conectar automaticamente ao servidor Hazelcast existente. Certifique-se de que:

1. **O servidor está acessível** na rede do MicroK8s
2. **A configuração do cliente** aponta para o servidor correto
3. **As portas estão abertas** (padrão: 5701)

### Verificar conexão:

```bash
# Ver logs do cliente para confirmar conexão
microk8s kubectl logs -l app=hazelcast-client --tail=20

# Deve mostrar algo como:
# "Members {size:1, ver:1} ["
# "10.1.xx.xx:5701 - xxxxx [hazelcast-server]"
# "CLIENT CONNECTED"
```

### Service Connections necessárias:

1. **Docker Registry Service Connection**
   - Nome: `docker-registry-microk8s`
   - Tipo: Docker Registry
   - Registry URL: `localhost:32000` (ou seu registry)
   - Username/Password: conforme configuração

2. **Kubernetes Service Connection**
   - Nome: `microk8s-cluster`
   - Tipo: Kubernetes
   - Server URL: URL do seu cluster MicroK8s
   - Service Account: Use o token do service account criado

### Variáveis necessárias no pipeline:

```yaml
variables:
  dockerRegistryServiceConnection: 'docker-registry-microk8s'
  imageRepository: 'hazelcast-client'
  containerRegistry: 'localhost:32000'
  kubernetesServiceConnection: 'microk8s-cluster'
  namespace: 'default'
```

## Troubleshooting

### Problemas comuns:

1. **Pods não startam**
   ```bash
   microk8s kubectl describe pod <pod-name>
   microk8s kubectl logs <pod-name>
   ```

2. **Problemas de rede**
   ```bash
   # Verificar DNS
   microk8s kubectl exec -it <pod-name> -- nslookup hazelcast-service
   ```

3. **Problemas de imagem**
   ```bash
   # Listar imagens no registry
   curl http://localhost:32000/v2/_catalog
   ```

### Comandos úteis:

```bash
# Reiniciar deployment
microk8s kubectl rollout restart deployment/hazelcast-server
microk8s kubectl rollout restart deployment/hazelcast-client

# Escalar pods
microk8s kubectl scale deployment hazelcast-server --replicas=3

# Port forward para acesso local
microk8s kubectl port-forward service/hazelcast-service 5701:5701
microk8s kubectl port-forward service/hazelcast-client-service 8080:8080

# Cleanup completo
microk8s kubectl delete -f k8s/
```

## Monitoramento

### Verificar saúde do cluster:

```bash
# Status dos pods
microk8s kubectl get pods -w

# Eventos do cluster
microk8s kubectl get events --sort-by=.metadata.creationTimestamp

# Recursos utilizados
microk8s kubectl top pods
microk8s kubectl top nodes
```
