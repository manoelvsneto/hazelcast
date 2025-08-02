# 🔒 Solução para Problema de Certificado SSL Kubernetes

## ❌ **Problema Identificado:**

```
error: x509: certificate is valid for 127.0.0.1, 10.152.183.1, 10.0.0.237, 172.17.0.1, not 164.152.34.160
```

**Causa**: O certificado do cluster Kubernetes não inclui o IP externo (`164.152.34.160`) que o Azure DevOps está tentando usar para conectar.

## ✅ **Soluções Implementadas:**

### **1. Solução Temporária (Aplicada no Pipeline):**
- Adicionado `--insecure-skip-tls-verify` em todos os comandos kubectl
- Esta solução permite que o pipeline funcione mas reduz a segurança

### **2. Solução Permanente Recomendada:**

#### **Opção A: Configurar Service Connection com certificado correto**
1. No Azure DevOps, vá em **Project Settings** > **Service Connections**
2. Edite a connection `K8SOracleCloud`
3. Configure para usar certificado que inclua o IP externo

#### **Opção B: Usar kubeconfig com configuração adequada**
1. Gere um kubeconfig que use o IP interno ou nome DNS correto:
```bash
# No servidor do cluster
microk8s config > kubeconfig-azure.yaml

# Edite o server para usar IP interno ou configure DNS adequado
sed -i 's|164.152.34.160|10.152.183.1|g' kubeconfig-azure.yaml
```

2. Use este kubeconfig na service connection do Azure DevOps

#### **Opção C: Reconfigurar certificado do cluster**
```bash
# No servidor MicroK8s, adicionar IP externo ao certificado
sudo microk8s refresh-certs --cert server.crt --add-ip 164.152.34.160
```

## 🔧 **Configuração Atual do Pipeline:**

### **Melhorias Aplicadas:**
1. ✅ **Skip TLS verification** para contornar problema de certificado
2. ✅ **Debug step** para verificar conectividade antes do deploy
3. ✅ **Criação automática** de namespace se não existir
4. ✅ **Logs detalhados** para troubleshooting
5. ✅ **Verificação de status** completa após deployment

### **Steps Adicionados:**
- **Debug Kubernetes Connection**: Testa conectividade antes do deploy
- **Enhanced Verification**: Logs e status detalhados após deploy

## 🚀 **Resultado Esperado:**

Com as correções aplicadas, o pipeline deve:
1. ✅ Conectar ao cluster (ignorando certificado)
2. ✅ Criar namespace `hazelcast` se necessário
3. ✅ Fazer deploy do cliente Hazelcast
4. ✅ Verificar status e logs do deployment

## ⚠️ **Considerações de Segurança:**

- `--insecure-skip-tls-verify` reduz a segurança
- **Recomendado**: Implementar solução permanente (Opções A, B ou C)
- Para ambiente de produção, sempre use certificados válidos

## 📝 **Próximos Passos:**

1. **Imediato**: Pipeline deve funcionar com skip TLS
2. **Curto prazo**: Implementar uma das soluções permanentes
3. **Longo prazo**: Configurar certificados adequados para produção

## 🔍 **Debug Adicional:**

Se ainda houver problemas, adicione este step ao pipeline:
```yaml
- script: |
    echo "=== KUBECONFIG DEBUG ==="
    kubectl config view --minify
    echo "=== CLUSTER INFO ==="
    kubectl cluster-info dump --insecure-skip-tls-verify
  displayName: 'Debug Kubernetes Config'
```
