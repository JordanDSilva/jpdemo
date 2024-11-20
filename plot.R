library(data.table)
library(dplyr)
library(ProFound)
library(Rfits)
library(Rwcs)
library(celestial)

df = bind_cols(
  fread("~/jpdemo/JP/ProFound/Detects/2738002001/NRCA/2738002001_NRCA_segstats.csv"),
  fread("~/jpdemo/JP/ProFound/Measurements/2738002001/NRCA/2738002001_NRCA_photometry.csv")
)

RA = 260.7066337
DEC = 65.7481699

objMatch = coordmatchsing(
  RAref = RA,
  Decref = DEC,
  coordcompare = df[, c("RAcen", "Deccen")]
)

objMatch$ID

dfObj = df[objMatch$ID, ]

sedData = readRDS(
  "~/jpdemo/data.rds"
)

proDetIm = Rfits_read(
  "~/jpdemo/JP/ProFound/Detects/2738002001/NRCA/2738002001_NRCA_profound_stack.fits"
)

pixC = Rwcs_s2p(
  RA = RA, Dec = DEC,
  keyvalues = proDetIm$image$keyvalues
)

proF090W = readRDS(
  "~/jpdemo/JP/ProFound/Measurements/2738002001/NRCA/2738002001_NRCA_F090W_results.rds"
)
proF277W = readRDS(
  "~/jpdemo/JP/ProFound/Measurements/2738002001/NRCA/2738002001_NRCA_F277W_results.rds"
)
proF444W = readRDS(
  "~/jpdemo/JP/ProFound/Measurements/2738002001/NRCA/2738002001_NRCA_F444W_results.rds"
)

filtout = sedData$filtout

png(
  "~/jpdemo/plots/sedplot.png", width = 10, height = 10, res = 240, units = "in"
)
par(oma = rep(2,4), mar = rep(2.0,4), xaxt = "n", yaxt = "n")
layout_matrix <- matrix(c(1, 2, 3, 4, 4, 4, 5, 5, 5), ncol = 3, byrow = TRUE)
layout(
  layout_matrix
)
profoundSegimPlot(
  image = magcutout(
    image = proF090W$image,
    loc = pixC,
    box = 200
  )$image, 
  segim = magcutout(
    image = proF090W$segim == dfObj$segID...1,
    loc = pixC,
    box = 200
  )$image, 
  col = "cyan", 
  locut = 0.5,
  hicut = 0.999
)
text(
  x = 100, 
  y = 25, 
  "F090W", 
  col = "cyan"
)

profoundSegimPlot(
  image = magcutout(
    image = proF277W$image,
    loc = pixC,
    box = 200
  )$image, 
  segim = magcutout(
    image = proF277W$segim == dfObj$segID...1,
    loc = pixC,
    box = 200
  )$image, 
  col = "green", 
  locut = 0.5,
  hicut = 0.999
)
text(
  x = 100, 
  y = 25, 
  "F277W", 
  col = "green"
)

profoundSegimPlot(
  image = magcutout(
    image = proF444W$image,
    loc = pixC,
    box = 200
  )$image, 
  segim = magcutout(
    image = proF444W$segim == dfObj$segID...1,
    loc = pixC,
    box = 200
  )$image, 
  col = "red", 
  locut = 0.5,
  hicut = 0.999
)
text(
  x = 100, 
  y = 25, 
  "F444W", 
  col = "red"
)
magplot(
  NA, 
  log = "xy", 
  xlab = "Wavelength / Angstrom",
  ylab = "Flux density/ Jansky", 
  xlim = c(7000, 100000),
  ylim = 10^c(-5,-3.5)
)
lines(
  filtout[[1]]$wave,
  1e-4 * filtout[[1]]$response / max(filtout[[1]]$response, na.rm = TRUE), 
  col = "cyan"
)
lines(
  filtout[[2]]$wave,
  1e-4 * filtout[[2]]$response / max(filtout[[2]]$response, na.rm = TRUE), 
  col = "green"
)
lines(
  filtout[[3]]$wave,
  1e-4 * filtout[[3]]$response / max(filtout[[3]]$response, na.rm = TRUE), 
  col = "red"
)

lines(
  sedData$fitSed, 
  col = "black", 
  lwd = 2
)
lines(
  sedData$starsWave,
  sedData$fitStars,
  col = rgb(0,0,1,0.8), 
  lwd = 2
)
magerr(
  sedData$flux_data$cenwave, 
  sedData$flux_data$flux, 
  ylo = sedData$flux_data$fluxerr, 
  length = 0.1, 
  col = "red"
)
points(
  sedData$flux_data$cenwave, 
  sedData$flux_data$flux, 
  pch = 21, 
  cex = 2.0,
  col = "black",
  bg = "red"
)
legend(
  x = "topleft",
  pch = c(16, NA, NA),
  lty = c(NA, 1, 1),
  lwd = c(NA, 2, 2),
  cex = 1.3,
  col = c("red", "black", "blue"),
  legend = c("Our data", "Fitted SED", "Contribution from stars")
)

magplot(NA, NA, type = "l",
        , ylim = c(1e-3,155), side = c(1,2,3,4), xlim = c(0,14), xlab = "Lookback Time (Gyr)",
        ylab = expression("Star Formation Rate [msol" ~ "yr"^{-1} ~ "Mpc"^{-3} ~ "]"), cex.lab = 1.0)
points(
  x = 0.0, 
  y = 50,
  pch = "\u2193", 
  cex = 5
)
text(
  0.7, 70, 
  "Present day", 
  cex = 2.0
)
points(
  x = 13.4, 
  y = 50,
  pch = "\u2193", 
  cex = 5
)
text(
  13.4, 70, 
  "Big Bang", 
  cex = 2.0
)
lines(
  sedData$age, 
  sedData$sfr,
  lwd = 3
)
dev.off()

