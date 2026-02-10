-- E-COMMERCE COM GESTÃO DE ESTOQUE (ERP)

CREATE DATABASE IF NOT EXISTS ecommerce_erp;
USE ecommerce_erp;

-- 1. TABELA CLIENTE (Superclasse)
CREATE TABLE Cliente (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    tipo_cliente ENUM('PF', 'PJ') NOT NULL,
    endereco VARCHAR(255),
    contato VARCHAR(45)
);

-- 2. PESSOA FÍSICA (Subclasse)
CREATE TABLE Pessoa_Fisica (
    id_pf INT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cpf CHAR(11) NOT NULL UNIQUE,
    CONSTRAINT fk_pf_cliente FOREIGN KEY (id_pf) REFERENCES Cliente(id_cliente) ON DELETE CASCADE
);

-- 3. PESSOA JURÍDICA (Subclasse)
CREATE TABLE Pessoa_Juridica (
    id_pj INT PRIMARY KEY,
    razao_social VARCHAR(100) NOT NULL,
    cnpj CHAR(14) NOT NULL UNIQUE,
    CONSTRAINT fk_pj_cliente FOREIGN KEY (id_pj) REFERENCES Cliente(id_cliente) ON DELETE CASCADE
);

-- 4. VENDEDOR
CREATE TABLE Vendedor (
    id_vendedor INT AUTO_INCREMENT PRIMARY KEY,
    razao_social VARCHAR(100) NOT NULL,
    localizacao VARCHAR(255)
);

-- 5. PRODUTO E ESTADOS DE ESTOQUE
CREATE TABLE Produto (
    id_produto INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    sku VARCHAR(50) UNIQUE,
    quantidade_estoque INT DEFAULT 0,    -- Total físico (Entrada de Material)
    quantidade_reservada INT DEFAULT 0,  -- Pedidos em aberto
    quantidade_bloqueada INT DEFAULT 0,  -- Avarias/Quarentena
    valor_unitario DECIMAL(10,2)
);

-- 6. PEDIDO
CREATE TABLE Pedido (
    id_pedido INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    id_vendedor INT,
    status_pedido ENUM('Aberto', 'Confirmado', 'Pago', 'Enviado', 'Cancelado') DEFAULT 'Aberto',
    data_criacao DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pedido_cliente FOREIGN KEY (id_cliente) REFERENCES Cliente(id_cliente),
    CONSTRAINT fk_pedido_vendedor FOREIGN KEY (id_vendedor) REFERENCES Vendedor(id_vendedor)
);

-- 7. RELAÇÃO PEDIDO E PRODUTO (Itens do Pedido)
CREATE TABLE Pedido_Item (
    id_pedido INT NOT NULL,
    id_produto INT NOT NULL,
    quantidade INT NOT NULL,
    valor_venda DECIMAL(10,2),
    PRIMARY KEY (id_pedido, id_produto),
    CONSTRAINT fk_item_pedido FOREIGN KEY (id_pedido) REFERENCES Pedido(id_pedido),
    CONSTRAINT fk_item_produto FOREIGN KEY (id_produto) REFERENCES Produto(id_produto)
);

-- 8. ENTREGA
CREATE TABLE Entrega (
    id_entrega INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido INT NOT NULL UNIQUE,
    status_entrega ENUM('Preparando', 'Em trânsito', 'Entregue') DEFAULT 'Preparando',
    codigo_rastreio VARCHAR(50) UNIQUE,
    CONSTRAINT fk_entrega_pedido FOREIGN KEY (id_pedido) REFERENCES Pedido(id_pedido)
);


-- LOGICA DE AUTOMAÇÃO (TRIGGERS)

DELIMITER //

-- A) Reserva produto ao adicionar no pedido
CREATE TRIGGER TRG_Reserva_Ao_Inserir
AFTER INSERT ON Pedido_Item
FOR EACH ROW
BEGIN
    UPDATE Produto 
    SET quantidade_reservada = quantidade_reservada + NEW.quantidade
    WHERE id_produto = NEW.id_produto;
END; //

-- B) Libera reserva se o item for removido do pedido
CREATE TRIGGER TRG_Libera_Reserva_Ao_Deletar
AFTER DELETE ON Pedido_Item
FOR EACH ROW
BEGIN
    UPDATE Produto 
    SET quantidade_reservada = quantidade_reservada - OLD.quantidade
    WHERE id_produto = OLD.id_produto;
END; //

-- C) Baixa definitiva do estoque físico quando o status vira 'Enviado'
CREATE TRIGGER TRG_Baixa_Estoque_Final
AFTER UPDATE ON Pedido
FOR EACH ROW
BEGIN
    IF NEW.status_pedido = 'Enviado' AND OLD.status_pedido <> 'Enviado' THEN
        UPDATE Produto p
        INNER JOIN Pedido_Item pi ON p.id_produto = pi.id_produto
        SET p.quantidade_estoque = p.quantidade_estoque - pi.quantidade,
            p.quantidade_reservada = p.quantidade_reservada - pi.quantidade
        WHERE pi.id_pedido = NEW.id_pedido;
    END IF;
END; //

DELIMITER ;

-- 9. VIEW PARA CONSULTA DE ESTOQUE DISPONÍVEL (Lógica de Negócio)
CREATE VIEW vw_estoque_disponivel AS
SELECT 
    nome,
    sku,
    quantidade_estoque AS estoque_total,
    (quantidade_estoque - quantidade_reservada - quantidade_bloqueada) AS disponivel_para_venda
FROM Produto;
