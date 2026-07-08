#Tests 
source('src/rmfReader.R')
source('src/alertaBuilder.R')

marcas <- openxlsx2::read_xlsx("marcas.xlsx")
rmfs <- list(
  "2018" = rmfReader("rmf/Anexos_RMF2018_29122017.pdf", c(2,30)),
  "2019" = rmfReader("rmf/Anexo_11_RMF_2019_30042019.pdf", c(2,34)),
  "2020" = rmfReader("rmf/Anexo+11+2020.pdf", c(2,36)),
  "2021" = rmfReader("rmf/Anexo+11+RMF+2021+DOF+11012021.pdf", c(2,45))
)

dt <- rmfComparator(rmfs, marcas$brand)

system2("python3", args = c("src/alertaCleaner.py","alerta/","alerta_clean.csv"))

dt[ ,cofepris := txtComparator(marca, alerta[titulo%in%2017,texto])]

