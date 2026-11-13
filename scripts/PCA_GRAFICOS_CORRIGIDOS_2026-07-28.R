################################################################################
# PCA DOS ELEMENTOS pXRF - SUB-BACIA DO RIBEIRÃO MARCELA
# Base: Geral_RibMar.xlsx | Aba: ID_UFLA
################################################################################

#############################################
# PACOTES
#############################################
# Instale somente se necessário:
# install.packages(c("readxl", "dplyr", "FactoMineR", "factoextra", "ggplot2", "writexl"))

library(readxl)
library(dplyr)
library(FactoMineR)
library(factoextra)
library(ggplot2)
library(writexl)

#############################################
# LOCALIZANDO A PASTA DO PRÓPRIO CÓDIGO
#############################################
obter_pasta_script <- function() {
  frames <- sys.frames()
  caminhos_source <- vapply(
    frames,
    function(x) if (!is.null(x$ofile)) as.character(x$ofile) else "",
    character(1)
  )
  caminhos_source <- caminhos_source[nzchar(caminhos_source)]

  if (length(caminhos_source) > 0) {
    return(dirname(normalizePath(tail(caminhos_source, 1), winslash = "/")))
  }

  argumentos <- commandArgs(trailingOnly = FALSE)
  argumento_arquivo <- grep("^--file=", argumentos, value = TRUE)

  if (length(argumento_arquivo) > 0) {
    caminho <- sub("^--file=", "", argumento_arquivo[1])
    return(dirname(normalizePath(caminho, winslash = "/")))
  }

  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    caminho <- tryCatch(rstudioapi::getSourceEditorContext()$path,
                        error = function(e) "")
    if (nzchar(caminho)) {
      return(dirname(normalizePath(caminho, winslash = "/")))
    }
  }

  return(getwd())
}

pasta_projeto <- obter_pasta_script()
setwd(pasta_projeto)

#############################################
# LOCALIZANDO E LENDO A PLANILHA
#############################################
arquivos_encontrados <- list.files(
  path = pasta_projeto,
  pattern = "^Geral_RibMar\\.xlsx$",
  ignore.case = TRUE,
  full.names = TRUE
)

if (length(arquivos_encontrados) == 0) {
  stop("A planilha Geral_RibMar.xlsx não foi encontrada na mesma pasta do código.")
}

if (length(arquivos_encontrados) > 1) {
  stop("Foi encontrada mais de uma planilha chamada Geral_RibMar.xlsx. Mantenha apenas uma.")
}

arquivo_dados <- arquivos_encontrados[1]
dados <- read_excel(arquivo_dados, sheet = "ID_UFLA")

colunas_obrigatorias <- c("ID", "Name", "Classe")
colunas_ausentes <- setdiff(colunas_obrigatorias, names(dados))

if (length(colunas_ausentes) > 0) {
  stop(paste("Colunas obrigatórias ausentes:", paste(colunas_ausentes, collapse = ", ")))
}

dados$Classe <- as.factor(dados$Classe)

#############################################
# IDENTIFICANDO E CONFERINDO OS ELEMENTOS pXRF
#############################################
pxrf_todos <- grep("_pxrf$", names(dados), value = TRUE)

if (length(pxrf_todos) == 0) {
  stop("Nenhuma coluna terminada em _pxrf foi encontrada.")
}

converter_numerico <- function(x, nome_variavel) {
  if (is.numeric(x)) return(x)

  texto <- trimws(as.character(x))
  texto[texto == ""] <- NA_character_
  numero <- suppressWarnings(as.numeric(gsub(",", ".", texto, fixed = TRUE)))

  invalidos <- !is.na(texto) & is.na(numero)
  if (any(invalidos)) {
    stop(paste0(
      "A variável ", nome_variavel,
      " contém valores que não puderam ser convertidos para número."
    ))
  }

  return(numero)
}

for (variavel in pxrf_todos) {
  dados[[variavel]] <- converter_numerico(dados[[variavel]], variavel)
}

#############################################
# SELEÇÃO DOS ELEMENTOS pXRF ELEGÍVEIS
#############################################
# A planilha original não é modificada e os zeros são mantidos.
# Critérios:
# 1) proporção de zeros menor ou igual a 70%;
# 2) pelo menos 10 valores únicos;
# 3) desvio-padrão maior que zero.

resumo_pxrf <- data.frame(
  Variavel = pxrf_todos,
  Zeros = sapply(dados[pxrf_todos], function(x) sum(x == 0, na.rm = TRUE)),
  Prop_zeros = sapply(dados[pxrf_todos], function(x) mean(x == 0, na.rm = TRUE)),
  Valores_unicos = sapply(dados[pxrf_todos], function(x) dplyr::n_distinct(x, na.rm = TRUE)),
  Desvio_padrao = sapply(dados[pxrf_todos], function(x) sd(x, na.rm = TRUE)),
  stringsAsFactors = FALSE
)

