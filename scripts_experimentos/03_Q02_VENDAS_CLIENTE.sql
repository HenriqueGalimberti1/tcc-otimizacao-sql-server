USE LojaDB_desempenho;
GO
-- EXECUTAR ESTE ARQUIVO INTEIRO APENAS EM LABORATORIO.
-- Requer 01_INSTALAR_LABORATORIO.sql.
-- Limpa exclusivamente indices IX_TCC_*; preserva indices PK/UNIQUE e FKs.
EXEC dbo.TCC_LimparIndices;
GO
-- Q02: selecionar um cliente com vendas em 2025 (fora da medicao).
DECLARE @ClienteId int;
SELECT TOP(1) @ClienteId=id_cliente
FROM dbo.Venda WHERE data_venda>='20250101' AND data_venda<'20260101'
GROUP BY id_cliente ORDER BY COUNT_BIG(*) DESC,id_cliente;
IF @ClienteId IS NULL THROW 51011,'Sem vendas em 2025; ajustar janela de datas.',1;
DECLARE @SQL nvarchar(max)=N'
 SELECT CONVERT(decimal(38,4),COUNT_BIG(*) + COALESCE(SUM(CONVERT(bigint,DATALENGTH(v.status))),0)) AS resultado
 FROM dbo.Venda AS v
 WHERE v.id_cliente='+CONVERT(nvarchar(15),@ClienteId)+N'
   AND v.data_venda>=''20250101'' AND v.data_venda<''20260101'';';
SELECT @ClienteId AS cliente_utilizado;
EXEC dbo.TCC_MedirConsulta 'Q02','A_BASE',@SQL,20,5,N'Sem indice adicional';
CREATE NONCLUSTERED INDEX IX_TCC_Venda_Cliente ON dbo.Venda(id_cliente);
EXEC dbo.TCC_MedirConsulta 'Q02','B_SIMPLES',@SQL,20,5,N'Indice cliente';
DROP INDEX IX_TCC_Venda_Cliente ON dbo.Venda;
CREATE NONCLUSTERED INDEX IX_TCC_Venda_Cliente_Data
 ON dbo.Venda(id_cliente,data_venda) INCLUDE(status);
EXEC dbo.TCC_MedirConsulta 'Q02','C_COMPOSTO',@SQL,20,5,N'Indice (cliente,data) INCLUDE(status)';
GO
