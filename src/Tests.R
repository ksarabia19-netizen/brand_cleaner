#Tests 
source('src/rmfReader.R')
source('src/alertaBuilder.R')
source('src/rmfComparator.R')

marcas <- openxlsx2::read_xlsx("marcas.xlsx")
rmfs <- list(
  "2018" = rmfReader("rmf/Anexos_RMF2018_29122017.pdf", c(2,30)),
  "2019" = rmfReader("rmf/Anexo_11_RMF_2019_30042019.pdf", c(2,34)),
  "2020" = rmfReader("rmf/Anexo+11+2020.pdf", c(2,36)),
  "2021" = rmfReader("rmf/Anexo+11+RMF+2021+DOF+11012021.pdf", c(2,45)),
  "2023" = rmfReader("rmf/Anexo_11-RMF_2023-10012023.pdf", c(2,50))
)

dt <- rmfComparator(rmfs, marcas$brand)

dt[ ,cofepris := txtComparator(marca, alerta[titulo%in%2017,texto])]

dt[ ,c("legal", "aparece"):=isLegal(`2023`,cofepris), by=1:nrow(dt)]
