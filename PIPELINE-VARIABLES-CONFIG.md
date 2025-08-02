# 🔐 Configuração de Variáveis no Azure DevOps Pipeline

## 📋 **Variáveis Configuradas no Pipeline**

O pipeline agora usa **variáveis do Azure DevOps** ao invés de valores hardcoded para maior segurança e flexibilidade.

---

## 🏗️ **Variáveis no azure-pipelines.yml**

### **📊 Variáveis Públicas (Valores Padrão):**
```yaml
variables:
  # SQL Server Azure
  SQL_SERVER_HOST: 'your-server.database.windows.net'
  SQL_SERVER_DATABASE: 'hazelcast_db'
  SQL_SERVER_USERNAME: 'hazelcast-admin'
  
  # Azure Service Bus
  SERVICE_BUS_NAMESPACE: 'your-servicebus-namespace.servicebus.windows.net'
  SERVICE_BUS_QUEUE: 'hazelcast-events'
```

### **🔒 Variáveis Secretas (Devem ser configuradas no Azure DevOps):**
- `SQL_SERVER_PASSWORD` 🔐
- `SERVICE_BUS_ACCESS_KEY` 🔐

---

## ⚙️ **Como Configurar Variáveis Secretas no Azure DevOps**

### **1. Acessar Pipeline Variables:**
1. **Azure DevOps** → Seu projeto
2. **Pipelines** → Selecionar seu pipeline
3. **Edit** → **Variables** (canto superior direito)
4. **New variable**

### **2. Configurar SQL_SERVER_PASSWORD:**
```
Name: SQL_SERVER_PASSWORD
Value: SuaSenhaDoSQLServerAqui
✅ Keep this value secret (marcar esta opção)
```

### **3. Configurar SERVICE_BUS_ACCESS_KEY:**
```
Name: SERVICE_BUS_ACCESS_KEY
Value: SuaChaveDoServiceBusAqui
✅ Keep this value secret (marcar esta opção)
```

### **4. Opcional - Sobrescrever Valores Padrão:**

Se quiser sobrescrever os valores padrão, pode criar variáveis para:

```
SQL_SERVER_HOST: seu-servidor.database.windows.net
SQL_SERVER_DATABASE: sua-database
SQL_SERVER_USERNAME: seu-usuario
SERVICE_BUS_NAMESPACE: seu-namespace.servicebus.windows.net
SERVICE_BUS_QUEUE: sua-queue
```

---

## 🔄 **Como o Pipeline Substitui as Variáveis**

### **1. Template com Placeholders:**
```yaml
# k8s/hazelcast-client-deployment.yaml
env:
  - name: SQL_SERVER_CONNECTION_STRING
    value: "jdbc:sqlserver://__SQL_SERVER_HOST__:1433;databaseName=__SQL_SERVER_DATABASE__..."
  - name: SQL_SERVER_PASSWORD
    value: "__SQL_SERVER_PASSWORD__"
  - name: SERVICE_BUS_CONNECTION_STRING
    value: "Endpoint=sb://__SERVICE_BUS_NAMESPACE__;...;SharedAccessKey=__SERVICE_BUS_ACCESS_KEY__"
```

### **2. Pipeline Substitui Durante Deploy:**
```bash
# azure-pipelines.yml - Deploy stage
sed -i "s|__SQL_SERVER_HOST__|$(SQL_SERVER_HOST)|g" manifest.yaml
sed -i "s|__SQL_SERVER_PASSWORD__|$(SQL_SERVER_PASSWORD)|g" manifest.yaml
sed -i "s|__SERVICE_BUS_ACCESS_KEY__|$(SERVICE_BUS_ACCESS_KEY)|g" manifest.yaml
```

