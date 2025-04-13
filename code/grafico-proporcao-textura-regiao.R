# =============================================================================
# Análise da Proporção de Classes Texturais por Região
# =============================================================================
# Este script processa e visualiza dados de classes texturais do solo por região
# do Oeste do Paraná. Ele calcula a proporção percentual das classes em cada 
# região e gera um gráfico de barras empilhadas 100% com cores personalizadas.
#
# Contato: cardoso.mvs@gmail.com, taciarahorst@professores.utfpr.edu.br
# Dados: MapBiomas ou outro levantamento edáfico
# Requisitos: R + pacotes (readxl, ggplot2, dplyr, tidyr, scales)
#
# Execução:
#   - Verifique e ajuste o caminho do arquivo Excel na Etapa 2.
#   - Execute o script no RStudio.
#
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# 1. Carregar pacotes
# -----------------------------------------------------------------------------
if (!require("pacman")) install.packages("pacman")
pacman::p_load(
  readxl,     # Leitura de arquivos Excel (.xlsx)
  ggplot2,    # Visualização de dados
  dplyr,      # Manipulação de dados
  scales,     # Formatação de eixos e legendas
  tidyr       # Transformações auxiliares
)

# -----------------------------------------------------------------------------
# 2. Importar dados (ajuste o caminho para seu arquivo)
# -----------------------------------------------------------------------------
dados <- read_excel("C:/Users/marco/Downloads/OESTE-PR/area_agrupada_por_ANO_UF_e_Classe.xlsx")

# -----------------------------------------------------------------------------
# 3. Verificar estrutura dos dados (debug visual)
# -----------------------------------------------------------------------------
cat("\nPrimeiras linhas dos dados importados:\n")
print(head(dados))

# -----------------------------------------------------------------------------
# 4. Calcular proporções por classe e região
# -----------------------------------------------------------------------------
dados_prop <- dados %>%
  group_by(regiao, classe_textural) %>%
  summarise(area_total = sum(area_total, na.rm = TRUE), .groups = "drop") %>%
  group_by(regiao) %>%
  mutate(
    proporcao = area_total / sum(area_total) * 100,  # Calcula a % dentro da região
    classe_textural = factor(
      classe_textural,
      levels = c("Arenosa", "Média", "Argilosa", "Muito argilosa", "Siltosa"),
      labels = c("Arenosa", "Média", "Argilosa", "Muito Argilosa", "Siltosa")
    )
  )

# -----------------------------------------------------------------------------
# 5. Definir paleta de cores personalizada
# -----------------------------------------------------------------------------
cores <- c(
  "Arenosa" = "#fefe72",         # Amarelo
  "Média" = "#d7c4a4",           # Bege médio
  "Argilosa" = "#aa8785",        # Marrom rosado
  "Muito Argilosa" = "#a83700",  # Terracota escuro
  "Siltosa" = "#b5d5ae"          # Verde claro
)

# -----------------------------------------------------------------------------
# 6. Criar gráfico de barras empilhadas (proporcional, 100%)
# -----------------------------------------------------------------------------
grafico <- ggplot(dados_prop, aes(x = regiao, y = proporcao, fill = classe_textural)) +
  geom_col(position = "fill", width = 0.7) +
  scale_fill_manual(values = cores) +
  scale_y_continuous(
    labels = percent_format(),             # Exibe como %
    breaks = seq(0, 1, by = 0.2),
    expand = c(0, 0)
  ) +
  labs(
    title = "Proporção de Classes Texturais por Região",
    subtitle = "Dados do Oeste do Paraná",
    x = NULL,
    y = "Proporção (%)",
    fill = "Classe Textural"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold", hjust = 0.5, size = 16),
    plot.subtitle = element_text(hjust = 0.5, size = 12, color = "gray40"),
    legend.position = "right",
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid.major.x = element_blank()
  ) +
  coord_flip()  # Inverte para barras horizontais

# -----------------------------------------------------------------------------
# 7. Visualizar e salvar gráfico
# -----------------------------------------------------------------------------
print(grafico)

ggsave(
  filename = "proporcao_classes_texturais_regiao.png",
  plot = grafico,
  width = 10,
  height = 6,
  dpi = 300
)
