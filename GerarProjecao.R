library(dplyr)
library(WriteXLS)
library(htmltools)
library(prophet)

#Lê os argumentos
argumentos <- commandArgs(trailingOnly = TRUE)

#Armazena a quantidade de meses desejada para a projeção
meses <- as.numeric(argumentos[1])

#Baixa o dataset do repositório wcota/covid19br, para contar sempre com os dados mais atuais
download.file("https://raw.githubusercontent.com/wcota/covid19br/master/cases-brazil-states.csv", 
              destfile = "cases-brazil-states.csv", quiet = FALSE)

#Lê o dataset
casos_dia <- read.csv('cases-brazil-states.csv')

#Converte o campo da Data
casos_dia$date <- as.Date(casos_dia$date, "%Y-%m-%d")

#Extrai a lista de UFs
registro_estados <- data.frame(table(casos_dia$state[casos_dia$state != "TOTAL"]))
lista_estados <- as.vector(registro_estados$Var1)

#Criação dos dataframes de casos e óbitos por dia e estado
casos_dia_estado <- casos_dia[casos_dia$state != 'TOTAL', c('date', 'state', 'newCases')]
obitos_dia_estado <- casos_dia[casos_dia$state != 'TOTAL', c('date', 'state', 'newDeaths')]

#Renomeia colunas para o padrão exigido pelo Prophet
colnames(casos_dia_estado) <- c("ds", "state", "y")
colnames(obitos_dia_estado) <- c("ds", "state", "y")

#Criação dos dataframes de casos e óbitos a nível nacional
casos_dia_nacional <- casos_dia_estado %>%
  group_by(ds) %>%
  summarise(y = sum(y))

obitos_dia_nacional <- obitos_dia_estado %>%
  group_by(ds) %>%
  summarise(y = sum(y))

#Treina os modelos com base nos dados de casos e óbitos a nível nacional. Sazonalidade anual ativada
modelo_casos_nacional <- prophet(casos_dia_nacional, 
                                 seasonality.mode = "multiplicative", 
                                 yearly.seasonality = TRUE, 
                                 weekly.seasonality = FALSE, 
                                 daily.seasonality = FALSE)

modelo_obitos_nacional <- prophet(obitos_dia_nacional, 
                                 seasonality.mode = "multiplicative", 
                                 yearly.seasonality = TRUE, 
                                 weekly.seasonality = FALSE, 
                                 daily.seasonality = FALSE)

#Cria os dataframes com os períodos futuros, conforme a quantidade de meses para a projeção futura
periodosfuturos_casos_nacional <- make_future_dataframe(modelo_casos_nacional, periods = meses * 30, freq = "day")
periodosfuturos_obitos_nacional <- make_future_dataframe(modelo_obitos_nacional, periods = meses * 30, freq = "day")

#Cria as projeções de casos e óbitos a nível nacional
projecao_casos_nacional <- predict(modelo_casos_nacional, periodosfuturos_casos_nacional)
projecao_obitos_nacional <- predict(modelo_obitos_nacional, periodosfuturos_obitos_nacional)

#Cria os plots de casos e óbitos a nível nacional
plot_casos_nacional <- dyplot.prophet(modelo_casos_nacional, projecao_casos_nacional, main = paste0("Casos de Covid - Projeção para os próximos ", meses, " meses - Nacional"))
plot_obitos_nacional <- dyplot.prophet(modelo_obitos_nacional, projecao_obitos_nacional, main = paste0("Óbitos de Covid - Projeção para os próximos ", meses, " meses - Nacional"))

#Cria os plots auxiliares com dados de tendência e sazonalidade de casos e óbitos a nível nacional
png("Tendência e Sazonalidade de Casos - Nacional.png", width = 800, height = 600, units = "px")
prophet_plot_components(modelo_casos_nacional, projecao_casos_nacional)
dev.off()

png("Tendência e Sazonalidade de Óbitos - Nacional.png", width = 800, height = 600, units = "px")
prophet_plot_components(modelo_obitos_nacional, projecao_obitos_nacional)
dev.off()

