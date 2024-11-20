dir.create("~/jpdemo/pckgs", recursive = TRUE)
.libPaths( c("~/jpdemo/pckgs", .libPaths()) )

install.packages(c("matrixStats", "dplyr", "foreach", "doParallel", "data.table", "Cairo", "utils", "stringr", "remotes"), repos = "http://cran.us.r-project.org")

remotes::install_github("asgr/magicaxis")
remotes::install_github("asgr/celestial")
remotes::install_github("asgr/imager")
remotes::install_github("asgr/Rwcs")
remotes::install_github("asgr/Rfits")
remotes::install_github("asgr/ProPane")
remotes::install_github("asgr/ProFound")

