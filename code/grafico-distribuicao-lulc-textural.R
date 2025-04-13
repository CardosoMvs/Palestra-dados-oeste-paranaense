# =============================================================================
# Análise de Área por Classe Textural ao Longo do Tempo
# =============================================================================
# Este script realiza a visualização da evolução da área ocupada por diferentes 
# classes texturais de solo ao longo do tempo, por região, utilizando gráficos 
# de área empilhada.
#
# Contato: cardoso.mvs@gmail.com, taciarahost@professores.utfpr.edu.br
# Fonte dos dados: Planilha Excel com áreas por Ano, UF, Região e Classe Textural
# Requisitos: R + pacotes (readxl, ggplot2, dplyr, tidyr, scales)
#
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# 1. Carregar pacotes necessários
# -----------------------------------------------------------------------------
if (!require("pacman")) install.packages("pacman")
pacman::p_load(
  readxl,     # Leitura de arquivos Excel (.xlsx)
  ggplot2,    # Visualização de dados
  dplyr,      # Manipulação de dados
  tidyr,      # Ajuste de formatos (pivot, mutate etc.)
  scales      # Formatação de eixos e rótulos
)

# -----------------------------------------------------------------------------
# 2. Importar os dados do Excel
# -----------------------------------------------------------------------------
caminho_arquivo <- "C:/Users/marco/Downloads/OESTE-PR/area_agrupada_por_ANO_UF_e_Classe.xlsx"
dados <- read_excel(caminho_arquivo)

# -----------------------------------------------------------------------------
# 3. Visualizar estrutura dos dados (debug)
# -----------------------------------------------------------------------------
cat("\nPrimeiras linhas dos dados:\n")
print(head(dados))

cat("\nEstrutura dos dados:\n")
print(str(dados))

# -----------------------------------------------------------------------------
# 4. Ajustar os dados (se necessário)
# -----------------------------------------------------------------------------
# Trata caso "area_total" venha com vírgula decimal
if (any(grepl(",", dados$area_total))) {
  dados <- dados %>%
    mutate(area_total = as.numeric(gsub(",", ".", area_total)))
}

# -----------------------------------------------------------------------------
# 5. Criar gráfico de área empilhada por região e ano
# -----------------------------------------------------------------------------
grafico <- ggplot(dados, aes(x = ano, y = area_total, fill = classe_textural)) +
  geom_area(alpha = 0.7, position = "stack") +
  facet_wrap(~regiao, scales = "free_y") +
  labs(
    title = "Evolução da Área por Classe Textural",
    subtitle = "Distribuição por ano e região",
    x = "Ano",
    y = "Área Total (ha)",
    fill = "Classe Textural",
    caption = "Fonte: Elaboração própria a partir de dados do MapBiomas"
  ) +
  scale_fill_viridis_d() +
  scale_y_continuous(labels = label_number(big.mark = ".", decimal.mark = ",")) +
  theme_minimal(base_size = 13) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold", hjust = 0.5, size = 16),
    plot.subtitle = element_text(hjust = 0.5, color = "gray40", size = 12),
    strip.text = element_text(face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

# -----------------------------------------------------------------------------
# 6. Visualizar e salvar o gráfico
# -----------------------------------------------------------------------------
print(grafico)

ggsave(
  filename = "evolucao_classe_textural_por_regiao.png",
  plot = grafico,
  width = 12,
  height = 8,
  dpi = 300
)
