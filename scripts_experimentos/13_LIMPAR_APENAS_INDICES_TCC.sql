USE LojaDB_desempenho;
GO
-- Remove EXCLUSIVAMENTE indices criados pelo pacote (IX_TCC_*).
-- NAO remove dados, tabelas de negocio, PK, FK, UNIQUE nem CHECK.
EXEC dbo.TCC_LimparIndices;
GO
SELECT t.name AS tabela,i.name AS indice_restante
FROM sys.indexes i JOIN sys.tables t ON t.object_id=i.object_id
WHERE t.name IN (N'Categoria',N'Produto',N'Estoque',N'Fornecedor',N'Produto_Fornecedor',N'Cliente',N'Venda',N'Item_Venda',N'Pagamento')
AND i.name IS NOT NULL ORDER BY t.name,i.name;
GO
