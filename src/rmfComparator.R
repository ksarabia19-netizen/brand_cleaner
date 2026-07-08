#
#<------------------ RMF COMPARATOR ------------------------------------->
#

library(stringdist)

normalizar_texto <- function(x) {
  x <- tolower(x)
  x <- stringi::stri_trans_general(x, "Latin-ASCII")  # quita tildes, diéresis, ñ->n
  x <- gsub("\\s+", " ", x)   # colapsa espacios múltiples/tabs a uno solo
  x <- trimws(x)
  return(x)
}
extraer_prefijo_palabra <- function(texto, n) {
  if (nchar(texto) <= n) return(texto)
  
  resto <- substr(texto, n + 1, nchar(texto))
  pos_espacio <- regexpr(" ", resto)

  if (pos_espacio == -1) {
    return(texto)  
  } else {
    return(substr(texto, 1, n + pos_espacio - 1))
  }
  
}

txtComparator <- Vectorize(function(marca, productos, threshold = 0.95) {
  marca <- normalizar_texto(marca)
  productos <- normalizar_texto(productos)
  
  n <- nchar(marca)
  prefijos <- vapply(productos, extraer_prefijo_palabra, character(1), n = n)
  sim <- 1 - stringdist(marca, prefijos, method = "jw", p = 0.1)
  return(max(sim, na.rm = TRUE))
}, vectorize.args = "marca")


rmfComparator <- function(rmfs, marcas){
  dt <- data.table(
    "marca" = marcas
  )
  rmfNames <- names(rmfs)
  i <- 1
  for(rmf in rmfs){
    producto <- rmf[["producto"]]
    producto <- producto[!is.na(producto)]
    set(dt, j = rmfNames[[i]], value = txtComparator(dt$marca, producto))
    i <- i + 1
  }
}

