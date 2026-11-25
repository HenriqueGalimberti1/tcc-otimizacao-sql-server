USE LojaDB_desempenho;
GO
-- Q06: YEAR() e intervalo [inicio,fim) devem fornecer a mesma contagem.
DECLARE @a bigint=(SELECT COUNT_BIG(*) FROM dbo.Venda
                    WHERE status='FINALIZADA' AND YEAR(data_venda)=2025);
DECLARE @b bigint=(SELECT COUNT_BIG(*) FROM dbo.Venda
                    WHERE status='FINALIZADA'
                    AND data_venda>='20250101' AND data_venda<'20260101');
SELECT @a AS q06_year,@b AS q06_intervalo;
IF @a<>@b THROW 51021,'Q06: consultas diferentes!',1;
GO
-- Q05: comparar os 20 produtos por id e quantidade, nao apenas um checksum.
SELECT TOP(20) iv.id_produto, SUM(CONVERT(bigint,iv.quantidade)) AS unidades
INTO #Q5_A
FROM dbo.Venda v JOIN dbo.Item_Venda iv ON iv.id_venda=v.id_venda
JOIN dbo.Produto p ON p.id_produto=iv.id_produto
WHERE v.status='FINALIZADA' AND v.data_venda>='20250701' AND v.data_venda<'20251001'
GROUP BY iv.id_produto,p.nome
ORDER BY unidades DESC,iv.id_produto;
;WITH Totais AS (
 SELECT iv.id_produto,SUM(CONVERT(bigint,iv.quantidade)) unidades
 FROM dbo.Venda v JOIN dbo.Item_Venda iv ON iv.id_venda=v.id_venda
 WHERE v.status='FINALIZADA' AND v.data_venda>='20250701' AND v.data_venda<'20251001'
 GROUP BY iv.id_produto
)
SELECT TOP(20) t.id_produto,t.unidades INTO #Q5_B
FROM Totais t JOIN dbo.Produto p ON p.id_produto=t.id_produto
ORDER BY t.unidades DESC,t.id_produto;
IF EXISTS(SELECT id_produto,unidades FROM #Q5_A EXCEPT SELECT id_produto,unidades FROM #Q5_B)
 OR EXISTS(SELECT id_produto,unidades FROM #Q5_B EXCEPT SELECT id_produto,unidades FROM #Q5_A)
 THROW 51022,'Q05: rankings diferentes!',1;
SELECT 'OK: Q05 e Q06 retornam resultados equivalentes' AS situacao;
DROP TABLE #Q5_A;
DROP TABLE #Q5_B;
GO