pxrf_selecionados <- resumo_pxrf %>%
  filter(
    Prop_zeros <= 0.70,
    Valores_unicos >= 10,
    Desvio_padrao > 0
  ) %>%
  pull(Variavel)

resumo_pxrf$Usada_na_PCA <- ifelse(
  resumo_pxrf$Variavel %in% pxrf_selecionados,
  "Sim",
  "Nao"
)

if (length(pxrf_selecionados) < 2) {
  stop("Menos de duas variáveis pXRF passaram pelos critérios. A PCA não pode ser executada.")
}

if (anyNA(dados[pxrf_selecionados])) {
  stop("Existem valores ausentes nas variáveis pXRF selecionadas. Revise a planilha antes da PCA.")
}

#############################################
# PREPARANDO E EXECUTANDO A PCA
#############################################
identificador <- ifelse(
  is.na(dados$Name) | trimws(as.character(dados$Name)) == "",
  as.character(dados$ID),
  as.character(dados$Name)
)
identificador <- make.unique(identificador)

# Classe entra apenas como variável qualitativa suplementar.
# Os elementos pXRF são as variáveis ativas da PCA.
dados_pca <- data.frame(
  Classe = dados$Classe,
  dados[, pxrf_selecionados, drop = FALSE],
  check.names = FALSE
)
rownames(dados_pca) <- identificador

numero_componentes <- min(
  ncol(dados_pca) - 1,
  nrow(dados_pca) - 1
)

resultado_pca <- PCA(
  dados_pca,
  scale.unit = TRUE,
  quali.sup = 1,
  ncp = numero_componentes,
  graph = FALSE
)

#############################################
# EXTRAINDO RESULTADOS
#############################################
autovalores <- as.data.frame(get_eigenvalue(resultado_pca))
autovalores$Componente <- paste0("PC", seq_len(nrow(autovalores)))
autovalores <- autovalores %>%
  select(Componente, everything())

names(autovalores)[2:4] <- c(
  "Autovalor",
  "Variancia_percentual",
  "Variancia_acumulada_percentual"
)
autovalores$Kaiser_maior_que_1 <- ifelse(autovalores$Autovalor > 1, "Sim", "Nao")

n_componentes_kaiser <- sum(autovalores$Autovalor > 1)

resultado_ind <- get_pca_ind(resultado_pca)
resultado_var <- get_pca_var(resultado_pca)

coordenadas_amostras <- as.data.frame(resultado_ind$coord)
coordenadas_amostras$ID <- dados$ID
coordenadas_amostras$Name <- dados$Name
coordenadas_amostras$Classe <- dados$Classe
coordenadas_amostras <- coordenadas_amostras %>%
  select(ID, Name, Classe, everything())

coordenadas_variaveis <- as.data.frame(resultado_var$coord)
coordenadas_variaveis$Variavel <- rownames(coordenadas_variaveis)
coordenadas_variaveis <- coordenadas_variaveis %>%
  select(Variavel, everything())

cos2_variaveis <- as.data.frame(resultado_var$cos2)
cos2_variaveis$Variavel <- rownames(cos2_variaveis)
cos2_variaveis <- cos2_variaveis %>%
  select(Variavel, everything())

contribuicao_variaveis <- as.data.frame(resultado_var$contrib)
contribuicao_variaveis$Variavel <- rownames(contribuicao_variaveis)
contribuicao_variaveis <- contribuicao_variaveis %>%
  select(Variavel, everything())

resumo_pc1_pc2 <- data.frame(
  Variavel = rownames(resultado_var$coord),
  Coordenada_PC1 = resultado_var$coord[, 1],
  Coordenada_PC2 = resultado_var$coord[, 2],
  Cos2_PC1 = resultado_var$cos2[, 1],
  Cos2_PC2 = resultado_var$cos2[, 2],
  Cos2_PC1_PC2 = rowSums(resultado_var$cos2[, 1:2, drop = FALSE]),
  Contribuicao_PC1 = resultado_var$contrib[, 1],
  Contribuicao_PC2 = resultado_var$contrib[, 2],
  Contribuicao_PC1_PC2 = rowSums(resultado_var$contrib[, 1:2, drop = FALSE]),
  row.names = NULL
) %>%
  arrange(desc(Cos2_PC1_PC2))

#############################################
# RESULTADOS DA CLASSE COMO VARIÁVEL SUPLEMENTAR
#############################################
classe_coord <- data.frame()
classe_cos2 <- data.frame()
classe_vtest <- data.frame()
classe_eta2 <- data.frame()

