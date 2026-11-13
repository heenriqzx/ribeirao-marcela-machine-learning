################################################################################
# RANDOM FOREST COM LOOCV E SELEÇÃO AUTOMÁTICA POR CORRELAÇÃO DE PEARSON
# PROJETO RIBEIRÃO MARCELA
################################################################################

# Instale somente se necessário:
# install.packages(c("readxl", "dplyr", "randomForest", "writexl", "ggplot2"))

library(readxl)
library(dplyr)
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

# Para evitar uma validação interna excessivamente pesada, o mtry de cada
# subconjunto segue o padrão do randomForest para regressão: p/3, mínimo 1.
definir_mtry <- function(numero_preditores) {
  max(1, floor(numero_preditores / 3))
}

nome_seguro <- function(x) {
  ifelse(x == "T", "CTC_potencial", x)
}

################################################################################
# 5. LOOCV: SELEÇÃO DE PEARSON REFEITA DENTRO DE CADA RODADA
################################################################################

metricas_todos_modelos <- data.frame()
predicoes_todos_modelos <- data.frame()
eventos_selecao <- data.frame()

metricas_melhores <- data.frame()
predicoes_melhores <- data.frame()
frequencia_melhores <- data.frame()
preditores_finais <- data.frame()
importancia_melhores <- data.frame()
modelos_finais <- list()

n <- nrow(data_solo)

