library(pdftools)
library(data.table)

setwd("C:/Users/khayr/Documents/brand_clenaer")

pags <- c(2,30)
docs <- 1

mis <- pdf_data("Anexos_RMF2018_29122017.pdf")
mis <- rbindlist(mis, idcol = "page")
setDT(mis)
mis <- mis[page%between%pags]
lineas <- mis[order(page, y, x),
              .(texto = paste(text, collapse = " ")),
              by = .(page, y)]

lineas[, is_header := grepl("^\\d+\\.\\s*", texto) & grepl("R\\.F\\.C\\.", texto)]
lineas[is_header == TRUE, .(page, texto)]


extraer_codigo <- Vectorize(function(texto) {
  if (grepl("^\\d{6}\\b", texto)) {
    sub("^(\\d{6})\\b.*", "\\1", texto)
  } else {
    NA_character_
  }
}) 

lineas[, codigo := extraer_codigo(texto)]
lineas <- lineas[is_header == TRUE | !is.na(codigo)]

extraer_producto <- Vectorize(function(texto, codigo) {
  if (is.na(codigo)) {
    NA_character_
  } else {
    trimws(sub("^\\d{6}\\b", "", texto))
  }
})
lineas[ ,producto := extraer_producto(texto, codigo)]

lineas[, grupo := cumsum(is_header)]



library(stringdist)

buscar_marca <- function(marca, productos, threshold = 0.95) {
  marca <- tolower(trimws(marca))
  productos <- tolower(trimws(productos))
  
  n <- nchar(marca)
  prefijos <- substr(productos, 1, n)
  
  sim <- 1 - stringdist(marca, prefijos, method = "jw", p = 0.1)
  
  list(
    encontrado = any(sim >= threshold),
    precision  = max(sim)
  )
}

alerta <- readxl::read_xlsx("alerta.xlsx")

for(marca in alerta$Marca){
  cat(marca)
  x <- buscar_marca(marca, lineas$producto)
  print(x)
}