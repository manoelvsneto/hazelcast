# ✅ Correção: "no main manifest attribute, in app.jar"

## ❌ **Problema Identificado:**

```
no main manifest attribute, in app.jar
```

**Causa**: O JAR gerado pelo Maven não tinha o atributo `Main-Class` configurado no `MANIFEST.MF`, tornando-o não executável.

## 🔧 **Correções Aplicadas:**

### **1. Atualizado pom.xml:**

#### **Adicionado Maven Shade Plugin:**
```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-shade-plugin</artifactId>
    <version>3.4.1</version>
    <!-- Configuração completa para JAR executável -->
</plugin>
```

#### **Funcionalidades do Shade Plugin:**
- ✅ **Cria JAR com todas as dependências** (fat JAR)
- ✅ **Configura Main-Class** no MANIFEST.MF
- ✅ **Resolve conflitos** de META-INF
- ✅ **Remove assinaturas digitais** problemáticas
- ✅ **Preserva resources** de services

#### **Classe Principal Configurada:**
```xml
<mainClass>com.hazelcast.example.HazelcastAzureIntegratedClient</mainClass>
```

### **2. Atualizado Dockerfile.runtime:**

#### **Melhorias no Dockerfile:**
```dockerfile
# Copia JAR shaded específico
COPY target/hazelcast-project-*.jar app.jar

# Configurações de memória adequadas
ENV JAVA_OPTS="-Xmx512m -Xms256m -Dhazelcast.logging.type=slf4j"

# Execução com variáveis de ambiente
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
```

### **3. Adicionado Debug no Pipeline:**
```yaml
echo "Listando JARs disponíveis:"
ls -la $(System.ArtifactsDirectory)/drop/target/
```

## 🚀 **Como Funciona Agora:**

### **Build Process:**
1. **Maven compile**: Compila código fonte
2. **Maven test**: Executa testes
3. **Maven package**: Gera JAR normal + JAR shaded
4. **Shade Plugin**: Cria `hazelcast-project-1.0.0.jar` executável

### **Docker Process:**
1. **Dockerfile procura** por `hazelcast-project-*.jar`
2. **Copia JAR executável** como `app.jar`
3. **Executa** com `java $JAVA_OPTS -jar app.jar`

### **Resultado:**
- ✅ **JAR executável** com Main-Class configurado
- ✅ **Todas as dependências** incluídas
- ✅ **Configuração de memória** otimizada
- ✅ **Logging configurado** adequadamente

## 📋 **Arquivos Gerados:**

Após o build, você terá:
```
target/
├── hazelcast-project-1.0.0.jar           # JAR executável (shaded)
├── original-hazelcast-project-1.0.0.jar  # JAR original (sem deps)
└── classes/                               # Classes compiladas
```

## 🔍 **Verificação Local:**

Para testar localmente:
```bash
# Build do projeto
mvn clean package

# Verificar JARs gerados
ls -la target/*.jar

# Testar execução
java -jar target/hazelcast-project-1.0.0.jar

# Verificar MANIFEST.MF
jar tf target/hazelcast-project-1.0.0.jar | grep -i manifest
unzip -p target/hazelcast-project-1.0.0.jar META-INF/MANIFEST.MF
```

## ⚡ **Benefícios das Mudanças:**

1. **JAR Auto-Suficiente**: Todas as dependências incluídas
2. **Executável Direto**: Pode ser executado com `java -jar`
3. **Configuração Correta**: Main-Class no MANIFEST.MF
4. **Memória Otimizada**: Configurações adequadas para containers
5. **Logging Configurado**: SLF4J como padrão do Hazelcast

## 🐳 **Pipeline Atualizado:**

O pipeline agora:
1. ✅ **Gera JAR executável** com shade plugin
2. ✅ **Lista JARs** disponíveis para debug
3. ✅ **Copia JAR correto** no Dockerfile
4. ✅ **Executa com configurações** otimizadas

O erro "no main manifest attribute" agora está **completamente resolvido**! 🎯
