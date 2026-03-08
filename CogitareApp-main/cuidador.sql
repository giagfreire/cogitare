-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: mysql-cogitare.alwaysdata.net
-- Generation Time: Oct 20, 2025 at 06:05 PM
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

--
-- Indexes for dumped tables
--

--
-- Indexes for table `cuidador`
--
ALTER TABLE `cuidador`
  ADD PRIMARY KEY (`IdCuidador`),
  ADD KEY `IdEndereco` (`IdEndereco`),
  ADD KEY `idx_cuidador_nome` (`Nome`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `cuidador`
--
ALTER TABLE `cuidador`
  MODIFY `IdCuidador` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `cuidador`
--
ALTER TABLE `cuidador`
  ADD CONSTRAINT `cuidador_ibfk_1` FOREIGN KEY (`IdEndereco`) REFERENCES `endereco` (`IdEndereco`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
