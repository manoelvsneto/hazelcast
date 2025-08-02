# Configuração dos Secrets do Azure para Kubernetes

## 1. Criar Secret para Azure SQL Server

```bash
# Substituir pelos seus valores reais
kubectl create secret generic azure-sql-secret \
  --from-literal=connection-string="jdbc:sqlserver://SEU_SERVIDOR.database.windows.net:1433;databaseName=SEU_DATABASE;encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;" \
  --from-literal=username="SEU_USUARIO" \
  --from-literal=password="SUA_SENHA"
```

## 2. Criar Secret para Azure Service Bus

```bash
# Substituir pela sua connection string real
kubectl create secret generic azure-servicebus-secret \
  --from-literal=connection-string="Endpoint=sb://SEU_NAMESPACE.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=SUA_CHAVE"
```

## 3. Verificar secrets criados

```bash
kubectl get secrets
kubectl describe secret azure-sql-secret
kubectl describe secret azure-servicebus-secret
```

## 4. Exemplo de valores para teste local

### SQL Server (exemplo):
```
Connection String: jdbc:sqlserver://myserver.database.windows.net:1433;databaseName=hazelcast_db;encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;
Username: hazelcast_user
Password: MinhaSenh@123!
```

### Service Bus (exemplo):
```
Connection String: Endpoint=sb://myhazelcast.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=CHAVE_AQUI
Queue Name: hazelcast-events
```

## 5. Script para criar secrets rapidamente

```bash
#!/bin/bash

# SQL Server Secret
read -p "SQL Server Connection String: " SQL_CONN
read -p "SQL Server Username: " SQL_USER
read -s -p "SQL Server Password: " SQL_PASS
echo

kubectl create secret generic azure-sql-secret \
  --from-literal=connection-string="$SQL_CONN" \
  --from-literal=username="$SQL_USER" \
  --from-literal=password="$SQL_PASS"

# Service Bus Secret  
read -p "Service Bus Connection String: " SB_CONN

kubectl create secret generic azure-servicebus-secret \
  --from-literal=connection-string="$SB_CONN"

echo "Secrets created successfully!"
```

## 6. Para atualizar secrets existentes

```bash
# Deletar e recriar
kubectl delete secret azure-sql-secret
kubectl delete secret azure-servicebus-secret

# Recriar com novos valores
# ... usar comandos acima
```

## 7. Verificar se a aplicação está usando os secrets

```bash
# Ver logs da aplicação
kubectl logs -l app=hazelcast-client -f

# Deve mostrar:
# "SQL Server connection established"
# "Service Bus connection established"
```
