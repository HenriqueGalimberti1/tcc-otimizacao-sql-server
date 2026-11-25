USE LojaDB_desempenho;
GO
-- Executar UM bloco escolhido com Ctrl+M (incluir plano real).
-- A consulta de producao do guia pode ter plano diferente da variante escalar
-- usada no medidor. Para validar a variante medida, copiar @SQL do Qxx correspondente
-- e executa-lo isoladamente com STATISTICS IO e TIME.
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO
-- Exemplo de catalogo de produtos (plano com/sem indice composto/cobertura):
SELECT p.id_produto,p.nome,p.preco_atual
FROM dbo.Produto AS p
WHERE p.id_categoria=12 AND p.preco_atual>=100 AND p.preco_atual<300
ORDER BY p.preco_atual,p.id_produto;
GO
-- Faturamento por mes, corresponde ao dominio do experimento Q04:
SELECT YEAR(v.data_venda) AS ano,MONTH(v.data_venda) AS mes,
 SUM(CONVERT(decimal(18,2),iv.quantidade)*iv.preco_unitario) AS faturamento
FROM dbo.Venda v JOIN dbo.Item_Venda iv ON iv.id_venda=v.id_venda
WHERE v.status='FINALIZADA' AND v.data_venda>='20250101' AND v.data_venda<'20260101'
GROUP BY YEAR(v.data_venda),MONTH(v.data_venda)
ORDER BY ano,mes;
GO
-- Refatoracao de data, comparar separadamente, MESMO indice para as duas:
SELECT COUNT_BIG(*) AS vendas
FROM dbo.Venda WHERE status='FINALIZADA' AND YEAR(data_venda)=2025;
GO
SELECT COUNT_BIG(*) AS vendas
FROM dbo.Venda WHERE status='FINALIZADA'
AND data_venda>='20250101' AND data_venda<'20260101';
GO
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO
