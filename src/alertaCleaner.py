"""
Extrae tablas de PDFs que tienen bordes reales dibujados (rectángulos/líneas
vectoriales, no solo texto alineado por espacios).

Maneja un caso particular: cuando una tabla continúa de una página a otra,
la primera fila de la continuación a veces NO tiene su línea superior propia
dibujada. pdfplumber (vía find_tables()) pierde esa fila por defecto. Este
script la detecta y la reconstruye.

Requiere: pip install pdfplumber

Uso desde línea de comandos:
    python3 extraer_tablas_pdf.py config_archivos.json salida.csv

Donde config_archivos.json es una lista de objetos con esta forma:
[
    {"ruta": "archivo1.pdf", "paginas": [1, 2, 3], "titulo": "Nombre explícito 1"},
    {"ruta": "archivo2.pdf", "paginas": null,      "titulo": "Nombre explícito 2"}
]
- "paginas": lista de números de página (1-indexado) a procesar, o null para todas.
- "titulo": el nombre que quieres que aparezca en el CSV de salida para ese
  archivo (no se usa el nombre del PDF).
"""
import pdfplumber
import csv
import json
import sys


def obtener_limites_columna(tabla):
    """¿En qué valores de 'x' empieza y termina cada columna?"""
    coordenadas_x = set()
    for celda in tabla.cells:
        x0, _, x1, _ = celda
        coordenadas_x.add(round(x0, 1))
        coordenadas_x.add(round(x1, 1))
    return sorted(coordenadas_x)


def techo_de_fila_oculta(pagina, tabla):
    """
    Busca líneas verticales (separadores de columna) que sigan dibujadas
    por encima de donde find_tables() dice que empieza la tabla.
    Si las encuentra, ahí hay una fila que no tiene borde propio arriba
    (típico de una tabla que continúa de la página anterior).

    Regresa el 'y' donde arranca esa fila oculta, o None si no hay ninguna.

    NOTA para mantenimiento futuro: si esto deja de funcionar con un PDF
    nuevo, este es el primer lugar a revisar. Asume que las líneas
    verticales de la grilla son angostas (width < 1). Si el PDF usa un
    grosor de línea distinto, ajustar ese número.
    """
    limites_columna = obtener_limites_columna(tabla)
    techo_detectado = tabla.bbox[1]

    verticales_mas_arriba = [
        r for r in pagina.rects
        if r['width'] < 1
        and r['top'] < techo_detectado - 1
        and any(abs(r['x0'] - limite) < 1 for limite in limites_columna)
    ]

    if not verticales_mas_arriba:
        return None
    return min(r['top'] for r in verticales_mas_arriba)


def obtener_palabras_de_fila_oculta(pagina, tabla):
    """Regresa las palabras que caen dentro de la franja de la fila oculta (si existe)."""
    techo_detectado = tabla.bbox[1]
    x_izquierda, _, x_derecha, _ = tabla.bbox

    techo_oculto = techo_de_fila_oculta(pagina, tabla)
    if techo_oculto is None:
        return []

    return [
        palabra for palabra in pagina.extract_words()
        if techo_oculto - 2 <= palabra['top'] < techo_detectado
        and x_izquierda <= palabra['x0'] <= x_derecha
    ]


def encontrar_indice_de_columna(x_de_la_palabra, limites_columna):
    """Dado el 'x' donde empieza una palabra, dice a qué columna pertenece."""
    for indice in range(len(limites_columna) - 1):
        if limites_columna[indice] <= x_de_la_palabra < limites_columna[indice + 1]:
            return indice
    return None


def repartir_en_columnas(palabras, limites_columna):
    """Arma la fila completa (una celda por columna), respetando el orden de lectura."""
    numero_de_columnas = len(limites_columna) - 1
    palabras_por_columna = [[] for _ in range(numero_de_columnas)]

    for palabra in palabras:
        indice_columna = encontrar_indice_de_columna(palabra['x0'], limites_columna)
        if indice_columna is not None:
            palabras_por_columna[indice_columna].append(palabra)

    fila_armada = []
    for lista_de_palabras in palabras_por_columna:
        # ordenar por 'top' (arriba a abajo) y luego 'x0' (izquierda a derecha),
        # por si la celda tiene más de una línea
        palabras_ordenadas = sorted(lista_de_palabras, key=lambda p: (p['top'], p['x0']))
        fila_armada.append(" ".join(p['text'] for p in palabras_ordenadas))

    return fila_armada


def procesar_pagina(pagina):
    """
    Toma UNA página del PDF y regresa la lista de filas de su tabla,
    ya con la fila oculta (si existe) reconstruida y puesta al inicio.
    Si la página no tiene ninguna tabla, regresa una lista vacía.
    """
    tablas_de_la_pagina = pagina.find_tables()
    if not tablas_de_la_pagina:
        return []

    tabla = tablas_de_la_pagina[0]
    filas = tabla.extract()

    limites_columna = obtener_limites_columna(tabla)
    palabras_ocultas = obtener_palabras_de_fila_oculta(pagina, tabla)

    if palabras_ocultas:
        filas = [repartir_en_columnas(palabras_ocultas, limites_columna)] + filas

    return filas


def procesar_pdf(ruta_pdf, paginas):
    """
    ruta_pdf: ruta al archivo PDF.
    paginas: lista de números de página a procesar (1-indexado), ej. [1, 2, 3].
             Si se pasa None, procesa todas las páginas del archivo.
    """
    filas_totales = []
    with pdfplumber.open(ruta_pdf) as pdf:
        paginas_a_usar = paginas if paginas is not None else range(1, len(pdf.pages) + 1)
        for numero_de_pagina in paginas_a_usar:
            pagina = pdf.pages[numero_de_pagina - 1]  # pdfplumber es 0-indexado
            for fila in procesar_pagina(pagina):
                filas_totales.append({"page": numero_de_pagina, "celdas": fila})
    return filas_totales


def procesar_lote(config_archivos, archivo_salida):
    """
    config_archivos: lista de diccionarios, uno por PDF a procesar. Cada uno con:
        - "ruta": ruta al archivo PDF
        - "paginas": lista de páginas a mirar, ej. [1, 2, 3] (o None/null para todas)
        - "titulo": nombre explícito para identificar este archivo en el CSV de
                    salida (no se usa el nombre del PDF)
    """
    filas_totales = []
    for entrada in config_archivos:
        filas_del_archivo = procesar_pdf(entrada["ruta"], entrada["paginas"])
        for fila in filas_del_archivo:
            for indice_columna, texto in enumerate(fila["celdas"]):
                filas_totales.append({
                    "titulo": entrada["titulo"],
                    "page": fila["page"],
                    "col": indice_columna,
                    "texto": (texto or "").replace("\n", " ")
                })

    with open(archivo_salida, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["titulo", "page", "col", "texto"])
        writer.writeheader()
        writer.writerows(filas_totales)


if __name__ == "__main__":
    ruta_config = sys.argv[1]
    ruta_salida = sys.argv[2]

    with open(ruta_config, encoding="utf-8") as f:
        config = json.load(f)

    procesar_lote(config, ruta_salida)