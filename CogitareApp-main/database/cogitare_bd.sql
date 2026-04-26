-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Mar 08, 2026 at 10:08 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

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
CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_atendimento_atualizar` (IN `p_IdAtendimento` INT, IN `p_IdResponsavel` INT, IN `p_IdCuidador` INT, IN `p_IdIdoso` INT, IN `p_DataInicio` DATETIME, IN `p_DataFim` DATETIME, IN `p_Status` VARCHAR(20), IN `p_Local` VARCHAR(255), IN `p_Valor` DECIMAL(10,2), IN `p_ObservacaoExtra` TEXT, IN `p_IdAdministrador` INT)   BEGIN
    DECLARE v_NomeResponsavel VARCHAR(100);
    DECLARE v_NomeCuidador VARCHAR(100);
    DECLARE v_NomeIdoso VARCHAR(100);
    DECLARE v_Existe INT DEFAULT 0;
    
    -- Verificar se o atendimento existe
    SELECT COUNT(*) INTO v_Existe FROM atendimento WHERE IdAtendimento = p_IdAtendimento;
    
    IF v_Existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Atendimento não encontrado';
    END IF;
    
    -- Buscar nomes para o log
    SELECT Nome INTO v_NomeResponsavel FROM responsavel WHERE IdResponsavel = p_IdResponsavel;
    SELECT Nome INTO v_NomeCuidador FROM cuidador WHERE IdCuidador = p_IdCuidador;
    SELECT Nome INTO v_NomeIdoso FROM idoso WHERE IdIdoso = p_IdIdoso;
    
    -- Atualizar atendimento
    UPDATE atendimento
    SET 
        IdResponsavel = p_IdResponsavel,
        IdCuidador = p_IdCuidador,
        IdIdoso = p_IdIdoso,
        DataInicio = p_DataInicio,
        DataFim = p_DataFim,
        Status = p_Status,
        Local = p_Local,
        Valor = p_Valor,
        ObservacaoExtra = p_ObservacaoExtra
    WHERE IdAtendimento = p_IdAtendimento;
    
    -- Registrar no histórico do administrador
    INSERT INTO historicoadministrador (IdAdministrador, Operacao, DataOperacao)
    VALUES (
        p_IdAdministrador,
        CONCAT('Atendimento (ID: ', p_IdAtendimento, ') alterado - Responsável: ', IFNULL(v_NomeResponsavel, 'N/A'), 
               ' | Cuidador: ', IFNULL(v_NomeCuidador, 'N/A'), 
               ' | Idoso: ', IFNULL(v_NomeIdoso, 'N/A'), 
               ' | Status: ', p_Status, 
               ' | Valor: R$ ', IFNULL(FORMAT(p_Valor, 2, 'pt_BR'), '0,00')),
        NOW()
    );
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_atendimento_atualizar_status` (IN `p_IdAtendimento` INT, IN `p_Status` VARCHAR(20), IN `p_IdAdministrador` INT)   BEGIN
    DECLARE v_NomeResponsavel VARCHAR(100);
    DECLARE v_NomeCuidador VARCHAR(100);
    DECLARE v_NomeIdoso VARCHAR(100);
    DECLARE v_StatusAnterior VARCHAR(20);
    
    -- Buscar dados do atendimento
    SELECT 
        a.Status,
        r.Nome,
        c.Nome,
        i.Nome
    INTO 
        v_StatusAnterior,
        v_NomeResponsavel,
        v_NomeCuidador,
        v_NomeIdoso
    FROM atendimento a
    LEFT JOIN responsavel r ON a.IdResponsavel = r.IdResponsavel
    LEFT JOIN cuidador c ON a.IdCuidador = c.IdCuidador
    LEFT JOIN idoso i ON a.IdIdoso = i.IdIdoso
    WHERE a.IdAtendimento = p_IdAtendimento;
    
    -- Verificar se o atendimento existe
    IF v_StatusAnterior IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Atendimento não encontrado';
    END IF;
    
    -- Atualizar status
    UPDATE atendimento 
    SET Status = p_Status 
    WHERE IdAtendimento = p_IdAtendimento;
    
    -- Registrar no histórico do administrador
    INSERT INTO historicoadministrador (IdAdministrador, Operacao, DataOperacao)
    VALUES (
        p_IdAdministrador,
        CONCAT('Status do atendimento (ID: ', p_IdAtendimento, ') alterado de "', 
               IFNULL(v_StatusAnterior, 'N/A'), '" para "', p_Status, 
               '" - Idoso: ', IFNULL(v_NomeIdoso, 'N/A')),
        NOW()
    );
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_atendimento_buscar_por_id` (IN `p_IdAtendimento` INT)   BEGIN
    SELECT 
        a.*, 
        r.Nome AS NomeResponsavel, 
        i.Nome AS NomeIdoso, 
        c.Nome AS NomeCuidador
    FROM atendimento a
    LEFT JOIN responsavel r ON a.IdResponsavel = r.IdResponsavel
    LEFT JOIN idoso i ON a.IdIdoso = i.IdIdoso
    LEFT JOIN cuidador c ON a.IdCuidador = c.IdCuidador
    WHERE a.IdAtendimento = p_IdAtendimento;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_atendimento_criar` (IN `p_IdResponsavel` INT, IN `p_IdCuidador` INT, IN `p_IdIdoso` INT, IN `p_DataInicio` DATETIME, IN `p_DataFim` DATETIME, IN `p_Status` VARCHAR(20), IN `p_Local` VARCHAR(255), IN `p_Valor` DECIMAL(10,2), IN `p_ObservacaoExtra` TEXT, IN `p_IdAdministrador` INT)   BEGIN
    DECLARE v_NomeResponsavel VARCHAR(100);
    DECLARE v_NomeCuidador VARCHAR(100);
    DECLARE v_NomeIdoso VARCHAR(100);
    DECLARE v_IdAtendimento INT;
    
    -- Buscar nomes para o log
    SELECT Nome INTO v_NomeResponsavel FROM responsavel WHERE IdResponsavel = p_IdResponsavel;
    SELECT Nome INTO v_NomeCuidador FROM cuidador WHERE IdCuidador = p_IdCuidador;
    SELECT Nome INTO v_NomeIdoso FROM idoso WHERE IdIdoso = p_IdIdoso;
    
    -- Inserir atendimento
    INSERT INTO atendimento (
        IdResponsavel, IdCuidador, IdIdoso, DataInicio, DataFim, 
        Status, Local, Valor, ObservacaoExtra
    )
    VALUES (
        p_IdResponsavel, p_IdCuidador, p_IdIdoso, p_DataInicio, p_DataFim,
        p_Status, p_Local, p_Valor, p_ObservacaoExtra
    );
    
    SET v_IdAtendimento = LAST_INSERT_ID();
    
    -- Registrar no histórico do administrador
    INSERT INTO historicoadministrador (IdAdministrador, Operacao, DataOperacao)
    VALUES (
        p_IdAdministrador,
        CONCAT('Atendimento criado (ID: ', v_IdAtendimento, ') - Responsável: ', IFNULL(v_NomeResponsavel, 'N/A'), 
               ' | Cuidador: ', IFNULL(v_NomeCuidador, 'N/A'), 
               ' | Idoso: ', IFNULL(v_NomeIdoso, 'N/A'), 
               ' | Valor: R$ ', IFNULL(FORMAT(p_Valor, 2, 'pt_BR'), '0,00')),
        NOW()
    );
    
    SELECT v_IdAtendimento AS Id;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_atendimento_excluir` (IN `p_IdAtendimento` INT, IN `p_IdAdministrador` INT)   BEGIN
    DECLARE v_NomeResponsavel VARCHAR(100);
    DECLARE v_NomeCuidador VARCHAR(100);
    DECLARE v_NomeIdoso VARCHAR(100);
    DECLARE v_Status VARCHAR(20);
    DECLARE v_Valor DECIMAL(10,2);
    DECLARE v_Existe INT DEFAULT 0;
    
    -- Verificar se o atendimento existe e buscar dados
    SELECT 
        COUNT(*),
        r.Nome,
        c.Nome,
        i.Nome,
        a.Status,
        a.Valor
    INTO 
        v_Existe,
        v_NomeResponsavel,
        v_NomeCuidador,
        v_NomeIdoso,
        v_Status,
        v_Valor
    FROM atendimento a
    LEFT JOIN responsavel r ON a.IdResponsavel = r.IdResponsavel
    LEFT JOIN cuidador c ON a.IdCuidador = c.IdCuidador
    LEFT JOIN idoso i ON a.IdIdoso = i.IdIdoso
    WHERE a.IdAtendimento = p_IdAtendimento;
    
    IF v_Existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Atendimento não encontrado';
    END IF;
    
    -- Registrar no histórico do administrador ANTES de excluir
    INSERT INTO historicoadministrador (IdAdministrador, Operacao, DataOperacao)
    VALUES (
        p_IdAdministrador,
        CONCAT('Atendimento excluído (ID: ', p_IdAtendimento, ') - Responsável: ', IFNULL(v_NomeResponsavel, 'N/A'), 
               ' | Cuidador: ', IFNULL(v_NomeCuidador, 'N/A'), 
               ' | Idoso: ', IFNULL(v_NomeIdoso, 'N/A'), 
               ' | Status: ', IFNULL(v_Status, 'N/A'), 
               ' | Valor: R$ ', IFNULL(FORMAT(v_Valor, 2, 'pt_BR'), '0,00')),
        NOW()
    );
    
    -- Excluir atendimento
    DELETE FROM atendimento WHERE IdAtendimento = p_IdAtendimento;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_atendimento_listar` ()   BEGIN
    SELECT 
        a.*, 
        r.Nome AS NomeResponsavel, 
        i.Nome AS NomeIdoso, 
        c.Nome AS NomeCuidador
    FROM atendimento a
    LEFT JOIN responsavel r ON a.IdResponsavel = r.IdResponsavel
    LEFT JOIN idoso i ON a.IdIdoso = i.IdIdoso
    LEFT JOIN cuidador c ON a.IdCuidador = c.IdCuidador
    ORDER BY a.DataInicio DESC;
