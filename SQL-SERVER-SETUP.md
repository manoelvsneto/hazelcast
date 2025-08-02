# 🗄️ SQL Server Setup para Hazelcast - Guia Completo

## 📋 **Scripts Disponíveis:**

### **📄 sql-server-schema.sql**
Script completo com:
- ✅ Criação das tabelas `users` e `user_events`
- ✅ Índices para performance otimizada
- ✅ Dados de exemplo para teste
- ✅ Verificações de estrutura
- ✅ Comentários detalhados

### **🔧 setup-sql-server.ps1** (Windows)
Script PowerShell automático para executar o schema

### **🔧 setup-sql-server.sh** (Linux/macOS)  
Script Bash automático para executar o schema

---

## 🗄️ **Estrutura das Tabelas**

### **👥 Tabela: users**
```sql
CREATE TABLE users (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,           -- Chave primária auto-incremento
    user_id NVARCHAR(100) NOT NULL UNIQUE,         -- ID único do usuário (chave do Hazelcast)
    username NVARCHAR(255) NOT NULL,               -- Nome do usuário  
    email NVARCHAR(255),                           -- Email do usuário (opcional)
    created_at DATETIME2 DEFAULT GETDATE(),        -- Data de criação
    last_login DATETIME2                           -- Último login (opcional)
);
```

**Campos:**
- `id` - Chave primária auto-incremento
- `user_id` - **Chave do Hazelcast Map** (único)
- `username` - Nome do usuário
- `email` - Email (opcional)
- `created_at` - Timestamp de criação automático
- `last_login` - Último login (atualizado pela aplicação)

### **📝 Tabela: user_events**
```sql
CREATE TABLE user_events (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,           -- Chave primária auto-incremento
    user_id NVARCHAR(100) NOT NULL,                -- ID do usuário relacionado
    event_type NVARCHAR(100) NOT NULL,             -- Tipo do evento (ADDED, UPDATED, REMOVED)
    event_data NVARCHAR(MAX),                      -- Dados do evento em JSON
    created_at DATETIME2 DEFAULT GETDATE()         -- Timestamp do evento
);
```

**Campos:**
- `id` - Chave primária auto-incremento  
- `user_id` - Referência ao usuário
- `event_type` - **ADDED**, **UPDATED**, **REMOVED**
- `event_data` - JSON com dados do evento
- `created_at` - Timestamp automático

### **📊 Índices Criados:**
```sql
-- Performance otimizada
IX_users_user_id              -- Busca rápida por user_id
IX_user_events_user_id        -- Join rápido com users
IX_user_events_created_at     -- Ordenação temporal
IX_user_events_event_type     -- Filtro por tipo de evento
```

---

## 🚀 **Como Executar o Setup**

### **🔧 Opção 1: Script Automático (Windows)**
```powershell
# Executar com parâmetros padrão (localhost)
.\setup-sql-server.ps1

# Executar com servidor específico
.\setup-sql-server.ps1 -ServerName "localhost" -DatabaseName "hazelcast_db" -Username "sa"

# Azure SQL Server
.\setup-sql-server.ps1 -ServerName "meu-servidor.database.windows.net" -DatabaseName "hazelcast_db" -Username "admin-hazelcast"

# Autenticação Windows
.\setup-sql-server.ps1 -ServerName "localhost" -UseWindowsAuth
```

### **🔧 Opção 2: Script Automático (Linux/macOS)**
```bash
# Tornar executável
chmod +x setup-sql-server.sh

# Executar com parâmetros padrão
./setup-sql-server.sh

# Executar com servidor específico  
./setup-sql-server.sh localhost hazelcast_db sa

# Azure SQL Server
./setup-sql-server.sh meu-servidor.database.windows.net hazelcast_db admin-hazelcast
```

### **🔧 Opção 3: Manual com SQL Server Management Studio**
1. Abrir **SQL Server Management Studio**
2. Conectar ao servidor
3. Abrir arquivo `sql-server-schema.sql`
4. Executar (F5)

### **🔧 Opção 4: Manual com sqlcmd**
```bash
# Windows
sqlcmd -S localhost -d hazelcast_db -U sa -P senha -i sql-server-schema.sql

# Linux/macOS
sqlcmd -S localhost -d hazelcast_db -U sa -P senha -i sql-server-schema.sql
```

---

## 📊 **Verificação do Setup**

