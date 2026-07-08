#
#<----------------------- PDF READER RMF LICITS --------------------------------------------------->
#
library(pdftools)
library(data.table)

extraer_codigo <- Vectorize(function(texto) {
  if (grepl("^\\d{6}\\b", texto)) {
    sub("^(\\d{6})\\b.*", "\\1", texto)
  } else {
    NA_character_
  }
}) 
extraer_producto <- Vectorize(function(texto, codigo) {
  if (is.na(codigo)) {
    NA_character_
  } else {
    trimws(sub("^\\d{6}\\b", "", texto))
  }
})
rmfReader <- function(file, pages){
  mis <- pdf_data(file)
  mis <- rbindlist(mis, idcol = "page")
  setDT(mis)
  mis <- mis[page%between%pages]
  lineas <- mis[order(page, y, x),
                .(texto = paste(text, collapse = " ")),
                by = .(page, y)]

  lineas[, is_header := grepl("^\\d+\\.\\s*", texto) & grepl("R\\.F\\.C\\.", texto)]
  lineas[is_header == TRUE, .(page, texto)]

  lineas[, codigo := extraer_codigo(texto)]
  lineas <- lineas[is_header == TRUE | !is.na(codigo)]
  
  lineas[ ,producto := extraer_producto(texto, codigo)]
  lineas[ ,grupo := cumsum(is_header)]
  lineas[ ,is_cigarro := substr(codigo,1,1)%in%c(0,1)]
  return(lineas[(is_cigarro) | (is_header)])
}


