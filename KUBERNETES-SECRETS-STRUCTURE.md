# 🔐 Secrets Kubernetes - Configuração Separada

## ✅ **Nova Estrutura Implementada**

### **📁 Arquivos Criados:**

#### **1. k8s/hazelcast-secrets.yaml**
- ✅ **azure-sql-secret** - Credenciais SQL Server
- ✅ **azure-servicebus-secret** - Credenciais Service Bus  
- ✅ **hazelcast-config-secret** - Configurações Hazelcast
- ✅ **Placeholders** para substituição pelo pipeline

#### **2. k8s/hazelcast-client-deployment.yaml (Atualizado)**
- ✅ **secretKeyRef** ao invés de valores diretos
- ✅ **Referências aos secrets** criados
- ✅ **Melhor segurança** e organização

---

## 🔄 **Como Funciona Agora**

### **1. Pipeline Aplica Secrets Primeiro:**
```yaml
# azure-pipelines.yml
- task: Kubernetes@1
  displayName: 'Apply Secrets'
  arguments: '-f hazelcast-secrets.yaml'

- task: Kubernetes@1  
  displayName: 'Deploy Hazelcast Client'
  arguments: '-f hazelcast-client-deployment.yaml'
```

### **2. Secrets Template (hazelcast-secrets.yaml):**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: azure-sql-secret
  namespace: hazelcast
stringData:
  connection-string: "jdbc:sqlserver://__SQL_SERVER_HOST__:1433;..."
  username: "__SQL_SERVER_USERNAME__"
  password: "__SQL_SERVER_PASSWORD__"
```

### **3. Pipeline Substitui Variáveis:**
```bash
# Secrets são atualizados com variáveis do pipeline
sed -i "s|__SQL_SERVER_HOST__|$(SQL_SERVER_HOST)|g" hazelcast-secrets.yaml
sed -i "s|__SQL_SERVER_PASSWORD__|$(SQL_SERVER_PASSWORD)|g" hazelcast-secrets.yaml
```

### **4. Deployment Usa Secrets:**
```yaml
env:
  - name: SQL_SERVER_CONNECTION_STRING
    valueFrom:
      secretKeyRef:
        name: azure-sql-secret
        key: connection-string
```

---

## 🗄️ **Secrets Criados**

### **🔐 azure-sql-secret:**
```yaml
stringData:
  connection-string: "jdbc:sqlserver://HOST:1433;databaseName=DB;..."
  username: "admin-user"
  password: "senha-secreta"
```

**Variáveis do Pipeline Usadas:**
- `SQL_SERVER_HOST`
- `SQL_SERVER_DATABASE` 
- `SQL_SERVER_USERNAME`
- `SQL_SERVER_PASSWORD` 🔒

### **🔐 azure-servicebus-secret:**
```yaml
stringData:
  connection-string: "Endpoint=sb://NAMESPACE;...;SharedAccessKey=KEY"
  queue-name: "hazelcast-events"
```

**Variáveis do Pipeline Usadas:**
- `SERVICE_BUS_NAMESPACE`
- `SERVICE_BUS_ACCESS_KEY` 🔒
- `SERVICE_BUS_QUEUE`

### **🔐 hazelcast-config-secret:**
```yaml
stringData:
  cluster-name: "dev"
  server-address: "hazelcast.hazelcast:5701"
