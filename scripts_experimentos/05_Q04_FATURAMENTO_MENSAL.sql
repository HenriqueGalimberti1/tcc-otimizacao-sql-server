USE LojaDB_desempenho;
GO
-- EXECUTAR ESTE ARQUIVO INTEIRO APENAS EM LABORATORIO.
-- Requer 01_INSTALAR_LABORATORIO.sql.
-- Limpa exclusivamente indices IX_TCC_*; preserva indices PK/UNIQUE e FKs.
EXEC dbo.TCC_LimparIndices;
GO
-- Q04: quatro cenarios progressivos. Os indices em B/C/D se acumulam
-- pois essa e a pergunta experimental; no Q01 foram substituidos.
EXEC dbo.TCC_MedirConsulta @Experimento='Q04', @Cenario='A_BASE',
    @SQL=N';WITH Mensal AS (
 SELECT DATEFROMPARTS(YEAR(v.data_venda),MONTH(v.data_venda),1) AS mes,
        SUM(CONVERT(decimal(18,2),iv.quantidade)*iv.preco_unitario) AS faturamento
 FROM dbo.Venda v INNER JOIN dbo.Item_Venda iv ON iv.id_venda=v.id_venda
 WHERE v.status=''FINALIZADA''
   AND v.data_venda>=''20250101'' AND v.data_venda<''20260101''
 GROUP BY DATEFROMPARTS(YEAR(v.data_venda),MONTH(v.data_venda),1)
)
SELECT CONVERT(decimal(38,4),COALESCE(SUM(faturamento * (MONTH(mes)+1)),0)) AS resultado
FROM Mensal;', @Repeticoes=20, @Aquecimentos=5, @Observacao=N'sem indices secundarios';
GO

CREATE NONCLUSTERED INDEX IX_TCC_Venda_Status_Data
 ON dbo.Venda(status,data_venda);
GO
EXEC dbo.TCC_MedirConsulta @Experimento='Q04', @Cenario='B_VENDA',
    @SQL=N';WITH Mensal AS (
 SELECT DATEFROMPARTS(YEAR(v.data_venda),MONTH(v.data_venda),1) AS mes,
        SUM(CONVERT(decimal(18,2),iv.quantidade)*iv.preco_unitario) AS faturamento
 FROM dbo.Venda v INNER JOIN dbo.Item_Venda iv ON iv.id_venda=v.id_venda
 WHERE v.status=''FINALIZADA''
   AND v.data_venda>=''20250101'' AND v.data_venda<''20260101''
 GROUP BY DATEFROMPARTS(YEAR(v.data_venda),MONTH(v.data_venda),1)
)
SELECT CONVERT(decimal(38,4),COALESCE(SUM(faturamento * (MONTH(mes)+1)),0)) AS resultado
FROM Mensal;', @Repeticoes=20, @Aquecimentos=5, @Observacao=N'indice status+data';
GO

CREATE NONCLUSTERED INDEX IX_TCC_ItemVenda_Venda
 ON dbo.Item_Venda(id_venda);
GO
EXEC dbo.TCC_MedirConsulta @Experimento='Q04', @Cenario='C_ITEM',
    @SQL=N';WITH Mensal AS (
 SELECT DATEFROMPARTS(YEAR(v.data_venda),MONTH(v.data_venda),1) AS mes,
        SUM(CONVERT(decimal(18,2),iv.quantidade)*iv.preco_unitario) AS faturamento
 FROM dbo.Venda v INNER JOIN dbo.Item_Venda iv ON iv.id_venda=v.id_venda
 WHERE v.status=''FINALIZADA''
   AND v.data_venda>=''20250101'' AND v.data_venda<''20260101''
 GROUP BY DATEFROMPARTS(YEAR(v.data_venda),MONTH(v.data_venda),1)
)
SELECT CONVERT(decimal(38,4),COALESCE(SUM(faturamento * (MONTH(mes)+1)),0)) AS resultado
FROM Mensal;', @Repeticoes=20, @Aquecimentos=5, @Observacao=N'tambem indice FK em Item_Venda';
GO

DROP INDEX IX_TCC_ItemVenda_Venda ON dbo.Item_Venda;
CREATE NONCLUSTERED INDEX IX_TCC_ItemVenda_Venda_Include
 ON dbo.Item_Venda(id_venda) INCLUDE(quantidade,preco_unitario);
GO
EXEC dbo.TCC_MedirConsulta @Experimento='Q04', @Cenario='D_COBERTURA',
    @SQL=N';WITH Mensal AS (
 SELECT DATEFROMPARTS(YEAR(v.data_venda),MONTH(v.data_venda),1) AS mes,
        SUM(CONVERT(decimal(18,2),iv.quantidade)*iv.preco_unitario) AS faturamento
 FROM dbo.Venda v INNER JOIN dbo.Item_Venda iv ON iv.id_venda=v.id_venda
 WHERE v.status=''FINALIZADA''
   AND v.data_venda>=''20250101'' AND v.data_venda<''20260101''
 GROUP BY DATEFROMPARTS(YEAR(v.data_venda),MONTH(v.data_venda),1)
)
SELECT CONVERT(decimal(38,4),COALESCE(SUM(faturamento * (MONTH(mes)+1)),0)) AS resultado
FROM Mensal;', @Repeticoes=20, @Aquecimentos=5, @Observacao=N'indice da FK com INCLUDE';
GO
