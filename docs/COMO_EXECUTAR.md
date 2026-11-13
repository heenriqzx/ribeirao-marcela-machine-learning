# Como examinar e executar os scripts

**Status:** instruções para análise local. Não há garantia de execução integral sem as bases e a revalidação metodológica.

## Pré-requisitos

1. Instalar **R** e, opcionalmente, **RStudio**.
2. Instalar os pacotes necessários, por exemplo:

```r
install.packages(c(
  "readxl", "dplyr", "FactoMineR", "factoextra", "ggplot2",
  "writexl", "caret", "randomForest", "tidyverse", "kernlab"
))
```

3. Consultar o início de cada script para identificar suas dependências específicas.

## Organização dos dados no computador (FORA da pasta sincronizada com GitHub)

Os scripts históricos esperam arquivos na pasta de execução. Por segurança, use uma **cópia local de trabalho fora do repositório GitHub**, com acesso restrito e somente após a autorização pertinente:

```text
execucao_privada/
├── Geral_RibMar.xlsx
├── PCA_GRAFICOS_CORRIGIDOS_2026-07-28.R
├── RF_70_30_Pearson_2026-07-28.R
└── RF_LOOCV_Pearson_2026-07-28.R
```

Para o script SVM histórico, a pasta de trabalho deve conter o arquivo `Dados_RibMar_RF_v2.csv` (ou a variante de nome prevista no script), com separador `;` e decimal `,`:

```text
execucao_privada_svm/
├── Dados_RibMar_RF_v2.csv
└── SVM_LOOCV_Ribeirao_Marcela_2026-07-09.R
```

**Atenção:** os três primeiros códigos localizam os arquivos em relação à pasta do próprio script; o SVM histórico usa o diretório de trabalho atual do R. Confira `getwd()` ao executar o SVM. Se as bases não estiverem disponíveis, apenas consulte os códigos, sem tentar inferir resultados.

## Conferências antes de usar resultados

- Verificar nomes e tipos de colunas e a aba `ID_UFLA`.
- Registrar versões do R e dos pacotes (por exemplo, `sessionInfo()`).
- Conferir os conjuntos de atributos-alvo, que diferem entre RF e SVM.
- Revisar a divisão treino/teste, os critérios de seleção de variáveis e o método de validação.
- Revisar saídas geradas, gráficos e indicadores com o orientador.

Não foi executado nenhum treinamento completo em R durante a preparação desta versão do portfólio. O ambiente de preparação não possuía o R instalado.
