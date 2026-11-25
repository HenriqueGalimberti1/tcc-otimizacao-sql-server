-- Objetos auxiliares do laboratorio na propria base; NAO altera tabelas de negocio.
-- Executar UMA vez em ambiente de testes. Nao executar em producao.
USE LojaDB_desempenho;
GO
IF OBJECT_ID(N'dbo.TCC_Medicoes',N'U') IS NULL
BEGIN
 CREATE TABLE dbo.TCC_Medicoes (
   id bigint IDENTITY(1,1) NOT NULL PRIMARY KEY,
   grupo uniqueidentifier NOT NULL,
   momento datetime2(3) NOT NULL DEFAULT SYSDATETIME(),
   experimento varchar(10) NOT NULL,
   cenario varchar(32) NOT NULL,
   repeticao int NOT NULL,
   duracao_ms decimal(19,3) NOT NULL,
   cpu_ms bigint NULL,
   leituras_logicas bigint NULL,
   leituras_fisicas bigint NULL,
   gravacoes_fisicas bigint NULL,
   resultado decimal(38,4) NULL,
   observacao nvarchar(300) NULL
 );
END;
GO
CREATE OR ALTER PROCEDURE dbo.TCC_LimparIndices
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @cmd nvarchar(max), @schema sysname, @tabela sysname, @indice sysname;
  DECLARE indice_cursor CURSOR LOCAL FAST_FORWARD FOR
  SELECT s.name, t.name, i.name
  FROM sys.indexes AS i
  JOIN sys.tables AS t ON i.object_id=t.object_id
  JOIN sys.schemas AS s ON s.schema_id=t.schema_id
  WHERE s.name=N'dbo' AND t.name IN
     (N'Categoria',N'Produto',N'Estoque',N'Fornecedor',N'Produto_Fornecedor',N'Cliente',N'Venda',N'Item_Venda',N'Pagamento')
    AND i.name LIKE N'IX[_]TCC[_]%'
    AND i.is_primary_key=0 AND i.is_unique_constraint=0;
  OPEN indice_cursor;
  FETCH NEXT FROM indice_cursor INTO @schema, @tabela, @indice;
  WHILE @@FETCH_STATUS=0
  BEGIN
    SET @cmd = N'DROP INDEX ' + QUOTENAME(@indice) + N' ON ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@tabela) + N';';
    EXEC sys.sp_executesql @cmd;
    FETCH NEXT FROM indice_cursor INTO @schema, @tabela, @indice;
  END;
  CLOSE indice_cursor; DEALLOCATE indice_cursor;
END;
GO
-- O procedimento abaixo captura UM resultado numerico por consulta; isso evita
-- renderizar milhares de linhas no SSMS e permite comparacoes uniformes.
-- A duracao inclui pequena sobrecarga de INSERT...EXEC/#temp; leituras/CPU sao
-- deltas da requisicao (tambem incluem instrumentacao). Confirmar casos selecionados
-- com SET STATISTICS IO/TIME e Plano de Execucao Real, fora deste procedimento.
CREATE OR ALTER PROCEDURE dbo.TCC_MedirConsulta
  @Experimento varchar(10), @Cenario varchar(32), @SQL nvarchar(max),
  @Repeticoes int=20, @Aquecimentos int=5, @Observacao nvarchar(300)=NULL