```

---

## 🎯 **Vantagens da Nova Estrutura**

### **🔒 Segurança:**
- ✅ **Secrets separados** do deployment
- ✅ **Kubernetes native** secret management
- ✅ **Valores não expostos** em logs
- ✅ **Base64 encoding** automático

### **🔧 Organização:**
- ✅ **Separação de responsabilidades**
- ✅ **Reutilização** de secrets por múltiplos deployments
- ✅ **Manutenção facilitada**
- ✅ **Padrão Kubernetes** seguido

### **⚙️ Flexibilidade:**
- ✅ **Secrets independentes** do deployment
- ✅ **Atualizações separadas**
- ✅ **Rollback facilitado**
- ✅ **Ambientes diferentes** com secrets diferentes

---

## 📋 **Fluxo de Deploy Atualizado**

### **1. Build Stage:**
```
Maven Build → JAR criado → Artifacts publicados
```

### **2. Docker Stage:**
```
Docker Build → Push para Registry → Cleanup automático
```

### **3. Deploy Stage:**
```
Download Artifacts → Update Manifests → Apply Secrets → Deploy App
```

### **Ordem de Aplicação:**
1. ✅ **hazelcast-secrets.yaml** (primeiro)
2. ✅ **hazelcast-client-deployment.yaml** (depois)

---

## 🔍 **Verificação dos Secrets**

### **Listar Secrets:**
```bash
kubectl get secrets -n hazelcast
```

### **Ver Conteúdo de um Secret:**
```bash
# Ver secret (base64 encoded)
kubectl get secret azure-sql-secret -n hazelcast -o yaml

# Ver secret decodificado
kubectl get secret azure-sql-secret -n hazelcast -o jsonpath='{.data.username}' | base64 -d
```

### **Verificar se Deployment Está Usando:**
```bash
kubectl describe deployment hazelcast-client -n hazelcast | grep -A 10 "Environment"
```

### **Logs de Conectividade:**
```bash
kubectl logs -f deployment/hazelcast-client -n hazelcast | grep -i "sql\|service bus\|connection"
```

---

## 🛠️ **Comandos Úteis**

### **Aplicar Secrets Manualmente:**
```bash
kubectl apply -f k8s/hazelcast-secrets.yaml -n hazelcast
```

### **Atualizar Secret Específico:**
```bash
# Editar secret diretamente
kubectl edit secret azure-sql-secret -n hazelcast

# Ou recriar
kubectl delete secret azure-sql-secret -n hazelcast
kubectl apply -f k8s/hazelcast-secrets.yaml -n hazelcast
```

### **Verificar Referências:**
```bash
# Verificar se deployment referencia os secrets corretos
kubectl get deployment hazelcast-client -n hazelcast -o yaml | grep -A 5 secretKeyRef
```

---

## 🆘 **Troubleshooting**

### **❌ Secret não encontrado:**
```
Error: couldn't find key username in Secret hazelcast/azure-sql-secret
```

**Solução:**
```bash
# Verificar se secret existe
kubectl get secret azure-sql-secret -n hazelcast

# Aplicar novamente
kubectl apply -f k8s/hazelcast-secrets.yaml -n hazelcast
```

### **❌ Valores não substituídos:**
```yaml
# Se ainda aparecer placeholders:
connection-string: "jdbc:sqlserver://__SQL_SERVER_HOST__:1433;..."
```

**Solução:**
- Verificar se variáveis estão definidas no pipeline
- Verificar se sed está substituindo corretamente
- Verificar logs do pipeline

### **❌ Deployment não inicia:**
```
Error: CreateContainerConfigError
```

**Solução:**
```bash
# Verificar events do pod
kubectl describe pod -l app=hazelcast-client -n hazelcast

# Verificar se secrets existem
kubectl get secrets -n hazelcast
```

---

## 📊 **Benefícios Alcançados**

### **Antes (Valores Hardcoded):**
```yaml
env:
  - name: SQL_SERVER_PASSWORD
    value: "MinhaSenh@123"  # ❌ Exposto no YAML
```

### **Agora (Secrets Kubernetes):**
```yaml
env:
  - name: SQL_SERVER_PASSWORD
    valueFrom:
      secretKeyRef:
        name: azure-sql-secret  # ✅ Referência segura
        key: password
```

### **Resultado:**
- 🔒 **Senhas protegidas** no Kubernetes
- 📋 **Organização melhorada**
- ⚙️ **Manutenção facilitada**
- 🚀 **Padrão da indústria** seguido

**🎉 Secrets organizados e seguros implementados!** 🔐
