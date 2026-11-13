###############################################################################################
#          SCRIPT SVM PARA PREDIÇÃO DE ATRIBUTOS DO SOLO - RIBEIRÃO MARCELA
###############################################################################################

#############################################
# INSTALANDO PACOTES
#############################################
# Rode estas linhas só se algum pacote ainda não estiver instalado:
#install.packages("tidyverse")
#install.packages("caret")
#install.packages("kernlab")

#############################################
# CARREGANDO PACOTES
#############################################
library(tidyverse)
library(caret)
library(kernlab)

#############################################
# CARREGANDO OS DADOS
#############################################
# Deixe este script na mesma pasta do arquivo CSV.
# O arquivo principal esperado é: Dados_RibMar_RF_v2.csv

arquivo <- "Dados_RibMar_RF_v2.csv"

if (!file.exists(arquivo) && file.exists("Dados_RibMar_RF_v2(1).csv")) {
  arquivo <- "Dados_RibMar_RF_v2(1).csv"
}

data_solo <- read_delim(
  arquivo,
  delim = ";",
  locale = locale(decimal_mark = ","),
  show_col_types = FALSE
)

data_solo$Classe <- as.factor(data_solo$Classe)

# Para usar Classe no LOOCV sem erro: CX e GX têm uma amostra cada.
# Elas são agrupadas como "Outras" apenas para a variável Classe_modelo.
# A coluna Classe original permanece intacta.
classes_raras <- names(which(table(data_solo$Classe) < 2))

data_solo <- data_solo %>%
  mutate(
    Classe_modelo = as.character(Classe),
    Classe_modelo = ifelse(Classe_modelo %in% classes_raras, "Outras", Classe_modelo),
    Classe_modelo = as.factor(Classe_modelo)
  )

# Conferência rápida
head(data_solo)
summary(data_solo$Carbono)
table(data_solo$Classe)
table(data_solo$Classe_modelo)

#############################################
# DEFININDO ATRIBUTOS E VARIÁVEIS PREDITORAS
#############################################

# Atributos de laboratório que serão preditos, um modelo separado para cada atributo.
# Na fica fora porque está zerado na base.
atributos <- c(
  "Argila", "Silte", "Areia", "Carbono", "MO", "pH", "SB", "T", "V",
  "K", "P", "Ca", "Mg", "Al", "H_Al", "t", "m", "P_Rem"
)

# Candidatos pXRF: todas as colunas terminadas em _pxrf.
pxrf_candidatos <- names(data_solo)[str_detect(names(data_solo), "_pxrf$")]

#############################################
# SELEÇÃO AUTOMÁTICA DOS PREDITORES pXRF
#############################################
# Critérios usados:
# 1) remover variáveis constantes;
# 2) remover variáveis com poucos valores diferentes;
# 3) remover variáveis com zeros demais.

resumo_pxrf <- data.frame()

for (variavel in pxrf_candidatos) {
  x <- data_solo[[variavel]]
  resumo_pxrf <- rbind(
    resumo_pxrf,
    data.frame(
      Variavel = variavel,
      N = sum(!is.na(x)),
      N_zeros = sum(x == 0, na.rm = TRUE),
      Perc_zeros = round(100 * mean(x == 0, na.rm = TRUE), 2),
      N_unicos = length(unique(x[!is.na(x)])),
      Desvio_padrao = sd(x, na.rm = TRUE)
    )
  )
}

resumo_pxrf <- resumo_pxrf %>%
  mutate(
    Usar = Desvio_padrao > 0 & N_unicos >= 5 & Perc_zeros <= 80
  )

preditores_pxrf <- resumo_pxrf %>%
  filter(Usar) %>%
  pull(Variavel)

write.csv2(resumo_pxrf, "Resumo_selecao_pXRF_SVM.csv", row.names = FALSE)

print(resumo_pxrf)
print(preditores_pxrf)

#############################################
# FUNÇÕES AUXILIARES
#############################################

calc_rpd <- function(pred, obs) {
  rmse <- sqrt(mean((obs - pred)^2, na.rm = TRUE))
  sd(obs, na.rm = TRUE) / rmse
}

nome_seguro <- function(x) {
  ifelse(x == "T", "CTC_potencial", ifelse(x == "t", "CTC_efetiva", x))
}

#############################################
# CONFIGURAÇÃO DA MODELAGEM SVM
#############################################
# LOOCV: deixa uma amostra fora por vez.
# preProcess center/scale é essencial para SVM.

control <- trainControl(
  method = "LOOCV",
  savePredictions = "final",
  returnResamp = "final"
)

#############################################
# MODELAGEM, PREDIÇÃO E VALIDAÇÃO
#############################################

resultados_svm <- data.frame()
dados_preditos_svm <- data.frame()
importancia_svm <- data.frame()
modelos_svm <- list()

metodos <- c("Sem_Classe", "Com_Classe")

