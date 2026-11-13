# Limitações, reprodutibilidade e verificações

## O que foi verificado nesta preparação

- Integridade dos quatro scripts originais copiados para este pacote (comparação por SHA-256).
- Presença dos quatro métodos anunciados e correspondência entre nomes de arquivos e documentação.
- Ausência de planilhas brutas, arquivos de resultados e modelos serializados no pacote entregue.
- Revisão estática de caminhos, bibliotecas, chamadas de leitura de dados e descrições dos métodos.
- Estrutura de Markdown, links relativos, extensão dos arquivos e varredura básica de possíveis segredos nos scripts.

**Isto é uma verificação documental/estática, não uma validação computacional ou científica do desempenho.**

## Pendências antes de declarar resultados reproduzíveis

- [ ] Obter acesso autorizado às versões exatas das bases utilizadas nas análises históricas.
- [ ] Executar os quatro scripts em R, registrar `sessionInfo()` e conferir saídas.
- [ ] Confirmar se as saídas preservadas correspondem às versões atuais de cada script.
- [ ] Avaliar se é necessária validação aninhada ou conjunto independente para evitar seleção otimista do melhor modelo.
- [ ] Padronizar a definição de R² em relatórios comparativos.
- [ ] Reconciliar a diferença entre os 18 atributos históricos do SVM e os 13 atributos recentes do RF.
- [ ] Obter orientação e autorização para compartilhar quaisquer resultados/gráficos.

## Observações específicas

**Random Forest LOOCV:** a seleção de variáveis por Pearson é refeita no treinamento de cada rodada, mas a seleção do melhor número de variáveis a partir das métricas da própria LOOCV ainda exige revisão metodológica.

**Random Forest 70/30:** a comparação e escolha da melhor configuração usando o mesmo conjunto de validação pode produzir avaliação otimista do conjunto escolhido.

**SVM:** versão histórica com escopo diferente; a busca de hiperparâmetros e o desempenho informado pelo processo LOOCV também merecem revisão antes de ser apresentado como estimativa independente.

**PCA:** método exploratório, não é uma medida de capacidade preditiva. A versão selecionada contém ajustes de visualização.

**Datas de arquivos:** refletem últimas modificações armazenadas no conjunto recuperado; não comprovam datas de criação, execução ou aprovação científica.

## Estado de publicação

**Publicação privada para revisão:** adequada após o usuário conferir o pacote.  
**Publicação pública:** pendente de autorização da equipe/orientador, atribuição de autoria e revisão científica.  
**Métricas numéricas publicáveis:** nenhuma selecionada nesta etapa.
