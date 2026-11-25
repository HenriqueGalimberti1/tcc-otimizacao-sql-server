USE LojaDB_desempenho;
GO
-- APENAS DIAGNOSTICO: CHECKs de integridade sao conceito distinto de otimizar consultas.
SELECT
 (SELECT COUNT_BIG(*) FROM dbo.Produto WHERE preco_atual<=0) AS produtos_preco_nao_positivo,
 (SELECT COUNT_BIG(*) FROM dbo.Item_Venda WHERE quantidade<=0) AS itens_qtd_nao_positiva,
 (SELECT COUNT_BIG(*) FROM dbo.Estoque WHERE quantidade_disponivel<0) AS estoques_negativos,
 (SELECT COUNT_BIG(*) FROM dbo.Pagamento WHERE valor<=0) AS pagamentos_nao_positivos;
-- Se o grupo quiser aplicar as restricoes do script 03 original, decidir e
-- documentar a partir de QUAL momento valem para TODOS os cenarios.
-- Nao classificar CHECK como intervencao automaticamente aceleradora.
GO
