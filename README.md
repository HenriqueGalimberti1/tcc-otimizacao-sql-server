# Guia Prático de Otimização de Banco de Dados Relacionais

[![SQL Server](https://img.shields.io/badge/SQL%20Server-2025%20Developer-CC292B?logo=microsoftsqlserver&logoColor=white)](https://www.microsoft.com/sql-server)
[![SSMS](https://img.shields.io/badge/SSMS-v22-0078D4?logo=microsoft&logoColor=white)](https://learn.microsoft.com/sql/ssms/)
[![Dataset](https://img.shields.io/badge/Dataset-%3E%202.8M%20registros-2ea44f)](#modelagem-e-dataset)
[![Licença](https://img.shields.io/badge/Licen%C3%A7a-MIT-blue.svg)](LICENSE)

Repositório com os scripts SQL, instrumentação experimental, medições brutas e relatórios estatísticos do Trabalho de Conclusão de Curso (TCC) em **Engenharia da Computação** pelo **Centro Universitário Multivix Vitória (2026)**.

* **Autores:** Daniel Padovani Alcântara, Henrique Galimberti Abreu dos Santos, Leticia Cassoli Dias Siqueira
* **Orientador:** Prof. Me. Kevyn Phillipe Gusmão

---

## 📌 Visão Geral do Projeto

Este estudo analisa empiricamente o impacto de estratégias de **indexação física** (índices simples, compostos e de cobertura) e de **reescrita lógica de consultas SQL** sobre o desempenho do Microsoft SQL Server 2025. 

As métricas analisadas compreendem:
* **Tempo de resposta / latência** (mediana, média, percentil 95 e desvio-padrão);
* **Tempo de processamento de CPU** (ms);
* **Volume de I/O em memória** (leituras lógicas de páginas de 8 KB).

Ao todo, foram executados **8 experimentos controlados (Q01 a Q08)** contemplando **23 cenários de intervenção**, totalizando **540 observações medidas** em um ambiente isolado e sem concorrência externa.

---

## 🗄️ Modelagem e Dataset (`LojaDB_desempenho`)

O ambiente experimental adota um modelo relacional normalizado composto por 9 entidades principais, simulando as operações de um comércio eletrônico:

* `Categoria` (20 registros)
* `Fornecedor` (500 registros)
* `Produto` (50.000 registros)
* `Estoque` (50.000 registros, 1:1 com Produto)
* `Produto_Fornecedor` (~150.000 associações N:N)
* `Cliente` (100.000 registros)
* `Venda` (500.000 registros distribuídos em 3 anos históricos)
* `Pagamento` (500.000 registros sincronizados)
* `Item_Venda` (1.500.000 registros de itens comercializados)

**Volumetria consolidada:** mais de **2,8 milhões de registros**.

---

## 🖥️ Especificações do Ambiente Experimental

* **Processador:** Intel Core i7-14700K
* **Memória RAM:** 32 GB DDR5
* **Armazenamento:** SSD Kingston NV3 M.2 NVMe (1 TB)
* **Sistema Operacional:** Windows 11 Home (64 bits)
* **SGBD:** Microsoft SQL Server 2025 Developer Edition (Standard Developer, configurações padrão)
* **Ferramenta de Gerenciamento:** SQL Server Management Studio (SSMS) v22

---

## 📁 Estrutura do Repositório

```text
tcc-otimizacao-sql-server/
│
├── database/
│   ├── 01_BDTCC_Criacao.sql              # DDL de criação do banco e das 9 tabelas
│   └── 02_BDTCC_Carga_Aleatoria.sql      # Carga sintética automatizada (~2,8M tuplas)
│
├── scripts_experimentos/
│   ├── 00_VERIFICAR_BASE.sql             # Conferência de volumetria, datas e índices iniciais
│   ├── 01_INSTALAR_LABORATORIO.sql       # Instalação de TCC_Medicoes e procedures de coleta
│   ├── 02_Q01_PRODUTOS_INDICES.sql       # Q01: Filtro seletivo (simples, composto e cobertura)
│   ├── 03_Q02_VENDAS_CLIENTE.sql         # Q02: Filtro por cliente e intervalo temporal
│   ├── 04_Q03_JOIN_VENDA_ITEM.sql        # Q03: Indexação de FK em operações de junção
│   ├── 05_Q04_FATURAMENTO_MENSAL.sql     # Q04: Consulta analítica com índices acumulados
│   ├── 06_Q05_RANKING_REESCRITA.sql      # Q05: Reescrita lógica (agregação antes de JOIN)
│   ├── 07_Q06_DATA_REFATORACAO.sql       # Q06: Função YEAR() vs. intervalo de datas (SARGable)
│   ├── 08_Q07_ATUALIZACAO.sql            # Q07: Custo de manutenção de índice em UPDATE
│   ├── 09_Q08_ITEM_POR_PRODUTO.sql       # Q08: Impacto de índices em tabela de grande porte
│   ├── 10_RELATORIO_RESULTADOS.sql       # Consolidação estatística dos 23 cenários
│   ├── 11_VALIDAR_RESULTADOS.sql         # Teste de equivalência lógica de conjuntos (Q05 e Q06)
│   ├── 12_AMOSTRAS_PARA_PLANOS.sql       # Consultas para extração de planos de execução reais
│   ├── 13_LIMPAR_APENAS_INDICES_TCC.sql  # Utilitário: exclusão de índices criados no teste
│   ├── 14_CHECK_OPCIONAL_INTEGRIDADE.sql # Utilitário: checagem de integridade das tabelas
│   └── 16_LIMPAR_MEDICOES_OPCIONAL.sql   # Utilitário: limpeza da tabela de histórico
│
├── resultados/
│   ├── TCC_Medicoes_540_observacoes.csv  # 540 observações coletadas no laboratório
│   ├── relatorio_estatistico_consolidado.csv # Estatísticas consolidadas por cenário
│   ├── 15_FICHA_COLETA_MANUAL.xlsx       # Planilha integrada com dados e resumos
│   └── planos_execucao/                  # Capturas dos Planos de Execução Reais no SSMS
│
├── .gitignore
├── LICENSE
└── README.md
```

---

## 🚀 Guia de Reprodução Passo a Passo

Para reproduzir os testes com integridade metodológica, execute as etapas no SSMS conectado a uma instância local do SQL Server:

1. **Criação do Banco de Dados:** Execute `database/01_BDTCC_Criacao.sql`.
2. **Carga dos Dados:** Execute `database/02_BDTCC_Carga_Aleatoria.sql` para gerar o dataset sintético.
3. **Verificação Preliminar:** Execute `scripts_experimentos/00_VERIFICAR_BASE.sql` e verifique se as contagens correspondem à volumetria esperada.
4. **Instalação do Laboratório:** Execute `scripts_experimentos/01_INSTALAR_LABORATORIO.sql`. Essa rotina cria a tabela `TCC_Medicoes` e as procedures de medição.
5. **Execução dos Experimentos:** Execute individualmente os scripts de `02_Q01_PRODUTOS_INDICES.sql` até `09_Q08_ITEM_POR_PRODUTO.sql`. Cada script aplica o aquecimento prévio (5 execuções) e coleta 20 repetições por cenário.
6. **Validação Lógica:** Execute `scripts_experimentos/11_VALIDAR_RESULTADOS.sql` para atestar a equivalência de resultados entre as consultas refatoradas (Q05 e Q06).
7. **Consolidação Estatística:** Execute `scripts_experimentos/10_RELATORIO_RESULTADOS.sql` para obter os tempos médios, medianas, percentis e leituras lógicas.
8. **Análise de Planos Reais:** Ative o Plano de Execução Real (`Ctrl + M`) no SSMS e rode `scripts_experimentos/12_AMOSTRAS_PARA_PLANOS.sql` para inspecionar os operadores (Seeks, Scans, Lookups).
9. **Restauração do Ambiente:** Para remover os índices criados sem alterar os dados, execute `scripts_experimentos/13_LIMPAR_APENAS_INDICES_TCC.sql`.

---

## 📊 Matriz de Experimentos

| Consulta | Tabela(s) | Cenários | Foco do Experimento |
| :---: | :--- | :---: | :--- |
| **Q01** | `Produto` | A a D | Índice simples, composto e índice de cobertura (`INCLUDE`) |
| **Q02** | `Venda` | A a C | Filtragem por cliente e data com cobertura de status |
| **Q03** | `Venda`, `Item_Venda` | A a C | Indexação de foreign key em junções de tabelas volumosas |
| **Q04** | `Venda`, `Item_Venda` | A a D | Consulta analítica (agregação temporal) com índices progressivos |
| **Q05** | `Venda`, `Item_Venda`, `Produto` | A e B | Reorganização de álgebra relacional: agregação prévia antes do JOIN |
| **Q06** | `Venda` | A e B | Predicado não-SARGable (`YEAR()`) versus intervalo explícito de datas |
| **Q07** | `Produto` | A e B | Sobrecarga de manutenção de índices em operações de escrita (`UPDATE`) |
| **Q08** | `Item_Venda` | A a C | Otimização de consultas em tabela com ~1,5 milhão de linhas |

---

## 📈 Resumo dos Resultados

### Leituras Lógicas Médias por Cenário

| Teste | Cenário A (Baseline) | Cenário B | Cenário C | Cenário D | Variação Final vs. A |
| :---: | :---: | :---: | :---: | :---: | :--- |
| **Q01** | 288,75 | 289,05 | 288,60 | 26,60 | **-90,8%** |
| **Q02** | 2.306,35 | 66,90 | 25,35 | — | **-98,9%** |
| **Q03** | 6.442,60 | 132,60 | 52,35 | — | **-99,2%** |
| **Q04** | 8.837,90 | 6.737,35 | 6.737,05 | 5.390,75 | **-39,0%** |
| **Q05** | 4.570,10 | 4.264,60 | — | — | **-6,7%** |
| **Q06** | 860,83 | 304,20 | — | — | **-64,7%** |
| **Q07** | 9.050,00 | 63.533,05 | — | — | **+602,0%** (Escrita) |
| **Q08** | 6.439,75 | 231,60 | 25,20 | — | **-99,6%** |

### Duração e Tempo de CPU

| Teste | Cenário | Duração Média (ms) | Mediana (ms) | DP (ms) | CPU Média (ms) | Variação Mediana |
| :---: | :--- | :---: | :---: | :---: | :---: | :---: |
| **Q01** | `A_BASE` | 2,85 | 2,84 | 0,95 | 2,60 | Baseline |
| **Q01** | `D_COBERTURA` | 0,30 | 0,00* | 0,47 | 0,50 | -100,0%* |
| **Q02** | `A_BASE` | 21,68 | 22,04 | 1,49 | 21,75 | Baseline |
| **Q02** | `C_COMPOSTO` | 0,20 | 0,00* | 0,41 | 0,20 | -100,0%* |
| **Q03** | `A_BASE` | 9,10 | 8,73 | 2,78 | 30,00 | Baseline |
| **Q03** | `C_COBERTURA` | 0,18 | 0,00* | 0,44 | 0,20 | -100,0%* |
| **Q04** | `A_BASE` | 40,12 | 41,01 | 7,12 | 210,70 | Baseline |
| **Q04** | `D_COBERTURA` | 28,75 | 27,59 | 5,15 | 161,65 | -32,7% |
| **Q05** | `A_JOIN_PRIMEIRO` | 17,02 | 17,26 | 2,13 | 74,58 | Baseline |
| **Q05** | `B_AGREGA_PRIMEIRO` | 15,58 | 15,94 | 2,28 | 65,18 | -7,6% |
| **Q06** | `A_YEAR` | 18,66 | 18,66 | 2,09 | 18,78 | Baseline |
| **Q06** | `B_INTERVALO` | 4,45 | 4,21 | 0,51 | 4,35 | **-77,5%** |
| **Q07** | `A_BASE` | 7,14 | 6,52 | 1,95 | 7,30 | Baseline |
| **Q07** | `B_COM_INDICE_PRECO` | 51,04 | 49,51 | 19,38 | 48,30 | **+659,8%** |
| **Q08** | `A_BASE` | 13,09 | 13,53 | 1,74 | 63,25 | Baseline |
| **Q08** | `C_COBERTURA` | 0,15 | 0,00* | 0,37 | 0,20 | -100,0%* |

*\*Nota: Mediana registrada como 0,00 ms em função da resolução temporal de consultas submilissegundo; nesses casos, a média e a diminuição drástica das leituras lógicas atestam o ganho físico.*

---

## 🔍 Conclusões Técnicas Centrais

1. **Eficiência de Índices de Cobertura (`INCLUDE`):** A eliminação de saltos à tabela principal (*Key Lookups*) reduziu as leituras lógicas em mais de 98% a 99% em consultas seletivas e de junção (Q02, Q03 e Q08).
2. **Predicados SARGable:** A substituição de chamadas de funções escalares (`YEAR(data_venda) = 2025`) por intervalos indexáveis explícitos reduziu o tempo de execução em **77,45%** e o consumo de CPU em **76,8%** (Q06) com a mesma estrutura de dados.
3. **Custo de Manutenção em Escritas (DML):** A criação de um índice sobre uma coluna constantemente atualizada aumentou a mediana do tempo de `UPDATE` de **6,52 ms para 49,51 ms (+659,8%)**, demonstrando a necessidade de equilíbrio entre desempenho de leitura e impacto em escrita (Q07).

---

## 📜 Como Citar

```bibtex
@monography{alcantara2026guia,
  author    = {Daniel Padovani Alcântara and Henrique Galimberti Abreu dos Santos and Leticia Cassoli Dias Siqueira},
  title     = {Guia prático de otimização de banco de dados relacionais},
  school    = {Centro Universitário Multivix Vitória},
  year      = {2026},
  type      = {Trabalho de Conclusão de Curso (Graduação em Engenharia da Computação)},
  address   = {Vitória, ES},
  url       = {https://github.com/HenriqueGalimberti1/tcc-otimizacao-sql-server}
}
```

---

## 📄 Licença

Este projeto é disponibilizado sob os termos da licença [MIT](LICENSE).
