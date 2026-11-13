# Metodologia e organização dos scripts

## Dados e pergunta de pesquisa

A pesquisa histórica envolve 54 amostras de solos da sub-bacia do Ribeirão Marcela. São utilizados atributos laboratoriais como respostas e elementos medidos por pXRF como possíveis preditores. Bases de trabalho e medições não estão incluídas neste repositório.

## PCA

Arquivo: [`PCA_GRAFICOS_CORRIGIDOS_2026-07-28.R`](../scripts/PCA_GRAFICOS_CORRIGIDOS_2026-07-28.R).

- Lê a aba `ID_UFLA` da planilha `Geral_RibMar.xlsx`.
- Identifica candidatos pXRF pelas colunas terminadas em `_pxrf`.
- Aplica filtro por proporção de zeros, número de valores distintos e desvio-padrão.
- Executa PCA com padronização, considerando `Classe` como variável qualitativa suplementar.
- Gera tabelas de contribuições, coordenadas e figuras exploratórias.

## Random Forest: 70/30

Arquivo: [`RF_70_30_Pearson_2026-07-28.R`](../scripts/RF_70_30_Pearson_2026-07-28.R).

- Utiliza 13 atributos-alvo na versão selecionada: Argila, Silte, Areia, pH, SB, T, V, K, P, Ca, Mg, H_Al e MO.
- Realiza divisão única de amostras em modelagem e validação (proporção aproximada 70/30, conforme `createDataPartition`).
- Seleciona variáveis candidatas por correlação com a resposta nos dados de modelagem.
- Compara quantidades de variáveis e ajusta parâmetros por validação cruzada interna.
- **Limitação relevante:** o melhor conjunto é escolhido usando o desempenho da própria partição de validação; a métrica do modelo vencedor pode ser otimista.

## Random Forest: LOOCV

Arquivo: [`RF_LOOCV_Pearson_2026-07-28.R`](../scripts/RF_LOOCV_Pearson_2026-07-28.R).

- Modela os mesmos 13 atributos-alvo.
- Retira uma amostra por rodada de validação.
- Recalcula o ranking de Pearson com os dados do treinamento a cada rodada, evitando usar diretamente a resposta da amostra reservada na seleção dos preditores.
- Testa diferentes quantidades de variáveis por execução LOOCV.
- **Limitação relevante:** o melhor número de preditores é selecionado pelos resultados da própria LOOCV. A avaliação desse modelo selecionado não constitui uma estimativa externa independente.

## Support Vector Machine: LOOCV (histórico)

Arquivo: [`SVM_LOOCV_Ribeirao_Marcela_2026-07-09.R`](../scripts/SVM_LOOCV_Ribeirao_Marcela_2026-07-09.R).

- Usa `caret` com `svmRadial` (`kernlab`), centralização e escalonamento.
- Considera modelos com e sem a variável de classe, com reagrupamento de classes raras.
- A versão contempla **18 atributos-alvo** — uma fase metodológica anterior ao escopo recente de 13 atributos.
- Exporta predições, resultados e gráficos.
- **Não comparar diretamente as métricas SVM com as métricas RF recentes** como se fossem o mesmo desenho experimental.

## Indicadores e interpretação

Os scripts calculam ou exportam RMSE, MAE, RPD e valores nomeados `R2`. Em parte do código Random Forest, `R2` é calculado como `cor(observado, predito)^2`. Esse valor **não é necessariamente igual** ao coeficiente preditivo `1 - SSE/SST`. A convenção usada deve ser especificada em qualquer comparação ou relatório.

## Relação com o portfólio de IA

Random Forest, SVM e PCA são técnicas estatísticas/de aprendizado de máquina. O componente de **IA generativa** do processo foi o uso de assistência para desenvolver e revisar código; não se deve confundir isso com treinamento de modelos de linguagem ou criação de agentes autônomos.