#Salva os plots
save_html(plot_casos_nacional, file = "Casos de Covid - Projeção - Nacional.html")
save_html(plot_obitos_nacional, file = "Obitos de Covid - Projeção - Nacional.html")

#Cria os resultados compilados
resultados_casos_nacional <- projecao_casos_nacional[, c("yhat_lower", "yhat", "yhat_upper")]
resultados_obitos_nacional <- projecao_obitos_nacional[, c("yhat_lower", "yhat", "yhat_upper")]

#Tira as casas decimais
resultados_casos_nacional <- round(resultados_casos_nacional, digits = 0)
resultados_obitos_nacional <- round(resultados_obitos_nacional, digits = 0)

colnames(resultados_casos_nacional) <- c("ProjecaoMenor", "ProjecaoUsual", "ProjecaoMaior")
colnames(resultados_obitos_nacional) <- c("ProjecaoMenor", "ProjecaoUsual", "ProjecaoMaior")

#Salva em uma planilha unificada
WriteXLS(c("resultados_casos_nacional", "resultados_obitos_nacional"), 
         "Resultados Nacional.xls", 
         BoldHeaderRow = TRUE, 
         row.names = TRUE,
         AdjWidth = TRUE)

#Realiza a mesma rotina feita para os casos e óbitos a nível nacional em um loop 'for' para cada estado da federação
for (estado in lista_estados) {

modelo_casos <- prophet(casos_dia_estado[casos_dia_estado$state == estado, c("ds", "y")], 
                        seasonality.mode = "multiplicative", 
                        yearly.seasonality = TRUE, 
                        weekly.seasonality = FALSE, 
                        daily.seasonality = FALSE)

modelo_obitos <- prophet(obitos_dia_estado[obitos_dia_estado$state == estado, c("ds", "y")], 
                         seasonality.mode = "multiplicative", 
                         yearly.seasonality = TRUE, 
                         weekly.seasonality = FALSE, 
                         daily.seasonality = FALSE)

periodosfuturos_casos <- make_future_dataframe(modelo_casos, periods = meses * 30, freq = "day")
periodosfuturos_obitos <- make_future_dataframe(modelo_obitos, periods = meses * 30, freq = "day")

projecao_casos <- predict(modelo_casos, periodosfuturos_casos)
projecao_obitos <- predict(modelo_obitos, periodosfuturos_obitos)

plot_casos <- dyplot.prophet(modelo_casos, projecao_casos, main = paste0("Casos de Covid - Projeção para os próximos ", meses , " meses - ", estado))
plot_obitos <- dyplot.prophet(modelo_obitos, projecao_obitos, main = paste0("Óbitos de Covid - Projeção para os próximos ", meses, " meses - ", estado))

png(paste0("Tendência e Sazonalidade de Casos - ", estado, ".png"), width = 800, height = 600, units = "px")
prophet_plot_components(modelo_casos, projecao_casos)
dev.off()

png(paste0("Tendência e Sazonalidade de Óbitos - ", estado, ".png"), width = 800, height = 600, units = "px")
prophet_plot_components(modelo_obitos, projecao_obitos)
dev.off()

save_html(plot_casos, file = paste0("Casos de Covid - Projeção - ", estado, ".html"))
save_html(plot_obitos, file = paste0("Obitos de Covid - Projeção - ", estado, ".html"))

resultados_compilados_casos <- projecao_casos[, c("yhat_lower", "yhat", "yhat_upper")]
resultados_compilados_obitos <- projecao_obitos[, c("yhat_lower", "yhat", "yhat_upper")]

resultados_compilados_casos <- round(resultados_compilados_casos, digits = 0)
resultados_compilados_obitos <- round(resultados_compilados_obitos, digits = 0)

colnames(resultados_compilados_casos) <- c("ProjecaoMenor", "ProjecaoUsual", "ProjecaoMaior")
colnames(resultados_compilados_obitos) <- c("ProjecaoMenor", "ProjecaoUsual", "ProjecaoMaior")

WriteXLS(c("resultados_compilados_casos", "resultados_compilados_obitos"), 
         paste0("Resultados - ", estado, ".xls"), 
         BoldHeaderRow = TRUE, 
         row.names = TRUE,
         AdjWidth = TRUE)

}
