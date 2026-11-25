USE LojaDB_desempenho;
GO
-- EXECUTAR ESTE ARQUIVO INTEIRO APENAS EM LABORATORIO.
-- Requer 01_INSTALAR_LABORATORIO.sql.
-- Limpa exclusivamente indices IX_TCC_*; preserva indices PK/UNIQUE e FKs.
EXEC dbo.TCC_LimparIndices;
GO
-- Q03: indice em Venda fixo em A/B/C; variar SOMENTE Item_Venda.
CREATE NONCLUSTERED INDEX IX_TCC_Venda_Cliente_Data
 ON dbo.Venda(id_cliente,data_venda);
DECLARE @ClienteId int;
SELECT TOP(1) @ClienteId=id_cliente FROM dbo.Venda
 WHERE data_venda>='20250101' AND data_venda<'20260101'
 GROUP BY id_cliente ORDER BY COUNT_BIG(*) DESC,id_cliente;
IF @ClienteId IS NULL THROW 51012,'Sem vendas em 2025',1;
DECLARE @SQL nvarchar(max)=N'
 SELECT CONVERT(decimal(38,4),COALESCE(SUM(CONVERT(decimal(18,2),iv.quantidade)*iv.preco_unitario),0)) AS resultado
 FROM dbo.Venda AS v
 JOIN dbo.Item_Venda AS iv ON iv.id_venda=v.id_venda
 WHERE v.id_cliente='+CONVERT(nvarchar(15),@ClienteId)+N'
 AND v.data_venda>=''20250101'' AND v.data_venda<''20260101'';';
SELECT @ClienteId AS cliente_utilizado;
EXEC dbo.TCC_MedirConsulta 'Q03','A_BASE',@SQL,20,5,N'Sem indice extra em Item_Venda; indice Venda fixo';
CREATE NONCLUSTERED INDEX IX_TCC_ItemVenda_Venda ON dbo.Item_Venda(id_venda);
EXEC dbo.TCC_MedirConsulta 'Q03','B_FK',@SQL,20,5,N'Item_Venda(id_venda)';
DROP INDEX IX_TCC_ItemVenda_Venda ON dbo.Item_Venda;
CREATE NONCLUSTERED INDEX IX_TCC_ItemVenda_Venda_Include
 ON dbo.Item_Venda(id_venda) INCLUDE(quantidade,preco_unitario);
EXEC dbo.TCC_MedirConsulta 'Q03','C_COBERTURA',@SQL,20,5,N'Item_Venda(id_venda) INCLUDE(quantidade,preco_unitario)';
GO