AS
BEGIN
 SET NOCOUNT ON;
 IF @Repeticoes NOT BETWEEN 1 AND 500 OR @Aquecimentos NOT BETWEEN 0 AND 100
   THROW 51002, 'Numero de repeticoes/aquecimentos invalido.',1;
 DECLARE @i int=1, @total int=@Repeticoes+@Aquecimentos;
 DECLARE @grupo uniqueidentifier=NEWID();
 DECLARE @inicio datetime2(7), @fim datetime2(7);
 DECLARE @cpu0 bigint,@cpu1 bigint,@log0 bigint,@log1 bigint,
         @fis0 bigint,@fis1 bigint,@write0 bigint,@write1 bigint;
 DECLARE @res decimal(38,4);
 CREATE TABLE #UmaResposta(resultado decimal(38,4) NULL);
 WHILE @i <= @total
 BEGIN
   TRUNCATE TABLE #UmaResposta;
   SELECT @cpu0=cpu_time, @log0=logical_reads, @fis0=reads, @write0=writes
   FROM sys.dm_exec_requests WHERE session_id=@@SPID;
   SET @inicio=SYSDATETIME();
   INSERT INTO #UmaResposta(resultado) EXEC sys.sp_executesql @SQL;
   SET @fim=SYSDATETIME();
   SELECT @cpu1=cpu_time, @log1=logical_reads, @fis1=reads, @write1=writes
   FROM sys.dm_exec_requests WHERE session_id=@@SPID;
   IF (SELECT COUNT_BIG(*) FROM #UmaResposta) <> 1
     THROW 51003, 'A consulta precisa devolver exatamente UMA linha e UMA coluna numerica.',1;
   SELECT @res=resultado FROM #UmaResposta;
   IF @i>@Aquecimentos
   BEGIN
      INSERT dbo.TCC_Medicoes
       (grupo,experimento,cenario,repeticao,duracao_ms,cpu_ms,leituras_logicas,
        leituras_fisicas,gravacoes_fisicas,resultado,observacao)
      VALUES
       (@grupo,@Experimento,@Cenario,@i-@Aquecimentos,
        DATEDIFF_BIG(MICROSECOND,@inicio,@fim)/1000.0,
        @cpu1-@cpu0,@log1-@log0,@fis1-@fis0,@write1-@write0,@res,@Observacao);
   END;
   SET @i+=1;
 END;
 SELECT experimento,cenario,COUNT(*) AS medicoes,
        AVG(duracao_ms) AS media_ms,MIN(duracao_ms) AS minimo_ms,
        MAX(duracao_ms) AS maximo_ms,MIN(resultado) AS resultado_min,
        MAX(resultado) AS resultado_max
 FROM dbo.TCC_Medicoes WHERE grupo=@grupo GROUP BY experimento,cenario;
END;
GO
-- Procedimento especifico Q07: atualiza, captura metricas, faz ROLLBACK,
-- e so grava o resultado DEPOIS do rollback. Evita ROLLBACK em INSERT EXEC.
CREATE OR ALTER PROCEDURE dbo.TCC_MedirAtualizacao
  @Cenario varchar(32), @Repeticoes int=20, @Aquecimentos int=5
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF @@TRANCOUNT<>0 THROW 51004, 'Executar Q07 fora de outra transacao.',1;
 IF @Repeticoes NOT BETWEEN 1 AND 500 OR @Aquecimentos NOT BETWEEN 0 AND 100
   THROW 51005, 'Numero de repeticoes/aquecimentos invalido.',1;
 DECLARE @i int=1,@total int=@Repeticoes+@Aquecimentos,@linhas int;
 DECLARE @grupo uniqueidentifier=NEWID(), @inicio datetime2(7),@fim datetime2(7);
 DECLARE @cpu0 bigint,@cpu1 bigint,@log0 bigint,@log1 bigint,
         @fis0 bigint,@fis1 bigint,@write0 bigint,@write1 bigint;
 WHILE @i<=@total
 BEGIN
  BEGIN TRY
   SELECT @cpu0=cpu_time, @log0=logical_reads, @fis0=reads, @write0=writes
   FROM sys.dm_exec_requests WHERE session_id=@@SPID;
   BEGIN TRANSACTION;
   SET @inicio=SYSDATETIME();
   UPDATE dbo.Produto
      SET preco_atual=preco_atual+CONVERT(decimal(10,2),0.01)
      WHERE id_produto BETWEEN 1000 AND 9999;
   SET @linhas=@@ROWCOUNT;
   SET @fim=SYSDATETIME();
   SELECT @cpu1=cpu_time,@log1=logical_reads,@fis1=reads,@write1=writes
   FROM sys.dm_exec_requests WHERE session_id=@@SPID;
   ROLLBACK TRANSACTION;
  END TRY
  BEGIN CATCH
   IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
   THROW;
  END CATCH;
  IF @i>@Aquecimentos
  BEGIN
   INSERT dbo.TCC_Medicoes
    (grupo,experimento,cenario,repeticao,duracao_ms,cpu_ms,
     leituras_logicas,leituras_fisicas,gravacoes_fisicas,resultado,observacao)
   VALUES
    (@grupo,'Q07',@Cenario,@i-@Aquecimentos,
     DATEDIFF_BIG(MICROSECOND,@inicio,@fim)/1000.0,
     @cpu1-@cpu0,@log1-@log0,@fis1-@fis0,@write1-@write0,
     CONVERT(decimal(38,4),@linhas),N'Tempo somente UPDATE; ROLLBACK excluido; efeitos de log podem variar');
  END;
  SET @i+=1;
 END;
 SELECT experimento,cenario,COUNT(*) AS medicoes,AVG(duracao_ms) AS media_ms,
        MIN(resultado) AS linhas_min,MAX(resultado) AS linhas_max
 FROM dbo.TCC_Medicoes WHERE grupo=@grupo GROUP BY experimento,cenario;
END;
GO
