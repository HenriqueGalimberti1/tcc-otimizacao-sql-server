# Guia Prático de Otimização de Bancos de Dados Relacionais

Repositório oficial contendo os scripts SQL, a instrumentação experimental, os dados brutos (`TCC_Medicoes`) e os relatórios estatísticos do Trabalho de Conclusão de Curso (TCC) apresentado ao curso de **Engenharia da Computação – Multivix Vitória (2026)**.

* **Autores:** Daniel Padovani Alcântara, Henrique Galimberti Abreu dos Santos, Leticia Cassoli Dias Siqueira
* **Orientador:** Prof. Me. Kevyn Phillipe Gusmão

---

## Sobre o Projeto

Este estudo avalia empiricamente o impacto de técnicas de indexação física e reescrita de consultas SQL sobre o tempo de resposta (ms), consumo de CPU (ms) e leituras lógicas de páginas de dados no **Microsoft SQL Server 2025**.

Os experimentos foram conduzidos sobre a base simulada de comércio eletrônico **`LojaDB_desempenho`**, composta por 9 tabelas normalizadas e mais de **2,8 milhões de registros**. Foram executados **8 experimentos controlados (Q01 a Q08)** distribuídos em **23 cenários**, totalizando **540 observações medidas** (cada bloco contou com 5 execuções de aquecimento seguidas de 20 execuções medidas via `sys.dm_exec_requests`).

---

## Estrutura do Repositório

* **`database/`**: Scripts DDL de criação do esquema relacional (`LojaDB_desempenho`) e rotina de carga sintética (~2,8 milhões de tuplas).
* **`scripts_experimentos/`**:
  * `00_VERIFICAR_BASE.sql`: Validação da volumetria e dos índices preexistentes.
  * `01_INSTALAR_LABORATORIO.sql`: Criação da tabela `TCC_Medicoes` e das rotinas `TCC_MedirConsulta` e `TCC_MedirAtualizacao`.
  * `02_Q01` a `09_Q08`: Scripts individuais de cada experimento e seus respectivos cenários (A a D).
  * `10_RELATORIO_RESULTADOS.sql`: Consolidação estatística (média, mediana, percentil 95, desvio-padrão, CPU e leituras lógicas).
  * `11_VALIDAR_RESULTADOS.sql`: Verificação de equivalência lógica entre consultas reescritas (`Q05` e `Q06`).
  * `12_AMOSTRAS_PARA_PLANOS.sql`: Consultas isoladas para inspeção de plano de execução real, `SET STATISTICS IO` e `SET STATISTICS TIME` no SSMS.
* **`resultados/`**: Exportação completa das 540 medições individuais e do relatório estatístico consolidado em formato `.csv`.

---

## Ambiente Experimental

* **Sistema Operacional:** Windows 11 Home
* **Processador:** Intel Core i7-14700K
* **Memória RAM:** 32 GB
* **Armazenamento:** SSD Kingston NV3 M.2 NVMe (1 TB)
* **SGBD:** Microsoft SQL Server 2025 Developer Edition (configurações padrão)
* **Ferramenta de Administração:** SQL Server Management Studio (SSMS) 22

---

## Como Reproduzir os Experimentos

1. **Criar e popular a base:** Execute `database/01_criar_banco_tabelas.sql` e, em seguida, `database/02_popular_dados.sql`.
2. **Conferir a base:** Execute `scripts_experimentos/00_VERIFICAR_BASE.sql` para validar as contagens e os índices iniciais.
3. **Instalar a instrumentação:** Execute `scripts_experimentos/01_INSTALAR_LABORATORIO.sql`.
4. **Rodar um experimento:** Execute o script desejado entre `02_Q01` e `09_Q08` (ex.: `07_Q06_DATA_REFATORACAO.sql`). Ao repetir rodadas, identifique o grupo de execução para manter o histórico separado.
5. **Validar equivalência (apenas Q05 e Q06):** Execute `scripts_experimentos/11_VALIDAR_RESULTADOS.sql`.
6. **Gerar o relatório:** Execute `scripts_experimentos/10_RELATORIO_RESULTADOS.sql` para consultar as métricas consolidadas.
7. **Inspecionar planos reais:** Ative o plano de execução real (`Ctrl + M`) no SSMS e rode `scripts_experimentos/12_AMOSTRAS_PARA_PLANOS.sql`.

---

## Síntese dos Experimentos (Q01 a Q08)

