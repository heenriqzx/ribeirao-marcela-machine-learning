################################################################################
# RANDOM FOREST 70/30 COM SELEÇÃO AUTOMÁTICA POR CORRELAÇÃO DE PEARSON
# PROJETO RIBEIRÃO MARCELA
################################################################################

# Instale somente se necessário:
# install.packages(c("readxl", "dplyr", "caret", "randomForest", "writexl", "ggplot2"))

library(readxl)
library(dplyr)
library(caret)
library(randomForest)
library(writexl)
library(ggplot2)

################################################################################
# 1. PASTA DO PROJETO
################################################################################

obter_pasta_script <- function() {
  caminhos <- vapply(
    sys.frames(),
    function(frame) {
      if (!is.null(frame$ofile)) as.character(frame$ofile) else NA_character_
    },
    character(1)
  )

  caminhos <- caminhos[!is.na(caminhos) & nzchar(caminhos)]

  if (length(caminhos) > 0) {
    return(dirname(normalizePath(
      tail(caminhos, 1), winslash = "/", mustWork = TRUE
    )))
  }

  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    caminho_ativo <- rstudioapi::getSourceEditorContext()$path
    if (nzchar(caminho_ativo)) {
      return(dirname(normalizePath(
        caminho_ativo, winslash = "/", mustWork = TRUE
      )))
    }
  }

  normalizePath(getwd(), winslash = "/", mustWork = TRUE)
}

pasta_projeto <- obter_pasta_script()
setwd(pasta_projeto)
cat("Pasta usada pelo código:\n", pasta_projeto, "\n\n")

################################################################################
# 2. LEITURA DOS DADOS
################################################################################

arquivo_dados <- file.path(pasta_projeto, "Geral_RibMar.xlsx")
aba_dados <- "ID_UFLA"

if (!file.exists(arquivo_dados)) {
  stop(
    "A planilha Geral_RibMar.xlsx não foi encontrada na mesma pasta do código:\n",
    pasta_projeto
  )
}

data_solo <- read_excel(arquivo_dados, sheet = aba_dados)

################################################################################
# 3. ATRIBUTOS RESPOSTA E CANDIDATOS pXRF
################################################################################

# Mesmos 13 atributos das tabelas anteriores.
atributos <- c(
  "Argila", "Silte", "Areia", "pH", "SB", "T", "V",
  "K", "P", "Ca", "Mg", "H_Al", "MO"
)

# Quantidades de preditores mais correlacionados que serão comparadas.
tamanhos_testados <- c(3, 5, 7, 10)

colunas_ausentes <- setdiff(c("ID", atributos), names(data_solo))
if (length(colunas_ausentes) > 0) {
  stop(
    "Estas colunas não foram encontradas na aba ID_UFLA: ",
    paste(colunas_ausentes, collapse = ", ")
  )
}

pxrf_todos <- names(data_solo)[grepl("_pxrf$", names(data_solo))]
if (length(pxrf_todos) == 0) {
  stop("Nenhuma coluna terminada em _pxrf foi encontrada.")
}

# Garante que respostas e pXRF sejam numéricos.
colunas_numericas <- unique(c(atributos, pxrf_todos))
data_solo[colunas_numericas] <- lapply(
  data_solo[colunas_numericas],
  function(x) suppressWarnings(as.numeric(x))
)

# Filtro técnico anterior: não usa a variável resposta.
resumo_pxrf <- data.frame(
  Variavel = pxrf_todos,
  Zeros = sapply(data_solo[pxrf_todos], function(x) sum(x == 0, na.rm = TRUE)),
  Prop_zeros = sapply(data_solo[pxrf_todos], function(x) mean(x == 0, na.rm = TRUE)),
  Valores_unicos = sapply(data_solo[pxrf_todos], function(x) length(unique(x[!is.na(x)]))),
  Desvio_padrao = sapply(data_solo[pxrf_todos], function(x) sd(x, na.rm = TRUE)),
  row.names = NULL
)

resumo_pxrf$Elegivel <- ifelse(
  resumo_pxrf$Prop_zeros <= 0.70 &
    resumo_pxrf$Valores_unicos >= 10 &
    resumo_pxrf$Desvio_padrao > 0,
  "Sim", "Nao"
)

preditores_elegiveis <- resumo_pxrf$Variavel[resumo_pxrf$Elegivel == "Sim"]

if (length(preditores_elegiveis) < max(tamanhos_testados)) {
  stop(
    "Existem apenas ", length(preditores_elegiveis),
    " pXRF elegíveis, mas o código precisa de pelo menos ",
    max(tamanhos_testados), "."
  )
}

# Interrompe em vez de modelar silenciosamente com valores ausentes.
if (anyNA(data_solo[c(atributos, preditores_elegiveis)])) {
  stop(
    "Foram encontrados valores ausentes após a leitura/conversão. ",
    "Confira as colunas numéricas da planilha antes de continuar."
  )
}

################################################################################
# 4. FUNÇÕES DE APOIO
################################################################################