if (!is.null(resultado_pca$quali.sup)) {
  if (!is.null(resultado_pca$quali.sup$coord)) {
    classe_coord <- as.data.frame(resultado_pca$quali.sup$coord)
    classe_coord$Classe <- rownames(classe_coord)
    classe_coord <- classe_coord %>% select(Classe, everything())
  }

  if (!is.null(resultado_pca$quali.sup$cos2)) {
    classe_cos2 <- as.data.frame(resultado_pca$quali.sup$cos2)
    classe_cos2$Classe <- rownames(classe_cos2)
    classe_cos2 <- classe_cos2 %>% select(Classe, everything())
  }

  if (!is.null(resultado_pca$quali.sup$v.test)) {
    classe_vtest <- as.data.frame(resultado_pca$quali.sup$v.test)
    classe_vtest$Classe <- rownames(classe_vtest)
    classe_vtest <- classe_vtest %>% select(Classe, everything())
  }

  if (!is.null(resultado_pca$quali.sup$eta2)) {
    classe_eta2 <- as.data.frame(resultado_pca$quali.sup$eta2)
    classe_eta2$Variavel <- rownames(classe_eta2)
    classe_eta2 <- classe_eta2 %>% select(Variavel, everything())
  }
}

#############################################
# SALVANDO TABELAS E MODELO
#############################################
arquivo_resultados <- file.path(pasta_projeto, "Resultados_PCA_RibMar.xlsx")
arquivo_modelo <- file.path(pasta_projeto, "Modelo_PCA_RibMar.rds")
arquivo_descricao <- file.path(pasta_projeto, "Descricao_Componentes_PCA.txt")

planilhas_saida <- list(
  "Selecao_pXRF" = resumo_pxrf,
  "Autovalores" = autovalores,
  "Amostras_coord" = coordenadas_amostras,
  "Variaveis_coord" = coordenadas_variaveis,
  "Variaveis_cos2" = cos2_variaveis,
  "Variaveis_contrib" = contribuicao_variaveis,
  "Resumo_PC1_PC2" = resumo_pc1_pc2
)

if (nrow(classe_coord) > 0) planilhas_saida[["Classe_coord"]] <- classe_coord
if (nrow(classe_cos2) > 0) planilhas_saida[["Classe_cos2"]] <- classe_cos2
if (nrow(classe_vtest) > 0) planilhas_saida[["Classe_vtest"]] <- classe_vtest
if (nrow(classe_eta2) > 0) planilhas_saida[["Classe_eta2"]] <- classe_eta2

write_xlsx(planilhas_saida, path = arquivo_resultados)
saveRDS(resultado_pca, arquivo_modelo)

descricao_componentes <- tryCatch(
  dimdesc(resultado_pca, axes = 1:min(3, numero_componentes), proba = 0.05),
  error = function(e) e
)

if (inherits(descricao_componentes, "error")) {
  writeLines(
    paste("Não foi possível gerar a descrição automática:", descricao_componentes$message),
    arquivo_descricao
  )
} else {
  capture.output(
    {
      cat("Número de componentes pelo critério de Kaiser:", n_componentes_kaiser, "\n\n")
      print(descricao_componentes)
    },
    file = arquivo_descricao
  )
}

#############################################
# GRÁFICOS
#############################################
pasta_graficos <- file.path(pasta_projeto, "Graficos_PCA_RibMar")
dir.create(pasta_graficos, showWarnings = FALSE)

# Nomes mais curtos apenas para os gráficos.
resumo_graficos <- resumo_pc1_pc2 %>%
  mutate(Nome_grafico = sub("_pxrf$", "", Variavel))

# 1. Biplot completo: mantido para consulta técnica.
grafico_biplot_completo <- fviz_pca_biplot(
  resultado_pca,
  geom.ind = "point",
  pointsize = 2.5,
  habillage = dados$Classe,
  addEllipses = FALSE,
  label = "var",
  col.var = "black",
  labelsize = 3.5,
  repel = TRUE,
  legend.title = "Classe de solo",
  title = NULL
) +
  theme_bw()

ggsave(
  file.path(pasta_graficos, "01A_PCA_Biplot_Completo.png"),
  plot = grafico_biplot_completo,
  width = 19,
  height = 13,
  units = "cm",
  dpi = 600
)

# 1B. Biplot simplificado para o relatório:
# mostra somente as 10 variáveis mais bem representadas em PC1 + PC2.
grafico_biplot_relatorio <- fviz_pca_biplot(
  resultado_pca,
  geom.ind = "point",
  pointsize = 2.5,
  habillage = dados$Classe,
  addEllipses = FALSE,
  label = "var",
  col.var = "black",
  labelsize = 4,
  repel = TRUE,
  select.var = list(cos2 = 10),
  legend.title = "Classe de solo",
  title = NULL
) +
  theme_bw()