for (metodo_atual in metodos) {

  if (metodo_atual == "Sem_Classe") {
    preditores_atuais <- preditores_pxrf
  } else {
    preditores_atuais <- c("Classe_modelo", preditores_pxrf)
  }

  for (atributo in atributos) {

    base_atual <- data_solo %>%
      select(all_of(c(atributo, preditores_atuais))) %>%
      drop_na()

    # Não roda se o atributo tiver variação insuficiente.
    if (length(unique(base_atual[[atributo]])) < 3) {
      resultados_svm <- rbind(
        resultados_svm,
        data.frame(
          Metodo = metodo_atual,
          Atributo = atributo,
          N = nrow(base_atual),
          RMSE = NA,
          R2 = NA,
          MAE = NA,
          RPD = NA,
          Observacao = "Atributo com pouca variação"
        )
      )
      next
    }

    formula_atual <- as.formula(paste(atributo, "~ ."))

    set.seed(1058)

    modelo_atual <- train(
      formula_atual,
      data = base_atual,
      method = "svmRadial",
      preProcess = c("center", "scale"),
      trControl = control,
      tuneLength = 7,
      metric = "RMSE"
    )

    chave_modelo <- paste(metodo_atual, atributo, sep = "_")
    modelos_svm[[chave_modelo]] <- modelo_atual

    pred_atual <- modelo_atual$pred

    # Garante que ficam apenas as predições do melhor ajuste.
    if (!is.null(modelo_atual$bestTune)) {
      for (parametro in names(modelo_atual$bestTune)) {
        pred_atual <- pred_atual[pred_atual[[parametro]] == modelo_atual$bestTune[[parametro]], ]
      }
    }

    pred_atual <- pred_atual %>%
      arrange(rowIndex) %>%
      select(obs, pred, rowIndex)

    obs <- pred_atual$obs
    pred <- pred_atual$pred

    rmse_atual <- sqrt(mean((obs - pred)^2, na.rm = TRUE))
    r2_atual <- R2(pred, obs)
    mae_atual <- mean(abs(obs - pred), na.rm = TRUE)
    rpd_atual <- calc_rpd(pred, obs)

    resultados_svm <- rbind(
      resultados_svm,
      data.frame(
        Metodo = metodo_atual,
        Atributo = atributo,
        N = nrow(base_atual),
        RMSE = rmse_atual,
        R2 = r2_atual,
        MAE = mae_atual,
        RPD = rpd_atual,
        Observacao = "OK"
      )
    )

    pred_atual$Atributo <- atributo
    pred_atual$Metodo <- metodo_atual
    dados_preditos_svm <- rbind(dados_preditos_svm, pred_atual)

    # Importância das variáveis.
    imp_atual <- tryCatch(
      {
        imp <- varImp(modelo_atual)$importance
        imp$Variavel <- rownames(imp)
        imp$Atributo <- atributo
        imp$Metodo <- metodo_atual
        rownames(imp) <- NULL
        imp
      },
      error = function(e) {
        data.frame(
          Overall = NA,
          Variavel = NA,
          Atributo = atributo,
          Metodo = metodo_atual
        )
      }
    )

    importancia_svm <- rbind(importancia_svm, imp_atual)
  }
}

#############################################
# RESULTADOS
#############################################

write.csv2(resultados_svm, "EstatisticaSVM_LOOCV_RibMar.csv", row.names = FALSE)
write.csv2(dados_preditos_svm, "ObsPreditoSVM_LOOCV_RibMar.csv", row.names = FALSE)
write.csv2(importancia_svm, "ImportanciaSVM_LOOCV_RibMar.csv", row.names = FALSE)
saveRDS(modelos_svm, "ModelosSVM_LOOCV_RibMar.rds")

print(resultados_svm)

#############################################
# GRÁFICOS OBSERVADO X PREDITO
#############################################

dir.create("Graficos_SVM_LOOCV", showWarnings = FALSE)

for (metodo_atual in metodos) {
  for (atributo in atributos) {

    dados_grafico <- dados_preditos_svm %>%
      filter(Metodo == metodo_atual, Atributo == atributo)

    if (nrow(dados_grafico) == 0) next

    grafico <- ggplot(dados_grafico, aes(x = obs, y = pred)) +
      geom_point(size = 2) +
      geom_abline(slope = 1, intercept = 0, linetype = "dotted") +
      geom_smooth(method = "lm", se = FALSE, linetype = "dashed") +
      labs(
        x = paste("Observed", atributo),
        y = paste("Predicted", atributo)
      ) +
      theme_bw()

    suppressMessages(
      ggsave(
        filename = paste0(
          "Graficos_SVM_LOOCV/",
          metodo_atual, "_", nome_seguro(atributo), "_observado_predito.png"
        ),
        plot = grafico,
        width = 12,
        height = 9,
        units = "cm",
        dpi = 300
      )
    )
  }
}

###############################################################################################
# FIM DO SCRIPT
###############################################################################################
