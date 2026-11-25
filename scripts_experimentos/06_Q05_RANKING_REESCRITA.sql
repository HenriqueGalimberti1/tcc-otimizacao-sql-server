USE LojaDB_desempenho;
GO
-- EXECUTAR ESTE ARQUIVO INTEIRO APENAS EM LABORATORIO.
-- Requer 01_INSTALAR_LABORATORIO.sql.
-- Limpa exclusivamente indices IX_TCC_*; preserva indices PK/UNIQUE e FKs.
EXEC dbo.TCC_LimparIndices;
GO
-- Q05: MESMOS INDICES nas duas variantes; diferenca e SQL.
CREATE NONCLUSTERED INDEX IX_TCC_Venda_Status_Data
 ON dbo.Venda(status,data_venda);
CREATE NONCLUSTERED INDEX IX_TCC_ItemVenda_Venda_Include
 ON dbo.Item_Venda(id_venda) INCLUDE(id_produto,quantidade);
GO
-- Alternar A e B para reduzir efeitos de ordem/carga do ambiente.
EXEC dbo.TCC_MedirConsulta @Experimento='Q05', @Cenario='A_JOIN_PRIMEIRO',
    @SQL=N'SELECT CONVERT(decimal(38,4),COALESCE(SUM(CONVERT(decimal(28,2),r.unidades)*(r.id_produto%31+1)+DATALENGTH(r.nome)),0)) AS resultado
FROM (
 SELECT TOP (20) iv.id_produto,p.nome,SUM(CONVERT(bigint,iv.quantidade)) AS unidades
 FROM dbo.Venda AS v JOIN dbo.Item_Venda AS iv ON iv.id_venda=v.id_venda
 JOIN dbo.Produto AS p ON p.id_produto=iv.id_produto
 WHERE v.status=''FINALIZADA'' AND v.data_venda>=''20250701'' AND v.data_venda<''20251001''
 GROUP BY iv.id_produto,p.nome
 ORDER BY unidades DESC,iv.id_produto
) AS r;', @Repeticoes=20, @Aquecimentos=5, @Observacao=N'JOIN com Produto antes da agregacao';
GO
EXEC dbo.TCC_MedirConsulta @Experimento='Q05', @Cenario='B_AGREGA_PRIMEIRO',
    @SQL=N';WITH Totais AS (
 SELECT iv.id_produto,SUM(CONVERT(bigint,iv.quantidade)) AS unidades
 FROM dbo.Venda AS v JOIN dbo.Item_Venda AS iv ON iv.id_venda=v.id_venda
 WHERE v.status=''FINALIZADA'' AND v.data_venda>=''20250701'' AND v.data_venda<''20251001''
 GROUP BY iv.id_produto
), TopProdutos AS (
 SELECT TOP(20) id_produto,unidades
 FROM Totais ORDER BY unidades DESC,id_produto
)
SELECT CONVERT(decimal(38,4),COALESCE(SUM(CONVERT(decimal(28,2),t.unidades)*(t.id_produto%31+1)+DATALENGTH(p.nome)),0)) AS resultado
FROM TopProdutos t JOIN dbo.Produto p ON p.id_produto=t.id_produto;', @Repeticoes=20, @Aquecimentos=5, @Observacao=N'TOP apos agrupar e antes de juntar Produto';
GO
EXEC dbo.TCC_MedirConsulta @Experimento='Q05', @Cenario='B_AGREGA_PRIMEIRO',
    @SQL=N';WITH Totais AS (
 SELECT iv.id_produto,SUM(CONVERT(bigint,iv.quantidade)) AS unidades
 FROM dbo.Venda AS v JOIN dbo.Item_Venda AS iv ON iv.id_venda=v.id_venda
 WHERE v.status=''FINALIZADA'' AND v.data_venda>=''20250701'' AND v.data_venda<''20251001''
 GROUP BY iv.id_produto
), TopProdutos AS (
 SELECT TOP(20) id_produto,unidades
 FROM Totais ORDER BY unidades DESC,id_produto
)
SELECT CONVERT(decimal(38,4),COALESCE(SUM(CONVERT(decimal(28,2),t.unidades)*(t.id_produto%31+1)+DATALENGTH(p.nome)),0)) AS resultado
FROM TopProdutos t JOIN dbo.Produto p ON p.id_produto=t.id_produto;', @Repeticoes=20, @Aquecimentos=5, @Observacao=N'segunda rodada B, controlar sequencia';
GO
EXEC dbo.TCC_MedirConsulta @Experimento='Q05', @Cenario='A_JOIN_PRIMEIRO',
    @SQL=N'SELECT CONVERT(decimal(38,4),COALESCE(SUM(CONVERT(decimal(28,2),r.unidades)*(r.id_produto%31+1)+DATALENGTH(r.nome)),0)) AS resultado
FROM (
 SELECT TOP (20) iv.id_produto,p.nome,SUM(CONVERT(bigint,iv.quantidade)) AS unidades
 FROM dbo.Venda AS v JOIN dbo.Item_Venda AS iv ON iv.id_venda=v.id_venda
 JOIN dbo.Produto AS p ON p.id_produto=iv.id_produto
 WHERE v.status=''FINALIZADA'' AND v.data_venda>=''20250701'' AND v.data_venda<''20251001''
 GROUP BY iv.id_produto,p.nome
 ORDER BY unidades DESC,iv.id_produto
) AS r;', @Repeticoes=20, @Aquecimentos=5, @Observacao=N'segunda rodada A, controlar sequencia';
GO