for (atributo in atributos) {

  cat("LOOCV do atributo:", atributo, "\n")

  metricas_atributo <- data.frame()
  predicoes_atributo <- list()
  selecoes_atributo <- list()

  for (k in tamanhos_testados) {

    cat("  Testando", k, "preditores\n")

    predicoes_k <- data.frame()
    selecoes_k <- data.frame()
    mtry_atual <- definir_mtry(k)

    for (i in seq_len(n)) {

      treino <- data_solo[-i, , drop = FALSE]
      teste <- data_solo[i, , drop = FALSE]

      # A amostra validada não participa da correlação nem da seleção.
      ranking <- calcular_ranking_pearson(
        dados = treino,
        atributo = atributo,
        preditores = preditores_elegiveis
      )

      if (nrow(ranking) < k) {
        stop(
          "Na rodada ", i, " de ", atributo,
          " não foi possível selecionar ", k, " preditores."
        )
      }

      selecionados <- head(ranking$Variavel, k)
      formula_atual <- reformulate(selecionados, response = atributo)

      set.seed(2025260298 + i + k)
      modelo <- randomForest(
        formula_atual,
        data = treino[, c(atributo, selecionados), drop = FALSE],
        ntree = 500,
        mtry = mtry_atual,
        nodesize = 7,
        maxnodes = 15,
        importance = FALSE
      )

      pred <- predict(
        modelo,
        newdata = teste[, selecionados, drop = FALSE]
      )

      predicoes_k <- bind_rows(
        predicoes_k,
        data.frame(
          ID = teste$ID,
          Linha_validada = i,
          Atributo = atributo,
          Numero_preditores = k,
          mtry = mtry_atual,
          Observado = teste[[atributo]],
          Predito = as.numeric(pred),
          Residuo = teste[[atributo]] - as.numeric(pred)
        )
      )

      selecoes_k <- bind_rows(
        selecoes_k,
        data.frame(
          Atributo = atributo,
          Numero_preditores = k,
          Linha_validada = i,
          Ordem = seq_along(selecionados),
          Variavel = selecionados,
          Correlacao = ranking$Correlacao[
            match(selecionados, ranking$Variavel)
          ],
          Correlacao_absoluta = ranking$Correlacao_absoluta[
            match(selecionados, ranking$Variavel)
          ]
        )
      )
    }

    metricas <- calcular_metricas(
      predicoes_k$Observado,
      predicoes_k$Predito
    )
    metricas$Atributo <- atributo
    metricas$Numero_preditores <- k
    metricas$mtry <- mtry_atual
    metricas$N_validacao <- nrow(predicoes_k)

    metricas_atributo <- bind_rows(metricas_atributo, metricas)
    metricas_todos_modelos <- bind_rows(metricas_todos_modelos, metricas)
    predicoes_todos_modelos <- bind_rows(
      predicoes_todos_modelos,
      predicoes_k
    )
    eventos_selecao <- bind_rows(eventos_selecao, selecoes_k)

    chave <- paste0("K", k)
    predicoes_atributo[[chave]] <- predicoes_k
    selecoes_atributo[[chave]] <- selecoes_k
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

  frequencia <- selecoes_atributo[[chave_melhor]] %>%
    count(Atributo, Numero_preditores, Variavel, name = "Frequencia_selecao") %>%
    mutate(
      Percentual_selecao = 100 * Frequencia_selecao / n,
      .after = Frequencia_selecao
    ) %>%
    arrange(desc(Frequencia_selecao), Variavel)

  frequencia_melhores <- bind_rows(frequencia_melhores, frequencia)

  # Modelo final para importância: ranking de Pearson calculado na base completa,
  # usando a quantidade vencedora na LOOCV.
  ranking_final <- calcular_ranking_pearson(
    dados = data_solo,
    atributo = atributo,
    preditores = preditores_elegiveis
  )
  selecionados_finais <- head(ranking_final$Variavel, melhor_k)
  mtry_final <- definir_mtry(melhor_k)

  formula_final <- reformulate(selecionados_finais, response = atributo)

  set.seed(2025260298)
  modelo_final <- randomForest(
    formula_final,
    data = data_solo[, c(atributo, selecionados_finais), drop = FALSE],
    ntree = 500,
    mtry = mtry_final,
    nodesize = 7,
    maxnodes = 15,
    importance = TRUE
  )

  imp <- importance(modelo_final)
  imp <- as.data.frame(imp)

  coluna_importancia <- if ("IncNodePurity" %in% names(imp)) {
    "IncNodePurity"
  } else {
    names(imp)[ncol(imp)]
  }

  tabela_imp <- data.frame(
    Atributo = atributo,
    Numero_preditores = melhor_k,
    Variavel = rownames(imp),
    Importancia = imp[[coluna_importancia]],
    row.names = NULL
  ) %>%
    arrange(desc(Importancia))

  importancia_melhores <- bind_rows(importancia_melhores, tabela_imp)

  preditores_finais <- bind_rows(
    preditores_finais,
    data.frame(
      Atributo = atributo,
      Numero_preditores = melhor_k,
      mtry = mtry_final,
      Ordem = seq_along(selecionados_finais),
      Variavel = selecionados_finais,
      Correlacao = ranking_final$Correlacao[
        match(selecionados_finais, ranking_final$Variavel)
      ],
      Correlacao_absoluta = ranking_final$Correlacao_absoluta[
        match(selecionados_finais, ranking_final$Variavel)
      ]
    )
  )

  modelos_finais[[atributo]] <- modelo_final
}

metricas_melhores <- metricas_melhores %>%
  select(Atributo, Numero_preditores, mtry, N_validacao, R2, RMSE, RPD, MAE)

metricas_todos_modelos <- metricas_todos_modelos %>%
  select(Atributo, Numero_preditores, mtry, N_validacao, R2, RMSE, RPD, MAE) %>%
  arrange(Atributo, Numero_preditores)

frequencia_todos_modelos <- eventos_selecao %>%
  count(Atributo, Numero_preditores, Variavel, name = "Frequencia_selecao") %>%
  mutate(
    Percentual_selecao = 100 * Frequencia_selecao / n,
    .after = Frequencia_selecao
  ) %>%
  arrange(Atributo, Numero_preditores, desc(Frequencia_selecao), Variavel)

################################################################################
# 6. GRÁFICOS DOS MELHORES MODELOS
################################################################################

pasta_graficos <- file.path(pasta_projeto, "Graficos_RF_LOOCV_Pearson")
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
      title = paste0("RF LOOCV - ", melhor_k, " preditores")
    ) +
    theme_bw()

  suppressMessages(
    ggsave(
      filename = file.path(
        pasta_graficos,
        paste0(nome_seguro(atributo), "_RF_LOOCV_Pearson.png")
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
# 7. SALVANDO OS RESULTADOS
################################################################################

arquivo_resultados <- file.path(
  pasta_projeto,
  "Resultados_RF_LOOCV_Pearson_RibMar.xlsx"
)
arquivo_modelos <- file.path(
  pasta_projeto,
  "Modelos_RF_LOOCV_Pearson_RibMar.rds"
)

write_xlsx(
  list(
    "Metricas_melhores" = metricas_melhores,
    "Metricas_todos_modelos" = metricas_todos_modelos,
    "Predicoes_melhores" = predicoes_melhores,
    "Predicoes_todos_modelos" = predicoes_todos_modelos,
    "Preditores_finais" = preditores_finais,
    "Freq_melhores" = frequencia_melhores,
    "Freq_todos_modelos" = frequencia_todos_modelos,
    "Importancia_melhores" = importancia_melhores,
    "Resumo_pXRF" = resumo_pxrf
  ),
  path = arquivo_resultados
)

saveRDS(modelos_finais, arquivo_modelos)

cat("\nRandom Forest com LOOCV e seleção por Pearson finalizado.\n")
cat("Resultados:\n", arquivo_resultados, "\n")
cat("Modelos finais:\n", arquivo_modelos, "\n")
cat("Gráficos:\n", pasta_graficos, "\n")
