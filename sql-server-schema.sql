-- ========================================
-- 🗄️ SQL Server Database Schema
-- Tabelas para Hazelcast Azure Integration
-- ========================================

-- 📊 Usar database específico (opcional)
-- USE hazelcast_db;
-- GO

-- ========================================
-- 👥 Tabela: users
-- Armazena dados dos usuários do cache Hazelcast
-- ========================================

-- Verificar se tabela existe e criar se necessário
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='users' AND xtype='U')
BEGIN
    CREATE TABLE users (
        id BIGINT IDENTITY(1,1) PRIMARY KEY,           -- Chave primária auto-incremento
        user_id NVARCHAR(100) NOT NULL UNIQUE,         -- ID único do usuário (chave do Hazelcast)
        username NVARCHAR(255) NOT NULL,               -- Nome do usuário
        email NVARCHAR(255),                           -- Email do usuário (opcional)
        created_at DATETIME2 DEFAULT GETDATE(),        -- Data de criação
        last_login DATETIME2                           -- Último login (opcional)
    );
    
    PRINT '✅ Tabela users criada com sucesso!';
END
ELSE
BEGIN
    PRINT '✅ Tabela users já existe!';
END
GO

-- ========================================
-- 📝 Tabela: user_events  
-- Log de eventos e auditoria do Hazelcast
-- ========================================

-- Verificar se tabela existe e criar se necessário
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='user_events' AND xtype='U')
BEGIN
    CREATE TABLE user_events (
        id BIGINT IDENTITY(1,1) PRIMARY KEY,           -- Chave primária auto-incremento
        user_id NVARCHAR(100) NOT NULL,                -- ID do usuário relacionado
        event_type NVARCHAR(100) NOT NULL,             -- Tipo do evento (ADDED, UPDATED, REMOVED)
        event_data NVARCHAR(MAX),                      -- Dados do evento em JSON
        created_at DATETIME2 DEFAULT GETDATE()         -- Timestamp do evento
    );
    
    PRINT '✅ Tabela user_events criada com sucesso!';
END
ELSE
BEGIN
    PRINT '✅ Tabela user_events já existe!';
END
GO

-- ========================================
-- 📋 Criar índices para performance
-- ========================================

-- Índice na tabela users
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name='IX_users_user_id')
BEGIN
    CREATE INDEX IX_users_user_id ON users(user_id);
    PRINT '✅ Índice IX_users_user_id criado!';
END

-- Índices na tabela user_events
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name='IX_user_events_user_id')
BEGIN
    CREATE INDEX IX_user_events_user_id ON user_events(user_id);
    PRINT '✅ Índice IX_user_events_user_id criado!';
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name='IX_user_events_created_at')
BEGIN
    CREATE INDEX IX_user_events_created_at ON user_events(created_at);
    PRINT '✅ Índice IX_user_events_created_at criado!';
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name='IX_user_events_event_type')
BEGIN
    CREATE INDEX IX_user_events_event_type ON user_events(event_type);
    PRINT '✅ Índice IX_user_events_event_type criado!';
END

GO

-- ========================================
-- 🔍 Verificar estrutura das tabelas
-- ========================================

PRINT '📊 Estrutura da tabela users:';
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    CHARACTER_MAXIMUM_LENGTH,
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'users'
ORDER BY ORDINAL_POSITION;

PRINT '📊 Estrutura da tabela user_events:';
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    CHARACTER_MAXIMUM_LENGTH,
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'user_events'
ORDER BY ORDINAL_POSITION;

-- ========================================
-- 📋 Dados de exemplo (opcional)
-- ========================================

-- Inserir usuário de teste se não existir
IF NOT EXISTS (SELECT 1 FROM users WHERE user_id = 'test-user-1')
BEGIN
    INSERT INTO users (user_id, username, email)
    VALUES ('test-user-1', 'Usuário Teste', 'teste@exemplo.com');
    
    PRINT '✅ Usuário de teste inserido!';
END

-- Inserir evento de teste
INSERT INTO user_events (user_id, event_type, event_data)
VALUES ('test-user-1', 'CREATED', '{"action": "user_created", "source": "sql_script", "timestamp": "' + FORMAT(GETDATE(), 'yyyy-MM-ddTHH:mm:ss') + '"}');

PRINT '✅ Evento de teste inserido!';

-- ========================================
-- 📊 Verificação final
-- ========================================

PRINT '📈 Contagem de registros:';
SELECT 'users' as tabela, COUNT(*) as total FROM users
UNION ALL
SELECT 'user_events' as tabela, COUNT(*) as total FROM user_events;

PRINT '🎉 Setup do banco de dados concluído com sucesso!';
PRINT '✅ Tabelas criadas: users, user_events';
PRINT '✅ Índices criados para performance';
PRINT '✅ Dados de exemplo inseridos';
PRINT '🚀 Pronto para usar com Hazelcast!';

-- ========================================
-- 🔧 Comandos úteis para manutenção
-- ========================================

/*
-- Limpar dados de teste:
DELETE FROM user_events WHERE user_id = 'test-user-1';
DELETE FROM users WHERE user_id = 'test-user-1';

-- Ver últimos eventos:
SELECT TOP 10 * FROM user_events ORDER BY created_at DESC;

-- Ver todos os usuários:
SELECT * FROM users ORDER BY created_at DESC;

-- Estatísticas das tabelas:
SELECT 
    t.name AS tabela,
    p.rows AS total_registros
FROM sys.tables t
INNER JOIN sys.partitions p ON t.object_id = p.object_id
WHERE t.name IN ('users', 'user_events')
    AND p.index_id IN (0,1);
*/
