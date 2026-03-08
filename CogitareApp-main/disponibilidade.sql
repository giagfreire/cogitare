-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: mysql-cogitare.alwaysdata.net
-- Generation Time: Oct 24, 2025 at 03:42 PM
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

--
-- Dumping data for table `disponibilidade`
--

INSERT INTO `disponibilidade` (`IdDisponibilidade`, `IdCuidador`, `DiaSemana`, `DataInicio`, `DataFim`, `Observacoes`, `Recorrente`) VALUES
(1, 1, 'Segunda', '2025-10-20 08:00:00', '2025-10-20 18:00:00', 'Horário comercial', 1),
(2, 1, 'Terça', '2025-10-20 08:00:00', '2025-10-20 18:00:00', 'Horário comercial', 1),
(3, 1, 'Quarta', '2025-10-20 08:00:00', '2025-10-20 18:00:00', 'Horário comercial', 1),
(4, 1, 'Quinta', '2025-10-20 08:00:00', '2025-10-20 18:00:00', 'Horário comercial', 1),
(5, 1, 'Sexta', '2025-10-20 08:00:00', '2025-10-20 18:00:00', 'Horário comercial', 1),
(6, 2, 'Segunda', '2025-10-20 06:00:00', '2025-10-20 22:00:00', 'Horário estendido', 1),
(7, 2, 'Terça', '2025-10-20 06:00:00', '2025-10-20 22:00:00', 'Horário estendido', 1),
(8, 2, 'Quarta', '2025-10-20 06:00:00', '2025-10-20 22:00:00', 'Horário estendido', 1),
(9, 2, 'Quinta', '2025-10-20 06:00:00', '2025-10-20 22:00:00', 'Horário estendido', 1),
(10, 2, 'Sexta', '2025-10-20 06:00:00', '2025-10-20 22:00:00', 'Horário estendido', 1),
(11, 2, 'Sábado', '2025-10-20 06:00:00', '2025-10-20 22:00:00', 'Horário estendido', 1),
(12, 3, 'Segunda', '2025-10-20 00:00:00', '2025-10-20 23:59:00', 'Disponível 24h', 1),
(13, 3, 'Terça', '2025-10-20 00:00:00', '2025-10-20 23:59:00', 'Disponível 24h', 1),
(14, 3, 'Quarta', '2025-10-20 00:00:00', '2025-10-20 23:59:00', 'Disponível 24h', 1),
(15, 3, 'Quinta', '2025-10-20 00:00:00', '2025-10-20 23:59:00', 'Disponível 24h', 1),
(16, 3, 'Sexta', '2025-10-20 00:00:00', '2025-10-20 23:59:00', 'Disponível 24h', 1),
(17, 3, 'Sábado', '2025-10-20 00:00:00', '2025-10-20 23:59:00', 'Disponível 24h', 1),
(18, 3, 'Domingo', '2025-10-20 00:00:00', '2025-10-20 23:59:00', 'Disponível 24h', 1),
(19, 4, 'Segunda', '2025-10-20 07:00:00', '2025-10-20 19:00:00', 'Horário comercial', 1),
(20, 4, 'Terça', '2025-10-20 07:00:00', '2025-10-20 19:00:00', 'Horário comercial', 1),
(21, 4, 'Quarta', '2025-10-20 07:00:00', '2025-10-20 19:00:00', 'Horário comercial', 1),
(22, 4, 'Quinta', '2025-10-20 07:00:00', '2025-10-20 19:00:00', 'Horário comercial', 1),
(23, 4, 'Sexta', '2025-10-20 07:00:00', '2025-10-20 19:00:00', 'Horário comercial', 1),
(24, 5, 'Segunda', '2025-10-20 09:00:00', '2025-10-20 17:00:00', 'Horário comercial', 1),
(25, 5, 'Terça', '2025-10-20 09:00:00', '2025-10-20 17:00:00', 'Horário comercial', 1),
(26, 5, 'Quarta', '2025-10-20 09:00:00', '2025-10-20 17:00:00', 'Horário comercial', 1),
(27, 5, 'Quinta', '2025-10-20 09:00:00', '2025-10-20 17:00:00', 'Horário comercial', 1),
(28, 5, 'Sexta', '2025-10-20 09:00:00', '2025-10-20 17:00:00', 'Horário comercial', 1),
(29, 6, 'Segunda', '2025-10-20 08:00:00', '2025-10-20 20:00:00', 'Horário estendido', 1),
(30, 6, 'Terça', '2025-10-20 08:00:00', '2025-10-20 20:00:00', 'Horário estendido', 1),
(31, 6, 'Quarta', '2025-10-20 08:00:00', '2025-10-20 20:00:00', 'Horário estendido', 1),
(32, 6, 'Quinta', '2025-10-20 08:00:00', '2025-10-20 20:00:00', 'Horário estendido', 1),
(33, 6, 'Sexta', '2025-10-20 08:00:00', '2025-10-20 20:00:00', 'Horário estendido', 1);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `disponibilidade`
--
ALTER TABLE `disponibilidade`
  ADD PRIMARY KEY (`IdDisponibilidade`),
  ADD KEY `IdCuidador` (`IdCuidador`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `disponibilidade`
--
ALTER TABLE `disponibilidade`
  MODIFY `IdDisponibilidade` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=34;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `disponibilidade`
--
ALTER TABLE `disponibilidade`
  ADD CONSTRAINT `disponibilidade_ibfk_1` FOREIGN KEY (`IdCuidador`) REFERENCES `cuidador` (`IdCuidador`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