### **✅ Verificar Tabelas Criadas:**
```sql
-- Listar tabelas
SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME IN ('users', 'user_events');

-- Verificar estrutura
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'users'
ORDER BY ORDINAL_POSITION;
```

### **✅ Verificar Dados de Exemplo:**
```sql
-- Ver usuários
SELECT * FROM users;

-- Ver eventos
SELECT * FROM user_events ORDER BY created_at DESC;

-- Contar registros
SELECT 'users' as tabela, COUNT(*) as total FROM users
UNION ALL
SELECT 'user_events' as tabela, COUNT(*) as total FROM user_events;
```

### **✅ Verificar Índices:**
```sql
-- Listar índices
SELECT 
    i.name as index_name,
    t.name as table_name,
    c.name as column_name
FROM sys.indexes i
JOIN sys.tables t ON i.object_id = t.object_id
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE t.name IN ('users', 'user_events')
ORDER BY t.name, i.name;
```

---

## 🔗 **Integração com Hazelcast**

### **Como o Hazelcast usa as tabelas:**

#### **1. Persistência Automática:**
```java
// Operação no Hazelcast Map
hazelcastMap.put("user123", userData);

// SQL gerado automaticamente:
INSERT INTO users (user_id, username, email, created_at) 
VALUES ('user123', 'João Silva', 'joao@email.com', GETDATE());
```

#### **2. Eventos Automáticos:**
```java
// Listener detecta mudança
public void entryAdded(EntryEvent<String, UserData> event) {
    // SQL gerado:
    INSERT INTO user_events (user_id, event_type, event_data, created_at)
    VALUES ('user123', 'ADDED', '{"username":"João Silva",...}', GETDATE());
}
```

#### **3. Consultas da Aplicação:**
```java
// Buscar usuário no banco
SELECT * FROM users WHERE user_id = 'user123';

// Histórico de eventos
SELECT * FROM user_events 
WHERE user_id = 'user123' 
ORDER BY created_at DESC;
```

---

## ⚙️ **Configuração no Pipeline**

### **Variáveis necessárias no Azure DevOps:**
```yaml
# azure-pipelines.yml
variables:
  SQL_SERVER_HOST: 'meu-servidor.database.windows.net'
  SQL_SERVER_DATABASE: 'hazelcast_db' 
  SQL_SERVER_USERNAME: 'admin-hazelcast'

# Variável secreta (configurar no Azure DevOps):
SQL_SERVER_PASSWORD: 'MinhaSenh@Segura123'
```

### **Connection String gerada:**
```
jdbc:sqlserver://meu-servidor.database.windows.net:1433;databaseName=hazelcast_db;encrypt=true;trustServerCertificate=true
```

---

## 🆘 **Troubleshooting**

### **❌ Erro: "Login failed"**
```
💡 Soluções:
- Verificar username/password
- Verificar se SQL Authentication está habilitado
- Verificar se usuário tem permissões no database
```

### **❌ Erro: "Database not found"**
```sql
-- Criar database se não existir
CREATE DATABASE hazelcast_db;
```

### **❌ Erro: "Cannot connect to server"**
```
💡 Soluções:
- Verificar se SQL Server está rodando
- Verificar firewall/rede
- Verificar porta (padrão 1433)
- Para Azure SQL: verificar firewall rules
```

### **❌ Erro: "Table already exists"**
```
✅ Normal! O script verifica antes de criar
-- O script usa: IF NOT EXISTS
```

---

## 📈 **Performance e Manutenção**

### **🔍 Monitoramento:**
```sql
-- Estatísticas das tabelas
SELECT 
    t.name AS tabela,
    p.rows AS total_registros,
    (p.rows * 8 / 1024) AS tamanho_mb
FROM sys.tables t
JOIN sys.partitions p ON t.object_id = p.object_id
WHERE t.name IN ('users', 'user_events')
    AND p.index_id IN (0,1);

-- Eventos mais recentes
SELECT TOP 10 
    event_type,
    user_id,
    created_at
FROM user_events 
ORDER BY created_at DESC;
```

### **🧹 Limpeza (opcional):**
```sql
-- Remover eventos antigos (mais de 30 dias)
DELETE FROM user_events 
WHERE created_at < DATEADD(day, -30, GETDATE());

-- Remover dados de teste
DELETE FROM user_events WHERE user_id = 'test-user-1';
DELETE FROM users WHERE user_id = 'test-user-1';
```

**🎉 Setup completo! Seu SQL Server está pronto para o Hazelcast!** 🚀
