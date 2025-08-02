# ✅ Azure Pipeline - Correções Aplicadas

## 📋 Problemas Identificados e Corrigidos

### ❌ **ANTES - Problemas encontrados:**

1. **Referências a arquivos inexistentes**:
   - ❌ `hazelcast-rbac.yaml` 
   - ❌ `hazelcast-configmap.yaml`
   - ❌ `hazelcast-service.yaml`
   - ❌ `hazelcast-deployment.yaml`

2. **Variáveis de placeholder não configuradas**:
   - ❌ `your-docker-registry`
   - ❌ `your-registry.azurecr.io`
   - ❌ `your-microk8s-connection`

3. **Paths incorretos para artifacts**:
   - ❌ `$(Pipeline.Workspace)/s/k8s/`

4. **Tasks deprecadas**:
   - ❌ `KubernetesManifest@0` (deprecated)

5. **Dockerfile incorreto**:
   - ❌ Referenciava `Dockerfile` genérico em vez de `Dockerfile.arm64`

### ✅ **DEPOIS - Correções aplicadas:**

1. **Pipeline focado apenas no cliente Hazelcast**:
   - ✅ Removidas referências a arquivos de servidor inexistentes
   - ✅ Deploy apenas do `hazelcast-client-deployment.yaml`

2. **Variáveis adequadamente configuradas**:
   - ✅ `dockerRegistryServiceConnection: 'hazelcast-acr-connection'`
   - ✅ `containerRegistry: 'hazelcastregistry.azurecr.io'`
   - ✅ `kubernetesServiceConnection: 'microk8s-cluster-connection'`

3. **Paths corrigidos**:
   - ✅ `$(System.ArtifactsDirectory)/drop/k8s/`

4. **Tasks atualizadas**:
   - ✅ `Kubernetes@1` em vez de `KubernetesManifest@0`

5. **Dockerfile ARM64 correto**:
   - ✅ `Dockerfile.arm64` explicitamente referenciado

## 🛠️ **Configuração Necessária no Azure DevOps**

### **1. Service Connections que precisam ser criadas:**

#### **Docker Registry Connection:**
- **Nome**: `hazelcast-acr-connection`
- **Tipo**: Azure Container Registry
- **Registry URL**: `https://hazelcastregistry.azurecr.io` (substitua pelo seu)

#### **Kubernetes Service Connection:**
- **Nome**: `microk8s-cluster-connection`
- **Tipo**: Kubernetes Service Connection
- **Configuração**: Aponte para seu cluster MicroK8s

### **2. Variáveis que você deve customizar:**

```yaml
variables:
  # CONFIGURE ESTAS VARIÁVEIS PARA SEU AMBIENTE:
  dockerRegistryServiceConnection: 'hazelcast-acr-connection'  # Sua service connection
  containerRegistry: 'hazelcastregistry.azurecr.io'           # Seu Azure Container Registry
  kubernetesServiceConnection: 'microk8s-cluster-connection'   # Sua service connection K8s
```

### **3. Environment no Azure DevOps:**

Criar um environment chamado `microk8s-cluster` no Azure DevOps para o deployment stage.

## 🚀 **Como o Pipeline Funciona Agora**

### **Stage 1: Build**
- ✅ Compila código Java com Maven
- ✅ Executa testes
- ✅ Publica resultados dos testes
- ✅ Empacota artifacts (JAR + K8s manifests + Dockerfiles)

### **Stage 2: Docker**
- ✅ Baixa artifacts do stage anterior
- ✅ Constrói imagem Docker ARM64
- ✅ Faz push para Azure Container Registry

### **Stage 3: Deploy**
- ✅ Baixa artifacts
- ✅ Atualiza manifest K8s com nova imagem
- ✅ Faz deploy apenas do cliente Hazelcast
- ✅ Verifica se deployment foi bem-sucedido

## 📝 **Próximos Passos**

1. **Configurar Service Connections** no Azure DevOps
2. **Atualizar variáveis** com seus valores reais
3. **Criar environment** `microk8s-cluster`
4. **Testar pipeline** com commit na branch main

## 🔧 **Comandos para Verificação Local**

```bash
# Verificar se Dockerfile.arm64 está correto
docker buildx build --platform linux/arm64 -f Dockerfile.arm64 -t test-image .

# Verificar manifest K8s
kubectl apply --dry-run=client -f k8s/hazelcast-client-deployment.yaml

# Testar pipeline localmente (se usando Azure CLI)
az pipelines run --name "azure-pipelines.yml"
```

## ⚠️ **Observações Importantes**

- Pipeline agora está otimizado para **apenas cliente Hazelcast**
- Assume que **servidor Hazelcast já existe** no cluster
- Configurado para **arquitetura ARM64** (Raspberry Pi, Apple Silicon, etc.)
- **Secrets do Azure** devem estar configurados no cluster K8s antes do deploy