ggsave(
  file.path(pasta_graficos, "01B_PCA_Biplot_Relatorio.png"),
  plot = grafico_biplot_relatorio,
  width = 19,
  height = 13,
  units = "cm",
  dpi = 600
)

# 2. Indivíduos separados por classe.
grafico_individuos <- fviz_pca_ind(
  resultado_pca,
  geom.ind = "point",
  pointsize = 2.5,
  habillage = dados$Classe,
  addEllipses = FALSE,
  repel = TRUE,
  legend.title = "Classe de solo",
  title = NULL
) +
  theme_bw()

ggsave(
  file.path(pasta_graficos, "02_PCA_Amostras_Classes.png"),
  plot = grafico_individuos,
  width = 17,
  height = 11,
  units = "cm",
  dpi = 600
)

# 3. Círculo de correlação simplificado:
# mostra as 12 variáveis mais bem representadas em PC1 + PC2.
grafico_circulo <- fviz_pca_var(
  resultado_pca,
  axes = c(1, 2),
  col.var = "cos2",
  gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
  select.var = list(cos2 = 12),
  labelsize = 4,
  repel = TRUE,
  title = NULL
) +
  theme_bw()

ggsave(
  file.path(pasta_graficos, "03_PCA_Circulo_Correlacao_Cos2.png"),
  plot = grafico_circulo,
  width = 17,
  height = 12,
  units = "cm",
  dpi = 600
)

# 4. Variância explicada por componente.
grafico_scree <- fviz_eig(
  resultado_pca,
  addlabels = TRUE,
  barfill = "grey70",
  barcolor = "black"
) +
  labs(
    title = NULL,
    x = "Componentes principais",
    y = "Variância explicada (%)"
  ) +
  theme_bw()

ggsave(
  file.path(pasta_graficos, "04_PCA_Variancia_Explicada.png"),
  plot = grafico_scree,
  width = 16,
  height = 10.5,
  units = "cm",
  dpi = 600
)

# 5. Autovalores e critério de Kaiser.
grafico_kaiser <- ggplot(
  autovalores,
  aes(x = factor(Componente, levels = Componente), y = Autovalor)
) +
  geom_col() +
  geom_hline(yintercept = 1, linetype = "dashed") +
  labs(
    title = NULL,
    x = "Componentes principais",
    y = "Autovalor"
  ) +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(
  file.path(pasta_graficos, "05_PCA_Criterio_Kaiser.png"),
  plot = grafico_kaiser,
  width = 16,
  height = 10.5,
  units = "cm",
  dpi = 600
)

# 6. Qualidade de representação em PC1 + PC2.
# Barras horizontais evitam sobreposição dos nomes.
dados_cos2 <- resumo_graficos %>%
  arrange(Cos2_PC1_PC2) %>%
  mutate(Nome_grafico = factor(Nome_grafico, levels = Nome_grafico))

grafico_cos2 <- ggplot(
  dados_cos2,
  aes(x = Nome_grafico, y = Cos2_PC1_PC2)
) +
  geom_col() +
  coord_flip() +
  labs(
    title = NULL,
    x = "Elemento pXRF",
    y = "cos² em PC1 + PC2"
  ) +
  theme_bw()

ggsave(
  file.path(pasta_graficos, "06_PCA_Cos2_PC1_PC2.png"),
  plot = grafico_cos2,
  width = 15,
  height = 12,
  units = "cm",
  dpi = 600
)

# 7. Contribuição das variáveis para PC1 + PC2.
# A linha tracejada representa a contribuição média esperada.
dados_contribuicao <- resumo_graficos %>%
  arrange(Contribuicao_PC1_PC2) %>%
  mutate(Nome_grafico = factor(Nome_grafico, levels = Nome_grafico))

contribuicao_media <- 100 / length(pxrf_selecionados)

grafico_contribuicao <- ggplot(
  dados_contribuicao,
  aes(x = Nome_grafico, y = Contribuicao_PC1_PC2)
) +
  geom_col() +
  geom_hline(
    yintercept = contribuicao_media,
    linetype = "dashed"
  ) +
  coord_flip() +
  labs(
    title = NULL,
    x = "Elemento pXRF",
    y = "Contribuição para PC1 + PC2 (%)"
  ) +
  theme_bw()

ggsave(
  file.path(pasta_graficos, "07_PCA_Contribuicao_PC1_PC2.png"),
  plot = grafico_contribuicao,
  width = 15,
  height = 12,
  units = "cm",
  dpi = 600
)

#############################################
# FINAL
#############################################
cat("PCA finalizada com sucesso.\n")
cat("Variáveis pXRF utilizadas:", length(pxrf_selecionados), "\n")
cat("Componentes com autovalor maior que 1:", n_componentes_kaiser, "\n")
cat("Resultados salvos em:\n", arquivo_resultados, "\n")
cat("Gráficos salvos em:\n", pasta_graficos, "\n")
