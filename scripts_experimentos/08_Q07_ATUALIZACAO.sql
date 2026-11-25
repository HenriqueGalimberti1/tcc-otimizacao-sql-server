USE LojaDB_desempenho;
GO
-- EXECUTAR ESTE ARQUIVO INTEIRO APENAS EM LABORATORIO.
-- Requer 01_INSTALAR_LABORATORIO.sql.
-- Limpa exclusivamente indices IX_TCC_*; preserva indices PK/UNIQUE e FKs.
EXEC dbo.TCC_LimparIndices;
GO
-- Q07: teste de escrita por ROLLBACK; a rotina registra apenas UPDATE.
-- Fechar outras transacoes. NAO executar em producao.
EXEC dbo.TCC_MedirAtualizacao 'A_BASE',20,5;
GO
CREATE NONCLUSTERED INDEX IX_TCC_Produto_Preco ON dbo.Produto(preco_atual);
GO
EXEC dbo.TCC_MedirAtualizacao 'B_COM_INDICE_PRECO',20,5;
GO