### **3. Resultado Final no Kubernetes:**
```yaml
env:
  - name: SQL_SERVER_CONNECTION_STRING
    value: "jdbc:sqlserver://meu-servidor.database.windows.net:1433;databaseName=hazelcast_db..."
  - name: SQL_SERVER_PASSWORD
    value: "MinhaSenh@Real123"
  - name: SERVICE_BUS_CONNECTION_STRING
    value: "Endpoint=sb://meu-namespace.servicebus.windows.net/;...;SharedAccessKey=abcd1234..."
```

---

## 🎯 **Valores Necessários para Configurar**

### **🗄️ SQL Server Azure:**

#### **Como obter:**
1. **Azure Portal** → SQL Server
2. **Connection strings** → JDBC

#### **Valores necessários:**
```
SQL_SERVER_HOST: meu-servidor.database.windows.net
SQL_SERVER_DATABASE: hazelcast_db
SQL_SERVER_USERNAME: admin-hazelcast
SQL_SERVER_PASSWORD: MinhaSenh@Segura123  # 🔐 SECRETO
```

### **🚌 Azure Service Bus:**

#### **Como obter:**
1. **Azure Portal** → Service Bus Namespace
2. **Shared access policies** → RootManageSharedAccessKey
3. **Primary Connection String**

#### **Connection String Format:**
```
Endpoint=sb://meu-namespace.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=abcd1234...
```

#### **Valores necessários:**
```
SERVICE_BUS_NAMESPACE: meu-namespace.servicebus.windows.net
SERVICE_BUS_ACCESS_KEY: abcd1234efgh5678ijklmnop...  # 🔐 SECRETO
SERVICE_BUS_QUEUE: hazelcast-events
```

---

## 📋 **Checklist de Configuração**

### **✅ No Azure DevOps:**
- [ ] **SQL_SERVER_PASSWORD** configurado como variável secreta
- [ ] **SERVICE_BUS_ACCESS_KEY** configurado como variável secreta
- [ ] Outras variáveis personalizadas (se necessário)

### **✅ Valores de Exemplo para Testar:**
```yaml
# Para desenvolvimento/teste pode usar valores fake:
SQL_SERVER_PASSWORD: "FakePassword123"
SERVICE_BUS_ACCESS_KEY: "FakeAccessKey12345"
```

### **✅ Verificação no Pipeline:**
- [ ] Build stage executa normalmente
- [ ] Deploy stage substitui variáveis corretamente
- [ ] Logs mostram valores substituídos (sem senhas expostas)
- [ ] Deployment aplicado no Kubernetes

---

## 🚀 **Vantagens desta Abordagem**

### **🔐 Segurança:**
- ✅ **Senhas não aparecem** no código fonte
- ✅ **Variáveis secretas protegidas** no Azure DevOps
- ✅ **Logs não expõem** informações sensíveis
- ✅ **Git não guarda secrets**

### **🔧 Flexibilidade:**
- ✅ **Diferentes ambientes** (dev, prod) com variáveis diferentes
- ✅ **Fácil rotação** de senhas sem alterar código
- ✅ **Configuração centralizada** no Azure DevOps
- ✅ **Reutilização** do mesmo deployment

### **🎯 Manutenibilidade:**
- ✅ **Um local** para configurar todas as variáveis
- ✅ **Sem hardcoding** de valores no código
- ✅ **Fácil debugging** com logs de substituição
- ✅ **Padrão da indústria** para CI/CD

---

## 🔧 **Comandos para Verificar**

### **Verificar variáveis no pipeline:**
```bash
# No Azure DevOps pipeline logs, procure por:
echo "SQL_SERVER_HOST: $(SQL_SERVER_HOST)"
echo "SERVICE_BUS_NAMESPACE: $(SERVICE_BUS_NAMESPACE)"
# As variáveis secretas NÃO aparecem nos logs
```

### **Verificar deployment aplicado:**
```bash
kubectl get deployment hazelcast-client -n hazelcast -o yaml
kubectl describe deployment hazelcast-client -n hazelcast
```

### **Verificar logs da aplicação:**
```bash
kubectl logs -f deployment/hazelcast-client -n hazelcast
```

**🎯 Configuração segura e flexível implementada!** 🚀
