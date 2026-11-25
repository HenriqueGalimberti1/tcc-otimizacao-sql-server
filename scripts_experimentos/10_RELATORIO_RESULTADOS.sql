USE LojaDB_desempenho;
GO
-- Leituras: diferencas da sessao, incluindo pequena sobrecarga da instrumentacao;
-- para plano real e E/S por tabela, ver README (STATISTICS IO/TIME).
;WITH med AS (
 SELECT experimento,cenario,grupo,repeticao,duracao_ms,cpu_ms,leituras_logicas,
        leituras_fisicas,gravacoes_fisicas,resultado,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY duracao_ms)
         OVER (PARTITION BY experimento,cenario) AS mediana_ms,
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY duracao_ms)
         OVER (PARTITION BY experimento,cenario) AS p95_ms
 FROM dbo.TCC_Medicoes
), resumo AS (
 SELECT experimento,cenario,COUNT_BIG(*) AS n,
        CONVERT(decimal(19,3),AVG(duracao_ms)) AS media_ms,
        CONVERT(decimal(19,3),MAX(mediana_ms)) AS mediana_ms,
        CONVERT(decimal(19,3),MAX(p95_ms)) AS p95_ms,
        CONVERT(decimal(19,3),STDEV(CONVERT(float,duracao_ms))) AS dp_ms,
        CONVERT(decimal(19,2),AVG(CONVERT(float,cpu_ms))) AS cpu_medio_ms,
        CONVERT(decimal(19,2),AVG(CONVERT(float,leituras_logicas))) AS leituras_logicas_medias,
        MIN(resultado) AS resultado_min,MAX(resultado) AS resultado_max
 FROM med GROUP BY experimento,cenario
), base AS (
 SELECT experimento,mediana_ms AS base_mediana
 FROM resumo WHERE cenario='A_BASE' OR cenario LIKE 'A[_]%'
)
SELECT r.*,
       CONVERT(decimal(10,2), 100.0 * (b.base_mediana-r.mediana_ms)/NULLIF(b.base_mediana,0)) AS reducao_tempo_vs_A_pct
FROM resumo AS r
OUTER APPLY (SELECT MAX(base_mediana) AS base_mediana FROM base b WHERE b.experimento=r.experimento) AS b
ORDER BY r.experimento,r.cenario;
GO
-- Se resultados minimo e maximo diferirem entre cenarios de um experimento,
-- conferir equivalencia semantica. Em consultas de ranking ver validacao especifica.
SELECT experimento,cenario,COUNT_BIG(*) AS repeticoes,
 MIN(resultado) AS resultado_min, MAX(resultado) AS resultado_max
FROM dbo.TCC_Medicoes GROUP BY experimento,cenario ORDER BY experimento,cenario;
GO
-- Imprime todas as observacoes para exportacao como CSV no SSMS.
SELECT id,momento,experimento,cenario,repeticao,duracao_ms,cpu_ms,
 leituras_logicas,leituras_fisicas,gravacoes_fisicas,resultado,observacao
FROM dbo.TCC_Medicoes ORDER BY experimento,cenario,id;
GO
