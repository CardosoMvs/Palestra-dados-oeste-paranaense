# =============================================================================
# Gráfico de Colunas Empilhadas: Evolução do Uso e Cobertura da Terra (Oeste do PR)
# =============================================================================
# Este script gera um gráfico de colunas empilhadas mostrando a evolução da 
# área ocupada por diferentes categorias de uso e cobertura da terra ao longo 
# do tempo, em centenas de milhares de hectares.
#
# Aplicação: Oeste do Paraná (dados MapBiomas)
# Categorias exibidas: Agropecuária, Floresta, Vegetação Herbácea e Área não Vegetada
#
# Contato: cardoso.mvs@gmail.com, taciarahorst@professoes.utfpr.edu.br
# Requisitos: R + pacotes ggplot2, dplyr, scales
# Execução:
#   install.packages(c("ggplot2", "dplyr", "scales"))
#
# -----------------------------------------------------------------------------

# Carregar pacotes
library(ggplot2)
library(dplyr)
library(scales)

# -----------------------------------------------------------------------------
# 1. Preparar dados
# -----------------------------------------------------------------------------
dados_coluna <- resultado_agregado %>%
  filter(categoria %in% c("Agropecuária", "Floresta", 
                          "Vegetação Herbácea e Arbustiva", "Área não Vegetada")) %>%
  mutate(
    categoria = factor(categoria, 
                       levels = c("Área não Vegetada",
                                  "Vegetação Herbácea e Arbustiva",
                                  "Floresta",
                                  "Agropecuária"))  # Ordem empilhada visual
  )

# -----------------------------------------------------------------------------
# 2. Paleta de cores personalizada (EXATA)
# -----------------------------------------------------------------------------
cores <- c(
  "Agropecuária" = "#ffefc3ff",                     # Bege claro
  "Floresta" = "#1f8d49ff",                         # Verde floresta
  "Vegetação Herbácea e Arbustiva" = "#d6bc74ff",   # Amarelo-terra
  "Área não Vegetada" = "#d4271eff"                 # Vermelho-sangue
)

# -----------------------------------------------------------------------------
# 3. Criar gráfico de colunas empilhadas (sem rótulos dentro das barras)
# -----------------------------------------------------------------------------
grafico_coluna <- ggplot(dados_coluna, aes(x = as.factor(ano), y = area_total_100k, fill = categoria)) +
  geom_col(position = "stack", width = 0.7, alpha = 0.9) +
  scale_fill_manual(values = cores) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +  # Pequeno espaço no topo
  labs(
    title = "Evolução do uso e cobertura da terra no oeste do Paraná",
    subtitle = "Área total em centenas de milhares de hectares",
    x = NULL,
    y = "Área (100 mil ha)",
    fill = "Categorias:",
    caption = "Fonte: Elaboração própria com dados do MapBiomas"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold", hjust = 0.5, size = 18),
    plot.subtitle = element_text(hjust = 0.5, color = "gray40", size = 14),
    legend.position = "bottom",
    legend.title = element_text(face = "bold"),
    panel.grid.major.x = element_blank(),
    axis.text.x = element_text(size = 14, angle = 45, hjust = 1),
    axis.title.y = element_text(margin = margin(r = 10))
  )

# -----------------------------------------------------------------------------
# 4. Visualizar gráfico
# -----------------------------------------------------------------------------
print(grafico_coluna)

# -----------------------------------------------------------------------------
# 5. Salvar imagem (opcional)
# -----------------------------------------------------------------------------
ggsave(
  "C:/Users/marco/Downloads/OESTE-PR/evolucao__222uso_solo_colunas.png",
  plot = grafico_coluna,
  width = 14,
  height = 7,
  dpi = 300
)
