# Machine Learning aplicado a atributos de solos — Ribeirão Marcela

**Portfólio técnico | R · Random Forest · SVM · PCA · Validação cruzada**

> **Status:** documentação de pesquisa em revisão. Os códigos são versões históricas selecionadas para estudo, **não** uma implementação científica definitivamente aprovada nem uma aplicação pronta para produção. Dados brutos e resultados não são disponibilizados neste repositório.

## Visão geral

Este repositório documenta uma parte do trabalho de iniciação científica desenvolvido na **Universidade Federal de Lavras (UFLA)**, na área de Ciência do Solo. O objetivo da pesquisa é investigar relações entre dados obtidos por **espectrometria de fluorescência de raios X portátil (pXRF)** e atributos de solos da sub-bacia do **Ribeirão Marcela**, utilizando análise exploratória e modelos de aprendizado de máquina.

O conjunto de dados utilizado no trabalho histórico contém **54 amostras**. A base pertence ao contexto de pesquisa da equipe e **não acompanha os códigos**.

### O que foi desenvolvido

- Preparação e seleção de variáveis de sensores pXRF para análises quantitativas.
- **PCA** (análise de componentes principais) e visualização multivariada.
- **Random Forest** com dois desenhos de avaliação: separação 70/30 e *Leave-One-Out Cross-Validation* (LOOCV).
- **Support Vector Machine (SVM)** com validação LOOCV em uma versão histórica da pesquisa.
- Cálculo e exportação de indicadores como **RMSE, MAE, RPD e R²**, além de gráficos observado × predito.

Essas atividades documentam experiência prática com dados científicos e códigos em R. **Não se afirma, aqui, desempenho preditivo específico nem superioridade entre algoritmos**, pois a reprodução e a revisão metodológica ainda estão pendentes.

## Códigos disponíveis

| Script | Objetivo | Observação |
| --- | --- | --- |
| [`PCA_GRAFICOS_CORRIGIDOS_2026-07-28.R`](scripts/PCA_GRAFICOS_CORRIGIDOS_2026-07-28.R) | PCA de variáveis pXRF e gráficos | Versão com ajustes visuais |
| [`RF_70_30_Pearson_2026-07-28.R`](scripts/RF_70_30_Pearson_2026-07-28.R) | Random Forest com treinamento/validação 70/30 | Avaliação de uma partição, com seleção de modelos |
| [`RF_LOOCV_Pearson_2026-07-28.R`](scripts/RF_LOOCV_Pearson_2026-07-28.R) | Random Forest com LOOCV e seleção de preditores por Pearson | Requer revisão da seleção do melhor modelo |
| [`SVM_LOOCV_Ribeirao_Marcela_2026-07-09.R`](scripts/SVM_LOOCV_Ribeirao_Marcela_2026-07-09.R) | SVM radial com LOOCV | **Versão histórica** com 18 atributos-alvo; RF usa 13 |

Os quatro arquivos foram **preservados sem edição do código-fonte** em relação ao pacote de revisão anterior. As datas nos nomes são datas de última modificação identificadas no material recuperado, não uma comprovação da data original de criação.

## Tecnologias

**Linguagem:** R  
**Métodos:** PCA, Random Forest, SVM radial, correlação de Pearson, LOOCV e validação 70/30.  
**Pacotes citados nos scripts:** `readxl`, `dplyr`, `FactoMineR`, `factoextra`, `ggplot2`, `writexl`, `caret`, `randomForest`, `tidyverse` e `kernlab`.

## Desenvolvimento assistido por IA

Durante o desenvolvimento do projeto, **o ChatGPT foi utilizado como apoio à elaboração, revisão e correção de scripts R**, com base em demandas de pesquisa e conjuntos de dados fornecidos pelo estudante. Os códigos foram utilizados como parte de um trabalho acadêmico, e as análises são apresentadas com suas limitações. Isso **não significa** que foi desenvolvido um agente autônomo, um aplicativo de IA generativa ou um novo algoritmo de aprendizado de máquina.

## Reproduzibilidade e limites

Os scripts dependem de arquivos locais de pesquisa (`Geral_RibMar.xlsx` e, no caso do SVM, `Dados_RibMar_RF_v2.csv`) **não distribuídos aqui**. Eles não formam, ainda, um fluxo que rode integralmente sem intervenção. Uma validação científica de desempenho exige reexecução em R, conferência das bases e revisão da estratégia de seleção de modelos.

Saiba mais em [Como executar](docs/COMO_EXECUTAR.md), [Metodologia](docs/METODOLOGIA.md), [Limitações e validação](docs/LIMITACOES_E_VALIDACAO.md) e [Autoria e uso de IA](docs/AUTORIA_E_IA.md).

## Contexto e autoria

**Organização do portfólio:** Henrique Peres Cardoso — estudante de Engenharia Ambiental e Sanitária da UFLA.  
**Pesquisa:** desenvolvida em equipe, no contexto da iniciação científica sob orientação do Prof. Dr. Sérgio Henrique Godinho Silva.  
**Perfil:** [LinkedIn de Henrique Peres Cardoso](https://www.linkedin.com/in/henrique-peres-cardoso/).

A atribuição de cada contribuição e a autorização para divulgação pública ainda devem ser confirmadas junto à equipe. **Nenhuma licença open source foi concedida.**

---

*Este repositório tem finalidade de documentação técnica e portfólio; não substitui relatório científico, artigo revisado por pares nem validação independente.*