END$$

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

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_avaliacao_atualizar` (IN `p_IdAvaliacao` INT, IN `p_Nota` INT, IN `p_Comentario` TEXT, IN `p_IdAdministrador` INT)   BEGIN
    DECLARE v_NomeResponsavel VARCHAR(100);
    DECLARE v_NomeCuidador VARCHAR(100);
    DECLARE v_NotaAnterior INT;
    DECLARE v_Existe INT DEFAULT 0;
    
    -- Verificar se a avaliação existe e buscar dados
    SELECT 
        COUNT(*),
        r.Nome,
        c.Nome,
        a.Nota
    INTO 
        v_Existe,
        v_NomeResponsavel,
        v_NomeCuidador,
        v_NotaAnterior
    FROM avaliacao a
    LEFT JOIN responsavel r ON a.IdResponsavel = r.IdResponsavel
    LEFT JOIN cuidador c ON a.IdCuidador = c.IdCuidador
    WHERE a.IdAvaliacao = p_IdAvaliacao;
    
    IF v_Existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Avaliação não encontrada';
    END IF;
    
    -- Atualizar avaliação
    UPDATE avaliacao 
    SET Nota = p_Nota, Comentario = p_Comentario
    WHERE IdAvaliacao = p_IdAvaliacao;
    
    -- Registrar no histórico do administrador
    INSERT INTO historicoadministrador (IdAdministrador, Operacao, DataOperacao)
    VALUES (
        p_IdAdministrador,
        CONCAT('Avaliação atualizada (ID: ', p_IdAvaliacao, ') - Nota alterada de ', 
               IFNULL(v_NotaAnterior, 'N/A'), ' para ', p_Nota, 
               ' | Responsável: ', IFNULL(v_NomeResponsavel, 'N/A'), 
               ' | Cuidador: ', IFNULL(v_NomeCuidador, 'N/A')),
        NOW()
    );
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_avaliacao_buscar_atendimentos_para_avaliacao` (IN `p_IdResponsavel` INT)   BEGIN
    SELECT 
        a.IdAtendimento,
        a.DataInicio,
        a.DataFim,
        c.Nome as NomeCuidador,
        i.Nome as NomeIdoso,
        CASE WHEN av.IdAvaliacao IS NOT NULL THEN 1 ELSE 0 END as JaAvaliado
    FROM atendimento a
    LEFT JOIN cuidador c ON a.IdCuidador = c.IdCuidador
    LEFT JOIN idoso i ON a.IdIdoso = i.IdIdoso
    LEFT JOIN avaliacao av ON a.IdAtendimento = av.IdAtendimento
    WHERE a.IdResponsavel = p_IdResponsavel 
    AND a.Status = 'Concluído'
    AND a.DataFim <= NOW()
    ORDER BY a.DataFim DESC;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_avaliacao_buscar_por_cuidador` (IN `p_IdCuidador` INT)   BEGIN
    SELECT 
        a.IdAvaliacao,
        a.Nota,
        a.Comentario,
        a.DataAvaliacao,
        r.Nome as NomeResponsavel,
        at.DataInicio,
        at.DataFim,
        i.Nome as NomeIdoso
    FROM avaliacao a
    LEFT JOIN responsavel r ON a.IdResponsavel = r.IdResponsavel
    LEFT JOIN atendimento at ON a.IdAtendimento = at.IdAtendimento
    LEFT JOIN idoso i ON at.IdIdoso = i.IdIdoso
    WHERE a.IdCuidador = p_IdCuidador
    ORDER BY a.DataAvaliacao DESC;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_avaliacao_buscar_por_id` (IN `p_IdAvaliacao` INT)   BEGIN
    SELECT 
        a.IdAvaliacao,
        a.Nota,
        a.Comentario,
        a.DataAvaliacao,
        a.IdResponsavel,
        a.IdCuidador,
        a.IdAtendimento,
        r.Nome as NomeResponsavel,
        c.Nome as NomeCuidador,
        at.DataInicio,
        at.DataFim,
        i.Nome as NomeIdoso
    FROM avaliacao a
    LEFT JOIN responsavel r ON a.IdResponsavel = r.IdResponsavel
    LEFT JOIN cuidador c ON a.IdCuidador = c.IdCuidador
    LEFT JOIN atendimento at ON a.IdAtendimento = at.IdAtendimento
    LEFT JOIN idoso i ON at.IdIdoso = i.IdIdoso
    WHERE a.IdAvaliacao = p_IdAvaliacao;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_avaliacao_buscar_por_responsavel` (IN `p_IdResponsavel` INT)   BEGIN
    SELECT 
        a.IdAvaliacao,
        a.Nota,
        a.Comentario,
        a.DataAvaliacao,
        c.Nome as NomeCuidador,
        at.DataInicio,
        at.DataFim,
        i.Nome as NomeIdoso
    FROM avaliacao a
    LEFT JOIN cuidador c ON a.IdCuidador = c.IdCuidador
    LEFT JOIN atendimento at ON a.IdAtendimento = at.IdAtendimento
    LEFT JOIN idoso i ON at.IdIdoso = i.IdIdoso
    WHERE a.IdResponsavel = p_IdResponsavel
    ORDER BY a.DataAvaliacao DESC;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_avaliacao_calcular_media_cuidador` (IN `p_IdCuidador` INT)   BEGIN
    SELECT 
        AVG(Nota) as MediaNota,
        COUNT(*) as TotalAvaliacoes
    FROM avaliacao 
    WHERE IdCuidador = p_IdCuidador;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_avaliacao_criar` (IN `p_IdResponsavel` INT, IN `p_IdCuidador` INT, IN `p_IdAtendimento` INT, IN `p_Nota` INT, IN `p_Comentario` TEXT, IN `p_IdAdministrador` INT)   BEGIN
    DECLARE v_NomeResponsavel VARCHAR(100);
    DECLARE v_NomeCuidador VARCHAR(100);
    DECLARE v_NomeIdoso VARCHAR(100);
    DECLARE v_IdAvaliacao INT;
    
    -- Buscar nomes para o log
    SELECT Nome INTO v_NomeResponsavel FROM responsavel WHERE IdResponsavel = p_IdResponsavel;
    SELECT Nome INTO v_NomeCuidador FROM cuidador WHERE IdCuidador = p_IdCuidador;
    SELECT Nome INTO v_NomeIdoso 
    FROM idoso i
    INNER JOIN atendimento a ON i.IdIdoso = a.IdIdoso
    WHERE a.IdAtendimento = p_IdAtendimento;
    
    -- Inserir avaliação
    INSERT INTO avaliacao (IdResponsavel, IdCuidador, IdAtendimento, Nota, Comentario)
    VALUES (p_IdResponsavel, p_IdCuidador, p_IdAtendimento, p_Nota, p_Comentario);
    
    SET v_IdAvaliacao = LAST_INSERT_ID();
    
    -- Registrar no histórico do administrador
    INSERT INTO historicoadministrador (IdAdministrador, Operacao, DataOperacao)
    VALUES (
        p_IdAdministrador,
        CONCAT('Avaliação criada (ID: ', v_IdAvaliacao, ') - Nota: ', p_Nota, 
               ' | Responsável: ', IFNULL(v_NomeResponsavel, 'N/A'), 
               ' | Cuidador: ', IFNULL(v_NomeCuidador, 'N/A'), 
               ' | Idoso: ', IFNULL(v_NomeIdoso, 'N/A'), 
               ' | Atendimento ID: ', IFNULL(p_IdAtendimento, 'N/A')),
        NOW()
    );
    
    SELECT v_IdAvaliacao AS Id;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_avaliacao_estatisticas` ()   BEGIN
    SELECT 
        COUNT(*) as TotalAvaliacoes,
        AVG(Nota) as MediaGeral,
        MIN(Nota) as MenorNota,
        MAX(Nota) as MaiorNota,
        COUNT(CASE WHEN Nota >= 4 THEN 1 END) as AvaliacoesPositivas,
        COUNT(CASE WHEN Nota <= 2 THEN 1 END) as AvaliacoesNegativas
    FROM avaliacao;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_avaliacao_excluir` (IN `p_IdAvaliacao` INT, IN `p_IdAdministrador` INT)   BEGIN
    DECLARE v_NomeResponsavel VARCHAR(100);
    DECLARE v_NomeCuidador VARCHAR(100);
    DECLARE v_Nota INT;
    DECLARE v_Existe INT DEFAULT 0;
    
    -- Verificar se a avaliação existe e buscar dados
    SELECT 
        COUNT(*),
        r.Nome,
        c.Nome,
        a.Nota
    INTO 
        v_Existe,
        v_NomeResponsavel,
        v_NomeCuidador,
        v_Nota
    FROM avaliacao a
    LEFT JOIN responsavel r ON a.IdResponsavel = r.IdResponsavel
    LEFT JOIN cuidador c ON a.IdCuidador = c.IdCuidador
    WHERE a.IdAvaliacao = p_IdAvaliacao;
    
    IF v_Existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Avaliação não encontrada';
    END IF;
    
    -- Registrar no histórico do administrador ANTES de excluir
    INSERT INTO historicoadministrador (IdAdministrador, Operacao, DataOperacao)
    VALUES (
        p_IdAdministrador,
        CONCAT('Avaliação excluída (ID: ', p_IdAvaliacao, ') - Nota: ', IFNULL(v_Nota, 'N/A'), 
               ' | Responsável: ', IFNULL(v_NomeResponsavel, 'N/A'), 
               ' | Cuidador: ', IFNULL(v_NomeCuidador, 'N/A')),
        NOW()
    );
    
    -- Excluir avaliação
    DELETE FROM avaliacao WHERE IdAvaliacao = p_IdAvaliacao;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_avaliacao_listar` ()   BEGIN
    SELECT 
        a.IdAvaliacao,
        a.Nota,
        a.Comentario,
        a.DataAvaliacao,
        a.IdResponsavel,
        a.IdCuidador,
        a.IdAtendimento,
        r.Nome as NomeResponsavel,
        c.Nome as NomeCuidador,
        at.DataInicio,
        at.DataFim,
        i.Nome as NomeIdoso
    FROM avaliacao a
    LEFT JOIN responsavel r ON a.IdResponsavel = r.IdResponsavel
    LEFT JOIN cuidador c ON a.IdCuidador = c.IdCuidador
    LEFT JOIN atendimento at ON a.IdAtendimento = at.IdAtendimento
    LEFT JOIN idoso i ON at.IdIdoso = i.IdIdoso
    ORDER BY a.DataAvaliacao DESC;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_avaliacao_verificar_existente` (IN `p_IdAtendimento` INT)   BEGIN
    SELECT 
        CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END as ExisteAvaliacao,
        IdAvaliacao
    FROM avaliacao 
    WHERE IdAtendimento = p_IdAtendimento
    LIMIT 1;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_buscar_admin_por_usuario` (IN `p_Usuario` VARCHAR(100))   BEGIN
    SELECT 
        a.IdAdministrador,
        a.Usuario,
        a.Senha,           -- hash (bcrypt)
        a.Tipo,
        a.Nome,
        a.Email,
        a.Ativo,
        a.UltimoAcesso
    FROM administrador a
    WHERE a.Usuario = p_Usuario
      AND a.Ativo = 1
    LIMIT 1;
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
        SUM(CASE 
            WHEN UPPER(p.StatusPagamento) = 'PAGO'
                 AND DATE(COALESCE(p.DataPagamento, a.DataFim, a.DataInicio)) BETWEEN p_DataInicio AND p_DataFim
            THEN 1 ELSE 0 END) AS QtdAtendimentos,
        SUM(CASE 
            WHEN UPPER(p.StatusPagamento) = 'PAGO'
                 AND DATE(COALESCE(p.DataPagamento, a.DataFim, a.DataInicio)) BETWEEN p_DataInicio AND p_DataFim
            THEN COALESCE(a.Valor, 0) ELSE 0 END) AS TotalReceitas,
        CASE 
            WHEN SUM(CASE 
                WHEN UPPER(p.StatusPagamento) = 'PAGO'
                     AND DATE(COALESCE(p.DataPagamento, a.DataFim, a.DataInicio)) BETWEEN p_DataInicio AND p_DataFim
                THEN 1 ELSE 0 END) > 0
            THEN SUM(CASE 
                    WHEN UPPER(p.StatusPagamento) = 'PAGO'
                         AND DATE(COALESCE(p.DataPagamento, a.DataFim, a.DataInicio)) BETWEEN p_DataInicio AND p_DataFim
                    THEN COALESCE(a.Valor, 0) ELSE 0 END) /
                 SUM(CASE 
                    WHEN UPPER(p.StatusPagamento) = 'PAGO'
                         AND DATE(COALESCE(p.DataPagamento, a.DataFim, a.DataInicio)) BETWEEN p_DataInicio AND p_DataFim
                    THEN 1 ELSE 0 END)
            ELSE 0
        END AS MediaAtendimento,
        SUM(CASE 
            WHEN UPPER(p.StatusPagamento) = 'PAGO'
                 AND DATE(COALESCE(p.DataPagamento, a.DataFim, a.DataInicio)) BETWEEN p_DataInicio AND p_DataFim
            THEN COALESCE(com.ValorTotal, 0) ELSE 0 END) AS TotalComissoes
    FROM cuidador c
    LEFT JOIN atendimento a ON c.IdCuidador = a.IdCuidador
    LEFT JOIN pagamento p ON a.IdAtendimento = p.IdAtendimento
    LEFT JOIN comissao com ON a.IdAtendimento = com.IdAtendimento
    GROUP BY c.IdCuidador, c.Nome
    ORDER BY TotalReceitas DESC, QtdAtendimentos DESC, c.Nome ASC
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

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_chat_arquivar` (IN `p_IdChat` INT, IN `p_IdAdministrador` INT)   BEGIN
    DECLARE v_Assunto VARCHAR(200);
    DECLARE v_Categoria VARCHAR(50);
    DECLARE v_Existe INT DEFAULT 0;
    
    -- Verificar se o chat existe e buscar dados
    SELECT 
        COUNT(*),
        Assunto,
        Categoria
    INTO 
        v_Existe,
        v_Assunto,
        v_Categoria
    FROM chat
    WHERE IdChat = p_IdChat;
    
    IF v_Existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Chat não encontrado';
    END IF;
    
    -- Registrar no histórico do administrador ANTES de arquivar
    INSERT INTO historicoadministrador (IdAdministrador, Operacao, DataOperacao)
    VALUES (
        p_IdAdministrador,
        CONCAT('Chat arquivado (ID: ', p_IdChat, ') - Categoria: ', IFNULL(v_Categoria, 'N/A'), 
               ' | Assunto: ', IFNULL(v_Assunto, 'N/A')),
        NOW()
    );
    
    -- Arquivar chat
    UPDATE chat 
    SET Status = 'Arquivado'
    WHERE IdChat = p_IdChat;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_chat_atualizar_status` (IN `p_IdChat` INT, IN `p_StatusSuporte` VARCHAR(20), IN `p_IdAdministrador` INT)   BEGIN
    DECLARE v_Assunto VARCHAR(200);
    DECLARE v_StatusAnterior VARCHAR(20);
    DECLARE v_Existe INT DEFAULT 0;
    
    -- Verificar se o ticket existe e buscar dados
    SELECT 
        COUNT(*),
        Assunto,
        StatusSuporte
    INTO 
        v_Existe,
        v_Assunto,
        v_StatusAnterior
    FROM chat
    WHERE IdChat = p_IdChat;
    
    IF v_Existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ticket não encontrado';
    END IF;
    
    -- Atualizar status
    UPDATE chat 
    SET StatusSuporte = p_StatusSuporte
    WHERE IdChat = p_IdChat;
    
    -- Registrar no histórico do administrador
    INSERT INTO historicoadministrador (IdAdministrador, Operacao, DataOperacao)
    VALUES (
        p_IdAdministrador,
        CONCAT('Status do ticket atualizado (ID: ', p_IdChat, ') - De "', 
               IFNULL(v_StatusAnterior, 'N/A'), '" para "', p_StatusSuporte, 
               '" | Assunto: ', IFNULL(v_Assunto, 'N/A')),
        NOW()
    );
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_chat_buscar_categorias` ()   BEGIN
    SELECT IdCategoria, Nome, Descricao, Ordem
    FROM categoriasuporte
    WHERE Ativa = TRUE
    ORDER BY Ordem ASC;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_chat_buscar_chat_por_id` (IN `p_IdChat` INT)   BEGIN
    SELECT 
        c.IdChat,
        c.IdCuidador,
        c.IdResponsavel,
        c.DataCriacao,
        c.Status,
        cu.Nome as NomeCuidador,
        cu.FotoUrl as FotoCuidador,
        r.Nome as NomeResponsavel,
        r.FotoUrl as FotoResponsavel
    FROM chat c
    LEFT JOIN cuidador cu ON c.IdCuidador = cu.IdCuidador
    LEFT JOIN responsavel r ON c.IdResponsavel = r.IdResponsavel
    WHERE c.IdChat = p_IdChat;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_chat_buscar_contatos_cuidador` (IN `p_IdCuidador` INT)   BEGIN
    SELECT DISTINCT
        r.IdResponsavel,
        r.Nome,
        r.FotoUrl,
        r.Email,
        r.Telefone
    FROM responsavel r
    INNER JOIN atendimento a ON r.IdResponsavel = a.IdResponsavel
    WHERE a.IdCuidador = p_IdCuidador AND a.Status IN ('Concluído', 'Em Andamento')
    ORDER BY r.Nome;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_chat_buscar_contatos_responsavel` (IN `p_IdResponsavel` INT)   BEGIN
    SELECT DISTINCT
        c.IdCuidador,
        c.Nome,
        c.FotoUrl,
        c.Email,
        c.Telefone
    FROM cuidador c
    INNER JOIN atendimento a ON c.IdCuidador = a.IdCuidador
    WHERE a.IdResponsavel = p_IdResponsavel AND a.Status IN ('Concluído', 'Em Andamento')
    ORDER BY c.Nome;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_chat_buscar_mensagens` (IN `p_IdChat` INT, IN `p_Limite` INT)   BEGIN
    SELECT 
        m.IdMensagem,
        m.IdRemetente,
        m.RemetenteTipo,
        m.Conteudo,
        m.DataEnvio,
        m.Lida,
        m.IsAdmin,
        m.TipoMensagem,
        CASE 
            WHEN m.IsAdmin = TRUE THEN 'Administrador'
            WHEN m.RemetenteTipo = 'cuidador' THEN c.Nome
            WHEN m.RemetenteTipo = 'responsavel' THEN r.Nome
            ELSE 'Usuário'
        END as NomeRemetente,
        CASE 
            WHEN m.IsAdmin = TRUE THEN NULL
            WHEN m.RemetenteTipo = 'cuidador' THEN c.FotoUrl
            WHEN m.RemetenteTipo = 'responsavel' THEN r.FotoUrl
            ELSE NULL
        END as FotoRemetente
    FROM mensagem m
    LEFT JOIN cuidador c ON m.IdRemetente = c.IdCuidador AND m.RemetenteTipo = 'cuidador'
    LEFT JOIN responsavel r ON m.IdRemetente = r.IdResponsavel AND m.RemetenteTipo = 'responsavel'
    WHERE m.IdChat = p_IdChat
    ORDER BY m.DataEnvio ASC
    LIMIT p_Limite;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_chat_buscar_por_id` (IN `p_IdChat` INT)   BEGIN
    SELECT 
        c.IdChat,
        c.Categoria,
        c.Prioridade,
        c.Assunto,
        c.StatusSuporte,
        c.DataCriacao,
        c.IdUsuario,
        c.TipoUsuario,
        CASE 
            WHEN c.TipoUsuario = 'cuidador' THEN cu.Nome
            WHEN c.TipoUsuario = 'responsavel' THEN r.Nome
            ELSE 'Usuário'
        END as NomeUsuario,
        CASE 
            WHEN c.TipoUsuario = 'cuidador' THEN cu.Email
            WHEN c.TipoUsuario = 'responsavel' THEN r.Email
            ELSE ''
        END as EmailUsuario,
        CASE 
            WHEN c.TipoUsuario = 'cuidador' THEN cu.Telefone
            WHEN c.TipoUsuario = 'responsavel' THEN r.Telefone
            ELSE ''
        END as TelefoneUsuario
    FROM chat c
    LEFT JOIN cuidador cu ON c.IdUsuario = cu.IdCuidador AND c.TipoUsuario = 'cuidador'
    LEFT JOIN responsavel r ON c.IdUsuario = r.IdResponsavel AND c.TipoUsuario = 'responsavel'
    WHERE c.IdChat = p_IdChat;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_chat_buscar_tickets_usuario` (IN `p_IdUsuario` INT, IN `p_TipoUsuario` VARCHAR(20))   BEGIN
    SELECT 
        c.IdChat,
        c.Categoria,
        c.Prioridade,
        c.Assunto,
        c.StatusSuporte,
        c.DataCriacao,
        (SELECT COUNT(*) FROM mensagem m 
         WHERE m.IdChat = c.IdChat AND m.Lida = 'Não' 
         AND m.IsAdmin = TRUE) as MensagensNaoLidas,
        (SELECT m.Conteudo FROM mensagem m 
         WHERE m.IdChat = c.IdChat 
         ORDER BY m.DataEnvio DESC LIMIT 1) as UltimaMensagem,
        (SELECT m.DataEnvio FROM mensagem m 
         WHERE m.IdChat = c.IdChat 
         ORDER BY m.DataEnvio DESC LIMIT 1) as DataUltimaMensagem
    FROM chat c
    WHERE c.IdUsuario = p_IdUsuario AND c.TipoUsuario = p_TipoUsuario AND c.Status = 'Ativo'
    ORDER BY c.DataCriacao DESC;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_chat_buscar_todos_tickets` (IN `p_StatusSuporte` VARCHAR(20), IN `p_Categoria` VARCHAR(50), IN `p_Prioridade` VARCHAR(20))   BEGIN
    SELECT 
        c.IdChat,
        c.Categoria,
        c.Prioridade,
        c.Assunto,
        c.StatusSuporte,
        c.DataCriacao,
        c.IdUsuario,
        c.TipoUsuario,
        CASE 
            WHEN c.TipoUsuario = 'cuidador' THEN cu.Nome
            WHEN c.TipoUsuario = 'responsavel' THEN r.Nome
            ELSE 'Usuário'
        END as NomeUsuario,
        CASE 
            WHEN c.TipoUsuario = 'cuidador' THEN cu.Email
            WHEN c.TipoUsuario = 'responsavel' THEN r.Email
            ELSE ''
        END as EmailUsuario,
        (SELECT COUNT(*) FROM mensagem m 
         WHERE m.IdChat = c.IdChat AND m.Lida = 'Não' 
         AND m.IsAdmin = FALSE) as MensagensNaoLidas,
        (SELECT m.Conteudo FROM mensagem m 
         WHERE m.IdChat = c.IdChat 
         ORDER BY m.DataEnvio DESC LIMIT 1) as UltimaMensagem,
        (SELECT m.DataEnvio FROM mensagem m 
         WHERE m.IdChat = c.IdChat 
         ORDER BY m.DataEnvio DESC LIMIT 1) as DataUltimaMensagem
    FROM chat c
    LEFT JOIN cuidador cu ON c.IdUsuario = cu.IdCuidador AND c.TipoUsuario = 'cuidador'
    LEFT JOIN responsavel r ON c.IdUsuario = r.IdResponsavel AND c.TipoUsuario = 'responsavel'
    WHERE c.Status = 'Ativo'
    AND (p_StatusSuporte IS NULL OR c.StatusSuporte = p_StatusSuporte)
    AND (p_Categoria IS NULL OR c.Categoria = p_Categoria)
    AND (p_Prioridade IS NULL OR c.Prioridade = p_Prioridade)
    ORDER BY c.DataCriacao DESC;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_chat_criar_ticket` (IN `p_IdUsuario` INT, IN `p_TipoUsuario` VARCHAR(20), IN `p_Categoria` VARCHAR(50), IN `p_Prioridade` VARCHAR(20), IN `p_Assunto` VARCHAR(200), IN `p_StatusSuporte` VARCHAR(20), IN `p_IdAdministrador` INT)   BEGIN
    DECLARE v_NomeUsuario VARCHAR(100);
    DECLARE v_IdChat INT;
    
    -- Buscar nome do usuário para o log
    IF p_TipoUsuario = 'cuidador' THEN
        SELECT Nome INTO v_NomeUsuario FROM cuidador WHERE IdCuidador = p_IdUsuario;
    ELSEIF p_TipoUsuario = 'responsavel' THEN
        SELECT Nome INTO v_NomeUsuario FROM responsavel WHERE IdResponsavel = p_IdUsuario;
    END IF;
    
    -- Inserir ticket
    INSERT INTO chat (IdUsuario, TipoUsuario, Categoria, Prioridade, Assunto, StatusSuporte, Status)
    VALUES (p_IdUsuario, p_TipoUsuario, p_Categoria, p_Prioridade, p_Assunto, p_StatusSuporte, 'Ativo');
    
    SET v_IdChat = LAST_INSERT_ID();
    
    -- Registrar no histórico do administrador
    INSERT INTO historicoadministrador (IdAdministrador, Operacao, DataOperacao)
    VALUES (
        p_IdAdministrador,
        CONCAT('Ticket de suporte criado (ID: ', v_IdChat, ') - Tipo: ', p_TipoUsuario, 
               ' | Categoria: ', p_Categoria, 
               ' | Prioridade: ', p_Prioridade, 
               ' | Usuário: ', IFNULL(v_NomeUsuario, 'N/A')),
        NOW()
    );
    
    SELECT v_IdChat AS Id;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_chat_enviar_mensagem` (IN `p_IdChat` INT, IN `p_IdRemetente` INT, IN `p_RemetenteTipo` VARCHAR(20), IN `p_Conteudo` TEXT, IN `p_IsAdmin` BOOLEAN, IN `p_TipoMensagem` VARCHAR(20), IN `p_IdAdministrador` INT)   BEGIN
    DECLARE v_NomeRemetente VARCHAR(100);
    DECLARE v_AssuntoTicket VARCHAR(200);
    DECLARE v_IdMensagem INT;
    
    -- Buscar informações para o log (se for admin)
    IF p_IsAdmin = TRUE THEN
        SELECT Assunto INTO v_AssuntoTicket FROM chat WHERE IdChat = p_IdChat;
        
        -- Registrar no histórico do administrador
        INSERT INTO historicoadministrador (IdAdministrador, Operacao, DataOperacao)
        VALUES (
            p_IdAdministrador,
            CONCAT('Mensagem enviada no ticket (ID: ', p_IdChat, ') - Assunto: ', IFNULL(v_AssuntoTicket, 'N/A')),
            NOW()
        );
    END IF;
    
    -- Inserir mensagem
    INSERT INTO mensagem (IdChat, IdRemetente, RemetenteTipo, Conteudo, Lida, IsAdmin, TipoMensagem)
    VALUES (p_IdChat, p_IdRemetente, p_RemetenteTipo, p_Conteudo, 'Não', p_IsAdmin, p_TipoMensagem);
    
    SET v_IdMensagem = LAST_INSERT_ID();
    
    SELECT v_IdMensagem AS Id;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_chat_estatisticas_cuidador` (IN `p_IdCuidador` INT)   BEGIN
    SELECT 
        COUNT(DISTINCT c.IdChat) as TotalChats,
        COUNT(DISTINCT c.IdResponsavel) as TotalContatos,
        (SELECT COUNT(*) FROM mensagem m 
         INNER JOIN chat ch ON m.IdChat = ch.IdChat 
         WHERE ch.IdCuidador = p_IdCuidador AND m.Lida = 'Não' 
         AND m.RemetenteTipo = 'responsavel') as MensagensNaoLidas
    FROM chat c
    WHERE c.IdCuidador = p_IdCuidador AND c.Status = 'Ativo';
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_chat_estatisticas_responsavel` (IN `p_IdResponsavel` INT)   BEGIN
    SELECT 
        COUNT(DISTINCT c.IdChat) as TotalChats,
        COUNT(DISTINCT c.IdCuidador) as TotalContatos,
        (SELECT COUNT(*) FROM mensagem m 
         INNER JOIN chat ch ON m.IdChat = ch.IdChat 
         WHERE ch.IdResponsavel = p_IdResponsavel AND m.Lida = 'Não' 
         AND m.RemetenteTipo = 'cuidador') as MensagensNaoLidas
    FROM chat c
    WHERE c.IdResponsavel = p_IdResponsavel AND c.Status = 'Ativo';
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_chat_estatisticas_suporte` ()   BEGIN
    SELECT 
        COUNT(*) as TotalTickets,
        SUM(CASE WHEN StatusSuporte = 'Aberto' THEN 1 ELSE 0 END) as TicketsAbertos,
        SUM(CASE WHEN StatusSuporte = 'Em Andamento' THEN 1 ELSE 0 END) as TicketsEmAndamento,
        SUM(CASE WHEN StatusSuporte = 'Fechado' THEN 1 ELSE 0 END) as TicketsFechados,
        SUM(CASE WHEN Prioridade = 'Alta' THEN 1 ELSE 0 END) as TicketsAltaPrioridade,
        SUM(CASE WHEN DataCriacao >= DATE_SUB(NOW(), INTERVAL 24 HOUR) THEN 1 ELSE 0 END) as TicketsUltimas24h
    FROM chat
    WHERE Status = 'Ativo';
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_chat_marcar_mensagens_lidas` (IN `p_IdChat` INT, IN `p_IdUsuario` INT, IN `p_TipoUsuario` VARCHAR(20))   BEGIN
    UPDATE mensagem 
    SET Lida = 'Sim'
    WHERE IdChat = p_IdChat AND IdRemetente != p_IdUsuario AND RemetenteTipo != p_TipoUsuario;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_criar_despesa` (IN `p_TipoDespesa` VARCHAR(100), IN `p_Categoria` VARCHAR(100), IN `p_Descricao` TEXT, IN `p_Valor` DECIMAL(10,2), IN `p_IdCuidador` INT, IN `p_Comprovante` VARCHAR(255), IN `p_Observacoes` TEXT, OUT `p_IdDespesa` INT, OUT `p_Mensagem` VARCHAR(255), OUT `p_Sucesso` BOOLEAN)   BEGIN
    DECLARE v_NomeCuidador VARCHAR(100);
    DECLARE v_DescricaoFinal TEXT;
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
    
    -- Combinar descrição e observações (tabela despesa não possui coluna Observacoes)
    SET v_DescricaoFinal = COALESCE(p_Descricao, '');
    IF p_Observacoes IS NOT NULL AND p_Observacoes <> '' THEN
        SET v_DescricaoFinal = CONCAT_WS('\n', v_DescricaoFinal, CONCAT('Observações: ', p_Observacoes));
    END IF;
    
    INSERT INTO despesa (TipoDespesa, Categoria, Descricao, Valor, DataDespesa, IdCuidador, Comprovante, Status)
    VALUES (p_TipoDespesa, p_Categoria, v_DescricaoFinal, p_Valor, NOW(), p_IdCuidador, p_Comprovante, 'Pago');
    
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

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_cuidador_atualizar` (IN `p_IdCuidador` INT, IN `p_IdEndereco` INT, IN `p_Cpf` VARCHAR(20), IN `p_Nome` VARCHAR(100), IN `p_Email` VARCHAR(100), IN `p_Telefone` VARCHAR(20), IN `p_Senha` VARCHAR(100), IN `p_DataNascimento` DATE, IN `p_FotoUrl` VARCHAR(255), IN `p_Biografia` TEXT, IN `p_Fumante` VARCHAR(3), IN `p_TemFilhos` VARCHAR(3), IN `p_PossuiCNH` VARCHAR(3), IN `p_TemCarro` VARCHAR(3), IN `p_IdAdministrador` INT)   BEGIN
    DECLARE v_NomeAnterior VARCHAR(100);
    DECLARE v_Existe INT DEFAULT 0;
    
    -- Verificar se o cuidador existe e buscar nome anterior
    SELECT COUNT(*), Nome
    INTO v_Existe, v_NomeAnterior
    FROM cuidador
    WHERE IdCuidador = p_IdCuidador;
    
    IF v_Existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cuidador não encontrado';
    END IF;
    
    -- Atualizar cuidador
    UPDATE cuidador 
    SET 
        IdEndereco = p_IdEndereco,
        Cpf = p_Cpf,
        Nome = p_Nome,
        Email = p_Email,
        Telefone = p_Telefone,
        Senha = p_Senha,
        DataNascimento = p_DataNascimento,
        FotoUrl = p_FotoUrl,
        Biografia = p_Biografia,
        Fumante = p_Fumante,
        TemFilhos = p_TemFilhos,
        PossuiCNH = p_PossuiCNH,
        TemCarro = p_TemCarro
    WHERE IdCuidador = p_IdCuidador;
    
    -- Registrar no histórico do administrador
    INSERT INTO historicoadministrador (IdAdministrador, Operacao, DataOperacao)
    VALUES (
        p_IdAdministrador,
        CONCAT('Cuidador atualizado (ID: ', p_IdCuidador, ') - Nome: ', IFNULL(v_NomeAnterior, 'N/A'), 
               ' para ', p_Nome, 
               ' | Email: ', IFNULL(p_Email, 'N/A'), ' | Telefone: ', IFNULL(p_Telefone, 'N/A')),
        NOW()
    );
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_cuidador_buscar_por_id` (IN `p_IdCuidador` INT)   BEGIN
    SELECT * FROM cuidador
    WHERE IdCuidador = p_IdCuidador;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_cuidador_criar` (IN `p_IdEndereco` INT, IN `p_Cpf` VARCHAR(20), IN `p_Nome` VARCHAR(100), IN `p_Email` VARCHAR(100), IN `p_Telefone` VARCHAR(20), IN `p_Senha` VARCHAR(100), IN `p_DataNascimento` DATE, IN `p_FotoUrl` VARCHAR(255), IN `p_Biografia` TEXT, IN `p_Fumante` VARCHAR(3), IN `p_TemFilhos` VARCHAR(3), IN `p_PossuiCNH` VARCHAR(3), IN `p_TemCarro` VARCHAR(3), IN `p_IdAdministrador` INT)   BEGIN
    DECLARE v_IdCuidador INT;
    
    -- Inserir cuidador
    INSERT INTO cuidador (
        IdEndereco, Cpf, Nome, Email, Telefone, Senha, DataNascimento, 
        FotoUrl, Biografia, Fumante, TemFilhos, PossuiCNH, TemCarro
    )
    VALUES (
        p_IdEndereco, p_Cpf, p_Nome, p_Email, p_Telefone, p_Senha, p_DataNascimento,
        p_FotoUrl, p_Biografia, p_Fumante, p_TemFilhos, p_PossuiCNH, p_TemCarro
    );
    
    SET v_IdCuidador = LAST_INSERT_ID();
    
    -- Registrar no histórico do administrador
    INSERT INTO historicoadministrador (IdAdministrador, Operacao, DataOperacao)
    VALUES (
        p_IdAdministrador,
        CONCAT('Cuidador criado (ID: ', v_IdCuidador, ') - Nome: ', p_Nome, 
               ' | Email: ', IFNULL(p_Email, 'N/A'), ' | CPF: ', IFNULL(p_Cpf, 'N/A')),
        NOW()
    );
    
    SELECT v_IdCuidador AS Id;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_cuidador_excluir` (IN `p_IdCuidador` INT, IN `p_IdAdministrador` INT)   BEGIN
    DECLARE v_Nome VARCHAR(100);
    DECLARE v_Email VARCHAR(100);
    DECLARE v_Existe INT DEFAULT 0;
    
    -- Verificar se o cuidador existe e buscar dados
    SELECT COUNT(*), Nome, Email
    INTO v_Existe, v_Nome, v_Email
    FROM cuidador
    WHERE IdCuidador = p_IdCuidador;
    
    IF v_Existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cuidador não encontrado';
    END IF;
    
    -- Registrar no histórico do administrador ANTES de excluir
    INSERT INTO historicoadministrador (IdAdministrador, Operacao, DataOperacao)
    VALUES (
        p_IdAdministrador,
        CONCAT('Cuidador excluído (ID: ', p_IdCuidador, ') - Nome: ', IFNULL(v_Nome, 'N/A'), 
               ' | Email: ', IFNULL(v_Email, 'N/A')),
        NOW()
    );
    
    -- Excluir dados relacionados aos atendimentos primeiro
    DELETE FROM avaliacao WHERE IdCuidador = p_IdCuidador;
    DELETE FROM comissao WHERE IdCuidador = p_IdCuidador;
    
    -- Excluir atendimentos (isto causará CASCADE para avaliações, pagamentos, receitas, histórico)
    DELETE FROM atendimento WHERE IdCuidador = p_IdCuidador;
    
    -- Excluir chats e mensagens relacionadas
    DELETE m FROM mensagem m
    INNER JOIN chat c ON m.IdChat = c.IdChat
    WHERE c.IdCuidador = p_IdCuidador;
    
    DELETE FROM chat WHERE IdCuidador = p_IdCuidador;
    
    -- Excluir dados auxiliares (muitos com CASCADE, mas por segurança)
    DELETE FROM cuidadorespecialidade WHERE IdCuidador = p_IdCuidador;
    DELETE FROM cuidadorservico WHERE IdCuidador = p_IdCuidador;
    DELETE FROM certificado WHERE IdCuidador = p_IdCuidador;
    DELETE FROM experiencia WHERE IdCuidador = p_IdCuidador;
    DELETE FROM formacao WHERE IdCuidador = p_IdCuidador;
    DELETE FROM disponibilidade WHERE IdCuidador = p_IdCuidador;
    DELETE FROM registroprofissional WHERE IdCuidador = p_IdCuidador;
    DELETE FROM historicocuidador WHERE IdCuidador = p_IdCuidador;
    DELETE FROM despesa WHERE IdCuidador = p_IdCuidador;
    
    -- Finalmente, excluir o cuidador
    DELETE FROM cuidador WHERE IdCuidador = p_IdCuidador;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_cuidador_listar` ()   BEGIN
    SELECT * FROM cuidador
    ORDER BY Nome;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_idoso_atualizar` (IN `p_IdIdoso` INT, IN `p_IdResponsavel` INT, IN `p_IdMobilidade` INT, IN `p_IdNivelAutonomia` INT, IN `p_Nome` VARCHAR(100), IN `p_DataNascimento` DATE, IN `p_Sexo` VARCHAR(20), IN `p_CuidadosMedicos` TEXT, IN `p_DescricaoExtra` TEXT, IN `p_FotoUrl` VARCHAR(255), IN `p_IdAdministrador` INT)   BEGIN
    DECLARE v_NomeAnterior VARCHAR(100);
    DECLARE v_Existe INT DEFAULT 0;
    
    -- Verificar se o idoso existe e buscar nome anterior
    SELECT COUNT(*), Nome
    INTO v_Existe, v_NomeAnterior
    FROM idoso
    WHERE IdIdoso = p_IdIdoso;
    
    IF v_Existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Idoso não encontrado';
    END IF;
    
    -- Atualizar idoso
    UPDATE idoso 
    SET 
        IdResponsavel = p_IdResponsavel,
        IdMobilidade = p_IdMobilidade,
        IdNivelAutonomia = p_IdNivelAutonomia,
        Nome = p_Nome,
        DataNascimento = p_DataNascimento,
        Sexo = p_Sexo,
        CuidadosMedicos = p_CuidadosMedicos,
        DescricaoExtra = p_DescricaoExtra,
        FotoUrl = p_FotoUrl
    WHERE IdIdoso = p_IdIdoso;
    
    -- Registrar no histórico do administrador
    INSERT INTO historicoadministrador (IdAdministrador, Operacao, DataOperacao)
    VALUES (
        p_IdAdministrador,
        CONCAT('Idoso atualizado (ID: ', p_IdIdoso, ') - Nome: ', IFNULL(v_NomeAnterior, 'N/A'), 
               ' para ', p_Nome, 
               ' | Responsável: ', IFNULL(p_IdResponsavel, 'N/A'), 
               ' | Sexo: ', IFNULL(p_Sexo, 'N/A')),
        NOW()
    );
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_idoso_buscar_por_id` (IN `p_IdIdoso` INT)   BEGIN
    SELECT * FROM idoso
    WHERE IdIdoso = p_IdIdoso;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_idoso_criar` (IN `p_IdResponsavel` INT, IN `p_IdMobilidade` INT, IN `p_IdNivelAutonomia` INT, IN `p_Nome` VARCHAR(100), IN `p_DataNascimento` DATE, IN `p_Sexo` VARCHAR(20), IN `p_CuidadosMedicos` TEXT, IN `p_DescricaoExtra` TEXT, IN `p_FotoUrl` VARCHAR(255), IN `p_IdAdministrador` INT)   BEGIN
    DECLARE v_IdIdoso INT;
    
    -- Inserir idoso
    INSERT INTO idoso (
        IdResponsavel, IdMobilidade, IdNivelAutonomia, Nome, DataNascimento, 
        Sexo, CuidadosMedicos, DescricaoExtra, FotoUrl
    )
    VALUES (
        p_IdResponsavel, p_IdMobilidade, p_IdNivelAutonomia, p_Nome, p_DataNascimento,
        p_Sexo, p_CuidadosMedicos, p_DescricaoExtra, p_FotoUrl
    );
    
    SET v_IdIdoso = LAST_INSERT_ID();
    
    -- Registrar no histórico do administrador
    INSERT INTO historicoadministrador (IdAdministrador, Operacao, DataOperacao)
    VALUES (
        p_IdAdministrador,
        CONCAT('Idoso criado (ID: ', v_IdIdoso, ') - Nome: ', p_Nome, 
               ' | Responsável: ', IFNULL(p_IdResponsavel, 'N/A'), 
               ' | Sexo: ', IFNULL(p_Sexo, 'N/A')),
        NOW()
    );
    
    SELECT v_IdIdoso AS Id;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_idoso_excluir` (IN `p_IdIdoso` INT, IN `p_IdAdministrador` INT)   BEGIN
    DECLARE v_Nome VARCHAR(100);
    DECLARE v_NomeResponsavel VARCHAR(100);
    DECLARE v_Existe INT DEFAULT 0;
    
    -- Verificar se o idoso existe e buscar dados
    SELECT 
        COUNT(*), 
        i.Nome,
        r.Nome
    INTO 
        v_Existe, 
        v_Nome,
        v_NomeResponsavel
    FROM idoso i
    LEFT JOIN responsavel r ON i.IdResponsavel = r.IdResponsavel
    WHERE i.IdIdoso = p_IdIdoso;
    
    IF v_Existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Idoso não encontrado';
    END IF;
    
    -- Registrar no histórico do administrador ANTES de excluir
    INSERT INTO historicoadministrador (IdAdministrador, Operacao, DataOperacao)
    VALUES (
        p_IdAdministrador,
        CONCAT('Idoso excluído (ID: ', p_IdIdoso, ') - Nome: ', IFNULL(v_Nome, 'N/A'), 
               ' | Responsável: ', IFNULL(v_NomeResponsavel, 'N/A')),
        NOW()
    );
    
    -- Excluir doenças e restrições alimentares do idoso
    DELETE FROM idosodoenca WHERE IdIdoso = p_IdIdoso;
    DELETE FROM idosorestricaoalimentar WHERE IdIdoso = p_IdIdoso;
    
    -- Excluir atendimentos (isso causará CASCADE para avaliações, pagamentos, receitas, histórico)
    DELETE FROM atendimento WHERE IdIdoso = p_IdIdoso;
    
    -- Finalmente, excluir o idoso
    DELETE FROM idoso WHERE IdIdoso = p_IdIdoso;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_idoso_listar` ()   BEGIN
    SELECT * FROM idoso
    ORDER BY Nome;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_idoso_listar_mobilidades` ()   BEGIN
    SELECT * FROM mobilidade ORDER BY Descricao;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_idoso_listar_niveis_autonomia` ()   BEGIN
    SELECT * FROM nivelautonomia ORDER BY Descricao;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_idoso_listar_responsaveis` ()   BEGIN
    SELECT IdResponsavel, Nome FROM responsavel ORDER BY Nome;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_pagamento_atualizar` (IN `p_IdPagamento` INT, IN `p_MetodoPagamento` VARCHAR(20), IN `p_StatusPagamento` VARCHAR(20), IN `p_CodigoTransacao` VARCHAR(255))   BEGIN
    UPDATE pagamento 
    SET MetodoPagamento = p_MetodoPagamento,
        StatusPagamento = p_StatusPagamento,
        CodigoTransacao = p_CodigoTransacao
    WHERE IdPagamento = p_IdPagamento;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_pagamento_buscar_por_id` (IN `p_IdPagamento` INT)   BEGIN
    SELECT 
        p.IdPagamento,
        p.IdAtendimento,
        p.MetodoPagamento,
        p.StatusPagamento,
        p.DataPagamento,
        p.CodigoTransacao,
        r.Nome as NomeResponsavel,
        r.Email as EmailResponsavel,
        r.Telefone as TelefoneResponsavel,
        c.Nome as NomeCuidador,
        c.Email as EmailCuidador,
        i.Nome as NomeIdoso,
        a.DataInicio,
        a.DataFim,
        a.Valor,
        a.Status as StatusAtendimento
    FROM pagamento p
    INNER JOIN atendimento a ON p.IdAtendimento = a.IdAtendimento
    INNER JOIN responsavel r ON a.IdResponsavel = r.IdResponsavel
    INNER JOIN cuidador c ON a.IdCuidador = c.IdCuidador
    INNER JOIN idoso i ON a.IdIdoso = i.IdIdoso
    WHERE p.IdPagamento = p_IdPagamento
    LIMIT 1;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_pagamento_buscar_por_responsavel` (IN `p_IdResponsavel` INT)   BEGIN
    SELECT 
        p.IdPagamento,
        p.IdAtendimento,
        p.MetodoPagamento,
        p.StatusPagamento,
        p.DataPagamento,
        p.CodigoTransacao,
        r.Nome as NomeResponsavel,
        r.Email as EmailResponsavel,
        r.Telefone as TelefoneResponsavel,
        c.Nome as NomeCuidador,
        c.Email as EmailCuidador,
        i.Nome as NomeIdoso,
        a.DataInicio,
        a.DataFim,
        a.Valor,
        a.Status as StatusAtendimento
    FROM pagamento p
    INNER JOIN atendimento a ON p.IdAtendimento = a.IdAtendimento
    INNER JOIN responsavel r ON a.IdResponsavel = r.IdResponsavel
    INNER JOIN cuidador c ON a.IdCuidador = c.IdCuidador
    INNER JOIN idoso i ON a.IdIdoso = i.IdIdoso
    WHERE a.IdResponsavel = p_IdResponsavel
    ORDER BY p.DataPagamento DESC;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_pagamento_buscar_por_status` (IN `p_Status` VARCHAR(20))   BEGIN
    SELECT 
        p.IdPagamento,
        p.IdAtendimento,
        p.MetodoPagamento,
        p.StatusPagamento,
        p.DataPagamento,
        p.CodigoTransacao,
        r.Nome as NomeResponsavel,
        r.Email as EmailResponsavel,
        r.Telefone as TelefoneResponsavel,
        c.Nome as NomeCuidador,
        c.Email as EmailCuidador,
        i.Nome as NomeIdoso,
        a.DataInicio,
        a.DataFim,
        a.Valor,
        a.Status as StatusAtendimento
    FROM pagamento p
    INNER JOIN atendimento a ON p.IdAtendimento = a.IdAtendimento
    INNER JOIN responsavel r ON a.IdResponsavel = r.IdResponsavel
    INNER JOIN cuidador c ON a.IdCuidador = c.IdCuidador
    INNER JOIN idoso i ON a.IdIdoso = i.IdIdoso
    WHERE p.StatusPagamento = p_Status
    ORDER BY p.DataPagamento DESC;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_pagamento_criar` (IN `p_IdAtendimento` INT, IN `p_MetodoPagamento` VARCHAR(20), IN `p_StatusPagamento` VARCHAR(20), IN `p_CodigoTransacao` VARCHAR(255))   BEGIN
    INSERT INTO pagamento (IdAtendimento, MetodoPagamento, StatusPagamento, CodigoTransacao)
    VALUES (p_IdAtendimento, p_MetodoPagamento, p_StatusPagamento, p_CodigoTransacao);
    SELECT LAST_INSERT_ID() AS Id;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_pagamento_criar_automatico` (IN `p_IdAtendimento` INT)   BEGIN
    DECLARE v_IdPagamento INT;
    DECLARE v_Existe INT DEFAULT 0;
    DECLARE v_StatusAtendimento VARCHAR(20);
    DECLARE v_CodigoTransacao VARCHAR(255);
    
    -- Verificar se já existe pagamento para este atendimento
    SELECT COUNT(*)
    INTO v_Existe
    FROM pagamento
    WHERE IdAtendimento = p_IdAtendimento;
    
    IF v_Existe > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pagamento já existe para este atendimento';
    END IF;
    
    -- Buscar status do atendimento
    SELECT Status
    INTO v_StatusAtendimento
    FROM atendimento
    WHERE IdAtendimento = p_IdAtendimento;
    
    IF v_StatusAtendimento IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Atendimento não encontrado';
    END IF;
    
    IF v_StatusAtendimento != 'Concluído' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Atendimento não está concluído';
    END IF;
    
    -- Gerar código de transação automático
    SET v_CodigoTransacao = CONCAT('AUTO-', p_IdAtendimento, '-', UNIX_TIMESTAMP(NOW()));
    
    -- Criar pagamento
    INSERT INTO pagamento (IdAtendimento, MetodoPagamento, StatusPagamento, DataPagamento, CodigoTransacao)
    VALUES (p_IdAtendimento, 'Dinheiro', 'Pago', NOW(), v_CodigoTransacao);
    
    SET v_IdPagamento = LAST_INSERT_ID();
    
    SELECT v_IdPagamento AS Id;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_pagamento_excluir` (IN `p_IdPagamento` INT)   BEGIN
    DELETE FROM pagamento WHERE IdPagamento = p_IdPagamento;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_pagamento_listar` ()   BEGIN
    SELECT 
        p.IdPagamento,
        p.IdAtendimento,
        p.MetodoPagamento,
        p.StatusPagamento,
        p.DataPagamento,
        p.CodigoTransacao,
        r.Nome as NomeResponsavel,
        r.Email as EmailResponsavel,
        r.Telefone as TelefoneResponsavel,
        c.Nome as NomeCuidador,
        c.Email as EmailCuidador,
        i.Nome as NomeIdoso,
        a.DataInicio,
        a.DataFim,
        a.Valor,
        a.Status as StatusAtendimento
    FROM pagamento p
    INNER JOIN atendimento a ON p.IdAtendimento = a.IdAtendimento
    INNER JOIN responsavel r ON a.IdResponsavel = r.IdResponsavel
    INNER JOIN cuidador c ON a.IdCuidador = c.IdCuidador
    INNER JOIN idoso i ON a.IdIdoso = i.IdIdoso
    ORDER BY p.DataPagamento DESC;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_registrar_login_admin` (IN `p_IdAdministrador` INT)   BEGIN
    UPDATE administrador
    SET UltimoAcesso = NOW()
    WHERE IdAdministrador = p_IdAdministrador;

    INSERT INTO historicoadministrador (IdAdministrador, Operacao, DataOperacao)
    VALUES (p_IdAdministrador, 'Login', NOW());
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_responsavel_atualizar` (IN `p_IdResponsavel` INT, IN `p_IdEndereco` INT, IN `p_Cpf` VARCHAR(20), IN `p_Nome` VARCHAR(100), IN `p_Email` VARCHAR(100), IN `p_Telefone` VARCHAR(20), IN `p_DataNascimento` DATE, IN `p_FotoUrl` VARCHAR(255), IN `p_IdAdministrador` INT)   BEGIN
    DECLARE v_NomeAnterior VARCHAR(100);
    DECLARE v_Existe INT DEFAULT 0;
    
    -- Verificar se o responsável existe e buscar nome anterior
    SELECT COUNT(*), Nome
    INTO v_Existe, v_NomeAnterior
    FROM responsavel
    WHERE IdResponsavel = p_IdResponsavel;
    
    IF v_Existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Responsável não encontrado';
    END IF;
    
    UPDATE responsavel
    SET 
        IdEndereco = p_IdEndereco,
        Cpf = p_Cpf,
        Nome = p_Nome,
        Email = p_Email,
        Telefone = p_Telefone,
        DataNascimento = p_DataNascimento,
        FotoUrl = p_FotoUrl
    WHERE IdResponsavel = p_IdResponsavel;
    
    -- Registrar no histórico do administrador
    INSERT INTO historicoadministrador (IdAdministrador, Operacao, DataOperacao)
    VALUES (
        p_IdAdministrador,
        CONCAT('Responsável atualizado (ID: ', p_IdResponsavel, ') - Nome: ', IFNULL(v_NomeAnterior, 'N/A'), 
               ' para ', p_Nome, 
               ' | Email: ', IFNULL(p_Email, 'N/A'), ' | Telefone: ', IFNULL(p_Telefone, 'N/A')),
        NOW()
    );
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_responsavel_criar` (IN `p_IdEndereco` INT, IN `p_Cpf` VARCHAR(20), IN `p_Nome` VARCHAR(100), IN `p_Email` VARCHAR(100), IN `p_Telefone` VARCHAR(20), IN `p_DataNascimento` DATE, IN `p_FotoUrl` VARCHAR(255), IN `p_IdAdministrador` INT)   BEGIN
    DECLARE v_IdResponsavel INT;
    
    INSERT INTO responsavel (IdEndereco, Cpf, Nome, Email, Telefone, DataNascimento, FotoUrl)
    VALUES (p_IdEndereco, p_Cpf, p_Nome, p_Email, p_Telefone, p_DataNascimento, p_FotoUrl);

    SET v_IdResponsavel = LAST_INSERT_ID();
    
    -- Registrar no histórico do administrador
    INSERT INTO historicoadministrador (IdAdministrador, Operacao, DataOperacao)
    VALUES (
        p_IdAdministrador,
        CONCAT('Responsável criado (ID: ', v_IdResponsavel, ') - Nome: ', p_Nome, 
               ' | Email: ', IFNULL(p_Email, 'N/A'), ' | CPF: ', IFNULL(p_Cpf, 'N/A')),
        NOW()
    );

    SELECT v_IdResponsavel AS Id;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_responsavel_excluir` (IN `p_IdResponsavel` INT, IN `p_IdAdministrador` INT)   BEGIN
    DECLARE v_Nome VARCHAR(100);
    DECLARE v_Email VARCHAR(100);
    DECLARE v_Existe INT DEFAULT 0;

    -- Verificar se o responsável existe e buscar dados
    SELECT COUNT(*), Nome, Email
    INTO v_Existe, v_Nome, v_Email
    FROM responsavel
    WHERE IdResponsavel = p_IdResponsavel;

    IF v_Existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Responsável não encontrado';
    END IF;

    -- Registrar no histórico do administrador ANTES de excluir
    INSERT INTO historicoadministrador (IdAdministrador, Operacao, DataOperacao)
    VALUES (
        p_IdAdministrador,
        CONCAT('Responsável excluído (ID: ', p_IdResponsavel, ') - Nome: ', IFNULL(v_Nome, 'N/A'),
               ' | Email: ', IFNULL(v_Email, 'N/A')),
        NOW()
    );

    -- Excluir avaliações diretamente vinculadas ao responsável
    DELETE FROM avaliacao
    WHERE IdResponsavel = p_IdResponsavel;

    -- Excluir avaliações e registros financeiros dos atendimentos deste responsável
    DELETE FROM avaliacao
    WHERE IdAtendimento IN (
        SELECT IdAtendimento FROM (
            SELECT IdAtendimento FROM atendimento WHERE IdResponsavel = p_IdResponsavel
        ) AS tmp_avaliacao
    );

    DELETE FROM comissao
    WHERE IdAtendimento IN (
        SELECT IdAtendimento FROM (
            SELECT IdAtendimento FROM atendimento WHERE IdResponsavel = p_IdResponsavel
        ) AS tmp_comissao
    );

    DELETE FROM pagamento
    WHERE IdAtendimento IN (
        SELECT IdAtendimento FROM (
            SELECT IdAtendimento FROM atendimento WHERE IdResponsavel = p_IdResponsavel
        ) AS tmp_pagamento
    );

    DELETE FROM receita
    WHERE IdAtendimento IN (
        SELECT IdAtendimento FROM (
            SELECT IdAtendimento FROM atendimento WHERE IdResponsavel = p_IdResponsavel
        ) AS tmp_receita
    );

    DELETE FROM historicoatendimento
    WHERE IdAtendimento IN (
        SELECT IdAtendimento FROM (
            SELECT IdAtendimento FROM atendimento WHERE IdResponsavel = p_IdResponsavel
        ) AS tmp_hist_atendimento
    );

    -- Excluir atendimentos do responsável
    DELETE FROM atendimento WHERE IdResponsavel = p_IdResponsavel;

    -- Excluir vínculos e dados de idosos ligados ao responsável
    DELETE FROM idosodoenca
    WHERE IdIdoso IN (
        SELECT IdIdoso FROM (
            SELECT IdIdoso FROM idoso WHERE IdResponsavel = p_IdResponsavel
        ) AS tmp_idoso_doenca
    );

    DELETE FROM idosorestricaoalimentar
    WHERE IdIdoso IN (
        SELECT IdIdoso FROM (
            SELECT IdIdoso FROM idoso WHERE IdResponsavel = p_IdResponsavel
        ) AS tmp_idoso_restricao
    );

    DELETE FROM idoso WHERE IdResponsavel = p_IdResponsavel;

    -- Excluir histórico específico do responsável
    DELETE FROM historicoresponsavel WHERE IdResponsavel = p_IdResponsavel;

    -- Excluir mensagens e chats associados ao responsável (caso não haja CASCADE)
    DELETE m FROM mensagem m
    INNER JOIN chat c ON m.IdChat = c.IdChat
    WHERE c.IdResponsavel = p_IdResponsavel;

    DELETE FROM chat WHERE IdResponsavel = p_IdResponsavel;

    -- Finalmente, excluir o responsável
    DELETE FROM responsavel WHERE IdResponsavel = p_IdResponsavel;
