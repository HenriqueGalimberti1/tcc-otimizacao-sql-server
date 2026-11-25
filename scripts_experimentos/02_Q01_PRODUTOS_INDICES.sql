USE LojaDB_desempenho;
GO
-- EXECUTAR ESTE ARQUIVO INTEIRO APENAS EM LABORATORIO.
-- Requer 01_INSTALAR_LABORATORIO.sql.
-- Limpa exclusivamente indices IX_TCC_*; preserva indices PK/UNIQUE e FKs.
EXEC dbo.TCC_LimparIndices;
GO
-- Q01: mesma consulta, quatro configuracoes alternativas; nao acumular indices.
-- Resultado numerico agrega preco e bytes do nome, forçando necessidade de 'nome'.
EXEC dbo.TCC_MedirConsulta @Experimento='Q01', @Cenario='A_BASE',
    @SQL=N'SELECT CONVERT(decimal(38,4),COALESCE(SUM(CONVERT(decimal(18,2),p.preco_atual)+CONVERT(decimal(18,2),DATALENGTH(p.nome))),0)) AS resultado
FROM dbo.Produto AS p
WHERE p.id_categoria=12 AND p.preco_atual>=100.00 AND p.preco_atual<300.00;', @Repeticoes=20, @Aquecimentos=5, @Observacao=N'sem indice secundario';
GO

CREATE NONCLUSTERED INDEX IX_TCC_Produto_Categoria ON dbo.Produto(id_categoria);
GO
EXEC dbo.TCC_MedirConsulta @Experimento='Q01', @Cenario='B_SIMPLES',
    @SQL=N'SELECT CONVERT(decimal(38,4),COALESCE(SUM(CONVERT(decimal(18,2),p.preco_atual)+CONVERT(decimal(18,2),DATALENGTH(p.nome))),0)) AS resultado
FROM dbo.Produto AS p
WHERE p.id_categoria=12 AND p.preco_atual>=100.00 AND p.preco_atual<300.00;', @Repeticoes=20, @Aquecimentos=5, @Observacao=N'id_categoria';
GO

DROP INDEX IX_TCC_Produto_Categoria ON dbo.Produto;
CREATE NONCLUSTERED INDEX IX_TCC_Produto_Categoria_Preco
 ON dbo.Produto(id_categoria,preco_atual,id_produto);
GO
EXEC dbo.TCC_MedirConsulta @Experimento='Q01', @Cenario='C_COMPOSTO',
    @SQL=N'SELECT CONVERT(decimal(38,4),COALESCE(SUM(CONVERT(decimal(18,2),p.preco_atual)+CONVERT(decimal(18,2),DATALENGTH(p.nome))),0)) AS resultado
FROM dbo.Produto AS p
WHERE p.id_categoria=12 AND p.preco_atual>=100.00 AND p.preco_atual<300.00;', @Repeticoes=20, @Aquecimentos=5, @Observacao=N'categoria,preco,produto';
GO

DROP INDEX IX_TCC_Produto_Categoria_Preco ON dbo.Produto;
CREATE NONCLUSTERED INDEX IX_TCC_Produto_Categoria_Preco_Include
 ON dbo.Produto(id_categoria,preco_atual,id_produto) INCLUDE(nome);
GO
EXEC dbo.TCC_MedirConsulta @Experimento='Q01', @Cenario='D_COBERTURA',
    @SQL=N'SELECT CONVERT(decimal(38,4),COALESCE(SUM(CONVERT(decimal(18,2),p.preco_atual)+CONVERT(decimal(18,2),DATALENGTH(p.nome))),0)) AS resultado
FROM dbo.Produto AS p
WHERE p.id_categoria=12 AND p.preco_atual>=100.00 AND p.preco_atual<300.00;', @Repeticoes=20, @Aquecimentos=5, @Observacao=N'indice composto com INCLUDE(nome)';
GO
