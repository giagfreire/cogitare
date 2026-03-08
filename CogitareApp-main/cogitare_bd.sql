-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: mysql-cogitare.alwaysdata.net
-- Generation Time: Oct 20, 2025 at 06:18 PM
-- Server version: 10.11.14-MariaDB
-- PHP Version: 7.4.33

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `cogitare_bd`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_atualizar_progresso_metas` (OUT `p_Mensagem` VARCHAR(255), OUT `p_Sucesso` BOOLEAN)   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET p_Sucesso = FALSE;
        SET p_Mensagem = 'Erro ao atualizar progresso das metas';
        ROLLBACK;
    END;
    
    START TRANSACTION;
    
    -- Atualizar meta de receita mensal
    UPDATE metafinanceira 
    SET ValorAtual = (
        SELECT COALESCE(SUM(Valor), 0) 
        FROM receita 
        WHERE DATE(DataRecebimento) >= DATE_FORMAT(CURDATE(), '%Y-%m-01')
        AND DATE(DataRecebimento) <= LAST_DAY(CURDATE())
        AND Status = 'Pago'
    )
    WHERE TipoMeta = 'Receita' AND Status = 'Ativa';
    
    -- Atualizar meta de lucro mensal
    UPDATE metafinanceira 
    SET ValorAtual = (
        SELECT COALESCE(SUM(Valor), 0) 
        FROM receita 
        WHERE DATE(DataRecebimento) >= DATE_FORMAT(CURDATE(), '%Y-%m-01')
        AND DATE(DataRecebimento) <= LAST_DAY(CURDATE())
        AND Status = 'Pago'
    ) - (
        SELECT COALESCE(SUM(Valor), 0) 
        FROM despesa 
        WHERE DATE(DataDespesa) >= DATE_FORMAT(CURDATE(), '%Y-%m-01')
        AND DATE(DataDespesa) <= LAST_DAY(CURDATE())
        AND Status = 'Pago'
    )
    WHERE TipoMeta = 'Lucro' AND Status = 'Ativa';
    
    SET p_Sucesso = TRUE;
    SET p_Mensagem = 'Progresso das metas atualizado com sucesso';
    COMMIT;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_buscar_comissoes_periodo` (IN `p_DataInicio` DATE, IN `p_DataFim` DATE)   BEGIN
    SELECT 
        c.IdComissao,
        c.ValorBase,
        c.PercentualComissao,
        c.ValorComissao,
        c.Bonificacao,
        c.ValorTotal,
        c.DataCalculo,
        c.DataPagamento,
        c.Status,
        cu.Nome as NomeCuidador,
        a.ObservacaoExtra as DescricaoAtendimento,
        a.Local,
        a.DataInicio
    FROM comissao c
    LEFT JOIN cuidador cu ON c.IdCuidador = cu.IdCuidador
    LEFT JOIN atendimento a ON c.IdAtendimento = a.IdAtendimento
    WHERE DATE(c.DataCalculo) BETWEEN p_DataInicio AND p_DataFim
    ORDER BY c.DataCalculo DESC;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_buscar_cuidadores_rentaveis` (IN `p_DataInicio` DATE, IN `p_DataFim` DATE)   BEGIN
    SELECT 
        c.IdCuidador,
        c.Nome,
        COUNT(a.IdAtendimento) as QtdAtendimentos,
        COALESCE(SUM(a.Valor), 0) as TotalReceitas,
        COALESCE(AVG(a.Valor), 0) as MediaAtendimento,
        COALESCE(SUM(com.ValorTotal), 0) as TotalComissoes
    FROM cuidador c
    LEFT JOIN atendimento a ON c.IdCuidador = a.IdCuidador 
        AND DATE(a.DataInicio) BETWEEN p_DataInicio AND p_DataFim
        AND a.Status = 'Concluído'
    LEFT JOIN comissao com ON a.IdAtendimento = com.IdAtendimento
    GROUP BY c.IdCuidador, c.Nome
    ORDER BY TotalReceitas DESC
    LIMIT 10;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_buscar_despesas_categoria` (IN `p_DataInicio` DATE, IN `p_DataFim` DATE)   BEGIN
    SELECT 
        Categoria,
        SUM(Valor) as TotalDespesas,
        COUNT(*) as QtdDespesas
    FROM despesa 
    WHERE DATE(DataDespesa) BETWEEN p_DataInicio AND p_DataFim
    AND Status = 'Pago'
    GROUP BY Categoria
    ORDER BY TotalDespesas DESC;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_buscar_despesas_periodo` (IN `p_DataInicio` DATE, IN `p_DataFim` DATE)   BEGIN
    SELECT 
        d.IdDespesa,
        d.TipoDespesa,
        d.Categoria,
        d.Descricao,
        d.Valor,
        d.DataDespesa,
        d.Status,
        d.Comprovante,
        c.Nome as NomeCuidador
    FROM despesa d
    LEFT JOIN cuidador c ON d.IdCuidador = c.IdCuidador
    WHERE DATE(d.DataDespesa) BETWEEN p_DataInicio AND p_DataFim
    ORDER BY d.DataDespesa DESC;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_buscar_estatisticas_financeiras` (IN `p_DataInicio` DATE, IN `p_DataFim` DATE)   BEGIN
    SELECT 
        -- ========== MÉTRICAS DE VENDAS ==========
        -- Total de vendas (todos os atendimentos)
        (SELECT COALESCE(SUM(Valor), 0) FROM atendimento) as TotalVendas,
        
        -- Valor a receber (atendimentos não concluídos)
        (SELECT COALESCE(SUM(Valor), 0) FROM atendimento 
         WHERE Status != 'Concluído') as ValorAReceber,
        
        -- Valor já recebido (atendimentos concluídos)
        (SELECT COALESCE(SUM(Valor), 0) FROM atendimento 
         WHERE Status = 'Concluído') as ValorRecebido,
        
        -- ========== MÉTRICAS DE REPASSE ==========
        -- Repasse aos cuidadores (90% do total de vendas)
        (SELECT COALESCE(SUM(Valor), 0) * 0.90 FROM atendimento) as RepasseCuidador,
        
        -- Receita da plataforma (10% do total de vendas)
        (SELECT COALESCE(SUM(Valor), 0) * 0.10 FROM atendimento) as ReceitaPlataforma,
        
        -- ========== MÉTRICAS DE RECEITA ==========
        -- Receita total de todos os atendimentos concluídos
        (SELECT COALESCE(SUM(Valor), 0) FROM atendimento 
         WHERE Status = 'Concluído') as ReceitaAtendimentosConcluidos,
        
        -- Receitas efetivamente recebidas (tabela receita)
        (SELECT COALESCE(SUM(Valor), 0) FROM receita 
         WHERE Status = 'Pago') as ReceitaTotalEfetiva,
        
        -- ========== MÉTRICAS DE DESPESAS ==========
        -- Despesas do período
        (SELECT COALESCE(SUM(Valor), 0) FROM despesa 
         WHERE DATE(DataDespesa) BETWEEN p_DataInicio AND p_DataFim AND Status = 'Pago') as TotalDespesas,
        
        -- Comissões baseadas em atendimentos concluídos
        (SELECT COALESCE(SUM(com.ValorTotal), 0) FROM comissao com
         INNER JOIN atendimento at ON com.IdAtendimento = at.IdAtendimento
         WHERE at.Status = 'Concluído' AND com.Status = 'Pago') as TotalComissoes,
        
        -- Inadimplência (atendimentos sem pagamento)
        (SELECT COALESCE(SUM(at.Valor), 0) FROM atendimento at
         LEFT JOIN pagamento p ON at.IdAtendimento = p.IdAtendimento
         WHERE at.Status = 'Concluído' 
         AND (p.IdPagamento IS NULL OR p.StatusPagamento != 'Pago')) as TotalInadimplencia,
        
        -- ========== QUANTIDADES ==========
        -- Quantidades de atendimentos por status
        (SELECT COUNT(*) FROM atendimento 
         WHERE Status = 'Concluído') as QtdAtendimentosConcluidos,
        
        (SELECT COUNT(*) FROM atendimento 
         WHERE Status != 'Concluído') as QtdAtendimentosPendentes,
        
        (SELECT COUNT(*) FROM atendimento) as QtdTotalAtendimentos,
        
        (SELECT COUNT(*) FROM receita 
         WHERE Status = 'Pago') as QtdReceitasEfetivas,
        
        (SELECT COUNT(*) FROM despesa 
         WHERE DATE(DataDespesa) BETWEEN p_DataInicio AND p_DataFim AND Status = 'Pago') as QtdDespesas,
        
        (SELECT COUNT(*) FROM atendimento at
         LEFT JOIN pagamento p ON at.IdAtendimento = p.IdAtendimento
         WHERE at.Status = 'Concluído' 
         AND (p.IdPagamento IS NULL OR p.StatusPagamento != 'Pago')) as QtdInadimplencia;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_buscar_inadimplencia_periodo` (IN `p_DataInicio` DATE, IN `p_DataFim` DATE)   BEGIN
    SELECT 
        i.IdInadimplencia,
        i.ValorDevido,
        i.DataVencimento,
        i.DiasAtraso,
        i.Status,
        i.TentativasCobranca,
        i.UltimaTentativa,
        r.Nome as NomeResponsavel,
        r.Email,
        r.Telefone,
        a.ObservacaoExtra as DescricaoAtendimento,
        a.Local,
        a.DataInicio,
        a.Status as StatusAtendimento
    FROM inadimplencia i
    LEFT JOIN responsavel r ON i.IdResponsavel = r.IdResponsavel
    LEFT JOIN atendimento a ON i.IdAtendimento = a.IdAtendimento
    WHERE DATE(i.DataVencimento) BETWEEN p_DataInicio AND p_DataFim
    ORDER BY i.DiasAtraso DESC;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_buscar_metas_financeiras` ()   BEGIN
    SELECT 
        IdMeta,
        TipoMeta,
        Descricao,
        ValorMeta,
        ValorAtual,
        DataInicio,
        DataFim,
        Status,
        ROUND((ValorAtual / ValorMeta) * 100, 2) as PercentualAlcancado
    FROM metafinanceira
    WHERE Status = 'Ativa'
    ORDER BY DataFim ASC;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_buscar_receitas_mes` ()   BEGIN
    SELECT 
        DATE_FORMAT(DataInicio, '%Y-%m') as Mes,
        SUM(Valor) as TotalReceitas,
        COUNT(*) as QtdReceitas
    FROM atendimento 
    WHERE DataInicio >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
    AND Status = 'Concluído'
    GROUP BY DATE_FORMAT(DataInicio, '%Y-%m')
    ORDER BY Mes ASC;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_buscar_receitas_periodo` (IN `p_DataInicio` DATE, IN `p_DataFim` DATE)   BEGIN
    SELECT 
        r.IdReceita,
        r.Valor,
        r.DataRecebimento,
        r.FormaPagamento,
        r.Status,
        r.Observacoes,
        resp.Nome as NomeResponsavel,
        a.ObservacaoExtra as DescricaoAtendimento,
        a.Local,
        a.DataInicio
    FROM receita r
    LEFT JOIN responsavel resp ON r.IdResponsavel = resp.IdResponsavel
    LEFT JOIN atendimento a ON r.IdAtendimento = a.IdAtendimento
    WHERE DATE(r.DataRecebimento) BETWEEN p_DataInicio AND p_DataFim
    ORDER BY r.DataRecebimento DESC;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_calcular_comissao` (IN `p_IdAtendimento` INT, IN `p_IdCuidador` INT, OUT `p_IdComissao` INT, OUT `p_ValorComissao` DECIMAL(10,2), OUT `p_Mensagem` VARCHAR(255), OUT `p_Sucesso` BOOLEAN)   BEGIN
    DECLARE v_ValorAtendimento DECIMAL(10,2);
    DECLARE v_PercentualComissao DECIMAL(5,2);
    DECLARE v_ComissaoExistente INT;
    DECLARE v_NomeCuidador VARCHAR(100);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET p_Sucesso = FALSE;
        SET p_Mensagem = 'Erro ao calcular comissão';
        ROLLBACK;
    END;
    
    START TRANSACTION;
    
    -- Buscar valor do atendimento
    SELECT a.Valor INTO v_ValorAtendimento
    FROM atendimento a
    WHERE a.IdAtendimento = p_IdAtendimento AND a.IdCuidador = p_IdCuidador;
    
    IF v_ValorAtendimento IS NULL THEN
        SET p_Sucesso = FALSE;
        SET p_Mensagem = 'Atendimento não encontrado';
        ROLLBACK;
    ELSE
        -- Buscar nome do cuidador
        SELECT Nome INTO v_NomeCuidador FROM cuidador WHERE IdCuidador = p_IdCuidador;
        
        -- Buscar percentual de comissão (padrão 70%)
        SELECT COALESCE(Valor, 70.00) INTO v_PercentualComissao
        FROM configuracaofinanceira
        WHERE Chave = 'percentual_comissao_padrao'
        LIMIT 1;
        
        SET p_ValorComissao = (v_ValorAtendimento * v_PercentualComissao) / 100;
        
        -- Verificar se já existe comissão
        SELECT COUNT(*) INTO v_ComissaoExistente
        FROM comissao
        WHERE IdAtendimento = p_IdAtendimento;
        
        IF v_ComissaoExistente > 0 THEN
            SET p_Sucesso = FALSE;
            SET p_Mensagem = 'Comissão já calculada para este atendimento';
            ROLLBACK;
        ELSE
            -- Inserir comissão
            INSERT INTO comissao (IdCuidador, IdAtendimento, ValorBase, PercentualComissao, ValorComissao, ValorTotal)
            VALUES (p_IdCuidador, p_IdAtendimento, v_ValorAtendimento, v_PercentualComissao, p_ValorComissao, p_ValorComissao);
            
            SET p_IdComissao = LAST_INSERT_ID();
            
            -- ========== REGISTRAR NO HISTÓRICO ==========
            INSERT INTO historicoadministrador (IdAdministrador, Operacao, DataOperacao)
            VALUES (
                1, 
                CONCAT('Comissão R$ ', FORMAT(p_ValorComissao, 2, 'pt_BR'), ' (', v_PercentualComissao, '%) calculada para ', v_NomeCuidador, ' (Atendimento ID: ', p_IdAtendimento, ')'),
                NOW()
            );
            
            SET p_Sucesso = TRUE;
            SET p_Mensagem = 'Comissão calculada com sucesso';
            COMMIT;
        END IF;
    END IF;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_criar_despesa` (IN `p_TipoDespesa` VARCHAR(100), IN `p_Categoria` VARCHAR(100), IN `p_Descricao` TEXT, IN `p_Valor` DECIMAL(10,2), IN `p_IdCuidador` INT, IN `p_Comprovante` VARCHAR(255), IN `p_Observacoes` TEXT, OUT `p_IdDespesa` INT, OUT `p_Mensagem` VARCHAR(255), OUT `p_Sucesso` BOOLEAN)   BEGIN
    DECLARE v_NomeCuidador VARCHAR(100);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET p_Sucesso = FALSE;
        SET p_Mensagem = 'Erro ao criar despesa';
        ROLLBACK;
    END;
    
    START TRANSACTION;
    
    -- Buscar nome do cuidador se existir
    IF p_IdCuidador IS NOT NULL THEN
        SELECT Nome INTO v_NomeCuidador FROM cuidador WHERE IdCuidador = p_IdCuidador;
    END IF;
    
    INSERT INTO despesa (TipoDespesa, Categoria, Descricao, Valor, IdCuidador, Comprovante, Observacoes)
    VALUES (p_TipoDespesa, p_Categoria, p_Descricao, p_Valor, p_IdCuidador, p_Comprovante, p_Observacoes);
    
    SET p_IdDespesa = LAST_INSERT_ID();
    
    -- ========== REGISTRAR NO HISTÓRICO ==========
    IF p_IdCuidador IS NOT NULL THEN
        INSERT INTO historicoadministrador (IdAdministrador, Operacao, DataOperacao)
        VALUES (
            1, 
            CONCAT('Despesa R$ ', FORMAT(p_Valor, 2, 'pt_BR'), ' criada - ', p_Categoria, ' (Cuidador: ', v_NomeCuidador, ')'),
            NOW()
        );
    ELSE
        INSERT INTO historicoadministrador (IdAdministrador, Operacao, DataOperacao)
        VALUES (
            1, 
            CONCAT('Despesa R$ ', FORMAT(p_Valor, 2, 'pt_BR'), ' criada - ', p_Categoria),
            NOW()
        );
    END IF;
    
    SET p_Sucesso = TRUE;
    SET p_Mensagem = 'Despesa criada com sucesso';
    
    COMMIT;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_criar_receita` (IN `p_IdAtendimento` INT, IN `p_IdResponsavel` INT, IN `p_Valor` DECIMAL(10,2), IN `p_FormaPagamento` VARCHAR(50), IN `p_Observacoes` TEXT, OUT `p_IdReceita` INT, OUT `p_Mensagem` VARCHAR(255), OUT `p_Sucesso` BOOLEAN)   BEGIN
    DECLARE v_StatusAtendimento VARCHAR(50);
    DECLARE v_ReceitaExistente INT;
    DECLARE v_NomeResponsavel VARCHAR(100);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET p_Sucesso = FALSE;
        SET p_Mensagem = 'Erro ao criar receita';
        ROLLBACK;
    END;
    
    START TRANSACTION;
    
    -- Buscar nome do responsável para o histórico
    SELECT Nome INTO v_NomeResponsavel FROM responsavel WHERE IdResponsavel = p_IdResponsavel;
    
    -- Verificar se a receita está vinculada a um atendimento
    IF p_IdAtendimento IS NOT NULL THEN
        -- Buscar status do atendimento
        SELECT Status INTO v_StatusAtendimento
        FROM atendimento
        WHERE IdAtendimento = p_IdAtendimento;
        
        -- Verificar se atendimento existe
        IF v_StatusAtendimento IS NULL THEN
            SET p_Sucesso = FALSE;
            SET p_Mensagem = 'Atendimento não encontrado';
            ROLLBACK;
        ELSE
            -- Verificar se atendimento está concluído
            IF v_StatusAtendimento != 'Concluído' THEN
                SET p_Sucesso = FALSE;
                SET p_Mensagem = CONCAT('Não é possível criar receita para atendimento com status "', v_StatusAtendimento, '". Apenas atendimentos "Concluído" podem ter receitas.');
                ROLLBACK;
            ELSE
                -- Verificar se já existe receita para este atendimento
                SELECT COUNT(*) INTO v_ReceitaExistente
                FROM receita
                WHERE IdAtendimento = p_IdAtendimento;
                
                IF v_ReceitaExistente > 0 THEN
                    SET p_Sucesso = FALSE;
                    SET p_Mensagem = 'Já existe uma receita para este atendimento';
                    ROLLBACK;
                ELSE
                    -- Inserir receita
                    INSERT INTO receita (IdAtendimento, IdResponsavel, Valor, FormaPagamento, Observacoes)
                    VALUES (p_IdAtendimento, p_IdResponsavel, p_Valor, p_FormaPagamento, p_Observacoes);
                    
                    SET p_IdReceita = LAST_INSERT_ID();
                    
                    -- ========== REGISTRAR NO HISTÓRICO ==========
                    INSERT INTO historicoadministrador (IdAdministrador, Operacao, DataOperacao)
                    VALUES (
                        1, 
                        CONCAT('Receita R$ ', FORMAT(p_Valor, 2, 'pt_BR'), ' criada para ', v_NomeResponsavel, ' (Atendimento ID: ', p_IdAtendimento, ')'),
                        NOW()
                    );
                    
                    SET p_Sucesso = TRUE;
                    SET p_Mensagem = 'Receita criada com sucesso';
                    COMMIT;
                END IF;
            END IF;
        END IF;
    ELSE
        -- Inserir receita sem atendimento
        INSERT INTO receita (IdAtendimento, IdResponsavel, Valor, FormaPagamento, Observacoes)
        VALUES (p_IdAtendimento, p_IdResponsavel, p_Valor, p_FormaPagamento, p_Observacoes);
        
        SET p_IdReceita = LAST_INSERT_ID();
        
        -- ========== REGISTRAR NO HISTÓRICO ==========
        INSERT INTO historicoadministrador (IdAdministrador, Operacao, DataOperacao)
        VALUES (
            1, 
            CONCAT('Receita R$ ', FORMAT(p_Valor, 2, 'pt_BR'), ' criada para ', v_NomeResponsavel),
            NOW()
        );
        
        SET p_Sucesso = TRUE;
        SET p_Mensagem = 'Receita criada com sucesso';
        COMMIT;
    END IF;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_criar_receita_automatica` (IN `p_IdAtendimento` INT, OUT `p_IdReceita` INT, OUT `p_Mensagem` VARCHAR(255), OUT `p_Sucesso` BOOLEAN)   BEGIN
    DECLARE v_IdResponsavel INT;
    DECLARE v_Valor DECIMAL(10,2);
    DECLARE v_Status VARCHAR(50);
    DECLARE v_ReceitaExistente INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET p_Sucesso = FALSE;
        SET p_Mensagem = 'Erro ao criar receita automática';
        ROLLBACK;
    END;
    
    START TRANSACTION;
    
    -- Buscar dados do atendimento
    SELECT IdResponsavel, Valor, Status
    INTO v_IdResponsavel, v_Valor, v_Status
    FROM atendimento
    WHERE IdAtendimento = p_IdAtendimento;
    
    -- Verificar se atendimento existe
    IF v_IdResponsavel IS NULL THEN
        SET p_Sucesso = FALSE;
        SET p_Mensagem = 'Atendimento não encontrado';
        ROLLBACK;
    ELSE
        -- Verificar se está concluído
        IF v_Status != 'Concluído' THEN
            SET p_Sucesso = FALSE;
            SET p_Mensagem = CONCAT('Não é possível criar receita para atendimento com status "', v_Status, '"');
            ROLLBACK;
        ELSE
            -- Verificar se já existe receita
            SELECT COUNT(*) INTO v_ReceitaExistente
            FROM receita
            WHERE IdAtendimento = p_IdAtendimento;
            
            IF v_ReceitaExistente > 0 THEN
                SET p_Sucesso = FALSE;
                SET p_Mensagem = 'Receita já existe para este atendimento';
                ROLLBACK;
            ELSE
                -- Verificar valor válido
                IF v_Valor IS NULL OR v_Valor <= 0 THEN
                    SET p_Sucesso = FALSE;
                    SET p_Mensagem = 'Valor do atendimento inválido';
                    ROLLBACK;
                ELSE
                    -- Criar receita
                    INSERT INTO receita (IdAtendimento, IdResponsavel, Valor, Status, FormaPagamento, Observacoes, DataRecebimento)
                    VALUES (p_IdAtendimento, v_IdResponsavel, v_Valor, 'Pago', 'Automático', 'Receita gerada automaticamente pelo sistema', NOW());
                    
                    SET p_IdReceita = LAST_INSERT_ID();
                    SET p_Sucesso = TRUE;
                    SET p_Mensagem = 'Receita criada automaticamente com sucesso';
                    COMMIT;
                END IF;
            END IF;
        END IF;
    END IF;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_verificar_inadimplencia` ()   BEGIN
    SELECT 
        a.IdAtendimento,
        a.IdResponsavel,
        a.Valor,
        a.DataInicio,
        r.Nome as NomeResponsavel,
        r.Email,
        r.Telefone,
        DATEDIFF(CURDATE(), a.DataInicio) as DiasAtraso
    FROM atendimento a
    LEFT JOIN responsavel r ON a.IdResponsavel = r.IdResponsavel
    WHERE a.Status = 'Concluído' 
    AND a.Valor > 0
    AND DATEDIFF(CURDATE(), a.DataInicio) > 5
    AND NOT EXISTS (
        SELECT 1 FROM receita rec 
        WHERE rec.IdAtendimento = a.IdAtendimento 
        AND rec.Status = 'Pago'
    )
    AND NOT EXISTS (
        SELECT 1 FROM inadimplencia i 
        WHERE i.IdAtendimento = a.IdAtendimento
    );
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `administrador`
--

CREATE TABLE `administrador` (
  `IdAdministrador` int(11) NOT NULL,
  `Usuario` varchar(100) NOT NULL,
  `Senha` varchar(255) DEFAULT NULL,
  `Tipo` varchar(100) NOT NULL,
  `Nome` varchar(100) DEFAULT NULL,
  `Email` varchar(100) DEFAULT NULL,
  `Ativo` tinyint(1) DEFAULT 1,
  `UltimoAcesso` datetime DEFAULT current_timestamp(),
  `DataCriacao` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `administrador`
--

INSERT INTO `administrador` (`IdAdministrador`, `Usuario`, `Senha`, `Tipo`, `Nome`, `Email`, `Ativo`, `UltimoAcesso`, `DataCriacao`) VALUES
(1, 'admin', '$2b$10$E4iPvOcs5u5ArXQu/UroaelhW58CuzI85xAEDVaEhqb9QCuTeUh1S', 'Administrador', 'Administrador', 'admin@cogitare.com', 1, '2025-10-20 15:17:18', '2025-09-18 14:56:27');

-- --------------------------------------------------------

--
-- Table structure for table `atendimento`
--

CREATE TABLE `atendimento` (
  `IdAtendimento` int(11) NOT NULL,
  `IdResponsavel` int(11) DEFAULT NULL,
  `IdCuidador` int(11) DEFAULT NULL,
  `IdIdoso` int(11) DEFAULT NULL,
  `DataInicio` datetime DEFAULT NULL,
  `DataFim` datetime DEFAULT NULL,
  `Status` varchar(20) DEFAULT NULL,
  `Local` varchar(255) DEFAULT NULL,
  `Valor` decimal(10,2) DEFAULT NULL,
  `ObservacaoExtra` text DEFAULT NULL,
  `DataCriacao` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `atendimento`
--

INSERT INTO `atendimento` (`IdAtendimento`, `IdResponsavel`, `IdCuidador`, `IdIdoso`, `DataInicio`, `DataFim`, `Status`, `Local`, `Valor`, `ObservacaoExtra`, `DataCriacao`) VALUES
(2, 4, 2, 7, '2025-09-17 14:00:00', '2025-09-17 18:00:00', 'Concluído', 'Rua Bandeira Paulista, 789 - Moema, São Paulo - CEP: 04532-000 (Apto 12)', 180.00, 'Primeira consulta agendada.', '2025-09-16 13:51:54'),
(4, 8, 4, 8, '2025-09-20 08:00:00', '2025-09-20 12:00:00', 'Concluído', 'Rua Harmonia, 456 - Vila Madalena', 200.00, 'Atendimento de 4 horas para cuidados básicos', '2025-09-19 10:00:00'),
(5, 9, 5, 9, '2025-09-21 14:00:00', '2025-09-21 18:00:00', 'Concluído', 'Alameda Santos, 789 - Jardins', 180.00, 'Sessão de fisioterapia e acompanhamento', '2025-09-20 09:00:00'),
(6, 10, 6, 10, '2025-09-22 09:00:00', '2025-09-22 17:00:00', 'Concluído', 'Rua Bandeira Paulista, 321 - Moema', 320.00, 'Acompanhamento de 8 horas para paciente com Alzheimer', '2025-09-21 11:00:00'),
(8, 12, 4, 12, '2025-09-24 08:00:00', '2025-09-24 20:00:00', 'Concluído', 'Rua Bandeira Paulista, 987 - Itaim Bibi', 480.00, 'Atendimento de 12 horas para paciente com Parkinson', '2025-09-23 10:00:00'),
(9, 13, 5, 13, '2025-09-25 15:00:00', '2025-09-25 19:00:00', 'Concluído', 'Rua Funchal, 147 - Vila Olímpia', 200.00, 'Fisioterapia e cuidados cardíacos', '2025-09-24 12:00:00'),
(10, 14, 6, 14, '2025-09-26 11:00:00', '2025-09-26 15:00:00', 'Concluído', 'Rua dos Três Irmãos, 258 - Brooklin', 180.00, 'Acompanhamento psicológico e cuidados básicos', '2025-09-25 09:00:00'),
(12, 8, 4, 8, '2025-09-28 08:00:00', '2025-09-28 12:00:00', 'Concluído', 'Rua Harmonia, 456 - Vila Madalena', 200.00, 'Retorno para acompanhamento', '2025-09-27 16:00:00');

-- --------------------------------------------------------

--
-- Table structure for table `avaliacao`
--

CREATE TABLE `avaliacao` (
  `IdAvaliacao` int(11) NOT NULL,
  `IdResponsavel` int(11) DEFAULT NULL,
  `IdCuidador` int(11) DEFAULT NULL,
  `IdAtendimento` int(11) DEFAULT NULL,
  `Nota` int(11) DEFAULT NULL,
  `Comentario` text DEFAULT NULL,
  `DataAvaliacao` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `avaliacao`
--

INSERT INTO `avaliacao` (`IdAvaliacao`, `IdResponsavel`, `IdCuidador`, `IdAtendimento`, `Nota`, `Comentario`, `DataAvaliacao`) VALUES
(1, 8, 4, 4, 5, 'Excelente atendimento! Lucia foi muito cuidadosa e atenciosa com minha mãe.', '2025-09-20 13:00:00'),
(3, 10, 6, 6, 5, 'Cristina tem muita paciência e conhecimento. Recomendo!', '2025-09-22 18:00:00'),
(5, 12, 4, 8, 5, 'Lucia novamente superou nossas expectativas. Muito profissional!', '2025-09-24 21:00:00'),
(6, 13, 5, 9, 5, 'Paulo é muito competente na fisioterapia.', '2025-09-25 20:00:00'),
(7, 14, 6, 10, 5, 'Cristina tem um dom especial para lidar com idosos.', '2025-09-26 16:00:00');

-- --------------------------------------------------------

--
-- Table structure for table `categoriasuporte`
--

CREATE TABLE `categoriasuporte` (
  `IdCategoria` int(11) NOT NULL,
  `Nome` varchar(50) NOT NULL,
  `Descricao` text DEFAULT NULL,
  `Ativa` tinyint(1) DEFAULT 1,
  `Ordem` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `categoriasuporte`
--

INSERT INTO `categoriasuporte` (`IdCategoria`, `Nome`, `Descricao`, `Ativa`, `Ordem`) VALUES
(1, 'Geral', 'Dúvidas gerais sobre o sistema', 1, 1),
(2, 'Atendimento', 'Problemas ou dúvidas sobre atendimentos', 1, 2),
(3, 'Pagamento', 'Questões relacionadas a pagamentos', 1, 3),
(4, 'Técnico', 'Problemas técnicos com o sistema', 1, 4),
(5, 'Sugestão', 'Sugestões de melhorias', 1, 5),
(6, 'Reclamação', 'Reclamações sobre serviços', 1, 6);

-- --------------------------------------------------------

--
-- Table structure for table `certificado`
--

CREATE TABLE `certificado` (
  `IdCertificado` int(11) NOT NULL,
  `IdCuidador` int(11) DEFAULT NULL,
  `Descricao` text DEFAULT NULL,
  `UrlCertificado` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `chat`
--

CREATE TABLE `chat` (
  `IdChat` int(11) NOT NULL,
  `IdCuidador` int(11) DEFAULT NULL,
  `IdResponsavel` int(11) DEFAULT NULL,
  `DataCriacao` datetime DEFAULT current_timestamp(),
  `Status` varchar(20) DEFAULT NULL,
  `Categoria` varchar(50) DEFAULT 'Geral',
  `Prioridade` varchar(20) DEFAULT 'Normal',
  `Assunto` varchar(200) DEFAULT NULL,
  `IdUsuario` int(11) DEFAULT NULL,
  `TipoUsuario` varchar(20) DEFAULT NULL,
  `StatusSuporte` varchar(20) DEFAULT 'Aberto'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `chat`
--

INSERT INTO `chat` (`IdChat`, `IdCuidador`, `IdResponsavel`, `DataCriacao`, `Status`, `Categoria`, `Prioridade`, `Assunto`, `IdUsuario`, `TipoUsuario`, `StatusSuporte`) VALUES
(4, 4, NULL, '2025-09-20 15:00:00', 'Ativo', 'Atendimento', 'Normal', 'Dúvida sobre medicação da paciente', 4, 'cuidador', 'Aberto'),
(5, NULL, 9, '2025-09-21 16:00:00', 'Ativo', 'Pagamento', 'Alta', 'Problema com pagamento do atendimento', 9, 'responsavel', 'Em Andamento'),
(6, 6, NULL, '2025-09-22 17:00:00', 'Ativo', 'Técnico', 'Normal', 'Dificuldade para acessar o sistema', 6, 'cuidador', 'Fechado'),
(7, NULL, 11, '2025-09-23 18:00:00', 'Ativo', 'Geral', 'Normal', 'Sugestão de melhoria no sistema', 11, 'responsavel', 'Aberto'),
(9, NULL, NULL, '2025-09-22 18:06:43', 'Ativo', 'Reclamação', 'Normal', 'sadas', 1, 'cuidador', 'Fechado'),
(10, NULL, NULL, '2025-10-03 13:52:35', 'Ativo', 'Atendimento', 'Alta', 'asddsadas', 1, 'cuidador', 'Aberto'),
(11, NULL, NULL, '2025-10-03 15:02:30', 'Ativo', 'Atendimento', 'Urgente', 'dssd', 1, 'admin', 'Fechado');

-- --------------------------------------------------------

--
-- Table structure for table `comissao`
--

CREATE TABLE `comissao` (
  `IdComissao` int(11) NOT NULL,
  `IdCuidador` int(11) NOT NULL,
  `IdAtendimento` int(11) DEFAULT NULL,
  `ValorBase` decimal(10,2) NOT NULL,
  `PercentualComissao` decimal(5,2) DEFAULT 70.00,
  `ValorComissao` decimal(10,2) NOT NULL,
  `Bonificacao` decimal(10,2) DEFAULT 0.00,
  `ValorTotal` decimal(10,2) NOT NULL,
  `DataCalculo` datetime DEFAULT current_timestamp(),
  `DataPagamento` datetime DEFAULT NULL,
  `Status` varchar(20) DEFAULT 'Pendente',
  `Observacoes` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `comissao`
--

INSERT INTO `comissao` (`IdComissao`, `IdCuidador`, `IdAtendimento`, `ValorBase`, `PercentualComissao`, `ValorComissao`, `Bonificacao`, `ValorTotal`, `DataCalculo`, `DataPagamento`, `Status`, `Observacoes`) VALUES
(1, 2, 2, 180.00, 70.00, 126.00, 0.00, 126.00, '2025-09-18 17:16:56', NULL, 'Pendente', 'Comissão do atendimento ID 2'),
(3, 4, 4, 200.00, 70.00, 140.00, 0.00, 140.00, '2025-09-20 12:30:00', NULL, 'Pago', 'Comissão do atendimento ID 4'),
(4, 5, 5, 180.00, 70.00, 126.00, 0.00, 126.00, '2025-09-21 18:15:00', NULL, 'Pago', 'Comissão do atendimento ID 5'),
(5, 6, 6, 320.00, 70.00, 224.00, 0.00, 224.00, '2025-09-22 17:30:00', NULL, 'Pago', 'Comissão do atendimento ID 6'),
(7, 4, 8, 480.00, 70.00, 336.00, 0.00, 336.00, '2025-09-24 20:30:00', NULL, 'Pago', 'Comissão do atendimento ID 8'),
(8, 5, 9, 200.00, 70.00, 140.00, 0.00, 140.00, '2025-09-25 19:00:00', NULL, 'Pago', 'Comissão do atendimento ID 9'),
(9, 6, 10, 180.00, 70.00, 126.00, 0.00, 126.00, '2025-09-26 15:20:00', NULL, 'Pago', 'Comissão do atendimento ID 10');

-- --------------------------------------------------------

--
-- Table structure for table `configuracaofinanceira`
--

CREATE TABLE `configuracaofinanceira` (
  `IdConfig` int(11) NOT NULL,
  `Chave` varchar(100) NOT NULL,
  `Valor` varchar(500) NOT NULL,
  `Descricao` text DEFAULT NULL,
  `DataAtualizacao` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `configuracaofinanceira`
--

INSERT INTO `configuracaofinanceira` (`IdConfig`, `Chave`, `Valor`, `Descricao`, `DataAtualizacao`) VALUES
(1, 'percentual_comissao_padrao', '70.00', 'Percentual padrão de comissão para cuidadores', '2025-09-18 16:49:04'),
(2, 'dias_para_inadimplencia', '5', 'Dias após vencimento para considerar inadimplência', '2025-09-18 16:49:04'),
(3, 'taxa_juros_mora', '2.00', 'Taxa de juros por mês de atraso', '2025-09-18 16:49:04'),
(4, 'meta_receita_mensal', '50000.00', 'Meta de receita mensal', '2025-09-18 16:49:04'),
(5, 'meta_lucro_mensal', '15000.00', 'Meta de lucro mensal', '2025-09-18 16:49:04');

-- --------------------------------------------------------

--
-- Table structure for table `cuidador`
--

CREATE TABLE `cuidador` (
  `IdCuidador` int(11) NOT NULL,
  `IdEndereco` int(11) DEFAULT NULL,
  `Cpf` varchar(20) DEFAULT NULL,
  `Nome` varchar(100) DEFAULT NULL,
  `Email` varchar(100) DEFAULT NULL,
  `Telefone` varchar(20) DEFAULT NULL,
  `Senha` varchar(100) DEFAULT NULL,
  `DataNascimento` date DEFAULT NULL,
  `FotoUrl` varchar(255) DEFAULT NULL,
  `Biografia` text DEFAULT NULL,
  `Fumante` varchar(3) DEFAULT 'Não',
  `TemFilhos` varchar(3) DEFAULT 'Não',
  `PossuiCNH` varchar(3) DEFAULT 'Não',
  `TemCarro` varchar(3) DEFAULT 'Não'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `cuidador`
--

INSERT INTO `cuidador` (`IdCuidador`, `IdEndereco`, `Cpf`, `Nome`, `Email`, `Telefone`, `Senha`, `DataNascimento`, `FotoUrl`, `Biografia`, `Fumante`, `TemFilhos`, `PossuiCNH`, `TemCarro`) VALUES
(1, NULL, NULL, 'Carlos Oliveira', 'carlos.oliveira@email.com', '(11) 88888-1112', NULL, '1985-03-24', '/avatar/cuidador.png', 'Cuidador experiente com 5 anos de experiência', 'Não', 'Sim', 'Não', 'Sim'),
(2, 2, NULL, 'Fernanda Lima', 'fernanda.lima@email.com', '(11) 88888-2222', NULL, '1990-07-12', '/avatar/cuidador.png', 'Especialista em cuidados com idosos.', 'Não', 'Sim', 'Sim', 'Não'),
(3, 3, '999.000.111-22', 'Roberto Alves', 'roberto.alves@email.com', '(11) 88888-3333', '$2b$10$example', '1988-11-30', '/avatar/cuidador.png', 'Enfermeiro com especialização em geriatria', 'Não', 'Sim', 'Sim', 'Sim'),
(4, 12, '11122233344', 'Lucia Mendes', 'lucia.mendes@email.com', '(11) 88888-4444', '$2b$10$example', '1983-06-20', '/avatar/cuidador.png', 'Enfermeira com 8 anos de experiência em cuidados geriátricos', 'Não', 'Sim', 'Sim', 'Sim'),
(5, 13, '22233344455', 'Paulo Roberto', 'paulo.roberto@email.com', '(11) 88888-5555', '$2b$10$example', '1987-01-15', '/avatar/cuidador.png', 'Fisioterapeuta especializado em reabilitação de idosos', 'Não', 'Não', 'Sim', 'Não'),
(6, 14, '33344455566', 'Cristina Santos', 'cristina.santos@email.com', '(11) 88888-6666', '$2b$10$example', '1981-11-08', '/avatar/cuidador.png', 'Psicóloga com experiência em demência e Alzheimer', 'Não', 'Sim', 'Sim', 'Sim');

-- --------------------------------------------------------

--
-- Table structure for table `cuidadorespecialidade`
--

CREATE TABLE `cuidadorespecialidade` (
  `IdCuidadorEspecialidade` int(11) NOT NULL,
  `IdCuidador` int(11) DEFAULT NULL,
  `IdEspecialidade` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `cuidadorespecialidade`
--

INSERT INTO `cuidadorespecialidade` (`IdCuidadorEspecialidade`, `IdCuidador`, `IdEspecialidade`) VALUES
(1, 1, 1),
(2, 1, 2),
(3, 2, 1),
(4, 2, 3),
(5, 3, 2),
(6, 3, 4);

-- --------------------------------------------------------

--
-- Table structure for table `cuidadorservico`
--

CREATE TABLE `cuidadorservico` (
  `IdCuidadorServico` int(11) NOT NULL,
  `IdCuidador` int(11) DEFAULT NULL,
  `IdServico` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `cuidadorservico`
--

INSERT INTO `cuidadorservico` (`IdCuidadorServico`, `IdCuidador`, `IdServico`) VALUES
(1, 1, 1),
(2, 1, 2),
(3, 2, 2),
(4, 2, 3),
(5, 3, 1),
(6, 3, 4);

-- --------------------------------------------------------

--
-- Table structure for table `despesa`
--

CREATE TABLE `despesa` (
  `IdDespesa` int(11) NOT NULL,
  `TipoDespesa` varchar(50) NOT NULL,
  `Categoria` varchar(50) NOT NULL,
  `Descricao` text DEFAULT NULL,
  `Valor` decimal(10,2) NOT NULL,
  `DataDespesa` datetime DEFAULT current_timestamp(),
  `IdCuidador` int(11) DEFAULT NULL,
  `Comprovante` varchar(500) DEFAULT NULL,
  `Status` varchar(20) DEFAULT 'Pendente'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `despesa`
--

INSERT INTO `despesa` (`IdDespesa`, `TipoDespesa`, `Categoria`, `Descricao`, `Valor`, `DataDespesa`, `IdCuidador`, `Comprovante`, `Status`) VALUES
(1, 'Operacional', 'Combustível', 'Combustível para deslocamentos', 500.00, '2025-09-18 16:49:04', NULL, NULL, 'Pago'),
(2, 'Operacional', 'Alimentação', 'Alimentação para cuidadores', 300.00, '2025-09-18 16:49:04', NULL, NULL, 'Pago'),
(3, 'Administrativa', 'Internet', 'Internet e telefone', 200.00, '2025-09-18 16:49:04', NULL, NULL, 'Pago'),
(4, 'Administrativa', 'Aluguel', 'Aluguel do escritório', 1500.00, '2025-09-18 16:49:04', NULL, NULL, 'Pago'),
(5, 'Marketing', 'Publicidade', 'Anúncios online', 800.00, '2025-09-18 16:49:04', NULL, NULL, 'Pago'),
(6, 'Operacional', 'Combustível', 'Combustível para deslocamentos dos cuidadores', 800.00, '2025-09-20 10:00:00', NULL, NULL, 'Pago'),
(7, 'Operacional', 'Alimentação', 'Alimentação para cuidadores em atendimentos longos', 450.00, '2025-09-21 12:00:00', NULL, NULL, 'Pago'),
(8, 'Administrativa', 'Internet', 'Internet e telefone do escritório', 250.00, '2025-09-22 14:00:00', NULL, NULL, 'Pago'),
(9, 'Administrativa', 'Aluguel', 'Aluguel do escritório', 2000.00, '2025-09-23 16:00:00', NULL, NULL, 'Pago'),
(10, 'Marketing', 'Publicidade', 'Anúncios online e materiais promocionais', 1200.00, '2025-09-24 18:00:00', NULL, NULL, 'Pago'),
(11, 'Recursos Humanos', 'Treinamento', 'Curso de capacitação para cuidadores', 600.00, '2025-09-25 20:00:00', NULL, NULL, 'Pago'),
(12, 'Operacional', 'Material', 'Material de higiene e cuidados', 300.00, '2025-09-26 22:00:00', NULL, NULL, 'Pago'),
(13, 'Administrativa', 'Contabilidade', 'Serviços de contabilidade', 400.00, '2025-09-27 08:00:00', NULL, NULL, 'Pago');

-- --------------------------------------------------------

--
-- Table structure for table `disponibilidade`
--

CREATE TABLE `disponibilidade` (
  `IdDisponibilidade` int(11) NOT NULL,
  `IdCuidador` int(11) DEFAULT NULL,
  `DiaSemana` varchar(20) DEFAULT NULL,
  `DataInicio` datetime DEFAULT NULL,
  `DataFim` datetime DEFAULT NULL,
  `Observacoes` text DEFAULT NULL,
  `Recorrente` tinyint(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `doenca`
--

CREATE TABLE `doenca` (
  `IdDoenca` int(11) NOT NULL,
  `Nome` varchar(100) DEFAULT NULL,
  `Descricao` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `doenca`
--

INSERT INTO `doenca` (`IdDoenca`, `Nome`, `Descricao`) VALUES
(1, 'Alzheimer', 'Demência degenerativa'),
(2, 'Parkinson', 'Doença neurológica degenerativa'),
(3, 'Diabetes', 'Distúrbio do metabolismo da glicose'),
(4, 'Hipertensão', 'Pressão arterial elevada'),
(5, 'Artrite', 'Inflamação das articulações');

-- --------------------------------------------------------

--
-- Table structure for table `endereco`
--

CREATE TABLE `endereco` (
  `IdEndereco` int(11) NOT NULL,
  `Cidade` varchar(100) DEFAULT NULL,
  `Bairro` varchar(100) DEFAULT NULL,
  `Rua` varchar(100) DEFAULT NULL,
  `Numero` varchar(20) DEFAULT NULL,
  `Complemento` varchar(100) DEFAULT NULL,
  `Cep` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `endereco`
--

INSERT INTO `endereco` (`IdEndereco`, `Cidade`, `Bairro`, `Rua`, `Numero`, `Complemento`, `Cep`) VALUES
(1, 'São Paulo', 'Vila Madalena', 'Rua Harmonia', '123', 'Apto 45', '05435-000'),
(2, 'São Paulo', 'Jardins', 'Alameda Santos', '456', 'Casa 2', '01418-000'),
(3, 'São Paulo', 'Moema', 'Rua Bandeira Paulista', '789', 'Apto 12', '04532-000'),
(4, 'São Paulo', 'Vila Madalena', 'Rua Harmonia', '456', 'Apto 23', '05435-001'),
(5, 'São Paulo', 'Jardins', 'Alameda Santos', '789', 'Casa 5', '01418-001'),
(6, 'São Paulo', 'Moema', 'Rua Bandeira Paulista', '321', 'Apto 45', '04532-001'),
(7, 'São Paulo', 'Pinheiros', 'Rua dos Pinheiros', '654', 'Casa 12', '05422-000'),
(8, 'São Paulo', 'Itaim Bibi', 'Rua Bandeira Paulista', '987', 'Apto 67', '04532-002'),
(9, 'São Paulo', 'Vila Olímpia', 'Rua Funchal', '147', 'Sala 89', '04551-000'),
(10, 'São Paulo', 'Brooklin', 'Rua dos Três Irmãos', '258', 'Apto 34', '04562-000'),
(11, 'São Paulo', 'Vila Nova Conceição', 'Rua Bandeira Paulista', '369', 'Casa 8', '04532-003'),
(12, 'São Paulo', 'Higienópolis', 'Rua da Consolação', '741', 'Apto 56', '01302-000'),
(13, 'São Paulo', 'Perdizes', 'Rua Cardeal Arcoverde', '852', 'Casa 3', '05008-000'),
(14, 'São Paulo', 'Vila Madalena', 'Rua Harmonia', '963', 'Apto 78', '05435-002'),
(15, 'São Paulo', 'Jardins', 'Alameda Santos', '159', 'Casa 9', '01418-002'),
(16, 'maua', 'vil Falchi', 'rua orlando tasca', '277', 'apro 26C', '09350276'),
(17, 'maua', 'vila falchi', 'rua orlando tasca', '277', 'apto 26C', '09350276'),
(18, 'maua', 'vil Falchi', 'rua orlando tasca ', '277', 'apto 38c', '09350276'),
(19, 'maua', 'vila falchi', 'rua orlando tasca', '277', 'APTO 28c', '09350276'),
(20, 'maua', 'bocaina', 'ruA ORLANDFS DAS', '277', 'ASD', '09350276'),
(21, 'São Paulo', 'Centro', 'Rua das Flores', '123', 'Apto 45', '01234567'),
(22, 'São Paulo', 'Centro', 'Rua das Flores', '123', 'Apto 45', '01234567'),
(23, 'dasasd', 'fsdadas', 'sdfadas', '123', 'dsaasd', '09350276'),
(24, 'dfsfdsffd', 'sdfdfsfdssd', 'dsfdsfds', '678', 'fdsdsffdsfds', '09350276'),
(25, 'Mauá', 'Vila Falchi', 'Rua Orlando Tasca', '277', 'Apto 26C', '09350276');

-- --------------------------------------------------------

--
-- Table structure for table `especialidade`
--

CREATE TABLE `especialidade` (
  `IdEspecialidade` int(11) NOT NULL,
  `Nome` varchar(100) DEFAULT NULL,
  `Descricao` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `especialidade`
--

INSERT INTO `especialidade` (`IdEspecialidade`, `Nome`, `Descricao`) VALUES
(1, 'Cuidados básicos', 'Higiene pessoal, alimentação e mobilidade'),
(2, 'Cuidados médicos', 'Administração de medicamentos e acompanhamento médico'),
(3, 'Fisioterapia', 'Exercícios e reabilitação física'),
(4, 'Psicologia', 'Acompanhamento psicológico e emocional'),
(5, 'Enfermagem', 'Cuidados de enfermagem especializados');

-- --------------------------------------------------------

--
-- Table structure for table `experiencia`
--

CREATE TABLE `experiencia` (
  `IdExperiencia` int(11) NOT NULL,
  `IdCuidador` int(11) DEFAULT NULL,
  `Descricao` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `formacao`
--

CREATE TABLE `formacao` (
  `IdFormacao` int(11) NOT NULL,
  `IdCuidador` int(11) DEFAULT NULL,
  `Descricao` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `historicoadministrador`
--

CREATE TABLE `historicoadministrador` (
  `IdHistoricoAdm` int(11) NOT NULL,
  `IdAdministrador` int(11) DEFAULT NULL,
  `Operacao` varchar(255) NOT NULL,
  `DataOperacao` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `historicoadministrador`
--

INSERT INTO `historicoadministrador` (`IdHistoricoAdm`, `IdAdministrador`, `Operacao`, `DataOperacao`) VALUES
(1, 1, 'Login', '2025-09-05 19:09:13'),
(2, 1, 'Login', '2025-09-06 10:04:39'),
(3, 1, 'Logout', '2025-09-06 10:04:46'),
(4, 1, 'Login', '2025-09-06 10:16:25'),
(5, 1, 'Logout', '2025-09-06 10:16:48'),
(6, 1, 'Login', '2025-09-06 10:17:36'),
(7, 1, 'Login', '2025-09-06 10:50:16'),
(8, 1, 'Login', '2025-09-06 11:19:38'),
(9, 1, 'Login', '2025-09-07 11:27:18'),
(10, 1, 'Idoso José Silva (ID 1) alterado.', '2025-09-07 11:27:34'),
(11, 1, 'Idoso José Silva (ID 1) alterado.', '2025-09-07 11:27:36'),
(12, 1, 'Idoso José Silva (ID 1) alterado.', '2025-09-07 11:27:47'),
(13, 1, 'Idoso José Silva (ID 1) alterado.', '2025-09-07 11:28:57'),
(14, 1, 'Logout', '2025-09-07 11:34:38'),
(15, 1, 'Login', '2025-09-07 11:34:47'),
(16, 1, 'Login', '2025-09-07 11:35:56'),
(17, 1, 'Idoso Rosa Santos (ID 2) alterado.', '2025-09-07 11:39:32'),
(18, 1, 'Login', '2025-09-07 17:42:51'),
(19, 1, 'Login', '2025-09-07 19:24:29'),
(20, 1, 'Login', '2025-09-08 14:39:22'),
(21, 1, 'Idoso Dona Maria (ID 4) criado.', '2025-09-08 14:43:11'),
(22, 1, 'Login', '2025-09-08 14:45:46'),
(23, 1, 'Idoso Pedro Costa (ID 3) alterado.', '2025-09-08 15:05:02'),
(24, 1, 'Idoso Daniela (ID 5) criado.', '2025-09-08 15:05:41'),
(25, 1, 'Login', '2025-09-08 15:29:12'),
(26, 1, 'Idoso Daniela (ID 5) alterado.', '2025-09-08 15:29:24'),
(27, 1, 'Login', '2025-09-08 15:35:48'),
(28, 1, 'Login', '2025-09-08 15:37:33'),
(29, 1, 'Logout', '2025-09-08 15:37:37'),
(30, 1, 'Login', '2025-09-08 16:12:43'),
(31, 1, 'Login', '2025-09-08 20:27:58'),
(32, 1, 'Login', '2025-09-08 20:31:38'),
(33, 1, 'Idoso Rosa Santos (ID 2) alterado.', '2025-09-08 20:31:46'),
(34, 1, 'Login', '2025-09-08 20:39:27'),
(35, 1, 'Login', '2025-09-08 20:41:29'),
(36, 1, 'Login', '2025-09-08 20:45:16'),
(37, 1, 'Responsável Ana Costa (ID 3) alterado.', '2025-09-08 20:47:14'),
(38, 1, 'Login', '2025-09-08 20:49:15'),
(39, 1, 'Login', '2025-09-08 20:50:58'),
(40, 1, 'Login', '2025-09-08 20:59:48'),
(41, 1, 'Login', '2025-09-08 21:02:07'),
(42, 1, 'Login', '2025-09-08 21:02:07'),
(43, 1, 'Responsável João Santos (ID 2) alterado.', '2025-09-08 21:02:33'),
(44, 1, 'Login', '2025-09-08 21:03:12'),
(45, 1, 'Login', '2025-09-08 21:05:42'),
(46, 1, 'Login', '2025-09-08 21:09:01'),
(47, 1, 'Login', '2025-09-08 21:14:31'),
(48, 1, 'Login', '2025-09-08 21:21:07'),
(49, 1, 'Login', '2025-09-08 21:21:08'),
(50, 1, 'Login', '2025-09-08 21:23:01'),
(51, 1, 'Login', '2025-09-08 21:23:01'),
(52, 1, 'Login', '2025-09-08 21:27:55'),
(53, 1, 'Login', '2025-09-08 21:29:58'),
(54, 1, 'Login', '2025-09-08 21:32:16'),
(55, 1, 'Login', '2025-09-08 21:34:15'),
(56, 1, 'Login', '2025-09-08 21:34:17'),
(57, 1, 'Login', '2025-09-08 21:36:42'),
(58, 1, 'Login', '2025-09-08 21:36:43'),
(59, 1, 'Login', '2025-09-08 21:37:57'),
(60, 1, 'Login', '2025-09-08 21:37:57'),
(61, 1, 'Login', '2025-09-08 21:39:45'),
(62, 1, 'Login', '2025-09-08 21:39:46'),
(63, 1, 'Login', '2025-09-08 21:42:28'),
(64, 1, 'Login', '2025-09-08 21:42:29'),
(65, 1, 'Idoso adasdas (ID 6) criado.', '2025-09-08 21:45:45'),
(66, 1, 'Login', '2025-09-08 21:53:31'),
(67, 1, 'Login', '2025-09-08 21:53:32'),
(68, 1, 'Login', '2025-09-08 21:57:27'),
(69, 1, 'Login', '2025-09-08 21:57:28'),
(70, 1, 'Login', '2025-09-08 21:57:28'),
(71, 1, 'Login', '2025-09-08 21:57:28'),
(72, 1, 'Login', '2025-09-08 21:57:28'),
(73, 1, 'Login', '2025-09-08 21:57:28'),
(74, 1, 'Login', '2025-09-08 21:59:07'),
(75, 1, 'Login', '2025-09-08 21:59:07'),
(76, 1, 'Login', '2025-09-08 22:03:04'),
(77, 1, 'Responsável Maria Silva (ID 1) alterado.', '2025-09-08 22:03:30'),
(78, 1, 'Login', '2025-09-08 22:07:06'),
(79, 1, 'Login', '2025-09-08 22:07:07'),
(80, 1, 'Login', '2025-09-08 22:07:07'),
(81, 1, 'Login', '2025-09-08 22:07:07'),
(82, 1, 'Login', '2025-09-08 22:07:07'),
(83, 1, 'Login', '2025-09-08 22:07:07'),
(84, 1, 'Login', '2025-09-08 22:07:07'),
(85, 1, 'Login', '2025-09-08 22:45:35'),
(86, 1, 'Login', '2025-09-08 22:45:36'),
(87, 1, 'Login', '2025-09-08 22:52:54'),
(88, 1, 'Login', '2025-09-08 22:52:55'),
(89, 1, 'Login', '2025-09-08 22:52:55'),
(90, 1, 'Login', '2025-09-08 22:52:55'),
(91, 1, 'Login', '2025-09-08 22:52:55'),
(92, 1, 'Login', '2025-09-08 23:02:55'),
(93, 1, 'Login', '2025-09-08 23:04:48'),
(94, 1, 'Login', '2025-09-08 23:08:57'),
(95, 1, 'Login', '2025-09-08 23:13:48'),
(96, 1, 'Login', '2025-09-08 23:13:49'),
(97, 1, 'Login', '2025-09-08 23:18:29'),
(98, 1, 'Login', '2025-09-08 23:18:29'),
(99, 1, 'Login', '2025-09-08 23:21:52'),
(100, 1, 'Login', '2025-09-08 23:30:05'),
(101, 1, 'Login', '2025-09-08 23:30:06'),
(102, 1, 'Login', '2025-09-08 23:35:10'),
(103, 1, 'Login', '2025-09-08 23:35:10'),
(104, 1, 'Login', '2025-09-08 23:35:11'),
(105, 1, 'Login', '2025-09-08 23:35:11'),
(106, 1, 'Logout', '2025-09-08 23:36:30'),
(107, 1, 'Login', '2025-09-08 23:36:35'),
(108, 1, 'Login', '2025-09-08 23:36:36'),
(109, 1, 'Login', '2025-09-08 23:41:10'),
(110, 1, 'Login', '2025-09-08 23:41:11'),
(111, 1, 'Login', '2025-09-08 23:41:12'),
(112, 1, 'Login', '2025-09-08 23:45:45'),
(113, 1, 'Login', '2025-09-08 23:50:29'),
(114, 1, 'Logout', '2025-09-09 00:00:40'),
(115, 1, 'Login', '2025-09-09 00:00:58'),
(116, 1, 'Login', '2025-09-09 00:09:32'),
(117, 1, 'Login', '2025-09-09 00:11:19'),
(118, 1, 'Login', '2025-09-09 00:11:19'),
(119, 1, 'Login', '2025-09-09 00:11:20'),
(120, 1, 'Login', '2025-09-09 00:11:20'),
(121, 1, 'Login', '2025-09-09 00:16:20'),
(122, 1, 'Login', '2025-09-09 00:16:21'),
(123, 1, 'Login', '2025-09-09 00:17:39'),
(124, 1, 'Login', '2025-09-09 00:17:40'),
(125, 1, 'Login', '2025-09-09 00:17:40'),
(126, 1, 'Login', '2025-09-09 00:17:40'),
(127, 1, 'Login', '2025-09-09 00:17:40'),
(128, 1, 'Login', '2025-09-09 18:06:55'),
(129, 1, 'Login', '2025-09-09 18:06:56'),
(130, 1, 'Login', '2025-09-09 19:40:06'),
(131, 1, 'Login', '2025-09-09 20:06:39'),
(132, 1, 'Login', '2025-09-09 20:06:40'),
(133, 1, 'Login', '2025-09-09 22:55:19'),
(134, 1, 'Login', '2025-09-10 13:35:14'),
(135, 1, 'Login', '2025-09-11 14:55:33'),
(136, 1, 'Idoso adasdas (ID 6) alterado.', '2025-09-11 14:58:09'),
(137, 1, 'Login', '2025-09-11 15:47:35'),
(138, 1, 'Logout', '2025-09-11 16:06:31'),
(139, 1, 'Login', '2025-09-11 16:18:06'),
(140, 1, 'Login', '2025-09-11 22:38:07'),
(141, 1, 'Login', '2025-09-11 22:38:08'),
(142, 1, 'Login', '2025-09-11 22:43:11'),
(143, 1, 'Login', '2025-09-11 22:43:12'),
(144, 1, 'Login', '2025-09-11 22:50:35'),
(145, 1, 'Login', '2025-09-11 23:06:48'),
(146, 1, 'Idoso adasdas (ID 6) alterado.', '2025-09-11 23:30:04'),
(147, 1, 'Login', '2025-09-11 23:39:38'),
(148, 1, 'Login', '2025-09-12 15:04:36'),
(149, 1, 'Login', '2025-09-12 15:04:36'),
(150, 1, 'Login', '2025-09-12 18:34:09'),
(151, 1, 'Login', '2025-09-12 18:34:09'),
(152, 1, 'Login', '2025-09-13 18:04:05'),
(153, 1, 'Login', '2025-09-13 18:04:06'),
(154, 1, 'Logout', '2025-09-13 18:04:41'),
(155, 1, 'Login', '2025-09-13 18:07:35'),
(156, 1, 'Logout', '2025-09-13 18:34:27'),
(157, 1, 'Login', '2025-09-13 18:34:34'),
(158, 1, 'Logout', '2025-09-13 18:49:20'),
(159, 1, 'Login', '2025-09-13 18:49:27'),
(160, 1, 'Login', '2025-09-13 19:55:22'),
(161, 1, 'Logout', '2025-09-13 20:03:40'),
(162, 1, 'Login', '2025-09-13 20:03:57'),
(163, 1, 'Login', '2025-09-13 22:18:14'),
(164, 1, 'Login', '2025-09-15 12:54:38'),
(165, 1, 'Login', '2025-09-15 12:54:38'),
(166, 1, 'Login', '2025-09-15 12:58:54'),
(167, 1, 'Login', '2025-09-15 15:22:10'),
(168, 1, 'Login', '2025-09-15 15:22:12'),
(169, 1, 'Logout', '2025-09-15 15:25:46'),
(170, 1, 'Login', '2025-09-15 15:26:07'),
(171, 1, 'Login', '2025-09-16 13:30:53'),
(172, 1, 'Logout', '2025-09-16 13:37:55'),
(173, 1, 'Login', '2025-09-16 13:38:06'),
(174, 1, 'Idoso Dona ana (ID 7) criado.', '2025-09-16 13:44:48'),
(175, 1, 'Login', '2025-09-16 14:17:18'),
(176, 1, 'Login', '2025-09-16 14:30:22'),
(177, 1, 'Login', '2025-09-16 15:41:59'),
(178, 1, 'Login', '2025-09-17 14:55:51'),
(179, 1, 'Login', '2025-09-17 19:07:29'),
(180, 1, 'Login', '2025-09-17 19:19:20'),
(181, 1, 'Login', '2025-09-17 19:23:41'),
(182, 1, 'Logout', '2025-09-17 19:24:07'),
(183, 1, 'Login', '2025-09-17 19:41:14'),
(184, 1, 'Login', '2025-09-17 19:41:56'),
(185, 1, 'Login', '2025-09-17 19:42:59'),
(186, 1, 'Login', '2025-09-17 19:53:35'),
(187, 1, 'Login', '2025-09-17 19:56:05'),
(188, 1, 'Login', '2025-09-17 19:58:33'),
(189, 1, 'Login', '2025-09-17 20:05:48'),
(190, 1, 'Login', '2025-09-17 20:05:57'),
(191, 1, 'Login', '2025-09-17 20:10:17'),
(192, 1, 'Login', '2025-09-17 20:12:45'),
(193, 1, 'Login', '2025-09-17 20:19:39'),
(194, 1, 'Login', '2025-09-17 20:20:39'),
(195, 1, 'Login', '2025-09-17 20:23:17'),
(196, 1, 'Login', '2025-09-17 20:24:17'),
(197, 1, 'Login', '2025-09-17 20:53:34'),
(198, 1, 'Login', '2025-09-17 20:53:34'),
(199, 1, 'Login', '2025-09-17 20:55:29'),
(200, 1, 'Login', '2025-09-17 20:59:11'),
(201, 1, 'Login', '2025-09-17 21:16:48'),
(202, 1, 'Login', '2025-09-17 21:22:08'),
(203, 1, 'Login', '2025-09-18 00:15:18'),
(204, 1, 'Login', '2025-09-18 14:00:50'),
(205, 1, 'Login', '2025-09-18 14:04:32'),
(206, 1, 'Login', '2025-09-18 14:13:59'),
(207, 1, 'Login', '2025-09-18 14:17:01'),
(208, 1, 'Login', '2025-09-18 14:20:11'),
(209, 1, 'Login', '2025-09-18 14:20:12'),
(210, 1, 'Login', '2025-09-18 14:23:07'),
(211, 1, 'Login', '2025-09-18 14:26:53'),
(212, 1, 'Login', '2025-09-18 14:36:42'),
(213, 1, 'Login', '2025-09-18 14:50:19'),
(214, 1, 'Login', '2025-09-18 14:57:01'),
(215, 1, 'Login', '2025-09-18 15:18:37'),
(216, 1, 'Login', '2025-09-18 15:18:37'),
(217, 1, 'Login', '2025-09-18 15:18:37'),
(218, 1, 'Login', '2025-09-18 15:20:15'),
(219, 1, 'Login', '2025-09-18 16:27:56'),
(220, 1, 'Login', '2025-09-18 16:33:29'),
(221, 1, 'Logout', '2025-09-18 16:34:50'),
(222, 1, 'Login', '2025-09-18 16:38:19'),
(223, 1, 'Login', '2025-09-18 16:49:33'),
(224, 1, 'Login', '2025-09-18 16:53:12'),
(225, 1, 'Login', '2025-09-18 16:59:41'),
(226, 1, 'Login', '2025-09-18 17:03:56'),
(227, 1, 'Login', '2025-09-18 17:03:56'),
(228, 1, 'Login', '2025-09-18 17:03:57'),
(229, 1, 'Login', '2025-09-18 17:10:32'),
(230, 1, 'Login', '2025-09-18 17:17:56'),
(231, 1, 'Login', '2025-09-18 17:25:25'),
(232, 1, 'Login', '2025-09-18 17:25:26'),
(233, 1, 'Login', '2025-09-18 17:37:47'),
(234, 1, 'Login', '2025-09-18 17:48:22'),
(235, 1, 'Login', '2025-09-18 17:48:22'),
(236, 1, 'Login', '2025-09-18 17:51:36'),
(237, 1, 'Login', '2025-09-18 17:52:59'),
(238, 1, 'Login', '2025-09-18 17:53:00'),
(239, 1, 'Login', '2025-09-18 17:53:00'),
(240, 1, 'Login', '2025-09-18 17:53:00'),
(241, 1, 'Login', '2025-09-18 17:54:32'),
(242, 1, 'Login', '2025-09-18 18:08:41'),
(243, 1, 'Login', '2025-09-18 18:46:53'),
(244, 1, 'Login', '2025-09-19 16:09:34'),
(245, 1, 'Login', '2025-09-19 21:21:27'),
(246, 1, 'Logout', '2025-09-19 21:23:47'),
(247, 1, 'Login', '2025-09-19 21:23:51'),
(248, 1, 'Login', '2025-09-22 18:01:10'),
(249, 1, 'Login', '2025-09-22 18:06:13'),
(250, 1, 'Login', '2025-09-22 18:14:51'),
(251, 1, 'Login', '2025-09-22 18:19:35'),
(252, 1, 'Login', '2025-09-22 18:32:47'),
(253, 1, 'Login', '2025-09-22 18:57:37'),
(254, 1, 'Login', '2025-09-22 18:57:38'),
(255, 1, 'Login', '2025-09-22 19:04:13'),
(256, 1, 'Login', '2025-09-22 19:09:52'),
(257, 1, 'Login', '2025-09-22 19:37:02'),
(258, 1, 'Login', '2025-09-22 19:48:25'),
(259, 1, 'Login', '2025-09-22 19:59:24'),
(260, 1, 'Login', '2025-09-22 20:09:49'),
(261, 1, 'Login', '2025-09-22 20:18:10'),
(262, 1, 'Login', '2025-09-24 14:15:50'),
(263, 1, 'Logout', '2025-09-24 14:19:12'),
(264, 1, 'Login', '2025-09-24 20:01:25'),
(265, 1, 'Login', '2025-09-24 20:08:32'),
(266, 1, 'Login', '2025-09-24 21:26:41'),
(267, 1, 'Login', '2025-09-24 21:26:41'),
(268, 1, 'Login', '2025-09-25 13:30:11'),
(269, 1, 'Login', '2025-09-25 15:16:47'),
(270, 1, 'Login', '2025-09-25 15:16:48'),
(271, 1, 'Login', '2025-09-25 18:55:17'),
(272, 1, 'Login', '2025-09-25 18:55:18'),
(273, 1, 'Login', '2025-09-25 20:43:28'),
(274, 1, 'Login', '2025-09-25 20:49:11'),
(275, 1, 'Login', '2025-09-29 20:14:31'),
(276, 1, 'Login', '2025-09-29 20:21:21'),
(277, 1, 'Login', '2025-09-30 15:39:08'),
(278, 1, 'Login', '2025-10-01 19:18:44'),
(279, 1, 'Login', '2025-10-02 15:47:58'),
(280, 1, 'Login', '2025-10-02 15:48:14'),
(281, 1, 'Logout', '2025-10-02 15:51:09'),
(282, 1, 'Login', '2025-10-02 16:08:28'),
(283, 1, 'Idoso adasdas (ID 6) alterado.', '2025-10-02 16:10:33'),
(284, 1, 'Login', '2025-10-02 16:17:44'),
(285, 1, 'Login', '2025-10-02 16:22:33'),
(286, 1, 'Login', '2025-10-02 16:23:20'),
(287, 1, 'Login', '2025-10-02 16:25:00'),
(288, 1, 'Login', '2025-10-02 16:45:32'),
(289, 1, 'Login', '2025-10-02 18:13:00'),
(290, 1, 'Login', '2025-10-02 18:14:29'),
(291, 1, 'Login', '2025-10-02 18:16:11'),
(292, 1, 'Login', '2025-10-02 18:19:36'),
(293, 1, 'Login', '2025-10-02 18:24:31'),
(294, 1, 'Login', '2025-10-02 18:30:24'),
(295, 1, 'Login', '2025-10-02 18:30:32'),
(296, 1, 'Login', '2025-10-02 19:32:08'),
(297, 1, 'Login', '2025-10-02 19:49:48'),
(298, 1, 'Login', '2025-10-02 19:49:48'),
(299, 1, 'Login', '2025-10-02 19:54:48'),
(300, 1, 'Login', '2025-10-02 20:01:21'),
(301, 1, 'Logout', '2025-10-02 20:27:28'),
(302, 1, 'Login', '2025-10-02 20:27:33'),
(303, 1, 'Login', '2025-10-02 20:29:27'),
(304, 1, 'Login', '2025-10-02 21:41:06'),
(305, 1, 'Login', '2025-10-03 13:50:07'),
(306, 1, 'Login', '2025-10-03 14:01:11'),
(307, 1, 'Login', '2025-10-03 14:52:02'),
(308, 1, 'Login', '2025-10-03 14:54:24'),
(309, 1, 'Login', '2025-10-03 14:54:24'),
(310, 1, 'Login', '2025-10-03 14:54:24'),
(311, 1, 'Login', '2025-10-03 14:54:25'),
(312, 1, 'Login', '2025-10-03 14:56:22'),
(313, 1, 'Login', '2025-10-03 14:58:51'),
(314, 1, 'Login', '2025-10-03 15:00:22'),
(315, 1, 'Login', '2025-10-03 15:02:17'),
(316, 1, 'Login', '2025-10-03 15:02:18'),
(317, 1, 'Login', '2025-10-03 15:05:02'),
(318, 1, 'Login', '2025-10-03 15:08:52'),
(319, 1, 'Login', '2025-10-03 15:11:15'),
(320, 1, 'Login', '2025-10-03 15:11:15'),
(321, 1, 'Login', '2025-10-06 13:07:35'),
(322, 1, 'Login', '2025-10-11 21:50:43'),
(323, 1, 'Login', '2025-10-14 18:20:23'),
(324, 1, 'Login', '2025-10-14 18:26:14'),
(325, 1, 'Login', '2025-10-14 18:43:38'),
(326, 1, 'Login', '2025-10-14 18:43:39'),
(327, 1, 'Login', '2025-10-16 00:40:22'),
(328, 1, 'Login', '2025-10-16 15:04:06'),
(329, 1, 'Login', '2025-10-16 15:08:37'),
(330, 1, 'Login', '2025-10-16 15:11:48'),
(331, 1, 'Login', '2025-10-20 13:22:29'),
(332, 1, 'Login', '2025-10-20 14:10:24'),
(333, 1, 'Login', '2025-10-20 15:01:16'),
(334, 1, 'Login', '2025-10-20 15:17:18');

-- --------------------------------------------------------

--
-- Table structure for table `historicoatendimento`
--

CREATE TABLE `historicoatendimento` (
  `IdHistorico` int(11) NOT NULL,
  `IdAtendimento` int(11) DEFAULT NULL,
  `StatusFinal` varchar(20) DEFAULT NULL,
  `DataRegistro` datetime DEFAULT current_timestamp(),
  `Observacoes` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `historicocuidador`
--

CREATE TABLE `historicocuidador` (
  `IdHistoricoCuidador` int(11) NOT NULL,
  `IdCuidador` int(11) DEFAULT NULL,
  `Operacao` varchar(255) NOT NULL,
  `DataOperacao` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `historicoresponsavel`
--

CREATE TABLE `historicoresponsavel` (
  `IdHistoricoResponsavel` int(11) NOT NULL,
  `IdResponsavel` int(11) DEFAULT NULL,
  `Operacao` varchar(255) NOT NULL,
  `DataOperacao` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `idoso`
--

CREATE TABLE `idoso` (
  `IdIdoso` int(11) NOT NULL,
  `IdResponsavel` int(11) DEFAULT NULL,
  `IdMobilidade` int(11) DEFAULT NULL,
  `IdNivelAutonomia` int(11) DEFAULT NULL,
  `Nome` varchar(100) DEFAULT NULL,
  `DataNascimento` date DEFAULT NULL,
  `Sexo` varchar(20) DEFAULT NULL,
  `CuidadosMedicos` text DEFAULT NULL,
  `DescricaoExtra` text DEFAULT NULL,
  `FotoUrl` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `idoso`
--

INSERT INTO `idoso` (`IdIdoso`, `IdResponsavel`, `IdMobilidade`, `IdNivelAutonomia`, `Nome`, `DataNascimento`, `Sexo`, `CuidadosMedicos`, `DescricaoExtra`, `FotoUrl`) VALUES
(7, 4, 5, 3, 'Dona ana', '1950-06-16', 'Feminino', '', '', '/avatar/idosa.png'),
(8, 8, 2, 3, 'Dona Maria', '1945-03-10', 'Feminino', 'Hipertensão, Diabetes tipo 2', 'Gosta de ouvir música clássica e ler livros', '/avatar/idosa.png'),
(9, 9, 1, 2, 'Seu José', '1940-07-22', 'Masculino', 'Artrite, Problemas de visão', 'Ex-professor, adora contar histórias', '/avatar/idoso.png'),
(10, 10, 3, 4, 'Dona Rosa', '1938-12-05', 'Feminino', 'Alzheimer, Osteoporose', 'Necessita acompanhamento constante', '/avatar/idosa.png'),
(11, 11, 1, 1, 'Seu Antonio', '1942-05-18', 'Masculino', 'Hipertensão controlada', 'Muito ativo, gosta de caminhar', '/avatar/idoso.png'),
(12, 12, 4, 4, 'Dona Carmen', '1935-08-30', 'Feminino', 'Parkinson, Diabetes', 'Necessita auxílio para alimentação', '/avatar/idosa.png'),
(13, 13, 2, 3, 'Seu Francisco', '1943-11-12', 'Masculino', 'Problemas cardíacos', 'Gosta de assistir TV e conversar', '/avatar/idoso.png'),
(14, 14, 1, 2, 'Dona Isabel', '1941-04-25', 'Feminino', 'Osteoporose leve', 'Muito independente, gosta de cozinhar', '/avatar/idosa.png'),
(15, 15, 3, 3, 'Seu Manuel', '1939-10-08', 'Masculino', 'Demência vascular', 'Necessita supervisão para medicação', '/avatar/idoso.png'),
(16, 16, 3, 3, 'Dona ana teste', '1955-10-19', 'Feminino', 'nadaasdasdasdasdas', 'nadaasddasdasdasdasd', '/avatar/idosa.png'),
(17, 21, 3, 3, 'Dona Maria Teste', '1955-10-19', 'Feminino', 'Teste de conexão', 'Teste de fluxo completo', '/avatar/idosa.png'),
(19, 23, 1, 1, 'asdasdassrthgsrteaa', '1955-10-19', 'Masculino', 'fgdhertsasdrfsd', 'zdfghsdf\\asdf', '/avatar/idoso.png'),
(20, 24, 1, 1, 'asddsasads', '1955-10-20', 'Feminino', 'sdadsafgfdsgfsdeafdsfds', 'xfghjfdgshdfgzhjklfaduiojghaoiusdghfuiysdoiyg', '/avatar/idosa.png'),
(21, 25, 1, 1, 'Dona Ana', '1955-11-02', 'Masculino', 'Necessita de medicação diaria para diabetes e pressão alta', 'Gosta de fazer bolo', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `idosodoenca`
--

CREATE TABLE `idosodoenca` (
  `IdIdosoDoenca` int(11) NOT NULL,
  `IdIdoso` int(11) DEFAULT NULL,
  `IdDoenca` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `idosorestricaoalimentar`
--

CREATE TABLE `idosorestricaoalimentar` (
  `IdIdosoRestricaoAlimentar` int(11) NOT NULL,
  `IdIdoso` int(11) DEFAULT NULL,
  `IdRestricaoAlimentar` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `inadimplencia`
--

CREATE TABLE `inadimplencia` (
  `IdInadimplencia` int(11) NOT NULL,
  `IdResponsavel` int(11) NOT NULL,
  `IdAtendimento` int(11) DEFAULT NULL,
  `ValorDevido` decimal(10,2) NOT NULL,
  `DataVencimento` date NOT NULL,
  `DiasAtraso` int(11) DEFAULT 0,
  `Status` varchar(20) DEFAULT 'Em Atraso',
  `TentativasCobranca` int(11) DEFAULT 0,
  `UltimaTentativa` datetime DEFAULT NULL,
  `Observacoes` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `mensagem`
--

CREATE TABLE `mensagem` (
  `IdMensagem` int(11) NOT NULL,
  `IdChat` int(11) DEFAULT NULL,
  `IdRemetente` int(11) DEFAULT NULL,
  `RemetenteTipo` varchar(20) DEFAULT NULL,
  `Conteudo` text DEFAULT NULL,
  `DataEnvio` datetime DEFAULT current_timestamp(),
  `Lida` varchar(10) DEFAULT NULL,
  `TipoMensagem` varchar(20) DEFAULT 'Texto',
  `AnexoUrl` varchar(500) DEFAULT NULL,
  `IsAdmin` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `mensagem`
--

INSERT INTO `mensagem` (`IdMensagem`, `IdChat`, `IdRemetente`, `RemetenteTipo`, `Conteudo`, `DataEnvio`, `Lida`, `TipoMensagem`, `AnexoUrl`, `IsAdmin`) VALUES
(5, 4, 4, 'cuidador', 'Olá, tenho uma dúvida sobre a medicação da Dona Maria. Ela precisa tomar o remédio antes ou depois das refeições?', '2025-09-20 15:00:00', 'Sim', 'Texto', NULL, 0),
(6, 4, 1, 'admin', 'Olá Lucia! A medicação deve ser tomada 30 minutos antes das refeições, conforme prescrição médica. Qualquer dúvida, pode me chamar!', '2025-09-20 15:15:00', 'Sim', 'Texto', NULL, 1),
(7, 5, 9, 'responsavel', 'Boa tarde! Tentei fazer o pagamento do atendimento de ontem, mas o PIX não está funcionando. Podem me ajudar?', '2025-09-21 16:00:00', 'Sim', 'Texto', NULL, 0),
(8, 5, 1, 'admin', 'Boa tarde Roberto! Vou verificar o problema com o PIX. Enquanto isso, você pode tentar pagar via cartão de crédito. Vou te enviar o link.', '2025-09-21 16:10:00', 'Sim', 'Texto', NULL, 1),
(9, 6, 6, 'cuidador', 'Não consigo acessar o sistema para registrar o atendimento de hoje. A página fica carregando infinitamente.', '2025-09-22 17:00:00', 'Sim', 'Texto', NULL, 0),
(10, 6, 1, 'admin', 'Cristina, tente limpar o cache do navegador ou usar outro navegador. Se o problema persistir, me avise que vou verificar do nosso lado.', '2025-09-22 17:05:00', 'Sim', 'Texto', NULL, 1),
(11, 7, 11, 'responsavel', 'Sugestão: seria interessante ter um sistema de lembretes para os cuidadores sobre os horários dos medicamentos.', '2025-09-23 18:00:00', 'Sim', 'Texto', NULL, 0),
(14, 9, 1, 'cuidador', 'asdas', '2025-09-22 18:06:43', 'Não', 'Texto', NULL, 0),
(15, 9, 1, 'cuidador', 'asd', '2025-09-22 18:06:50', 'Não', 'Texto', NULL, 0),
(16, 9, 1, 'cuidador', 'ola', '2025-09-22 18:06:54', 'Não', 'Texto', NULL, 0),
(17, 9, 1, 'cuidador', 'teste', '2025-09-24 20:02:52', 'Não', 'Texto', NULL, 0),
(18, 9, 1, 'cuidador', 'kk', '2025-09-25 15:21:20', 'Não', 'Texto', NULL, 0),
(19, 9, 1, 'cuidador', 'asdsd', '2025-10-02 20:28:42', 'Não', 'Texto', NULL, 0),
(20, 10, 1, 'cuidador', 'asddassda', '2025-10-03 13:52:36', 'Não', 'Texto', NULL, 0),
(21, 10, 1, 'cuidador', 'asdasdasdasda', '2025-10-03 13:52:42', 'Não', 'Texto', NULL, 0),
(22, 10, 1, 'cuidador', 'zczxc', '2025-10-03 14:01:43', 'Não', 'Texto', NULL, 0),
(23, 11, 1, 'Administrador', 'sdadsa', '2025-10-03 15:02:31', 'Não', 'Texto', NULL, 1),
(24, 11, 1, 'Administrador', 'Ola', '2025-10-03 15:02:46', 'Não', 'Texto', NULL, 1),
(25, 11, 1, 'Administrador', 'Como posso te ajudar?', '2025-10-03 15:05:20', 'Não', 'Texto', NULL, 1),
(26, 11, 1, 'Administrador', 'h', '2025-10-03 15:09:29', 'Não', 'Texto', NULL, 1),
(27, 11, 1, 'Administrador', 'l', '2025-10-03 15:09:33', 'Não', 'Texto', NULL, 1),
(28, 11, 1, 'Administrador', 'l', '2025-10-03 15:09:33', 'Não', 'Texto', NULL, 1),
(29, 11, 1, 'Administrador', 'l', '2025-10-03 15:09:34', 'Não', 'Texto', NULL, 1),
(30, 11, 1, 'Administrador', 'll', '2025-10-03 15:09:34', 'Não', 'Texto', NULL, 1),
(31, 11, 1, 'Administrador', 'l', '2025-10-03 15:09:35', 'Não', 'Texto', NULL, 1),
(32, 11, 1, 'Administrador', 'l', '2025-10-03 15:09:35', 'Não', 'Texto', NULL, 1),
(33, 11, 1, 'Administrador', 'l', '2025-10-03 15:09:36', 'Não', 'Texto', NULL, 1),
(34, 11, 1, 'Administrador', 'l', '2025-10-03 15:09:36', 'Não', 'Texto', NULL, 1),
(35, 11, 1, 'Administrador', 'll', '2025-10-03 15:09:36', 'Não', 'Texto', NULL, 1),
(36, 11, 1, 'Administrador', 'l', '2025-10-03 15:09:37', 'Não', 'Texto', NULL, 1),
(37, 11, 1, 'Administrador', 'l', '2025-10-03 15:09:37', 'Não', 'Texto', NULL, 1),
(38, 11, 1, 'Administrador', 'l', '2025-10-03 15:09:38', 'Não', 'Texto', NULL, 1),
(39, 11, 1, 'Administrador', 'l', '2025-10-03 15:09:38', 'Não', 'Texto', NULL, 1),
(40, 11, 1, 'Administrador', 'l', '2025-10-03 15:09:39', 'Não', 'Texto', NULL, 1),
(41, 11, 1, 'Administrador', 'l', '2025-10-03 15:09:39', 'Não', 'Texto', NULL, 1),
(42, 11, 1, 'Administrador', 'l', '2025-10-03 15:09:39', 'Não', 'Texto', NULL, 1),
(43, 11, 1, 'Administrador', 'l', '2025-10-03 15:09:40', 'Não', 'Texto', NULL, 1),
(44, 11, 1, 'Administrador', 'll', '2025-10-03 15:09:40', 'Não', 'Texto', NULL, 1);

-- --------------------------------------------------------

--
-- Table structure for table `metafinanceira`
--

CREATE TABLE `metafinanceira` (
  `IdMeta` int(11) NOT NULL,
  `TipoMeta` varchar(50) NOT NULL,
  `Descricao` text DEFAULT NULL,
  `ValorMeta` decimal(10,2) NOT NULL,
  `ValorAtual` decimal(10,2) DEFAULT 0.00,
  `DataInicio` date NOT NULL,
  `DataFim` date NOT NULL,
  `Status` varchar(20) DEFAULT 'Ativa',
  `DataCriacao` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `metafinanceira`
--

INSERT INTO `metafinanceira` (`IdMeta`, `TipoMeta`, `Descricao`, `ValorMeta`, `ValorAtual`, `DataInicio`, `DataFim`, `Status`, `DataCriacao`) VALUES
(1, 'Receita', 'Meta de receita mensal', 50000.00, 0.00, '2024-01-01', '2024-12-31', 'Ativa', '2025-09-18 16:49:04'),
(2, 'Lucro', 'Meta de lucro mensal', 15000.00, 0.00, '2024-01-01', '2024-12-31', 'Ativa', '2025-09-18 16:49:04'),
(3, 'Atendimentos', 'Meta de atendimentos mensais', 200.00, 0.00, '2024-01-01', '2024-12-31', 'Ativa', '2025-09-18 16:49:04');

-- --------------------------------------------------------

--
-- Table structure for table `mobilidade`
--

CREATE TABLE `mobilidade` (
  `IdMobilidade` int(11) NOT NULL,
  `Descricao` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `mobilidade`
--

INSERT INTO `mobilidade` (`IdMobilidade`, `Descricao`) VALUES
(1, 'Independente'),
(2, 'Cadeira de rodas'),
(3, 'Andador'),
(4, 'Bengala'),
(5, 'Auxílio total');

-- --------------------------------------------------------

--
-- Table structure for table `nivelautonomia`
--

CREATE TABLE `nivelautonomia` (
  `IdNivelAutonomia` int(11) NOT NULL,
  `Descricao` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `nivelautonomia`
--

INSERT INTO `nivelautonomia` (`IdNivelAutonomia`, `Descricao`) VALUES
(1, 'Totalmente independente'),
(2, 'Parcialmente independente'),
(3, 'Dependente de auxílio moderado'),
(4, 'Dependente de auxílio intensivo'),
(5, 'Totalmente dependente');

-- --------------------------------------------------------

--
-- Table structure for table `pagamento`
--

CREATE TABLE `pagamento` (
  `IdPagamento` int(11) NOT NULL,
  `IdAtendimento` int(11) DEFAULT NULL,
  `MetodoPagamento` varchar(20) DEFAULT NULL,
  `StatusPagamento` varchar(20) DEFAULT NULL,
  `DataPagamento` datetime DEFAULT current_timestamp(),
  `CodigoTransacao` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `pagamento`
--

INSERT INTO `pagamento` (`IdPagamento`, `IdAtendimento`, `MetodoPagamento`, `StatusPagamento`, `DataPagamento`, `CodigoTransacao`) VALUES
(1, 12, 'Dinheiro', 'Pago', '2025-10-03 02:55:22', 'TXN1758564442620432'),
(3, 10, 'PIX', 'Pago', '2025-10-01 23:51:59', 'TXN1758564443237740'),
(4, 9, 'Cartão de Crédito', 'Pago', '2025-09-25 19:44:03', 'TXN1758564443442348'),
(5, 8, 'Dinheiro', 'Pendente', NULL, NULL),
(7, 6, 'Cartão de Débito', 'Pago', '2025-09-22 20:22:39', 'TXN1758564444058919'),
(8, 5, 'PIX', 'Pago', '2025-09-24 21:26:32', 'TXN1758564444263327'),
(9, 4, 'PIX', 'Pago', '2025-09-23 04:05:58', 'TXN1758564444469158'),
(10, 2, 'Dinheiro', 'Pago', '2025-09-19 23:04:27', 'TXN1758564444674371');

-- --------------------------------------------------------

--
-- Table structure for table `receita`
--

CREATE TABLE `receita` (
  `IdReceita` int(11) NOT NULL,
  `IdAtendimento` int(11) DEFAULT NULL,
  `IdResponsavel` int(11) DEFAULT NULL,
  `Valor` decimal(10,2) NOT NULL,
  `DataRecebimento` datetime DEFAULT current_timestamp(),
  `FormaPagamento` varchar(50) DEFAULT NULL,
  `Status` varchar(20) DEFAULT 'Pago',
  `Observacoes` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `receita`
--

INSERT INTO `receita` (`IdReceita`, `IdAtendimento`, `IdResponsavel`, `Valor`, `DataRecebimento`, `FormaPagamento`, `Status`, `Observacoes`) VALUES
(1, 2, 4, 180.00, '2025-09-17 18:00:00', 'PIX', 'Pago', 'Receita do atendimento ID 2 - Fernanda Lima'),
(3, 4, 8, 200.00, '2025-09-20 12:30:00', 'PIX', 'Pago', 'Receita do atendimento ID 4 - Dona Maria'),
(4, 5, 9, 180.00, '2025-09-21 18:15:00', 'Cartão de Crédito', 'Pago', 'Receita do atendimento ID 5 - Seu José'),
(5, 6, 10, 320.00, '2025-09-22 17:30:00', 'Transferência', 'Pago', 'Receita do atendimento ID 6 - Dona Rosa'),
(7, 8, 12, 480.00, '2025-09-24 20:30:00', 'Dinheiro', 'Pago', 'Receita do atendimento ID 8 - Dona Carmen'),
(8, 9, 13, 200.00, '2025-09-25 19:00:00', 'Cartão de Débito', 'Pago', 'Receita do atendimento ID 9 - Seu Francisco'),
(9, 10, 14, 180.00, '2025-09-26 15:20:00', 'PIX', 'Pago', 'Receita do atendimento ID 10 - Dona Isabel'),
(12, 12, 8, 200.00, '2025-09-22 18:56:45', 'Automático', 'Pago', 'Receita gerada automaticamente pelo sistema');

-- --------------------------------------------------------

--
-- Table structure for table `registroprofissional`
--

CREATE TABLE `registroprofissional` (
  `IdRegistro` int(11) NOT NULL,
  `IdCuidador` int(11) DEFAULT NULL,
  `RegistroCRM` varchar(50) DEFAULT NULL,
  `RegistroCREFITO` varchar(50) DEFAULT NULL,
  `RegistroCOREN` varchar(50) DEFAULT NULL,
  `RegistroCRP` varchar(50) DEFAULT NULL,
  `DataRegistro` date NOT NULL,
  `StatusRegistro` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `responsavel`
--

CREATE TABLE `responsavel` (
  `IdResponsavel` int(11) NOT NULL,
  `IdEndereco` int(11) DEFAULT NULL,
  `Cpf` varchar(20) DEFAULT NULL,
  `Nome` varchar(100) DEFAULT NULL,
  `Email` varchar(100) DEFAULT NULL,
  `Telefone` varchar(20) DEFAULT NULL,
  `DataNascimento` date DEFAULT NULL,
  `Senha` varchar(255) DEFAULT NULL,
  `FotoUrl` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `responsavel`
--

INSERT INTO `responsavel` (`IdResponsavel`, `IdEndereco`, `Cpf`, `Nome`, `Email`, `Telefone`, `DataNascimento`, `Senha`, `FotoUrl`) VALUES
(4, 1, '48290020870', 'Maria Silva', 'dsadas@gmail.com', '11996556155', '2025-09-09', NULL, NULL),
(7, NULL, '49987245275', 'Álvaro', 'alvaro.machado.ferreira.am@gmail.com', '11973677837', '2001-10-29', NULL, NULL),
(8, NULL, '12345678901', 'Ana Carolina Santos', 'ana.santos@email.com', '(11) 99999-9999', '1980-05-14', NULL, NULL),
(9, 5, '23456789012', 'Roberto Silva', 'roberto.silva@email.com', '(11) 99999-2222', '1975-08-22', NULL, NULL),
(10, 6, '34567890123', 'Mariana Costa', 'mariana.costa@email.com', '(11) 99999-3333', '1982-12-10', NULL, NULL),
(11, 7, '45678901234', 'Carlos Eduardo', 'carlos.eduardo@email.com', '(11) 99999-4444', '1978-03-28', NULL, NULL),
(12, 8, '56789012345', 'Patricia Lima', 'patricia.lima@email.com', '(11) 99999-5555', '1985-07-14', NULL, NULL),
(13, 9, '67890123456', 'João Pedro', 'joao.pedro@email.com', '(11) 99999-6666', '1972-11-05', NULL, NULL),
(14, 10, '78901234567', 'Fernanda Oliveira', 'fernanda.oliveira@email.com', '(11) 99999-7777', '1988-09-18', NULL, NULL),
(15, 11, '89012345678', 'Ricardo Alves', 'ricardo.alves@email.com', '(11) 99999-8888', '1976-04-12', NULL, NULL),
(16, 16, '99988877766', 'Usuario Teste', 'usuario.teste@email.com', '11988887777', '1995-05-15', '$2a$10$ACnHNtFsYDRRNeGwwyvjpe3SxR3ZuOg6D36qPOZJCh0GtZ8l9a81u', NULL),
(17, 17, '48290020840', 'JULIO TEST ', 'testtest@gmail.com', '11996556155', '2005-07-31', '$2a$10$KDXIP0BLFoDq7YCZBLpbMODPFt4xOQC6go./RGHMPefkSvs7vkwGG', NULL),
(18, 18, '48290020810', 'teste teste', 'teste@gmail.com', '11996556155', '1995-10-09', '$2a$10$o68l80N55pnBTz6LavBjEuLjVpQRHD8nZJiEQ8y1lAgDZMXegyE2y', NULL),
(19, 19, '48290020890', 'teste teste teste', 'tstw@gmail.com', '11996556155', '1995-10-09', '$2a$10$1yn1Yh1wgvHsi2gbuW7P/u1nCykTx4rcXtsF1hZSnHNrbrv0HlO7m', NULL),
(20, 20, '48290020812', 'qwerererw qweqweqw ', 'weqweeqw@gmail.com', '11996556155', '1995-10-09', '$2a$10$0nXtLFGHZxkpOD1897fOMeNlKJVbXaJDd9rbU.ooalSVOzKCZU7Xu', NULL),
(21, 21, '98765432100', 'Maria Santos Teste', 'maria.teste@email.com', '11888888888', '1985-05-15', '$2a$10$lI9Agj2OPNgka1/Ps3Z/n.TmnKHIQOrh/Vjhm6MuSsOssRbInVCsm', NULL),
(22, 22, '11122233344', 'Pedro Oliveira Teste', 'pedro.teste@email.com', '11777777777', '1980-03-20', '$2a$10$2TBzKRm5ZwuH2K/qSNUJ/uwHqukq7cvVyfUI9S.i.dCQsoYRjKW1S', NULL),
(23, 23, '48290020816', 'asddasdasasd', 'asdasddssad@gmail.com', '11996556155', '1995-10-09', '$2a$10$Ojl32DcgWXrUuy0vaJIkzuZRt5eJRJPKCDpFN2KelkLIIOZFgQDuS', NULL),
(24, 24, '52598445805', 'dsadfsfdsffds', 'dsfkhjdsfjkhb@gmail.com', '11996556155', '1995-10-10', '$2a$10$SUv8QQASGE2gvjAqdBMaCeWL.CVp.Io0rsdXwhFdhDyfFqJK4UNtC', NULL),
(25, 25, '48290020856', 'Julio Franciso Bernardino', 'juliofranciscobernardino@gmail.com', '11996556155', '2005-07-31', '$2a$10$fBQVBguFQPc9Aqebc0ZFoumYL9eviFQYFcRdII.13esKLDu8./h2u', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `restricaoalimentar`
--

CREATE TABLE `restricaoalimentar` (
  `IdRestricaoAlimentar` int(11) NOT NULL,
  `Nome` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `restricaoalimentar`
--

INSERT INTO `restricaoalimentar` (`IdRestricaoAlimentar`, `Nome`) VALUES
(1, 'Sem açúcar'),
(2, 'Sem sal'),
(3, 'Sem lactose'),
(4, 'Sem glúten'),
(5, 'Dieta branda'),
(6, 'Dieta líquida');

-- --------------------------------------------------------

--
-- Table structure for table `servico`
--

CREATE TABLE `servico` (
  `IdServico` int(11) NOT NULL,
  `Nome` varchar(100) DEFAULT NULL,
  `Descricao` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `servico`
--

INSERT INTO `servico` (`IdServico`, `Nome`, `Descricao`) VALUES
(1, 'Cuidados 24h', 'Acompanhamento integral por 24 horas'),
(2, 'Cuidados diurnos', 'Acompanhamento durante o dia'),
(3, 'Cuidados noturnos', 'Acompanhamento durante a noite'),
(4, 'Cuidados de fim de semana', 'Acompanhamento nos fins de semana'),
(5, 'Cuidados esporádicos', 'Acompanhamento conforme necessidade');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `administrador`
--
ALTER TABLE `administrador`
  ADD PRIMARY KEY (`IdAdministrador`),
  ADD UNIQUE KEY `Usuario` (`Usuario`);

--
-- Indexes for table `atendimento`
--
ALTER TABLE `atendimento`
  ADD PRIMARY KEY (`IdAtendimento`),
  ADD KEY `IdResponsavel` (`IdResponsavel`),
  ADD KEY `IdCuidador` (`IdCuidador`),
  ADD KEY `IdIdoso` (`IdIdoso`),
  ADD KEY `idx_atendimento_status` (`Status`),
  ADD KEY `idx_atendimento_datas` (`DataInicio`,`DataFim`);

--
-- Indexes for table `avaliacao`
--
ALTER TABLE `avaliacao`
  ADD PRIMARY KEY (`IdAvaliacao`),
  ADD KEY `IdResponsavel` (`IdResponsavel`),
  ADD KEY `IdCuidador` (`IdCuidador`),
  ADD KEY `IdAtendimento` (`IdAtendimento`);

--
-- Indexes for table `categoriasuporte`
--
ALTER TABLE `categoriasuporte`
  ADD PRIMARY KEY (`IdCategoria`);

--
-- Indexes for table `certificado`
--
ALTER TABLE `certificado`
  ADD PRIMARY KEY (`IdCertificado`),
  ADD KEY `IdCuidador` (`IdCuidador`);

--
-- Indexes for table `chat`
--
ALTER TABLE `chat`
  ADD PRIMARY KEY (`IdChat`),
  ADD KEY `IdCuidador` (`IdCuidador`),
  ADD KEY `IdResponsavel` (`IdResponsavel`),
  ADD KEY `idx_chat_status` (`StatusSuporte`);

--
-- Indexes for table `comissao`
--
ALTER TABLE `comissao`
  ADD PRIMARY KEY (`IdComissao`),
  ADD KEY `IdCuidador` (`IdCuidador`),
  ADD KEY `comissao_ibfk_2` (`IdAtendimento`),
  ADD KEY `idx_comissao_status` (`Status`);

--
-- Indexes for table `configuracaofinanceira`
--
ALTER TABLE `configuracaofinanceira`
  ADD PRIMARY KEY (`IdConfig`),
  ADD UNIQUE KEY `Chave` (`Chave`);

--
-- Indexes for table `cuidador`
--
ALTER TABLE `cuidador`
  ADD PRIMARY KEY (`IdCuidador`),
  ADD KEY `IdEndereco` (`IdEndereco`),
  ADD KEY `idx_cuidador_nome` (`Nome`);

--
-- Indexes for table `cuidadorespecialidade`
--
ALTER TABLE `cuidadorespecialidade`
  ADD PRIMARY KEY (`IdCuidadorEspecialidade`),
  ADD KEY `IdCuidador` (`IdCuidador`),
  ADD KEY `IdEspecialidade` (`IdEspecialidade`);

--
-- Indexes for table `cuidadorservico`
--
ALTER TABLE `cuidadorservico`
  ADD PRIMARY KEY (`IdCuidadorServico`),
  ADD KEY `IdCuidador` (`IdCuidador`),
  ADD KEY `IdServico` (`IdServico`);

--
-- Indexes for table `despesa`
--
ALTER TABLE `despesa`
  ADD PRIMARY KEY (`IdDespesa`),
  ADD KEY `despesa_ibfk_1` (`IdCuidador`);

--
-- Indexes for table `disponibilidade`
--
ALTER TABLE `disponibilidade`
  ADD PRIMARY KEY (`IdDisponibilidade`),
  ADD KEY `IdCuidador` (`IdCuidador`);

--
-- Indexes for table `doenca`
--
ALTER TABLE `doenca`
  ADD PRIMARY KEY (`IdDoenca`);

--
-- Indexes for table `endereco`
--
ALTER TABLE `endereco`
  ADD PRIMARY KEY (`IdEndereco`);

--
-- Indexes for table `especialidade`
--
ALTER TABLE `especialidade`
  ADD PRIMARY KEY (`IdEspecialidade`);

--
-- Indexes for table `experiencia`
--
ALTER TABLE `experiencia`
  ADD PRIMARY KEY (`IdExperiencia`),
  ADD KEY `IdCuidador` (`IdCuidador`);

--
-- Indexes for table `formacao`
--
ALTER TABLE `formacao`
  ADD PRIMARY KEY (`IdFormacao`),
  ADD KEY `IdCuidador` (`IdCuidador`);

--
-- Indexes for table `historicoadministrador`
--
ALTER TABLE `historicoadministrador`
  ADD PRIMARY KEY (`IdHistoricoAdm`),
  ADD KEY `IdAdministrador` (`IdAdministrador`);

--
-- Indexes for table `historicoatendimento`
--
ALTER TABLE `historicoatendimento`
  ADD PRIMARY KEY (`IdHistorico`),
  ADD KEY `IdAtendimento` (`IdAtendimento`);

--
-- Indexes for table `historicocuidador`
--
ALTER TABLE `historicocuidador`
  ADD PRIMARY KEY (`IdHistoricoCuidador`),
  ADD KEY `IdCuidador` (`IdCuidador`);

--
-- Indexes for table `historicoresponsavel`
--
ALTER TABLE `historicoresponsavel`
  ADD PRIMARY KEY (`IdHistoricoResponsavel`),
  ADD KEY `IdResponsavel` (`IdResponsavel`);

--
-- Indexes for table `idoso`
--
ALTER TABLE `idoso`
  ADD PRIMARY KEY (`IdIdoso`),
  ADD KEY `IdResponsavel` (`IdResponsavel`),
  ADD KEY `IdMobilidade` (`IdMobilidade`),
  ADD KEY `IdNivelAutonomia` (`IdNivelAutonomia`),
  ADD KEY `idx_idoso_nome` (`Nome`);

--
-- Indexes for table `idosodoenca`
--
ALTER TABLE `idosodoenca`
  ADD PRIMARY KEY (`IdIdosoDoenca`),
  ADD KEY `IdIdoso` (`IdIdoso`),
  ADD KEY `IdDoenca` (`IdDoenca`);

--
-- Indexes for table `idosorestricaoalimentar`
--
ALTER TABLE `idosorestricaoalimentar`
  ADD PRIMARY KEY (`IdIdosoRestricaoAlimentar`),
  ADD KEY `IdIdoso` (`IdIdoso`),
  ADD KEY `IdRestricaoAlimentar` (`IdRestricaoAlimentar`);

--
-- Indexes for table `inadimplencia`
--
ALTER TABLE `inadimplencia`
  ADD PRIMARY KEY (`IdInadimplencia`),
  ADD KEY `IdResponsavel` (`IdResponsavel`),
  ADD KEY `IdAtendimento` (`IdAtendimento`);

--
-- Indexes for table `mensagem`
--
ALTER TABLE `mensagem`
  ADD PRIMARY KEY (`IdMensagem`),
  ADD KEY `IdChat` (`IdChat`);

--
-- Indexes for table `metafinanceira`
--
ALTER TABLE `metafinanceira`
  ADD PRIMARY KEY (`IdMeta`);

--
-- Indexes for table `mobilidade`
--
ALTER TABLE `mobilidade`
  ADD PRIMARY KEY (`IdMobilidade`);

--
-- Indexes for table `nivelautonomia`
--
ALTER TABLE `nivelautonomia`
  ADD PRIMARY KEY (`IdNivelAutonomia`);

--
-- Indexes for table `pagamento`
--
ALTER TABLE `pagamento`
  ADD PRIMARY KEY (`IdPagamento`),
  ADD KEY `IdAtendimento` (`IdAtendimento`);

--
-- Indexes for table `receita`
--
ALTER TABLE `receita`
  ADD PRIMARY KEY (`IdReceita`),
  ADD KEY `IdResponsavel` (`IdResponsavel`),
  ADD KEY `receita_ibfk_1` (`IdAtendimento`),
  ADD KEY `idx_receita_status` (`Status`);

--
-- Indexes for table `registroprofissional`
--
ALTER TABLE `registroprofissional`
  ADD PRIMARY KEY (`IdRegistro`),
  ADD KEY `IdCuidador` (`IdCuidador`);

--
-- Indexes for table `responsavel`
--
ALTER TABLE `responsavel`
  ADD PRIMARY KEY (`IdResponsavel`),
  ADD KEY `IdEndereco` (`IdEndereco`),
  ADD KEY `idx_responsavel_nome` (`Nome`);

--
-- Indexes for table `restricaoalimentar`
--
ALTER TABLE `restricaoalimentar`
  ADD PRIMARY KEY (`IdRestricaoAlimentar`);

--
-- Indexes for table `servico`
--
ALTER TABLE `servico`
  ADD PRIMARY KEY (`IdServico`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `administrador`
--
ALTER TABLE `administrador`
  MODIFY `IdAdministrador` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `atendimento`
--
ALTER TABLE `atendimento`
  MODIFY `IdAtendimento` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `avaliacao`
--
ALTER TABLE `avaliacao`
  MODIFY `IdAvaliacao` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `categoriasuporte`
--
ALTER TABLE `categoriasuporte`
  MODIFY `IdCategoria` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `certificado`
--
ALTER TABLE `certificado`
  MODIFY `IdCertificado` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `chat`
--
ALTER TABLE `chat`
  MODIFY `IdChat` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `comissao`
--
ALTER TABLE `comissao`
  MODIFY `IdComissao` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `configuracaofinanceira`
--
ALTER TABLE `configuracaofinanceira`
  MODIFY `IdConfig` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `cuidador`
--
ALTER TABLE `cuidador`
  MODIFY `IdCuidador` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `cuidadorespecialidade`
--
ALTER TABLE `cuidadorespecialidade`
  MODIFY `IdCuidadorEspecialidade` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `cuidadorservico`
--
ALTER TABLE `cuidadorservico`
  MODIFY `IdCuidadorServico` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `despesa`
--
ALTER TABLE `despesa`
  MODIFY `IdDespesa` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `disponibilidade`
--
ALTER TABLE `disponibilidade`
  MODIFY `IdDisponibilidade` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `doenca`
--
ALTER TABLE `doenca`
  MODIFY `IdDoenca` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `endereco`
--
ALTER TABLE `endereco`
  MODIFY `IdEndereco` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- AUTO_INCREMENT for table `especialidade`
--
ALTER TABLE `especialidade`
  MODIFY `IdEspecialidade` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `experiencia`
--
ALTER TABLE `experiencia`
  MODIFY `IdExperiencia` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `formacao`
--
ALTER TABLE `formacao`
  MODIFY `IdFormacao` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `historicoadministrador`
--
ALTER TABLE `historicoadministrador`
  MODIFY `IdHistoricoAdm` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=335;

--
-- AUTO_INCREMENT for table `historicoatendimento`
--
ALTER TABLE `historicoatendimento`
  MODIFY `IdHistorico` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `historicocuidador`
--
ALTER TABLE `historicocuidador`
  MODIFY `IdHistoricoCuidador` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `historicoresponsavel`
--
ALTER TABLE `historicoresponsavel`
  MODIFY `IdHistoricoResponsavel` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `idoso`
--
ALTER TABLE `idoso`
  MODIFY `IdIdoso` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;

--
-- AUTO_INCREMENT for table `idosodoenca`
--
ALTER TABLE `idosodoenca`
  MODIFY `IdIdosoDoenca` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `idosorestricaoalimentar`
--
ALTER TABLE `idosorestricaoalimentar`
  MODIFY `IdIdosoRestricaoAlimentar` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `inadimplencia`
--
ALTER TABLE `inadimplencia`
  MODIFY `IdInadimplencia` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `mensagem`
--
ALTER TABLE `mensagem`
  MODIFY `IdMensagem` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=45;

--
-- AUTO_INCREMENT for table `metafinanceira`
--
ALTER TABLE `metafinanceira`
  MODIFY `IdMeta` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `mobilidade`
--
ALTER TABLE `mobilidade`
  MODIFY `IdMobilidade` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `nivelautonomia`
--
ALTER TABLE `nivelautonomia`
  MODIFY `IdNivelAutonomia` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `pagamento`
--
ALTER TABLE `pagamento`
  MODIFY `IdPagamento` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `receita`
--
ALTER TABLE `receita`
  MODIFY `IdReceita` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT for table `registroprofissional`
--
ALTER TABLE `registroprofissional`
  MODIFY `IdRegistro` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `responsavel`
--
ALTER TABLE `responsavel`
  MODIFY `IdResponsavel` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- AUTO_INCREMENT for table `restricaoalimentar`
--
ALTER TABLE `restricaoalimentar`
  MODIFY `IdRestricaoAlimentar` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `servico`
--
ALTER TABLE `servico`
  MODIFY `IdServico` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `atendimento`
--
ALTER TABLE `atendimento`
  ADD CONSTRAINT `atendimento_ibfk_1` FOREIGN KEY (`IdResponsavel`) REFERENCES `responsavel` (`IdResponsavel`),
  ADD CONSTRAINT `atendimento_ibfk_2` FOREIGN KEY (`IdCuidador`) REFERENCES `cuidador` (`IdCuidador`),
  ADD CONSTRAINT `atendimento_ibfk_3` FOREIGN KEY (`IdIdoso`) REFERENCES `idoso` (`IdIdoso`) ON DELETE CASCADE;

--
-- Constraints for table `avaliacao`
--
ALTER TABLE `avaliacao`
  ADD CONSTRAINT `avaliacao_ibfk_1` FOREIGN KEY (`IdResponsavel`) REFERENCES `responsavel` (`IdResponsavel`),
  ADD CONSTRAINT `avaliacao_ibfk_2` FOREIGN KEY (`IdCuidador`) REFERENCES `cuidador` (`IdCuidador`),
  ADD CONSTRAINT `avaliacao_ibfk_3` FOREIGN KEY (`IdAtendimento`) REFERENCES `atendimento` (`IdAtendimento`) ON DELETE CASCADE;

--
-- Constraints for table `certificado`
--
ALTER TABLE `certificado`
  ADD CONSTRAINT `certificado_ibfk_1` FOREIGN KEY (`IdCuidador`) REFERENCES `cuidador` (`IdCuidador`) ON DELETE CASCADE;

--
-- Constraints for table `chat`
--
ALTER TABLE `chat`
  ADD CONSTRAINT `chat_ibfk_1` FOREIGN KEY (`IdCuidador`) REFERENCES `cuidador` (`IdCuidador`) ON DELETE CASCADE,
  ADD CONSTRAINT `chat_ibfk_2` FOREIGN KEY (`IdResponsavel`) REFERENCES `responsavel` (`IdResponsavel`) ON DELETE CASCADE;

--
-- Constraints for table `comissao`
--
ALTER TABLE `comissao`
  ADD CONSTRAINT `comissao_ibfk_1` FOREIGN KEY (`IdCuidador`) REFERENCES `cuidador` (`IdCuidador`),
  ADD CONSTRAINT `comissao_ibfk_2` FOREIGN KEY (`IdAtendimento`) REFERENCES `atendimento` (`IdAtendimento`) ON DELETE CASCADE;

--
-- Constraints for table `cuidador`
--
ALTER TABLE `cuidador`
  ADD CONSTRAINT `cuidador_ibfk_1` FOREIGN KEY (`IdEndereco`) REFERENCES `endereco` (`IdEndereco`);

--
-- Constraints for table `cuidadorespecialidade`
--
ALTER TABLE `cuidadorespecialidade`
  ADD CONSTRAINT `cuidadorespecialidade_ibfk_1` FOREIGN KEY (`IdCuidador`) REFERENCES `cuidador` (`IdCuidador`) ON DELETE CASCADE,
  ADD CONSTRAINT `cuidadorespecialidade_ibfk_2` FOREIGN KEY (`IdEspecialidade`) REFERENCES `especialidade` (`IdEspecialidade`);

--
-- Constraints for table `cuidadorservico`
--
ALTER TABLE `cuidadorservico`
  ADD CONSTRAINT `cuidadorservico_ibfk_1` FOREIGN KEY (`IdCuidador`) REFERENCES `cuidador` (`IdCuidador`) ON DELETE CASCADE,
  ADD CONSTRAINT `cuidadorservico_ibfk_2` FOREIGN KEY (`IdServico`) REFERENCES `servico` (`IdServico`);

--
-- Constraints for table `despesa`
--
ALTER TABLE `despesa`
  ADD CONSTRAINT `despesa_ibfk_1` FOREIGN KEY (`IdCuidador`) REFERENCES `cuidador` (`IdCuidador`) ON DELETE SET NULL;

--
-- Constraints for table `disponibilidade`
--
ALTER TABLE `disponibilidade`
  ADD CONSTRAINT `disponibilidade_ibfk_1` FOREIGN KEY (`IdCuidador`) REFERENCES `cuidador` (`IdCuidador`) ON DELETE CASCADE;

--
-- Constraints for table `experiencia`
--
ALTER TABLE `experiencia`
  ADD CONSTRAINT `experiencia_ibfk_1` FOREIGN KEY (`IdCuidador`) REFERENCES `cuidador` (`IdCuidador`) ON DELETE CASCADE;

--
-- Constraints for table `formacao`
--
ALTER TABLE `formacao`
  ADD CONSTRAINT `formacao_ibfk_1` FOREIGN KEY (`IdCuidador`) REFERENCES `cuidador` (`IdCuidador`) ON DELETE CASCADE;

--
-- Constraints for table `historicoadministrador`
--
ALTER TABLE `historicoadministrador`
  ADD CONSTRAINT `historicoadministrador_ibfk_1` FOREIGN KEY (`IdAdministrador`) REFERENCES `administrador` (`IdAdministrador`);

--
-- Constraints for table `historicoatendimento`
--
ALTER TABLE `historicoatendimento`
  ADD CONSTRAINT `historicoatendimento_ibfk_1` FOREIGN KEY (`IdAtendimento`) REFERENCES `atendimento` (`IdAtendimento`) ON DELETE CASCADE;

--
-- Constraints for table `historicocuidador`
--
ALTER TABLE `historicocuidador`
  ADD CONSTRAINT `historicocuidador_ibfk_1` FOREIGN KEY (`IdCuidador`) REFERENCES `cuidador` (`IdCuidador`) ON DELETE CASCADE;

--
-- Constraints for table `historicoresponsavel`
--
ALTER TABLE `historicoresponsavel`
  ADD CONSTRAINT `historicoresponsavel_ibfk_1` FOREIGN KEY (`IdResponsavel`) REFERENCES `responsavel` (`IdResponsavel`) ON DELETE CASCADE;

--
-- Constraints for table `idoso`
--
ALTER TABLE `idoso`
  ADD CONSTRAINT `idoso_ibfk_1` FOREIGN KEY (`IdResponsavel`) REFERENCES `responsavel` (`IdResponsavel`),
  ADD CONSTRAINT `idoso_ibfk_2` FOREIGN KEY (`IdMobilidade`) REFERENCES `mobilidade` (`IdMobilidade`),
  ADD CONSTRAINT `idoso_ibfk_3` FOREIGN KEY (`IdNivelAutonomia`) REFERENCES `nivelautonomia` (`IdNivelAutonomia`);

--
-- Constraints for table `idosodoenca`
--
ALTER TABLE `idosodoenca`
  ADD CONSTRAINT `idosodoenca_ibfk_1` FOREIGN KEY (`IdIdoso`) REFERENCES `idoso` (`IdIdoso`) ON DELETE CASCADE,
  ADD CONSTRAINT `idosodoenca_ibfk_2` FOREIGN KEY (`IdDoenca`) REFERENCES `doenca` (`IdDoenca`);

--
-- Constraints for table `idosorestricaoalimentar`
--
ALTER TABLE `idosorestricaoalimentar`
  ADD CONSTRAINT `idosorestricaoalimentar_ibfk_1` FOREIGN KEY (`IdIdoso`) REFERENCES `idoso` (`IdIdoso`) ON DELETE CASCADE,
  ADD CONSTRAINT `idosorestricaoalimentar_ibfk_2` FOREIGN KEY (`IdRestricaoAlimentar`) REFERENCES `restricaoalimentar` (`IdRestricaoAlimentar`);

--
-- Constraints for table `inadimplencia`
--
ALTER TABLE `inadimplencia`
  ADD CONSTRAINT `inadimplencia_ibfk_1` FOREIGN KEY (`IdResponsavel`) REFERENCES `responsavel` (`IdResponsavel`),
  ADD CONSTRAINT `inadimplencia_ibfk_2` FOREIGN KEY (`IdAtendimento`) REFERENCES `atendimento` (`IdAtendimento`);

--
-- Constraints for table `mensagem`
--
ALTER TABLE `mensagem`
  ADD CONSTRAINT `mensagem_ibfk_1` FOREIGN KEY (`IdChat`) REFERENCES `chat` (`IdChat`) ON DELETE CASCADE;

--
-- Constraints for table `pagamento`
--
ALTER TABLE `pagamento`
  ADD CONSTRAINT `pagamento_ibfk_1` FOREIGN KEY (`IdAtendimento`) REFERENCES `atendimento` (`IdAtendimento`) ON DELETE CASCADE;

--
-- Constraints for table `receita`
--
ALTER TABLE `receita`
  ADD CONSTRAINT `receita_ibfk_1` FOREIGN KEY (`IdAtendimento`) REFERENCES `atendimento` (`IdAtendimento`) ON DELETE CASCADE,
  ADD CONSTRAINT `receita_ibfk_2` FOREIGN KEY (`IdResponsavel`) REFERENCES `responsavel` (`IdResponsavel`);

--
-- Constraints for table `registroprofissional`
--
ALTER TABLE `registroprofissional`
  ADD CONSTRAINT `registroprofissional_ibfk_1` FOREIGN KEY (`IdCuidador`) REFERENCES `cuidador` (`IdCuidador`) ON DELETE CASCADE;

--
-- Constraints for table `responsavel`
--
ALTER TABLE `responsavel`
  ADD CONSTRAINT `responsavel_ibfk_1` FOREIGN KEY (`IdEndereco`) REFERENCES `endereco` (`IdEndereco`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
