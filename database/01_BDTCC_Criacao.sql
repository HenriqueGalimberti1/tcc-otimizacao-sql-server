-- Criação do banco de dados se você não tiver ainda.
CREATE DATABASE LojaDB_desempenho;
GO

-- Descomente essa linha para usar o banco que você criou.
USE LojaDB_desempenho;
GO

-- TABELA: Categoria
CREATE TABLE Categoria (
    id_categoria INT IDENTITY(1,1) PRIMARY KEY,
    descricao VARCHAR(100) NOT NULL
);
GO

-- TABELA: Produto
CREATE TABLE Produto (
    id_produto INT IDENTITY(1,1) PRIMARY KEY,
    id_categoria INT NOT NULL,
    nome VARCHAR(150) NOT NULL,
    preco_atual DECIMAL(10,2) NOT NULL,

    CONSTRAINT FK_Produto_Categoria
        FOREIGN KEY (id_categoria)
        REFERENCES Categoria(id_categoria)
);
GO

-- TABELA: Estoque
-- Relacionamento 1:1 com Produto
CREATE TABLE Estoque (
    id_produto INT PRIMARY KEY,
    quantidade_disponivel INT NOT NULL DEFAULT 0,

    CONSTRAINT FK_Estoque_Produto
        FOREIGN KEY (id_produto)
        REFERENCES Produto(id_produto)
);
GO

-- TABELA: Fornecedor
CREATE TABLE Fornecedor (
    id_fornecedor INT IDENTITY(1,1) PRIMARY KEY,
    nome VARCHAR(150) NOT NULL
);
GO

-- TABELA: Produto_Fornecedor
-- Relacionamento N:N
CREATE TABLE Produto_Fornecedor (
    id_produto INT NOT NULL,
    id_fornecedor INT NOT NULL,

    CONSTRAINT PK_Produto_Fornecedor
        PRIMARY KEY (id_produto, id_fornecedor),

    CONSTRAINT FK_PF_Produto
        FOREIGN KEY (id_produto)
        REFERENCES Produto(id_produto),

    CONSTRAINT FK_PF_Fornecedor
        FOREIGN KEY (id_fornecedor)
        REFERENCES Fornecedor(id_fornecedor)
);
GO

-- TABELA: Cliente
CREATE TABLE Cliente (
    id_cliente INT IDENTITY(1,1) PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE
);
GO

-- TABELA: Venda
CREATE TABLE Venda (
    id_venda INT IDENTITY(1,1) PRIMARY KEY,
    id_cliente INT NOT NULL,
    data_venda DATETIME NOT NULL DEFAULT GETDATE(),
    status VARCHAR(30) NOT NULL,

    CONSTRAINT FK_Venda_Cliente
        FOREIGN KEY (id_cliente)
        REFERENCES Cliente(id_cliente)
);
GO

-- TABELA: Item_Venda
CREATE TABLE Item_Venda (
    id_item INT IDENTITY(1,1) PRIMARY KEY,
    id_venda INT NOT NULL,
    id_produto INT NOT NULL,
    quantidade INT NOT NULL,
    preco_unitario DECIMAL(10,2) NOT NULL,

    CONSTRAINT FK_ItemVenda_Venda
        FOREIGN KEY (id_venda)
        REFERENCES Venda(id_venda),

    CONSTRAINT FK_ItemVenda_Produto
        FOREIGN KEY (id_produto)
        REFERENCES Produto(id_produto)
);
GO

-- TABELA: Pagamento
CREATE TABLE Pagamento (
    id_pagamento INT IDENTITY(1,1) PRIMARY KEY,
    id_venda INT NOT NULL,
    valor DECIMAL(10,2) NOT NULL,
    status VARCHAR(30) NOT NULL,

    CONSTRAINT FK_Pagamento_Venda
        FOREIGN KEY (id_venda)
        REFERENCES Venda(id_venda)
);
GO