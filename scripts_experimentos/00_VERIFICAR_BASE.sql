-- Somente leitura. Executar ANTES de instalar o laboratorio.
-- Requisito: banco LojaDB_desempenho criado e populado pelos scripts 01 e 02 dos alunos.
IF DB_ID(N'LojaDB_desempenho') IS NULL
    THROW 51001, 'Banco LojaDB_desempenho nao encontrado. Criar e popular primeiro.', 1;
GO
USE LojaDB_desempenho;
GO
SET NOCOUNT ON;
SELECT t.name AS tabela, SUM(p.rows) AS linhas
FROM sys.tables AS t JOIN sys.partitions AS p ON t.object_id=p.object_id
WHERE p.index_id IN (0,1) AND t.name IN
 (N'Categoria',N'Produto',N'Estoque',N'Fornecedor',N'Produto_Fornecedor',N'Cliente',N'Venda',N'Item_Venda',N'Pagamento')
GROUP BY t.name ORDER BY t.name;
SELECT MIN(data_venda) AS data_minima, MAX(data_venda) AS data_maxima,
 SUM(CASE WHEN data_venda>='20250101' AND data_venda<'20260101' THEN 1 ELSE 0 END) AS vendas_em_2025
FROM dbo.Venda;
SELECT status, COUNT_BIG(*) AS qtd FROM dbo.Venda GROUP BY status ORDER BY qtd DESC;
SELECT status, COUNT_BIG(*) AS qtd FROM dbo.Pagamento GROUP BY status ORDER BY qtd DESC;
SELECT SUM(CASE WHEN preco_atual <=0 THEN 1 ELSE 0 END) AS precos_nao_positivos FROM dbo.Produto;
SELECT SUM(CASE WHEN quantidade<=0 THEN 1 ELSE 0 END) AS itens_qtd_nao_positiva FROM dbo.Item_Venda;
SELECT SUM(CASE WHEN valor<=0 THEN 1 ELSE 0 END) AS pagamentos_nao_positivos FROM dbo.Pagamento;
-- Inventario de indices secundarios: PK e UNIQUE fazem parte da base original.
SELECT t.name AS tabela, i.name AS indice, i.type_desc,
       i.is_primary_key, i.is_unique_constraint, i.is_unique
FROM sys.indexes AS i JOIN sys.tables AS t ON t.object_id=i.object_id
WHERE t.name IN (N'Categoria',N'Produto',N'Estoque',N'Fornecedor',N'Produto_Fornecedor',N'Cliente',N'Venda',N'Item_Venda',N'Pagamento')
  AND i.index_id > 0
ORDER BY t.name,i.index_id;
-- Se o script 04 original tiver sido executado, NAO usar o baseline ate revisar os indices.
SELECT t.name AS tabela, i.name AS indice_adicional_inesperado
FROM sys.indexes AS i JOIN sys.tables AS t ON t.object_id=i.object_id
WHERE t.name IN (N'Categoria',N'Produto',N'Estoque',N'Fornecedor',N'Produto_Fornecedor',N'Cliente',N'Venda',N'Item_Venda',N'Pagamento')
 AND i.index_id>0 AND i.is_primary_key=0 AND i.is_unique_constraint=0
 AND i.name NOT LIKE N'IX[_]TCC[_]%';
-- Escolher um cliente de teste com vendas em 2025 (a escolha NAO faz parte da medicao).
SELECT TOP(1) id_cliente AS cliente_sugerido, COUNT_BIG(*) AS vendas_em_2025
FROM dbo.Venda
WHERE data_venda >= '20250101' AND data_venda < '20260101'
GROUP BY id_cliente ORDER BY COUNT_BIG(*) DESC, id_cliente;
