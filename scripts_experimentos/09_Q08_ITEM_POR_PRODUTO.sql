USE LojaDB_desempenho;
GO
-- EXECUTAR ESTE ARQUIVO INTEIRO APENAS EM LABORATORIO.
-- Requer 01_INSTALAR_LABORATORIO.sql.
-- Limpa exclusivamente indices IX_TCC_*; preserva indices PK/UNIQUE e FKs.
EXEC dbo.TCC_LimparIndices;
GO
-- Q08 complementar: filtro por produto em Item_Venda (1,5 milhao de registros previstos).
DECLARE @ProdutoId int;
SELECT TOP(1) @ProdutoId=id_produto FROM dbo.Item_Venda
GROUP BY id_produto ORDER BY COUNT_BIG(*) DESC,id_produto;
IF @ProdutoId IS NULL THROW 51013,'Nao ha itens vendidos.',1;
DECLARE @SQL nvarchar(max)=N'
 SELECT CONVERT(decimal(38,4),COALESCE(SUM(CONVERT(decimal(18,2),quantidade)+preco_unitario),0)) AS resultado
 FROM dbo.Item_Venda WHERE id_produto='+CONVERT(nvarchar(15),@ProdutoId)+N';';
SELECT @ProdutoId AS produto_utilizado;
EXEC dbo.TCC_MedirConsulta 'Q08','A_BASE',@SQL,20,5,N'Sem indice secundario no produto';
CREATE NONCLUSTERED INDEX IX_TCC_ItemVenda_Produto ON dbo.Item_Venda(id_produto);
EXEC dbo.TCC_MedirConsulta 'Q08','B_PRODUTO',@SQL,20,5,N'Indice simples em id_produto';
DROP INDEX IX_TCC_ItemVenda_Produto ON dbo.Item_Venda;
CREATE NONCLUSTERED INDEX IX_TCC_ItemVenda_Produto_Include
 ON dbo.Item_Venda(id_produto) INCLUDE(quantidade,preco_unitario);
EXEC dbo.TCC_MedirConsulta 'Q08','C_COBERTURA',@SQL,20,5,N'Indice em produto com INCLUDE';
GO
