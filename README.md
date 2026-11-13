# Machine Learning aplicado a atributos de solos | Ribeirão Marcela

**Portfólio técnico de Henrique Peres Cardoso** · Iniciação Científica — Universidade Federal de Lavras (UFLA)  
**Tecnologias e métodos:** R · pXRF · PCA · Random Forest · SVM · LOOCV · análise e visualização de dados

## Visão geral do projeto

Este repositório apresenta **scripts históricos desenvolvidos e utilizados no contexto de uma pesquisa em Ciência do Solo**. O trabalho investiga relações entre medições obtidas por **fluorescência de raios X portátil (pXRF)** e atributos de solos da sub-bacia do Ribeirão Marcela, utilizando análises exploratórias e aprendizado de máquina.

O estudo trabalhou com **54 amostras de solo**. Os dados brutos não estão disponíveis no repositório, por pertencerem ao contexto de uma pesquisa acadêmica em equipe.

### O que este portfólio demonstra

- **Análise de dados em R:** preparação de entradas, exploração estatística e interpretação de saídas.
- **PCA:** avaliação de padrões multivariados e construção de visualizações.
- **Random Forest:** modelagem preditiva em dois desenhos históricos de avaliação — partição 70/30 e validação *Leave-One-Out* (LOOCV).
- **Support Vector Machine (SVM):** aplicação de SVM radial com LOOCV em uma fase anterior da pesquisa.
- **Desenvolvimento assistido por IA generativa:** uso do ChatGPT como apoio na elaboração, revisão e correção de scripts em R.

**Participação do estudante:** integração à equipe de iniciação científica desde 2024, trabalho com bases de pesquisa e execução de análises computacionais, com acompanhamento dos resultados e suporte de IA generativa durante o desenvolvimento dos scripts. A pesquisa é coletiva e conta com orientação acadêmica.

## Arquivos de código

| Código | Propósito | Situação |
| --- | --- | --- |
| [PCA e gráficos](scripts/PCA_GRAFICOS_CORRIGIDOS_2026-07-28.R) | Análise de componentes principais e gráficos | Script histórico, não reexecutado nesta revisão |
| [Random Forest 70/30](scripts/RF_70_30_Pearson_2026-07-28.R) | Modelagem e avaliação com divisão treino/validação | Script histórico, não reexecutado nesta revisão |
| [Random Forest LOOCV](scripts/RF_LOOCV_Pearson_2026-07-28.R) | Modelagem com validação de uma amostra por rodada | Script histórico, não reexecutado nesta revisão |
| [SVM LOOCV](scripts/SVM_LOOCV_Ribeirao_Marcela_2026-07-09.R) | Modelagem com *Support Vector Machine* | Versão histórica; demanda ajuste de importação e reexecução |

Os códigos-fonte foram **preservados sem alterações** em relação às versões recuperadas do histórico da pesquisa. A existência de scripts e de resultados antigos **não equivale à certificação de que os arquivos atuais executem sem ajustes**.

## Como a inteligência artificial foi utilizada

O **ChatGPT auxiliou no desenvolvimento e na depuração dos scripts R** a partir de objetivos de pesquisa e dados de trabalho. Isso caracteriza experiência prática com **programação assistida por IA generativa**, distinta da criação de agentes autônomos ou da integração de APIs de modelos de linguagem.

Random Forest e SVM, por sua vez, são **algoritmos de aprendizado de máquina** empregados nas análises científicas. A IA generativa foi uma ferramenta de apoio ao processo de programação e análise — não o próprio algoritmo treinado nos dados de solos.

## Reprodutibilidade e limitações

Os scripts dependem de arquivos de entrada locais e de pacotes R. **A reprodução completa dos resultados não foi feita durante a organização deste portfólio**, e a disponibilização de dados, gráficos e resultados numéricos exige revisão e autorização da equipe de pesquisa.

Há uma incompatibilidade conhecida entre o delimitador esperado na versão histórica do script SVM e o arquivo de dados recuperado; **o código foi mantido intacto para preservar seu histórico**. Os modelos SVM e Random Forest também utilizam escopos históricos diferentes de atributos, portanto não se afirma comparação direta de desempenho entre eles.

A documentação detalhada está em [Metodologia](docs/METODOLOGIA.md), [Como executar](docs/COMO_EXECUTAR.md), [Limitações e validação](docs/LIMITACOES_E_VALIDACAO.md) e [Autoria e uso de IA](docs/AUTORIA_E_IA.md).

## Autoria e contexto acadêmico

- **Portfólio e participação na pesquisa:** Henrique Peres Cardoso — Engenharia Ambiental e Sanitária, UFLA.
- **Orientação científica:** Prof. Dr. Sérgio Henrique Godinho Silva (UFLA).
- **Natureza do trabalho:** pesquisa acadêmica desenvolvida em equipe, com contribuições que devem receber atribuição apropriada.
- **LinkedIn:** [henrique-peres-cardoso](https://www.linkedin.com/in/henrique-peres-cardoso/).

**Divulgação:** este repositório não contém dados brutos e não possui licença de software livre. A publicação pública dos códigos deve respeitar as autorizações de divulgação e os direitos dos colaboradores. Consulte [Antes de publicar](docs/ANTES_DE_PUBLICAR.md).
