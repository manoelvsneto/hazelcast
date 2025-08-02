# 🐳 Docker Hub Cleanup - Configuração

## 📋 **Configuração Necessária**

### **1. Variável Secreta no Azure DevOps**

Para que o pipeline funcione, você precisa criar uma **variável secreta** no Azure DevOps:

1. **Acesse seu projeto** no Azure DevOps
2. Vá em **Pipelines** > **Library** 
3. Crie uma **Variable Group** ou edite uma existente
4. Adicione a variável:
   - **Nome**: `DOCKERHUB_PASSWORD`
   - **Valor**: Sua senha do Docker Hub
   - **Tipo**: ✅ **Secret** (marque esta opção)

### **2. Configurar no Pipeline**

Se usar Variable Group, adicione no início do pipeline:
```yaml
variables:
- group: 'docker-hub-secrets'  # Nome do seu Variable Group
```

Ou adicione diretamente nas variáveis do pipeline (menos seguro):
```yaml
variables:
  DOCKERHUB_PASSWORD: $(DOCKERHUB_PASSWORD)  # Variável secreta
```

## 🔧 **Como Funciona**

### **Stage: DockerHubCleanup**
1. ✅ **Instala .NET SDK 8** no agent ARM64
2. ✅ **Cria projeto C# temporário** para fazer cleanup
3. ✅ **Autentica no Docker Hub** usando credenciais
4. ✅ **Lista todas as tags** do repositório (exceto 'latest')
5. ✅ **Exclui tags antigas** mantendo apenas 'latest'
6. ✅ **Fornece relatório** de exclusões

### **Fluxo do Pipeline Atualizado:**
```
Build → Docker → DockerHubCleanup → Deploy
```

### **Configurações Atuais:**
- **DOCKERHUB_USERNAME**: `manoelvsneto`
- **DOCKERHUB_REPOSITORY**: `hazelcast-client`
- **Executa apenas**: Na branch `main`
- **Mantém**: Tag `latest`
- **Exclui**: Todas as outras tags

## 📊 **Benefícios**

1. **Economia de espaço** no Docker Hub
2. **Limpeza automática** de builds antigos
3. **Manutenção da tag latest** sempre atualizada
4. **Logs detalhados** de exclusões
5. **Execução apenas na main** para evitar limpezas desnecessárias

## ⚙️ **Personalização**

### **Alterar repositório:**
```yaml
variables:
  DOCKERHUB_REPOSITORY: 'seu-novo-repositorio'
```

### **Alterar username:**
```yaml
variables:
  DOCKERHUB_USERNAME: 'seu-username'
```

### **Manter mais tags:**
Edite o código C# para manter tags específicas:
```csharp
if (tagName != "latest" && tagName != "stable" && tagName != "production")
{
    tags.Add(tagName);
}
```

## 🔒 **Segurança**

- ✅ **Senha protegida** como variável secreta
- ✅ **Token JWT** usado para autenticação
- ✅ **Não exposta** em logs do pipeline
- ✅ **Executada apenas** em builds da main

## 🐛 **Troubleshooting**

### **Erro de autenticação:**
- Verifique se `DOCKERHUB_PASSWORD` está configurada corretamente
- Confirme se as credenciais estão corretas

### **Erro "Repository not found":**
- Verifique se `DOCKERHUB_REPOSITORY` está correto
- Confirme se o repositório existe no Docker Hub

### **Erro de permissão:**
- Verifique se o usuário tem permissão para excluir tags
- Confirme se o repositório não é privado (se for, configure adequadamente)

## 📝 **Próximos Passos**

1. **Configure a variável secreta** `DOCKERHUB_PASSWORD`
2. **Teste o pipeline** na branch main
3. **Verifique logs** do stage DockerHubCleanup
4. **Confirme exclusões** no Docker Hub