| Consulta | Tabelas Envolvidas | Cenários | Aspecto Avaliado |
| :--- | :--- | :--- | :--- |
| **Q01** | `Produto` | A a D | Índice simples, composto e de cobertura |
| **Q02** | `Venda` | A a C | Índice simples e composto com cobertura |
| **Q03** | `Venda`, `Item_Venda` | A a C | Indexação da chave de junção e cobertura |
| **Q04** | `Venda`, `Item_Venda` | A a D | Consulta analítica com índices acumulados |
| **Q05** | `Venda`, `Item_Venda`, `Produto` | A e B | Reescrita da consulta (agregar antes de juntar) |
| **Q06** | `Venda` | A e B | Predicado de data com função `YEAR()` × intervalo explícito |
| **Q07** | `Produto` | A e B | Custo de manutenção do índice em atualização (`UPDATE`) |
| **Q08** | `Item_Venda` | A a C | Índice simples e de cobertura em tabela grande (~1,5M linhas) |

---

## Principais Resultados Obtidos

### 1. Média de Leituras Lógicas por Cenário

| Teste | Cenário A | Cenário B | Cenário C | Cenário D | Variação Final vs. A |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **Q01** | 288,75 | 289,05 | 288,60 | 26,60 | Redução de 90,8% |
| **Q02** | 2.306,35 | 66,90 | 25,35 | — | Redução de 98,9% |
| **Q03** | 6.442,60 | 132,60 | 52,35 | — | Redução de 99,2% |
| **Q04** | 8.837,90 | 6.737,35 | 6.737,05 | 5.390,75 | Redução de 39,0% |
| **Q05** | 4.570,10 | 4.264,60 | — | — | Redução de 6,7% |
| **Q06** | 860,83 | 304,20 | — | — | Redução de 64,7% |
| **Q07** | 9.050,00 | 63.533,05 | — | — | Aumento de 602,0% |
| **Q08** | 6.439,75 | 231,60 | 25,20 | — | Redução de 99,6% |

### 2. Duração, Tempo de CPU e Redução da Mediana

| Teste | Cenário | Média (ms) | Mediana (ms) | DP (ms) | CPU Média (ms) | Redução (%) |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| **Q01** | `A_BASE` | 2,85 | 2,84 | 0,95 | 2,60 | 0,00 |
| **Q01** | `B_SIMPLES` | 2,39 | 2,03 | 0,50 | 2,45 | 28,67 |
| **Q01** | `C_COMPOSTO` | 2,39 | 2,01 | 0,52 | 2,65 | 29,28 |
| **Q01** | `D_COBERTURA` | 0,30 | 0,00 | 0,47 | 0,50 | 100,00* |
| **Q02** | `A_BASE` | 21,68 | 22,04 | 1,49 | 21,75 | 0,00 |
| **Q02** | `B_SIMPLES` | 0,10 | 0,00 | 0,31 | 0,25 | 100,00* |
| **Q02** | `C_COMPOSTO` | 0,20 | 0,00 | 0,41 | 0,20 | 100,00* |
| **Q03** | `A_BASE` | 9,10 | 8,73 | 2,78 | 30,00 | 0,00 |
| **Q03** | `B_FK` | 0,21 | 0,00 | 0,42 | 0,20 | 100,00* |
| **Q03** | `C_COBERTURA` | 0,18 | 0,00 | 0,44 | 0,20 | 100,00* |
| **Q04** | `A_BASE` | 40,12 | 41,01 | 7,12 | 210,70 | 0,00 |
| **Q04** | `B_VENDA` | 30,31 | 29,99 | 4,43 | 176,05 | 26,88 |
| **Q04** | `C_ITEM` | 30,15 | 29,79 | 4,37 | 175,60 | 27,36 |
| **Q04** | `D_COBERTURA` | 28,75 | 27,59 | 5,15 | 161,65 | 32,73 |
| **Q05** | `A_JOIN_PRIMEIRO` | 17,02 | 17,26 | 2,13 | 74,58 | 0,00 |
| **Q05** | `B_AGREGA_PRIMEIRO` | 15,58 | 15,94 | 2,28 | 65,18 | 7,65 |
| **Q06** | `A_YEAR` | 18,66 | 18,66 | 2,09 | 18,78 | 0,00 |
| **Q06** | `B_INTERVALO` | 4,45 | 4,21 | 0,51 | 4,35 | 77,45 |
| **Q07** | `A_BASE` | 7,14 | 6,52 | 1,95 | 7,30 | 0,00 |
| **Q07** | `B_COM_INDICE_PRECO` | 51,04 | 49,51 | 19,38 | 48,30 | -659,78 |
| **Q08** | `A_BASE` | 13,09 | 13,53 | 1,74 | 63,25 | 0,00 |
| **Q08** | `B_PRODUTO` | 0,40 | 0,00 | 0,50 | 0,30 | 100,00* |
| **Q08** | `C_COBERTURA` | 0,15 | 0,00 | 0,37 | 0,20 | 100,00* |

*\*Nota: Em sete cenários, a mediana registrada foi 0,00 ms devido à resolução temporal das medições rápidas; nesses casos, a média e as leituras lógicas complementam a interpretação do ganho de desempenho.*
