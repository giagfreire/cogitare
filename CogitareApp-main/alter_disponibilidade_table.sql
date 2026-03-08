-- Script para alterar a estrutura da tabela disponibilidade
-- Execute este script no seu banco de dados MySQL/MariaDB

-- Alterar colunas DataInicio e DataFim de DATETIME para TIME
ALTER TABLE disponibilidade 
MODIFY COLUMN DataInicio TIME,
MODIFY COLUMN DataFim TIME;

-- Verificar a estrutura atualizada
DESCRIBE disponibilidade;