calcular_metricas <- function(obs, pred) {
  rmse <- sqrt(mean((obs - pred)^2))
  mae <- mean(abs(obs - pred))

  r2 <- if (length(unique(obs)) > 1 && length(unique(pred)) > 1) {
    cor(obs, pred, method = "pearson")^2
  } else {
    NA_real_
  }

  rpd <- sd(obs) / rmse

  data.frame(RMSE = rmse, R2 = r2, MAE = mae, RPD = rpd)
}

calcular_ranking_pearson <- function(dados, atributo, preditores) {
  valores <- sapply(preditores, function(preditor) {
    x <- dados[[preditor]]
    y <- dados[[atributo]]

    if (sd(x) == 0 || sd(y) == 0) return(NA_real_)
    cor(x, y, method = "pearson", use = "complete.obs")
  })

  data.frame(
    Variavel = preditores,
    Correlacao = as.numeric(valores),
    Correlacao_absoluta = abs(as.numeric(valores)),
    row.names = NULL
  ) %>%
    filter(!is.na(Correlacao_absoluta)) %>%
    arrange(desc(Correlacao_absoluta), Variavel)
}

criar_grade_mtry <- function(numero_preditores) {
  valores <- unique(round(seq(
    from = 1,
    to = numero_preditores,
    length.out = min(3, numero_preditores)
  )))

  expand.grid(mtry = sort(unique(pmax(1, pmin(numero_preditores, valores)))))
}

nome_seguro <- function(x) {
  ifelse(x == "T", "CTC_potencial", x)
}

################################################################################
# 5. DIVISÃO ÚNICA: 70% MODELAGEM / 30% VALIDAÇÃO
################################################################################

set.seed(21)
indice_modelagem <- createDataPartition(
  y = data_solo$Argila,
  p = 0.70,
  list = FALSE
)
indice_modelagem <- as.vector(indice_modelagem)

dados_modelagem <- data_solo[indice_modelagem, , drop = FALSE]
dados_validacao <- data_solo[-indice_modelagem, , drop = FALSE]

controle_rf <- trainControl(
  method = "cv",
  number = 5,
  search = "grid"
)

################################################################################
# 6. TESTE AUTOMÁTICO DAS COMBINAÇÕES
################################################################################

metricas_todos_modelos <- data.frame()
preditores_todos_modelos <- data.frame()
correlacoes_pearson <- data.frame()

metricas_melhores <- data.frame()
predicoes_melhores <- data.frame()
importancia_melhores <- data.frame()
preditores_melhores <- data.frame()
modelos_melhores <- list()

for (atributo in atributos) {

  cat("Modelando:", atributo, "\n")

  ranking <- calcular_ranking_pearson(
    dados = dados_modelagem,
    atributo = atributo,
    preditores = preditores_elegiveis
  )

  ranking$Atributo <- atributo
  ranking$Base_correlacao <- "70%_modelagem"
  ranking$Ordem <- seq_len(nrow(ranking))
  correlacoes_pearson <- bind_rows(correlacoes_pearson, ranking)

  modelos_atributo <- list()
  predicoes_atributo <- list()
  importancia_atributo <- list()
  metricas_atributo <- data.frame()

  for (k in tamanhos_testados) {

    selecionados <- head(ranking$Variavel, k)
    formula_atual <- reformulate(selecionados, response = atributo)
    grade_mtry <- criar_grade_mtry(length(selecionados))

    set.seed(2025260298 + k)
    modelo <- train(
      formula_atual,
      data = dados_modelagem[, c(atributo, selecionados), drop = FALSE],
      method = "rf",
      trControl = controle_rf,
      tuneGrid = grade_mtry,
      ntree = 500,
      nodesize = 7,
      maxnodes = 15,
      importance = TRUE
    )

    pred <- predict(
      modelo,
      newdata = dados_validacao[, selecionados, drop = FALSE]
    )
    obs <- dados_validacao[[atributo]]

    metricas <- calcular_metricas(obs, pred)
    metricas$Atributo <- atributo
    metricas$Numero_preditores <- k
    metricas$mtry <- modelo$bestTune$mtry
    metricas$N_modelagem <- nrow(dados_modelagem)
    metricas$N_validacao <- nrow(dados_validacao)
    metricas$Preditores <- paste(selecionados, collapse = "; ")

    metricas_atributo <- bind_rows(metricas_atributo, metricas)
    metricas_todos_modelos <- bind_rows(metricas_todos_modelos, metricas)

    preditores_todos_modelos <- bind_rows(
      preditores_todos_modelos,
      data.frame(
        Atributo = atributo,
        Numero_preditores = k,
        Ordem = seq_along(selecionados),
        Variavel = selecionados,
        Correlacao = ranking$Correlacao[match(selecionados, ranking$Variavel)],
        Correlacao_absoluta = ranking$Correlacao_absoluta[
          match(selecionados, ranking$Variavel)
        ]
      )
    )

    tabela_pred <- data.frame(
      ID = dados_validacao$ID,
      Atributo = atributo,
      Numero_preditores = k,
      Observado = obs,
      Predito = as.numeric(pred),
      Residuo = obs - as.numeric(pred)
    )

    imp <- varImp(modelo, scale = FALSE)$importance
    tabela_imp <- data.frame(
      Atributo = atributo,
      Numero_preditores = k,
      Variavel = rownames(imp),
      Importancia = imp$Overall,
      row.names = NULL
    ) %>%
      arrange(desc(Importancia))

    chave <- paste0("K", k)
    modelos_atributo[[chave]] <- modelo
    predicoes_atributo[[chave]] <- tabela_pred
    importancia_atributo[[chave]] <- tabela_imp
  }

  # Critério: menor RMSE; em empate, maior R².
  melhor <- metricas_atributo %>%
    mutate(R2_ordenacao = ifelse(is.na(R2), -Inf, R2)) %>%
    arrange(RMSE, desc(R2_ordenacao)) %>%
    slice(1) %>%
    select(-R2_ordenacao)

  melhor_k <- melhor$Numero_preditores
  chave_melhor <- paste0("K", melhor_k)

  metricas_melhores <- bind_rows(metricas_melhores, melhor)
  predicoes_melhores <- bind_rows(
    predicoes_melhores,
    predicoes_atributo[[chave_melhor]]
  )
  importancia_melhores <- bind_rows(
    importancia_melhores,
    importancia_atributo[[chave_melhor]]
  )

  selecionados_melhor <- strsplit(melhor$Preditores, "; ", fixed = TRUE)[[1]]
  preditores_melhores <- bind_rows(
    preditores_melhores,
    data.frame(
      Atributo = atributo,
      Numero_preditores = melhor_k,
      Ordem = seq_along(selecionados_melhor),
      Variavel = selecionados_melhor,
      Correlacao = ranking$Correlacao[
        match(selecionados_melhor, ranking$Variavel)
      ],
      Correlacao_absoluta = ranking$Correlacao_absoluta[
        match(selecionados_melhor, ranking$Variavel)
      ]
    )
  )

  modelos_melhores[[atributo]] <- modelos_atributo[[chave_melhor]]
}

