# 🔐 Configuração de Secrets - SQL Server e Azure Service Bus

## ⚠️ **IMPORTANTE: PERSONALIZE OS VALORES ABAIXO**

Os secrets foram adicionados como **plain text** no deployment. Você deve **substituir os valores de exemplo** pelos seus valores reais.

---

## 🗄️ **SQL Server Configuration**

### **Arquivo**: `k8s/hazelcast-client-deployment.yaml`

```yaml
# SQL Server Configuration
- name: SQL_SERVER_CONNECTION_STRING
  value: "jdbc:sqlserver://localhost:1433;databaseName=hazelcast_db;encrypt=true;trustServerCertificate=true"
- name: SQL_SERVER_USERNAME
  value: "sa"
- name: SQL_SERVER_PASSWORD
  value: "YourPassword123"
```

### **🔧 SUBSTITUA PELOS SEUS VALORES:**

#### **1. Connection String:**
```yaml
- name: SQL_SERVER_CONNECTION_STRING
  value: "jdbc:sqlserver://SEU_SERVIDOR:1433;databaseName=SUA_DATABASE;encrypt=true;trustServerCertificate=true"
```

**Exemplos de servidores:**
- **Local**: `localhost:1433`
- **Azure SQL**: `seu-servidor.database.windows.net:1433`
- **SQL Server remoto**: `ip-do-servidor:1433`

#### **2. Username:**
```yaml
- name: SQL_SERVER_USERNAME
  value: "SEU_USUARIO"
```

**Exemplos:**
- **Local**: `sa`
- **Azure SQL**: `seu-admin-user`
- **Domain user**: `domain\\usuario`

#### **3. Password:**
```yaml
- name: SQL_SERVER_PASSWORD
  value: "SUA_SENHA_REAL"
```

---

## 🚌 **Azure Service Bus Configuration**

### **Arquivo**: `k8s/hazelcast-client-deployment.yaml`

```yaml
# Service Bus Configuration
- name: SERVICE_BUS_CONNECTION_STRING
  value: "Endpoint=sb://your-servicebus-namespace.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=YOUR_ACCESS_KEY_HERE"
- name: SERVICE_BUS_QUEUE_NAME
  value: "hazelcast-events"
```

### **🔧 SUBSTITUA PELOS SEUS VALORES:**

#### **1. Connection String:**
```yaml
- name: SERVICE_BUS_CONNECTION_STRING
  value: "Endpoint=sb://SEU-NAMESPACE.servicebus.windows.net/;SharedAccessKeyName=SUA_POLICY;SharedAccessKey=SUA_CHAVE_AQUI"
```

#### **Como obter a Connection String:**

1. **Azure Portal** → Service Bus Namespace
2. **Settings** → Shared access policies
3. **Selecionar policy** (ex: RootManageSharedAccessKey)
4. **Copiar Primary Connection String**

**Exemplo real:**
```
Endpoint=sb://meu-servicebus.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=abcd1234efgh5678ijkl...
```

#### **2. Queue Name:**
```yaml
- name: SERVICE_BUS_QUEUE_NAME
  value: "nome-da-sua-queue"
```

---

## 📝 **Exemplo de Configuração Real**

### **SQL Server Azure:**
```yaml
- name: SQL_SERVER_CONNECTION_STRING
  value: "jdbc:sqlserver://meu-servidor.database.windows.net:1433;databaseName=hazelcast_db;encrypt=true;trustServerCertificate=false"
- name: SQL_SERVER_USERNAME
  value: "admin-hazelcast"
- name: SQL_SERVER_PASSWORD
  value: "MinhaSenh@Segur@123"
```

### **Service Bus Azure:**
```yaml
- name: SERVICE_BUS_CONNECTION_STRING
  value: "Endpoint=sb://meu-servicebus.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=abcd1234efgh5678ijklmnop..."
- name: SERVICE_BUS_QUEUE_NAME
  value: "eventos-hazelcast"
```

---

## 🔒 **Considerações de Segurança**

### **⚠️ Ambiente de Desenvolvimento:**
- ✅ **Plain text OK** para desenvolvimento/teste
- ✅ **Facilita configuração** inicial
- ✅ **Sem complexidade** de secrets management

### **🏭 Ambiente de Produção:**
- ⚠️ **Considere usar Kubernetes Secrets**
- ⚠️ **Ou Azure Key Vault**
- ⚠️ **Ou variáveis de ambiente seguras**

### **🔐 Conversão para Secrets (Opcional):**

Se quiser usar secrets do Kubernetes:

```bash
# Criar secret para SQL Server
kubectl create secret generic azure-sql-secret \
  --from-literal=connection-string="jdbc:sqlserver://..." \
  --from-literal=username="seu-usuario" \
  --from-literal=password="sua-senha" \
  -n hazelcast

# Criar secret para Service Bus
kubectl create secret generic azure-servicebus-secret \
  --from-literal=connection-string="Endpoint=sb://..." \
  -n hazelcast
```

---

## ✅ **Próximos Passos**

1. **📝 Editar** `k8s/hazelcast-client-deployment.yaml`
2. **🔧 Substituir** os valores pelos seus dados reais
3. **🚀 Fazer deploy** com `kubectl apply`
4. **📊 Verificar logs** para confirmar conexões

### **Comando para aplicar:**
```bash
kubectl apply -f k8s/hazelcast-client-deployment.yaml -n hazelcast
```

### **Verificar logs:**
```bash
kubectl logs -f deployment/hazelcast-client -n hazelcast
```

**🎯 Agora você pode personalizar os secrets com seus valores reais!**
