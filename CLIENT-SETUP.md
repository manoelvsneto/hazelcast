# Configuração simplificada - Cliente conectando ao servidor existente

## Arquivos do projeto:

```
k8s/
  hazelcast-client-deployment.yaml  # Deployment apenas do cliente
src/
  main/java/com/hazelcast/example/
    HazelcastClientExample.java     # Cliente que conecta ao servidor
    HazelcastServer.java           # Não usado (servidor já existe)
Dockerfile.arm64                   # Para build ARM64
deploy-client-only.sh             # Script simples de deploy
deploy-client-only.ps1           # Versão Windows
```

## Deploy rápido:

### Linux/macOS:
```bash
./deploy-client-only.sh
```

### Windows:
```powershell
.\deploy-client-only.ps1
```

## Configuração do cliente:

O cliente está configurado para conectar ao servidor existente através de:
- **Service DNS**: `hazelcast-service.default.svc.cluster.local:5701`
- **Cluster Name**: `dev` (ajuste se necessário)
- **Retry**: 10 tentativas de conexão

## Ajustar para seu servidor:

Se seu servidor tem configurações diferentes, edite `k8s/hazelcast-client-deployment.yaml`:

```yaml
env:
  - name: HAZELCAST_CLUSTER_NAME
    value: "SEU_CLUSTER_NAME"     # Nome do seu cluster
  - name: HAZELCAST_SERVER_ADDRESS  
    value: "SEU_SERVICE:5701"     # Service do seu servidor
```

## Verificar conexão:

```bash
# Ver logs do cliente
microk8s kubectl logs -l app=hazelcast-client -f

# Deve mostrar:
# "CLIENT CONNECTED"
# "Members {size:X, ver:Y}"
```

## Troubleshooting:

### Cliente não conecta:
1. Verificar se o service do servidor existe:
   ```bash
   microk8s kubectl get services | grep hazelcast
   ```

2. Verificar se o cluster name está correto:
   ```bash
   microk8s kubectl logs -l app=hazelcast-client --tail=20
   ```

3. Testar conectividade:
   ```bash
   microk8s kubectl exec -it deployment/hazelcast-client -- nslookup hazelcast-service
   ```
