CREATE DATABASE IF NOT EXISTS oficina;
USE oficina;

-- Clientes e Veículos
CREATE TABLE Cliente (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100),
    identificacao VARCHAR(20) UNIQUE
);

CREATE TABLE Veiculo (
    id_veiculo INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT,
    placa CHAR(7) UNIQUE,
    modelo VARCHAR(45),
    FOREIGN KEY (id_cliente) REFERENCES Cliente(id_cliente)
);

-- Equipe e Mecânicos
CREATE TABLE Equipe (
    id_equipe INT AUTO_INCREMENT PRIMARY KEY,
    nome_equipe VARCHAR(45)
);

CREATE TABLE Mecanico (
    codigo_mecanico INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100),
    especialidade VARCHAR(45),
    id_equipe INT,
    FOREIGN KEY (id_equipe) REFERENCES Equipe(id_equipe)
);

-- Ordem de Serviço (OS)
CREATE TABLE OS (
    id_os INT AUTO_INCREMENT PRIMARY KEY,
    id_veiculo INT,
    id_equipe INT,
    data_emissao DATETIME DEFAULT CURRENT_TIMESTAMP,
    data_conclusao DATETIME,
    valor_total DECIMAL(10,2) DEFAULT 0,
    status ENUM('Avaliação', 'Aguardando Autorização', 'Em Execução', 'Finalizado', 'Cancelado') DEFAULT 'Avaliação',
    FOREIGN KEY (id_veiculo) REFERENCES Veiculo(id_veiculo),
    FOREIGN KEY (id_equipe) REFERENCES Equipe(id_equipe)
);

-- Tabela de Referência de Serviços e Peças
CREATE TABLE Tabela_Servico (
    id_servico INT AUTO_INCREMENT PRIMARY KEY,
    descricao VARCHAR(100),
    valor_referencia DECIMAL(10,2)
);

CREATE TABLE Peca (
    id_peca INT AUTO_INCREMENT PRIMARY KEY,
    nome_peca VARCHAR(45),
    valor_unitario DECIMAL(10,2)
);

-- Itens da OS (Mão de Obra e Peças)
CREATE TABLE OS_Servicos (
    id_os INT,
    id_servico INT,
    quantidade INT DEFAULT 1,
    PRIMARY KEY (id_os, id_servico),
    FOREIGN KEY (id_os) REFERENCES OS(id_os),
    FOREIGN KEY (id_servico) REFERENCES Tabela_Servico(id_servico)
);

CREATE TABLE OS_Pecas (
    id_os INT,
    id_peca INT,
    quantidade INT,
    PRIMARY KEY (id_os, id_peca),
    FOREIGN KEY (id_os) REFERENCES OS(id_os),
    FOREIGN KEY (id_peca) REFERENCES Peca(id_peca)
);
