# =============================================================================
# Gráfico de Pizza com Duas Camadas: Cobertura do Solo por Nível de Classificação
# =============================================================================
# Este script gera um gráfico do tipo pizza com duas camadas (donut chart),
# representando a proporção de usos e coberturas do solo classificados em dois níveis:
#   - Nível 1 (N1): categorias mais amplas
#   - Nível 4 (N4): subcategorias mais detalhadas
#
# Aplicado ao município de Cascavel no ano de 1985.
#
# Contato: cardoso.mvs@gmail.com, taciarahorst@professoes.utfpr.edu.br
# Requisitos: R + pacotes ggplot2, ggforce, dplyr
# Reproduzir com:
#   install.packages(c("ggplot2", "ggforce", "dplyr"))
#
# -----------------------------------------------------------------------------

# Carregar pacotes necessários
library(ggplot2)
library(ggforce)
library(dplyr)

# -----------------------------------------------------------------------------
# Definição dos dados
# -----------------------------------------------------------------------------
dados <- data.frame(
  cobertura_n4 = c("Café", "Campo Alagado e Área Pantanosa", "Formação Florestal", 
                   "Mosaico de Usos", "Outras Lavouras Perenes", "Outras Lavouras Temporárias", 
                   "Outras Áreas não Vegetadas", "Pastagem", "Silvicultura", "Soja", "Área Urbanizada"),
  area_ha_n4 = c(1045.911115, 37.43979572, 331433.3318, 225103.4011, 297.3369469, 
                 259021.3063, 170.5657336, 152715.083, 8803.405075, 124133.6455, 6283.767102),
  cobertura_n1 = c("Agropecuária", "Vegetação Herbácea e Arbustiva", "Floresta", 
                   "Agropecuária", "Agropecuária", "Agropecuária", "Área não Vegetada", 
                   "Agropecuária", "Agropecuária", "Agropecuária", "Área não Vegetada")
)

# -----------------------------------------------------------------------------
# Definição das cores para cada categoria (N1 e N4)
# -----------------------------------------------------------------------------
cores <- c(
  # N1 (nível mais amplo)
  "Agropecuária" = "#E974ED", 
  "Vegetação Herbácea e Arbustiva" = "#519799",
  "Floresta" = "#1f8d49",
  "Área não Vegetada" = "#d4271e",
  
  # N4 (subcategorias detalhadas)
  "Café" = "#d68fe2",
  "Mosaico de Usos" = "#ffefc3",
  "Outras Lavouras Perenes" = "#e6ccff",
  "Outras Lavouras Temporárias" = "#f54ca9", 
  "Soja" = "#f5b3c8",
  "Pastagem" = "#edde8e",
  "Silvicultura" = "#7a5900",
  "Campo Alagado e Área Pantanosa" = "#519799",
  "Formação Florestal" = "#1f8d49",
  "Área Urbanizada" = "#d4271e",
  "Outras Áreas não Vegetadas" = "#db4d4f"
)

# -----------------------------------------------------------------------------
# Processar dados do Nível 1
# -----------------------------------------------------------------------------
dados_n1 <- dados %>%
  group_by(cobertura_n1) %>%
  summarise(area_ha = sum(area_ha_n4), .groups = "drop") %>%
  mutate(
    prop = area_ha / sum(area_ha),                      # proporção de cada classe
    start = cumsum(prop) * 2 * pi - prop * 2 * pi,      # ângulo inicial
    end = cumsum(prop) * 2 * pi                         # ângulo final
  )

# -----------------------------------------------------------------------------
# Processar dados do Nível 4 (subcategorias dentro de cada N1)
# -----------------------------------------------------------------------------
dados_n4 <- dados %>%
  group_by(cobertura_n1) %>%
  mutate(
    start_n1 = dados_n1$start[match(first(cobertura_n1), dados_n1$cobertura_n1)],
    range_n1 = dados_n1$end[match(first(cobertura_n1), dados_n1$cobertura_n1)] - start_n1,
    prop = area_ha_n4 / sum(area_ha_n4),
    start = start_n1 + cumsum(prop) * range_n1 - prop * range_n1,
    end = start_n1 + cumsum(prop) * range_n1
  ) %>%
  ungroup()

# -----------------------------------------------------------------------------
# Plotar gráfico de pizza em duas camadas com ggforce::geom_arc_bar
# -----------------------------------------------------------------------------
ggplot() +
  # Anel externo: categorias detalhadas (N4)
  geom_arc_bar(
    data = dados_n4,
    aes(x0 = 0, y0 = 0, r0 = 1.3, r = 1.8, start = start, end = end, fill = cobertura_n4),
    color = "white", size = 0.5
  ) +
  # Anel interno: categorias amplas (N1)
  geom_arc_bar(
    data = dados_n1,
    aes(x0 = 0, y0 = 0, r0 = 0.5, r = 1.2, start = start, end = end, fill = cobertura_n1),
    color = "white", size = 0.5
  ) +
  scale_fill_manual(values = cores, name = "Categorias") +
  coord_equal() +
  labs(title = "Cobertura do Solo - Cascavel (1985)") +
  theme_void() +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    legend.position = "bottom",
    legend.text = element_text(size = 8)
  )
