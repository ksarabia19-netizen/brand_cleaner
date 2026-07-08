library(data.table)
library(jsonlite)

# --------------------------------------------------------------------------
# 1. Configuración: un elemento por archivo PDF a procesar.
#    - ruta:    ruta al PDF
#    - paginas: vector de páginas a mirar (1-indexado), o NULL para todas
#    - titulo:  nombre explícito para identificar el archivo en el resultado
#               (no se usa el nombre del PDF)
# --------------------------------------------------------------------------
config <- list(
  list(
    ruta    = "alerta/Alerta_Sanitaria_tabaco_agosto_2016.pdf",
    paginas = c(1, 2, 3),
    titulo  = "2016"
  ),
    list(
    ruta    = "alerta/Alerta_Sanitaria_tabaco_y_e-cigarettes_27Abril2017.pdf",
    paginas = c(2, 3),
    titulo  = "2017"
  )
)

ruta_config <- "config_archivos.json"
ruta_salida <- "alerta/built_alerta.csv"

jsonlite::write_json(config, ruta_config, auto_unbox = TRUE, null = "null")

# --------------------------------------------------------------------------
# <------------------ Llamar al script de Python -------------------------->
# --------------------------------------------------------------------------
if(!file.exists(ruta_salida)) system2("python3", args = c("src/alertaCleaner.py", ruta_config, ruta_salida))

# --------------------------------------------------------------------------
# <------------------- Leer el resultado ---------------------------------->
# --------------------------------------------------------------------------
alerta <- fread(ruta_salida, encoding = "UTF-8")
