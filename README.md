# Hazelcast 5.5 com Integração Azure

Este projeto demonstra como usar Hazelcast 5.5 integrado com **Azure SQL Server** e **Azure Service Bus** em um ambiente Kubernetes (MicroK8s).

## 🚀 Funcionalidades

- **Hazelcast Client** conectando a cluster existente
- **Azure SQL Server** para persistência de dados
- **Azure Service Bus** para mensageria e eventos
- **Kubernetes deployment** otimizado para ARM64
- **Cache distribuído** com sincronização automática
- **Event listeners** para auditoria e monitoramento

## 🏗️ Arquitetura

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Hazelcast     │    │  SQL Server      │    │  Service Bus    │
│   Cluster       │◄──►│  (Azure)         │    │  (Azure)        │
│   (Existing)    │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         ▲                        ▲                        ▲
         │                        │                        │
         ▼                        ▼                        ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Hazelcast Client                              │
│              (MicroK8s Container)                              │
│                                                                │
│  • Cache distribuído                                          │
│  • Persistência automática                                    │
│  • Eventos para Service Bus                                   │
│  • Sincronização de dados                                     │
└─────────────────────────────────────────────────────────────────┘
```

## 📋 Pré-requisitos

- Java 11 ou superior
- Maven 3.6 ou superior
- IDE compatível com Java (recomendado: VS Code com Extension Pack for Java)

## 🛠️ Instalação e Configuração

### 1. Clone ou baixe o projeto
```bash
git clone <repository-url>
cd hazelcast-project
```

### 2. Compile o projeto
```bash
mvn clean compile
```

### 3. Execute os testes
```bash
mvn test
```

## 🎯 Como Usar

### Executando o Servidor Hazelcast

1. **Via Maven:**
```bash
mvn exec:java -Dexec.mainClass="com.hazelcast.example.HazelcastServer"
```

2. **Via IDE:**
   - Abra a classe `HazelcastServer.java`
   - Execute o método `main`

3. **Via linha de comando:**
```bash
mvn clean package
java -cp target/classes;target/dependency/* com.hazelcast.example.HazelcastServer
```

### Executando o Cliente Hazelcast

**Certifique-se de que o servidor está rodando primeiro!**

1. **Via Maven:**
```bash
mvn exec:java -Dexec.mainClass="com.hazelcast.example.HazelcastClientExample"
```

2. **Via IDE:**
   - Abra a classe `HazelcastClientExample.java`
   - Execute o método `main`

## 📊 Exemplos de Uso

### 1. Operações Básicas com Mapas Distribuídos
```java
IMap<String, String> map = hazelcastInstance.getMap("example-map");
map.put("chave", "valor");
String valor = map.get("chave");
```

### 2. Cache com TTL (Time-To-Live)
```java
map.put("temp-key", "valor temporário", 10, TimeUnit.SECONDS);
```

### 3. Gerenciamento de Sessões
```java
IMap<String, UserSession> sessions = client.getMap("user-sessions");
UserSession session = new UserSession("user123", "João", LocalDateTime.now());
sessions.put(session.getUserId(), session);
```

## 🔧 Configuração

### Configuração Programática
A configuração principal está em `HazelcastServer.createConfig()`:
- Nome do cluster: `hazelcast-example-cluster`
- Porta padrão: `5701`
- Backup count: `1` para a maioria dos mapas

### Configuração XML
Arquivo de configuração alternativo em `src/main/resources/hazelcast.xml` com:
- Configurações de rede
- Políticas de eviction
- TTL para diferentes mapas
- Configurações de backup

### Logging
Configuração de logging em `src/main/resources/logback.xml`:
- Logs no console e arquivo
- Rotação diária de logs
- Níveis configuráveis por pacote

## 🧪 Testes

Execute todos os testes:
```bash
mvn test
```

Execute um teste específico:
```bash
mvn test -Dtest=HazelcastDistributedMapTest
```

Os testes incluem:
- Operações básicas de mapas
- Operações condicionais
- Armazenamento de objetos complexos
- Estatísticas de mapas

## 📁 Estrutura do Projeto

```
hazelcast-project/
├── src/
│   ├── main/
│   │   ├── java/com/hazelcast/example/
│   │   │   ├── HazelcastServer.java          # Servidor principal
│   │   │   └── HazelcastClientExample.java   # Cliente com exemplos
│   │   └── resources/
│   │       ├── hazelcast.xml                 # Configuração XML
│   │       └── logback.xml                   # Configuração de logging
│   └── test/
│       └── java/com/hazelcast/example/
│           └── HazelcastDistributedMapTest.java  # Testes unitários
├── .github/
│   └── copilot-instructions.md               # Instruções para GitHub Copilot
├── pom.xml                                   # Configuração Maven
└── README.md                                 # Este arquivo
```

## 🔗 Dependências Principais

- **Hazelcast Core**: `5.5.0` - Funcionalidade principal do IMDG
- **Hazelcast Client**: `5.5.0` - Cliente para conexão remota
- **SLF4J + Logback**: Logging
- **JUnit 5**: Testes unitários

## 📝 Notas Importantes

### Rede e Firewall
- Por padrão, usa multicast para descoberta de nós
- Porta padrão: `5701` (configurável)
- Para ambientes de produção, considere configuração TCP/IP específica

### Memória
- Monitore o uso de memória em produção
- Configure políticas de eviction apropriadas
- Use TTL para dados temporários

### Segurança
- Para produção, configure autenticação e autorização
- Use SSL/TLS para comunicação entre nós
- Configure firewalls apropriadamente

## 🎓 Próximos Passos

1. **Explore outras estruturas de dados**: Queues, Sets, Lists, Topics
2. **Implemente processamento distribuído**: EntryProcessor, MapReduce
3. **Configure cluster em múltiplas máquinas**: TCP/IP discovery
4. **Integre com frameworks**: Spring Boot, Micronaut
5. **Implemente persistência**: MapStore, MapLoader
6. **Configure Management Center**: Monitoramento e administração

## 📚 Recursos Adicionais

- [Documentação Oficial Hazelcast 5.5](https://docs.hazelcast.com/hazelcast/5.5/)
- [Guia de Configuração](https://docs.hazelcast.com/hazelcast/5.5/configuration/understanding-configuration)
- [Exemplos de Código](https://github.com/hazelcast/hazelcast-code-samples)
- [Best Practices](https://docs.hazelcast.com/hazelcast/5.5/performance/best-practices)

## 🤝 Contribuindo

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto é distribuído sob a licença MIT. Veja `LICENSE` para mais informações.
