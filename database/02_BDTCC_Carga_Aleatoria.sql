USE LojaDB_desempenho;
GO

-- Cria tabela temporária Numeros para suportar os registros e relacionamentos. 
-- Definido o maior valor 1,5 milhão
IF OBJECT_ID('tempdb..#Numeros') IS NOT NULL
    DROP TABLE #Numeros;

WITH N1 AS (SELECT 1 n UNION ALL SELECT 1),
N2 AS (SELECT 1 n FROM N1 a CROSS JOIN N1 b),
N4 AS (SELECT 1 n FROM N2 a CROSS JOIN N2 b),
N8 AS (SELECT 1 n FROM N4 a CROSS JOIN N4 b),
N16 AS (SELECT 1 n FROM N8 a CROSS JOIN N8 b),
N32 AS (SELECT 1 n FROM N16 a CROSS JOIN N16 b)
SELECT TOP (1500000)
       ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Numero
INTO #Numeros
FROM N32;

-- Categorias são 20
INSERT INTO Categoria (descricao)
SELECT CONCAT('Categoria ', Numero)
FROM #Numeros
WHERE Numero <= 20;

-- Fornecedores são 500
INSERT INTO Fornecedor (nome)
SELECT CONCAT('Fornecedor ', Numero)
FROM #Numeros
WHERE Numero <= 500;

-- Produtos são 50.000
INSERT INTO Produto
(
    id_categoria,
    nome,
    preco_atual
)
SELECT
    ABS(CHECKSUM(NEWID())) % 20 + 1,
    CONCAT('Produto ', Numero),
    CAST((RAND(CHECKSUM(NEWID())) * 999 + 1) AS DECIMAL(10,2))
FROM #Numeros
WHERE Numero <= 50000;

-- Estoque são 50.000
INSERT INTO Estoque
(
    id_produto,
    quantidade_disponivel
)
SELECT
    id_produto,
    ABS(CHECKSUM(NEWID())) % 500
FROM Produto;

-- Relacionamento Produto x Fornecedor
-- Cada Produto terá de 1 a 3 Fornecedores.
-- Vai gerar aproximadamente 100.000 relacionamentos.
INSERT INTO Produto_Fornecedor
(
    id_produto,
    id_fornecedor
)
SELECT
    p.id_produto,
    ((ABS(CHECKSUM(NEWID())) % 500) + 1)
FROM Produto p

UNION

SELECT
    p.id_produto,
    ((ABS(CHECKSUM(NEWID())) % 500) + 1)
FROM Produto p

UNION

SELECT
    p.id_produto,
    ((ABS(CHECKSUM(NEWID())) % 500) + 1)
FROM Produto p;

-- Clientes são 100.000
INSERT INTO Cliente
(
    nome,
    email
)
SELECT
    CONCAT('Cliente ', Numero),
    CONCAT('cliente', Numero, '@email.com')
FROM #Numeros
WHERE Numero <= 100000;

-- Vendas são 500.000
-- Distribuí ao longo dos últimos 3 anos(365x3) = 1095 dias
INSERT INTO Venda
(
    id_cliente,
    data_venda,
    status
)
SELECT
    ABS(CHECKSUM(NEWID())) % 100000 + 1,
    DATEADD(
        DAY,
        -(ABS(CHECKSUM(NEWID())) % 1095),
        GETDATE()
    ),
    CASE ABS(CHECKSUM(NEWID())) % 4
        WHEN 0 THEN 'ABERTA'
        WHEN 1 THEN 'PAGA'
        WHEN 2 THEN 'CANCELADA'
        ELSE 'FINALIZADA'
    END
FROM #Numeros
WHERE Numero <= 500000;

-- Pagamentos são 500.000
INSERT INTO Pagamento
(
    id_venda,
    valor,
    status
)
SELECT
    id_venda,
    CAST((RAND(CHECKSUM(NEWID())) * 5000 + 50) AS DECIMAL(10,2)),
    CASE
        WHEN ABS(CHECKSUM(NEWID())) % 10 < 8
            THEN 'PAGO'
        ELSE 'PENDENTE'
    END
FROM Venda;

-- Itens de Venda (Média de 3 por venda) 1.500.000
INSERT INTO Item_Venda
(
    id_venda,
    id_produto,
    quantidade,
    preco_unitario
)
SELECT
    v.id_venda,
    ABS(CHECKSUM(NEWID())) % 50000 + 1,
    ABS(CHECKSUM(NEWID())) % 10 + 1,
    CAST(
        (ABS(CHECKSUM(NEWID())) % 100000) / 100.0 + 1
        AS DECIMAL(10,2)
    )
FROM Venda v
CROSS APPLY
(
    VALUES (1),(2),(3)
) x(n);

-- Atualização dos valores de pagamentos de acordo com os itens gerados (Integridade de dados)
UPDATE p
SET p.valor = x.total
FROM Pagamento p
INNER JOIN
(
    SELECT
        iv.id_venda,
        SUM(iv.quantidade * iv.preco_unitario) total
    FROM Item_Venda iv
    GROUP BY iv.id_venda
) x
    ON x.id_venda = p.id_venda;

-- Por fim essa query exibe a quantidade de registros que tem em cada tabela.
SELECT 'Categoria' Tabela, COUNT(*) Qtde FROM Categoria
UNION ALL
SELECT 'Fornecedor', COUNT(*) FROM Fornecedor
UNION ALL
SELECT 'Produto', COUNT(*) FROM Produto
UNION ALL
SELECT 'Cliente', COUNT(*) FROM Cliente
UNION ALL
SELECT 'Venda', COUNT(*) FROM Venda
UNION ALL
SELECT 'Item_Venda', COUNT(*) FROM Item_Venda
UNION ALL
SELECT 'Estoque', COUNT(*) FROM Estoque
UNION ALL
SELECT 'Pagamento', COUNT(*) FROM Pagamento;
go

--SELECT p.*, v.* FROM Pagamento p left join Venda v on v.id_venda = p.id_venda;