END$$

CREATE DEFINER=`cogitare`@`%` PROCEDURE `sp_responsavel_listar` ()   BEGIN
    SELECT 
        IdResponsavel, IdEndereco, Cpf, Nome, Email, Telefone, DataNascimento, FotoUrl 
    FROM responsavel
    ORDER BY Nome;
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
(1, 'admin', '$2b$10$E4iPvOcs5u5ArXQu/UroaelhW58CuzI85xAEDVaEhqb9QCuTeUh1S', 'Administrador', 'Administrador', 'admin@cogitare.com', 1, '2026-03-03 14:40:30', '2025-09-18 14:56:27');

-- --------------------------------------------------------

--
-- Table structure for table `assinaturacuidador`
--

CREATE TABLE `assinaturacuidador` (
  `IdAssinatura` int(11) NOT NULL,
  `IdCuidador` int(11) NOT NULL,
  `IdPlano` int(11) NOT NULL,
  `Status` varchar(20) NOT NULL DEFAULT 'Ativa',
  `DataInicio` datetime DEFAULT current_timestamp(),
  `DataFim` datetime DEFAULT NULL,
  `ContatosUsados` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
  `TemCarro` varchar(3) DEFAULT 'Não',
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `cuidador`
--

INSERT INTO `cuidador` (`IdCuidador`, `IdEndereco`, `Cpf`, `Nome`, `Email`, `Telefone`, `Senha`, `DataNascimento`, `FotoUrl`, `Biografia`, `Fumante`, `TemFilhos`, `PossuiCNH`, `TemCarro`) VALUES
(2, 2, NULL, 'Fernanda Lima', 'fernanda.lima@email.com', '(11) 88888-2222', NULL, '1990-07-12', '/avatar/cuidador.png', 'Especialista em cuidados com idosos.', 'Não', 'Sim', 'Sim', 'Não', NULL),
(3, 3, '999.000.111-22', 'Roberto Alves', 'roberto.alves@email.com', '(11) 88888-3333', '$2b$10$example', '1988-11-30', '/avatar/cuidador.png', 'Enfermeiro com especialização em geriatria', 'Não', 'Sim', 'Sim', 'Sim', NULL),
(4, 12, '11122233344', 'Lucia Mendes', 'lucia.mendes@email.com', '(11) 88888-4444', '$2b$10$example', '1983-06-20', '/avatar/cuidador.png', 'Enfermeira com 8 anos de experiência em cuidados geriátricos', 'Não', 'Sim', 'Sim', 'Sim', NULL),
(5, 13, '22233344455', 'Paulo Roberto', 'paulo.roberto@email.com', '(11) 88888-5555', '$2b$10$example', '1987-01-15', '/avatar/cuidador.png', 'Fisioterapeuta especializado em reabilitação de idosos', 'Não', 'Não', 'Sim', 'Não', NULL),
(6, 14, '33344455566', 'Cristina Santos', 'cristina.santos@email.com', '(11) 88888-6666', '$2b$10$example', '1981-11-08', '/avatar/cuidador.png', 'Psicóloga com experiência em demência e Alzheimer', 'Não', 'Sim', 'Sim', 'Sim', NULL),
(14, 31, '48290020856', 'julio', 'juliofranciscobernardino@gmail.com', '11996556155', '$2a$10$qp91ZIn1.479x6I3zGEBduPOH.A7ssIMc4cdWR6/Xllm0Q3LxWfMC', '2000-10-27', NULL, 'Formado na USCS', 'Não', 'Não', 'Sim', 'Sim', NULL),
(17, 43, '628.957.600-39', 'Suellen', 'suellen@gmail.com', '11996556155', '$2a$10$ZVTCFoICEGfk08tBfw7vjuow2s5Y5Yt3fwJ82QFEzZv5QQG8to2J.', '2000-11-30', NULL, 'Formada na USCS', 'Não', 'Sim', 'Sim', 'Sim', 100.00),
(18, 45, '020.070.490-74', 'roberto', 'roberto@gmail.com', '11996556155', '$2a$10$NDGaLsUP7eqk0hXVVx8qX.hp8rGd71.LM.aLA5bxI2IPJ0NKvaam2', '2000-11-30', NULL, 'Formado na USCS', 'Não', 'Sim', 'Sim', 'Sim', 100.00);

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
(3, 2, 1),
(4, 2, 3),
(5, 3, 2),
(6, 3, 4),
(7, 14, 1),
(8, 14, 2),
(10, 17, 1),
(11, 18, 1);

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
(3, 2, 2),
(4, 2, 3),
(5, 3, 1),
(6, 3, 4),
(7, 14, 3),
(8, 14, 4),
(10, 17, 1),
(11, 18, 1);

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
  `DataInicio` time DEFAULT NULL,
  `DataFim` time DEFAULT NULL,
  `Observacoes` text DEFAULT NULL,
  `Recorrente` tinyint(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `disponibilidade`
--

INSERT INTO `disponibilidade` (`IdDisponibilidade`, `IdCuidador`, `DiaSemana`, `DataInicio`, `DataFim`, `Observacoes`, `Recorrente`) VALUES
(6, 2, 'Segunda', '06:00:00', '22:00:00', 'Horário estendido', 1),
(7, 2, 'Terça', '06:00:00', '22:00:00', 'Horário estendido', 1),
(8, 2, 'Quarta', '06:00:00', '22:00:00', 'Horário estendido', 1),
(9, 2, 'Quinta', '06:00:00', '22:00:00', 'Horário estendido', 1),
(10, 2, 'Sexta', '06:00:00', '22:00:00', 'Horário estendido', 1),
(11, 2, 'Sábado', '06:00:00', '22:00:00', 'Horário estendido', 1),
(12, 3, 'Segunda', '00:00:00', '23:59:00', 'Disponível 24h', 1),
(13, 3, 'Terça', '00:00:00', '23:59:00', 'Disponível 24h', 1),
(14, 3, 'Quarta', '00:00:00', '23:59:00', 'Disponível 24h', 1),
(15, 3, 'Quinta', '00:00:00', '23:59:00', 'Disponível 24h', 1),
(16, 3, 'Sexta', '00:00:00', '23:59:00', 'Disponível 24h', 1),
(17, 3, 'Sábado', '00:00:00', '23:59:00', 'Disponível 24h', 1),
(18, 3, 'Domingo', '00:00:00', '23:59:00', 'Disponível 24h', 1),
(19, 4, 'Segunda', '07:00:00', '19:00:00', 'Horário comercial', 1),
(20, 4, 'Terça', '07:00:00', '19:00:00', 'Horário comercial', 1),
(21, 4, 'Quarta', '07:00:00', '19:00:00', 'Horário comercial', 1),
(22, 4, 'Quinta', '07:00:00', '19:00:00', 'Horário comercial', 1),
(23, 4, 'Sexta', '07:00:00', '19:00:00', 'Horário comercial', 1),
(24, 5, 'Segunda', '09:00:00', '17:00:00', 'Horário comercial', 1),
(25, 5, 'Terça', '09:00:00', '17:00:00', 'Horário comercial', 1),
(26, 5, 'Quarta', '09:00:00', '17:00:00', 'Horário comercial', 1),
(27, 5, 'Quinta', '09:00:00', '17:00:00', 'Horário comercial', 1),
(28, 5, 'Sexta', '09:00:00', '17:00:00', 'Horário comercial', 1),
(29, 6, 'Segunda', '08:00:00', '20:00:00', 'Horário estendido', 1),
(30, 6, 'Terça', '08:00:00', '20:00:00', 'Horário estendido', 1),
(31, 6, 'Quarta', '08:00:00', '20:00:00', 'Horário estendido', 1),
(32, 6, 'Quinta', '08:00:00', '20:00:00', 'Horário estendido', 1),
(33, 6, 'Sexta', '08:00:00', '20:00:00', 'Horário estendido', 1),
(34, 14, 'Segunda', '06:00:00', '16:00:00', 'Disponível das 6 às 16', 1),
(35, 14, 'Terça', '06:00:00', '16:00:00', 'Disponível das 6 às 16', 1),
(36, 14, 'Sábado', '06:00:00', '22:00:00', 'Disponível das 6 às 22', 1),
(38, 17, 'Terça', '06:00:00', '19:00:00', 'Disponível das 6 às 19', 1),
(39, 18, 'Segunda', '06:00:00', '23:00:00', 'Disponível das 6 às 23', 1);

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
(25, 'Mauá', 'Vila Falchi', 'Rua Orlando Tasca', '277', 'Apto 26C', '09350276'),
(26, 'Mauá', 'Vila Falchi', NULL, '277', 'APTO 26C', '09350276'),
(27, 'Mauá', 'Vila Falchi', 'Rua Orlando Tasca', '277', 'APTO 26C', '09350276'),
(28, 'Maua', 'Vila Falchi', 'Rua Orlando Tasca', '277', 'APTO 26C', '09350276'),
(29, 'Mauá', 'Vila Falchi', 'Rua Orlando Tasca', '277', 'APTO 26C', '09350276'),
(30, 'mauá', 'vila falchi', 'rua orlando tasca', '277', 'apto 26c', '09350276'),
(31, 'maua', 'vila falchi', 'rua orlando tasca', '277', 'apto 26c', '09350276'),
(32, 'Maua', 'Vila falchi', 'Rua Orlando Tasca', '277', NULL, '09350276'),
(33, 'Maua', 'Vila falchi', 'Rua Orlando Tasca', '277', NULL, '09350276'),
(34, 'Maua', 'Vila Falchi', 'Rua Orlando Tasca', '277', NULL, '09350276'),
(35, 'Maua', 'Vila Bocaina', 'Rua Orlando Tasca', '277', NULL, '09350276'),
(36, 'Mua', 'Vila Falchi', 'Rua Orlando Tasca', '266', 'jfdksjk', '09350276'),
(37, 'Mua', 'Vila Falchi', 'Rua Orlando Tasca', '266', 'jfdksjk', '09350276'),
(38, 'Maua', 'Vila Falchi', 'Rua Orlando Tasca', '277', NULL, '09350276'),
(39, 'Maua', 'Vila Falchi', 'Rua Orlando Tasca', '277', '26C', '09350276'),
(40, 'Maua', 'Vila Falchi', 'Rua Orlando Tasca', '277', NULL, '09350276'),
(41, 'Maua', 'Vila Falchi', 'Rua Orlando Tasca', '277', NULL, '09350276'),
(42, 'Carapicuiba', 'Jardim Carapicuiba', 'Rua Sao Carlos', '69', NULL, '06322-200'),
(43, 'maua', 'vila falchi', 'rua orlando tasca', '277', 'apto 26C', '09350276'),
(44, 'maua', 'vila bocaina', 'rua dos bandeirantes', '813', 'A', '09350276'),
(45, 'maua', 'parque sao vicente', 'rua mafalda russi pedro', '23', 'casa', '09270272'),
(46, 'São Caetano do Sul', 'Oswaldo Cruz', 'Rua Castro Alves', '123', 'casa 1', '09570400'),
(47, 'são caetano do sul', 'oswaldo cruz', 'rua castro alves', '123', 'casa', '09578450'),
(48, 'Santo Andre', 'Centro', 'Rua Teste', '123', NULL, '09000000'),
(49, 'são caetano do sul', 'são paulo', 'são paulo', '123', '123', '09587500');

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
(334, 1, 'Login', '2025-10-20 15:17:18'),
(335, 1, 'Login', '2025-10-24 21:11:20'),
(336, 1, 'Login', '2025-10-24 21:16:53'),
(337, 1, 'Login', '2025-10-30 16:08:51'),
(338, 1, 'Login', '2025-11-02 19:37:08'),
(339, 1, 'Login', '2025-11-02 19:41:59'),
(340, 1, 'Login', '2025-11-05 13:01:45'),
(341, 1, 'Login', '2025-11-05 13:34:24'),
(342, 1, 'Login', '2025-11-07 12:03:55'),
(343, 1, 'Cuidador excluído (ID: 15) - Nome: N/A | Email: N/A', '2025-11-07 12:04:24'),
(344, 1, 'Responsável excluído (ID: 16) - Nome: Usuario Teste | Email: usuario.teste@email.com', '2025-11-07 12:04:40'),
(345, 1, 'Login', '2025-11-07 12:11:20'),
(346, 1, 'Login', '2025-11-07 12:11:21'),
(347, 1, 'Responsável excluído (ID: 16) - Nome: Usuario Teste | Email: usuario.teste@email.com', '2025-11-07 12:11:33'),
(348, 1, 'Idoso excluído (ID: 20) - Nome: asddsasads | Responsável: dsadfsfdsffds', '2025-11-07 12:12:00'),
(349, 1, 'Login', '2025-11-07 12:24:14'),
(350, 1, 'Cuidador atualizado (ID: 1) - Nome: Carlos Oliveira para Carlos Oliveira 1 | Email: carlos.oliveira@email.com | Telefone: (11) 88888-1112', '2025-11-07 12:24:52'),
(351, 1, 'Login', '2025-11-07 12:58:14'),
(352, 1, 'Cuidador excluído (ID: 16) - Nome: jkdfjkfh | Email: testetesteteste@gmail.com', '2025-11-07 12:59:40'),
(353, 1, 'Responsável excluído (ID: 17) - Nome: JULIO TEST  | Email: testtest@gmail.com', '2025-11-07 12:59:53'),
(354, 1, 'Idoso excluído (ID: 19) - Nome: asdasdassrthgsrteaa | Responsável: asddasdasasd', '2025-11-07 13:00:04'),
(355, 1, 'Atendimento excluído (ID: 12) - Responsável: Ana Carolina Santos | Cuidador: Lucia Mendes | Idoso: Dona Maria | Status: Concluído | Valor: R$ 200,00', '2025-11-07 13:00:13'),
(356, 1, 'Avaliação excluída (ID: 1) - Nota: 5 | Responsável: Ana Carolina Santos | Cuidador: Lucia Mendes', '2025-11-07 13:00:43'),
(357, 1, 'Avaliação atualizada (ID: 3) - Nota alterada de 5 para 5 | Responsável: Mariana Costa | Cuidador: Cristina Santos', '2025-11-07 13:00:53'),
(358, 1, 'Login', '2025-11-07 13:11:03'),
(359, 1, 'Login', '2025-11-07 13:11:04'),
(360, 1, 'Login', '2025-11-07 13:21:00'),
(361, 1, 'Login', '2025-11-07 13:25:22'),
(362, 1, 'Login', '2025-11-07 13:28:09'),
(363, 1, 'Login', '2025-11-07 13:28:10'),
(364, 1, 'Login', '2025-11-07 13:30:00'),
(365, 1, 'Login', '2025-11-07 13:46:15'),
(366, 1, 'Login', '2025-11-07 13:46:15'),
(367, 1, 'Despesa R$ 500,00 criada - sdfsfSF (Cuidador: Fernanda Lima)', '2025-11-07 13:46:32'),
(368, 1, 'Login', '2025-11-07 14:02:45'),
(369, 1, 'Login', '2025-11-07 14:23:03'),
(370, 1, 'Login', '2025-11-07 14:26:55'),
(371, 1, 'Login', '2025-11-07 14:30:20'),
(372, 1, 'Login', '2025-11-07 14:41:40'),
(373, 1, 'Login', '2025-11-07 14:45:51'),
(374, 1, 'Login', '2025-11-07 14:45:51'),
(375, 1, 'Login', '2025-11-07 14:47:36'),
(376, 1, 'Login', '2025-11-07 14:47:36'),
(377, 1, 'Logout', '2025-11-07 15:17:25'),
(378, 1, 'Login', '2025-11-07 15:17:52'),
(379, 1, 'Login', '2025-11-07 15:24:02'),
(380, 1, 'Cuidador atualizado (ID: 1) - Nome: Carlos Oliveira 1 para Carlos Oliveira 1 | Email: carlos.oliveira@email.com | Telefone: (11) 88888-1112', '2025-11-07 15:26:19'),
(381, 1, 'Login', '2025-11-08 22:59:43'),
(382, 1, 'Login', '2025-11-09 23:02:19'),
(383, 1, 'Login', '2025-11-12 12:42:33'),
(384, 1, 'Login', '2025-11-12 13:18:46'),
(385, 1, 'Login', '2025-11-12 23:04:15'),
(386, 1, 'Login', '2025-11-12 23:08:58'),
(387, 1, 'Login', '2025-11-12 23:18:30'),
(388, 1, 'Login', '2025-11-12 23:21:54'),
(389, 1, 'Login', '2025-11-12 23:25:12'),
(390, 1, 'Login', '2025-11-12 23:33:24'),
(391, 1, 'Login', '2025-11-12 23:36:34'),
(392, 1, 'Login', '2025-11-12 23:57:52'),
(393, 1, 'Login', '2025-11-13 00:02:17'),
(394, 1, 'Login', '2025-11-13 00:02:18'),
(395, 1, 'Login', '2025-11-13 14:19:24'),
(396, 1, 'Login', '2025-11-13 14:19:25'),
(397, 1, 'Login', '2025-11-13 14:19:25'),
(398, 1, 'Logout', '2025-11-13 14:19:48'),
(399, 1, 'Login', '2025-11-13 14:23:16'),
(400, 1, 'Cuidador atualizado (ID: 1) - Nome: Carlos Oliveira 1 para Carlos Oliveira 1 | Email: carlos.oliveira@email.com | Telefone: (11) 88888-1112', '2025-11-13 14:23:59'),
(401, 1, 'Avaliação excluída (ID: 7) - Nota: 5 | Responsável: Fernanda Oliveira | Cuidador: Cristina Santos', '2025-11-13 14:24:53'),
(402, 1, 'Logout', '2025-11-13 14:26:17'),
(403, 1, 'Login', '2025-11-15 00:33:30'),
(404, 1, 'Login', '2025-11-24 17:42:08'),
(405, 1, 'Login', '2025-11-24 18:00:28'),
(406, 1, 'Logout', '2025-11-24 18:01:19'),
(407, 1, 'Login', '2025-11-24 18:02:53'),
(408, 1, 'Cuidador atualizado (ID: 14) - Nome: julio para julio bernardino | Email: juliofranciscobernardino@gmail.com | Telefone: 11996556155', '2025-11-24 18:03:21'),
(409, 1, 'Cuidador excluído (ID: 1) - Nome: Carlos Oliveira 1 | Email: carlos.oliveira@email.com', '2025-11-24 18:03:33'),
(410, 1, 'Responsável atualizado (ID: 8) - Nome: Ana Carolina Santos para Ana Carolina Santos | Email: ana.santos@email.com | Telefone: (11) 99999-9999', '2025-11-24 18:03:54'),
(411, 1, 'Logout', '2025-11-24 18:04:38'),
(412, 1, 'Login', '2025-11-24 18:05:07'),
(413, 1, 'Cuidador atualizado (ID: 14) - Nome: julio bernardino para julio | Email: juliofranciscobernardino@gmail.com | Telefone: 11996556155', '2025-11-24 18:05:38'),
(414, 1, 'Responsável excluído (ID: 24) - Nome: dsadfsfdsffds | Email: dsfkhjdsfjkhb@gmail.com', '2025-11-24 18:05:57'),
(415, 1, 'Logout', '2025-11-24 18:07:25'),
(416, 1, 'Login', '2025-11-24 18:07:43'),
(417, 1, 'Cuidador atualizado (ID: 14) - Nome: julio para julio | Email: juliofranciscobernardino@gmail.com | Telefone: 11996556155', '2025-11-24 18:08:16'),
(418, 1, 'Responsável excluído (ID: 23) - Nome: asddasdasasd | Email: asdasddssad@gmail.com', '2025-11-24 18:08:34'),
(419, 1, 'Responsável atualizado (ID: 29) - Nome: jkfhdgzghjhkg para Suellen | Email: sdjkhgfjkh@email.com | Telefone: 11996556155', '2025-11-24 18:08:53'),
(420, 1, 'Responsável criado (ID: 32) - Nome: Juliano | Email: juliano@email.com | CPF: 628.957.600-39', '2025-11-24 18:09:35'),
(421, 1, 'Idoso atualizado (ID: 23) - Nome: Alberto Aroldo Salvatore para Alberto Aroldo | Responsável: 31 | Sexo: Masculino', '2025-11-24 18:10:13'),
(422, 1, 'Idoso excluído (ID: 22) - Nome: teste1011 | Responsável: teste1teste2', '2025-11-24 18:10:22'),
(423, 1, 'Atendimento excluído (ID: 10) - Responsável: Fernanda Oliveira | Cuidador: Cristina Santos | Idoso: Dona Isabel | Status: Concluído | Valor: R$ 180,00', '2025-11-24 18:10:36'),
(424, 1, 'Ticket de suporte criado (ID: 13) - Tipo: admin | Categoria: Atendimento | Prioridade: Normal | Usuário: N/A', '2025-11-24 18:12:00'),
(425, 1, 'Mensagem enviada no ticket (ID: 13) - Assunto: Cuidador não foi', '2025-11-24 18:12:01'),
(426, 1, 'Mensagem enviada no ticket (ID: 13) - Assunto: Cuidador não foi', '2025-11-24 18:12:10'),
(427, 1, 'Mensagem enviada no ticket (ID: 13) - Assunto: Cuidador não foi', '2025-11-24 18:12:16'),
(428, 1, 'Status do ticket atualizado (ID: 13) - De \"Aberto\" para \"Fechado\" | Assunto: Cuidador não foi', '2025-11-24 18:12:17'),
(429, 1, 'Logout', '2025-11-24 18:14:19'),
(430, 1, 'Login', '2026-03-02 19:19:26'),
(431, 1, 'Login', '2026-03-03 14:40:30'),
(432, 1, 'Idoso atualizado (ID: 23) - Nome: Alberto Aroldo para Alberto Aroldo | Responsável: 31 | Sexo: Masculino', '2026-03-03 14:42:43');

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
(17, 21, 3, 3, 'Dona Maria Teste', '1955-10-19', 'Feminino', 'Teste de conexão', 'Teste de fluxo completo', '/avatar/idosa.png'),
(21, 25, 1, 1, 'Dona Ana', '1955-11-02', 'Masculino', 'Necessita de medicação diaria para diabetes e pressão alta', 'Gosta de fazer bolo', NULL),
(23, 31, 2, 3, 'Alberto Aroldo', '1945-09-25', 'Masculino', 'Micose', '', NULL),
(24, 33, 3, 2, 'Alfredo', '1955-12-12', 'Masculino', 'Necessita tomar remedio para diabetes', 'Precisa de ajuda para subir escadas', NULL),
(25, 34, 2, 4, 'julia justi', '1956-03-04', 'Feminino', 'todos!', 'interna ela ', NULL),
(26, 35, 3, 4, 'julia justi', '1920-03-01', 'Masculino', 'todos', NULL, NULL),
(27, 37, 1, 1, 'julia', '1956-03-06', 'Feminino', 'todos', NULL, NULL);

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
-- Table structure for table `plano`
--

CREATE TABLE `plano` (
  `IdPlano` int(11) NOT NULL,
  `Nome` varchar(50) NOT NULL,
  `Descricao` text DEFAULT NULL,
  `Preco` decimal(10,2) NOT NULL DEFAULT 0.00,
  `LimiteContatos` int(11) NOT NULL DEFAULT 0,
  `Destaque` tinyint(1) NOT NULL DEFAULT 0,
  `Ativo` tinyint(1) NOT NULL DEFAULT 1,
  `DataCriacao` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `plano`
--

INSERT INTO `plano` (`IdPlano`, `Nome`, `Descricao`, `Preco`, `LimiteContatos`, `Destaque`, `Ativo`, `DataCriacao`) VALUES
(1, 'Básico', 'Mais visibilidade e poucos contatos liberados', 29.90, 5, 0, 1, '2026-03-08 16:02:43'),
(2, 'Premium', 'Mais visibilidade e mais contatos liberados', 59.90, 20, 1, 1, '2026-03-08 16:02:43');

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
(8, NULL, '12345678901', 'Ana Carolina Santos', 'ana.santos@email.com', '(11) 99999-9999', '1980-05-13', NULL, NULL),
(9, 5, '23456789012', 'Roberto Silva', 'roberto.silva@email.com', '(11) 99999-2222', '1975-08-22', NULL, NULL),
(10, 6, '34567890123', 'Mariana Costa', 'mariana.costa@email.com', '(11) 99999-3333', '1982-12-10', NULL, NULL),
(11, 7, '45678901234', 'Carlos Eduardo', 'carlos.eduardo@email.com', '(11) 99999-4444', '1978-03-28', NULL, NULL),
(12, 8, '56789012345', 'Patricia Lima', 'patricia.lima@email.com', '(11) 99999-5555', '1985-07-14', NULL, NULL),
(13, 9, '67890123456', 'João Pedro', 'joao.pedro@email.com', '(11) 99999-6666', '1972-11-05', NULL, NULL),
(14, 10, '78901234567', 'Fernanda Oliveira', 'fernanda.oliveira@email.com', '(11) 99999-7777', '1988-09-18', NULL, NULL),
(15, 11, '89012345678', 'Ricardo Alves', 'ricardo.alves@email.com', '(11) 99999-8888', '1976-04-12', NULL, NULL),
(18, 18, '48290020810', 'teste teste', 'teste@gmail.com', '11996556155', '1995-10-09', '$2a$10$o68l80N55pnBTz6LavBjEuLjVpQRHD8nZJiEQ8y1lAgDZMXegyE2y', NULL),
(19, 19, '48290020890', 'teste teste teste', 'tstw@gmail.com', '11996556155', '1995-10-09', '$2a$10$1yn1Yh1wgvHsi2gbuW7P/u1nCykTx4rcXtsF1hZSnHNrbrv0HlO7m', NULL),
(20, 20, '48290020812', 'qwerererw qweqweqw ', 'weqweeqw@gmail.com', '11996556155', '1995-10-09', '$2a$10$0nXtLFGHZxkpOD1897fOMeNlKJVbXaJDd9rbU.ooalSVOzKCZU7Xu', NULL),
(21, 21, '98765432100', 'Maria Santos Teste', 'maria.teste@email.com', '11888888888', '1985-05-15', '$2a$10$lI9Agj2OPNgka1/Ps3Z/n.TmnKHIQOrh/Vjhm6MuSsOssRbInVCsm', NULL),
(22, 22, '11122233344', 'Pedro Oliveira Teste', 'pedro.teste@email.com', '11777777777', '1980-03-20', '$2a$10$2TBzKRm5ZwuH2K/qSNUJ/uwHqukq7cvVyfUI9S.i.dCQsoYRjKW1S', NULL),
(25, 25, '48290020856', 'Julio Franciso Bernardino', 'juliofranciscobernardino@gmail.com', '11996556155', '2005-07-31', '$2a$10$fBQVBguFQPc9Aqebc0ZFoumYL9eviFQYFcRdII.13esKLDu8./h2u', NULL),
(26, 34, '49802158828', 'teste', 'fhugfdshjg@gmail.com', '11996556155', '1995-11-12', '$2a$10$mQ8TuIhUhORpdzInjn2LDOuQix1Qrz4l0ebtUWWO8bleUiSQBynHO', NULL),
(27, 38, '438.305.870-15', 'zsjdfkifzh', 'hjfkgmgn@gmail.com', '11996556155', '1995-11-18', '$2a$10$2wpUKBwL2hP/21.YyPI2DuYI1ENkLVZG7KClUcuVLvYK/gCv0llTO', NULL),
(28, 39, '485.564.700-41', 'hjdfgjhjjfdjhfsdg', 'fdzgfdgfdg@gmail.com', '11996556155', '1995-11-23', '$2a$10$mtqMbXwEGypir./jtqbAxu9yVro49AdndjkZrdF9Wp1cd6yHjjT6K', NULL),
(29, NULL, '724.936.320-44', 'Suellen', 'sdjkhgfjkh@email.com', '11996556155', '1995-11-23', '$2a$10$rPmc33CzBn2yC.GYZC1AyO8GR/WL3BO0Tk5tOwXnMmu5.JLB.rWPO', NULL),
(30, 41, '801.789.660-37', 'teste1teste2', 'testetestetesettesss@email.com', '11996556155', '1995-11-18', '$2a$10$bLUXARiWiActbgs4Wp8.m.f5Z8C.Nfq73d1yrFHM9Rjp8pkOy88qu', NULL),
(31, 42, '187.643.788-02', 'Welton Aristoclaudio da Silva', 'jamaa1604@uorak.com', '1126882484', '2001-10-31', '$2a$10$/VBa5TcUw5iT0.SQbXJICOPBV0zJnTs4mKvHXT676rN5QAgm2oHRi', NULL),
(32, NULL, '628.957.600-39', 'Juliano', 'juliano@email.com', '1199999999', '1985-06-24', NULL, NULL),
(33, 44, '577.164.200-20', 'Juliano', 'juliano@gmail.com', '11996556155', '1995-12-02', '$2a$10$nPVV4MCj6e31E16V0k3Zt.nWspjbNL6vD08hAUJIuQF4NLd3vLsoy', NULL),
(34, 46, '663.171.570-90', 'Giovana Gomes', 'gigigomesfreire@gmail.com', '11969378652', '2000-03-17', '$2a$10$8aT0CWW9hrGjdeHxqBbEve8b/B7gie5rELaT2BTJEWiUgeWpUuQ0G', NULL),
(35, 47, '102.449.550-77', 'Giovana Gomes', 'blablabla@gmail.com', '11999996663', '1996-03-14', '$2a$10$JnCtLnAJp/1gXD.8vYKyweaPNNUExG4RYzuY8v.JFBi/ekt6mBy.G', NULL),
(36, 48, '12345678999', 'Teste Responsavel', 'teste1@teste.com', '11999999999', '1995-01-01', '$2a$10$rbrTff6BEwDgjuyOPXjLpe/CIISacP9lCA8A4SXGaZJbYGsLHYYq.', NULL),
(37, 49, '938.262.110-57', 'giovana', 'giovana@gmail.com', '1199999999', '1996-03-28', '$2a$10$tylXDtIE2jGBLtzfAMrgoOw5l1JKRrlhXr1vTTXuRFpXoC5.o0ste', NULL);

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
-- Indexes for table `assinaturacuidador`
--
ALTER TABLE `assinaturacuidador`
  ADD PRIMARY KEY (`IdAssinatura`),
  ADD KEY `idx_assinatura_cuidador` (`IdCuidador`),
  ADD KEY `idx_assinatura_plano` (`IdPlano`);

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
-- Indexes for table `plano`
--
ALTER TABLE `plano`
  ADD PRIMARY KEY (`IdPlano`);

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
-- AUTO_INCREMENT for table `assinaturacuidador`
--
ALTER TABLE `assinaturacuidador`
  MODIFY `IdAssinatura` int(11) NOT NULL AUTO_INCREMENT;

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
-- AUTO_INCREMENT for table `configuracaofinanceira`
--
ALTER TABLE `configuracaofinanceira`
  MODIFY `IdConfig` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `cuidador`
--
ALTER TABLE `cuidador`
  MODIFY `IdCuidador` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT for table `cuidadorespecialidade`
--
ALTER TABLE `cuidadorespecialidade`
  MODIFY `IdCuidadorEspecialidade` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `cuidadorservico`
--
ALTER TABLE `cuidadorservico`
  MODIFY `IdCuidadorServico` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `despesa`
--
ALTER TABLE `despesa`
  MODIFY `IdDespesa` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT for table `disponibilidade`
--
ALTER TABLE `disponibilidade`
  MODIFY `IdDisponibilidade` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=40;

--
-- AUTO_INCREMENT for table `doenca`
--
ALTER TABLE `doenca`
  MODIFY `IdDoenca` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `endereco`
--
ALTER TABLE `endereco`
  MODIFY `IdEndereco` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=50;

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
  MODIFY `IdHistoricoAdm` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=433;

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
  MODIFY `IdIdoso` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=28;

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
-- AUTO_INCREMENT for table `plano`
--
ALTER TABLE `plano`
  MODIFY `IdPlano` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `registroprofissional`
--
ALTER TABLE `registroprofissional`
  MODIFY `IdRegistro` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `responsavel`
--
ALTER TABLE `responsavel`
  MODIFY `IdResponsavel` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=38;

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
-- Constraints for table `assinaturacuidador`
--
ALTER TABLE `assinaturacuidador`
  ADD CONSTRAINT `fk_assinatura_cuidador` FOREIGN KEY (`IdCuidador`) REFERENCES `cuidador` (`IdCuidador`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_assinatura_plano` FOREIGN KEY (`IdPlano`) REFERENCES `plano` (`IdPlano`);

--
-- Constraints for table `certificado`
--
ALTER TABLE `certificado`
  ADD CONSTRAINT `certificado_ibfk_1` FOREIGN KEY (`IdCuidador`) REFERENCES `cuidador` (`IdCuidador`) ON DELETE CASCADE;

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
