USE LojaDB_desempenho;
GO
-- EXECUTAR ESTE ARQUIVO INTEIRO APENAS EM LABORATORIO.
-- Requer 01_INSTALAR_LABORATORIO.sql.
-- Limpa exclusivamente indices IX_TCC_*; preserva indices PK/UNIQUE e FKs.
EXEC dbo.TCC_LimparIndices;
GO
-- Q06: comparar funcao YEAR vs intervalo, com INDEX IGUAL nas duas.
CREATE NONCLUSTERED INDEX IX_TCC_Venda_Status_Data
 ON dbo.Venda(status,data_venda);
GO
EXEC dbo.TCC_MedirConsulta @Experimento='Q06', @Cenario='A_YEAR',
    @SQL=N'SELECT CONVERT(decimal(38,4),COUNT_BIG(*)) AS resultado
FROM dbo.Venda AS v WHERE v.status=''FINALIZADA'' AND YEAR(v.data_venda)=2025;', @Repeticoes=20, @Aquecimentos=5, @Observacao=N'funcao YEAR aplicada a data';
GO
EXEC dbo.TCC_MedirConsulta @Experimento='Q06', @Cenario='B_INTERVALO',
    @SQL=N'SELECT CONVERT(decimal(38,4),COUNT_BIG(*)) AS resultado
FROM dbo.Venda AS v WHERE v.status=''FINALIZADA''
  AND v.data_venda>=''20250101'' AND v.data_venda<''20260101'';', @Repeticoes=20, @Aquecimentos=5, @Observacao=N'range SARGable';
GO
EXEC dbo.TCC_MedirConsulta @Experimento='Q06', @Cenario='B_INTERVALO',
    @SQL=N'SELECT CONVERT(decimal(38,4),COUNT_BIG(*)) AS resultado
FROM dbo.Venda AS v WHERE v.status=''FINALIZADA''
  AND v.data_venda>=''20250101'' AND v.data_venda<''20260101'';', @Repeticoes=20, @Aquecimentos=5, @Observacao=N'segunda rodada B';
GO
EXEC dbo.TCC_MedirConsulta @Experimento='Q06', @Cenario='A_YEAR',
    @SQL=N'SELECT CONVERT(decimal(38,4),COUNT_BIG(*)) AS resultado
FROM dbo.Venda AS v WHERE v.status=''FINALIZADA'' AND YEAR(v.data_venda)=2025;', @Repeticoes=20, @Aquecimentos=5, @Observacao=N'segunda rodada A';
GO