metricas_melhores <- metricas_melhores %>%
  select(
    Atributo, Numero_preditores, mtry, N_modelagem, N_validacao,
    R2, RMSE, RPD, MAE, Preditores
  )

metricas_todos_modelos <- metricas_todos_modelos %>%
  select(
    Atributo, Numero_preditores, mtry, N_modelagem, N_validacao,
    R2, RMSE, RPD, MAE, Preditores
  ) %>%
  arrange(Atributo, Numero_preditores)

################################################################################
# 7. GRÁFICOS DOS MELHORES MODELOS
################################################################################

pasta_graficos <- file.path(pasta_projeto, "Graficos_RF_Pearson")
dir.create(pasta_graficos, showWarnings = FALSE, recursive = TRUE)

for (atributo in atributos) {
  dados_grafico <- predicoes_melhores %>%
    filter(Atributo == atributo)

  melhor_k <- unique(dados_grafico$Numero_preditores)

  grafico <- ggplot(dados_grafico, aes(x = Observado, y = Predito)) +
    geom_point(size = 2) +
    geom_abline(slope = 1, intercept = 0, linetype = "dotted") +
    geom_smooth(method = "lm", se = FALSE, linetype = "dashed") +
    labs(
      x = paste("Observado -", atributo),
      y = paste("Predito -", atributo),
      title = paste0("RF 70/30 - ", melhor_k, " preditores")
    ) +
    theme_bw()

  suppressMessages(
    ggsave(
      filename = file.path(
        pasta_graficos,
        paste0(nome_seguro(atributo), "_RF_Pearson.png")
      ),
      plot = grafico,
      width = 12,
      height = 9,
      units = "cm",
      dpi = 300
    )
  )
}

################################################################################
# 8. SALVANDO OS RESULTADOS
################################################################################

arquivo_resultados <- file.path(
  pasta_projeto,
  "Resultados_RF_Pearson_RibMar.xlsx"
)
arquivo_modelos <- file.path(
  pasta_projeto,
  "Modelos_RF_Pearson_RibMar.rds"
)

write_xlsx(
  list(
    "Metricas_melhores" = metricas_melhores,
    "Metricas_todos_modelos" = metricas_todos_modelos,
    "Predicoes_melhores" = predicoes_melhores,
    "Preditores_melhores" = preditores_melhores,
    "Preditores_testados" = preditores_todos_modelos,
    "Correlacoes_Pearson" = correlacoes_pearson,
    "Importancia_melhores" = importancia_melhores,
    "Resumo_pXRF" = resumo_pxrf
  ),
  path = arquivo_resultados
)

saveRDS(modelos_melhores, arquivo_modelos)

cat("\nRandom Forest 70/30 com seleção por Pearson finalizado.\n")
cat("Resultados:\n", arquivo_resultados, "\n")
cat("Modelos:\n", arquivo_modelos, "\n")
cat("Gráficos:\n", pasta_graficos, "\n")
