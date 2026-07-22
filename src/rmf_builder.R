
source('src/rmfReader.R')
rmfs <- list(
  "2018" = rmfReader("rmf/Anexos_RMF2018_29122017.pdf", c(2,30)),
  "2019" = rmfReader("rmf/Anexo_11_RMF_2019_30042019.pdf", c(2,34)),
  "2020" = rmfReader("rmf/Anexo+11+2020.pdf", c(2,36)),
  "2021" = rmfReader("rmf/Anexo+11+RMF+2021+DOF+11012021.pdf", c(2,45)),
  "2023" = rmfReader("rmf/Anexo_11-RMF_2023-10012023.pdf", c(2,50))
)
