library(data.table)
library(dplyr)
library(ProSpect)
library(Highlander)
library(celestial)
library(Rfits)
library(Rwcs)
library(magicaxis)

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

filtout = list(
  filt_F090W_JWST,
  filt_F277W_JWST,
  filt_F444W_JWST
)

wavelength = c(
  cenwave$cenwave[cenwave$filter == "F090W_JWST"],
  cenwave$cenwave[cenwave$filter == "F277W_JWST"],
  cenwave$cenwave[cenwave$filter == "F444W_JWST"]
)
flux = c(
  dfObj$F090W_fluxt,
  dfObj$F277W_fluxt,
  dfObj$F444W_fluxt
) * 1e-6
fluxerr = sqrt( (c(
  dfObj$F090W_scaled_fluxt_err,
  dfObj$F277W_scaled_fluxt_err,
  dfObj$F444W_scaled_fluxt_err
) * 1e-6)^2 + (0.1*flux)^2 )

flux_data = data.frame(
  cenwave = wavelength,
  flux = flux,
  fluxerr = fluxerr,
  filter = c("F090W_JWST", "F277W_JWST", "F444W_JWST")
)

pro_data=list(
  flux=flux_data,
  arglist=list(
    massfunc=massfunc_snorm_trunc,
    Z=0.02,
   
    emission = T,
  
    photoz = T,
    z_genSF = 30,
    mtrunc = 2,

    ref="737",
    H0 = 70,
    OmegaM = 0.3
  ),
  speclib=BC03hr,
  Dale=NULL,
  filtout=filtout,
  SFH=SFHfunc,
  verbose=TRUE,
  AGN = NULL,
  Dale_M2L_func=NULL,
  parm.names=c(
    'z',
    'mSFR','mpeak','mskew', 'mperiod'
  ),
  mon.names=c("LP"),
  logged=c(
    T, 
    T, F, F, F
  ),
  intervals=list(
    lo = c(
      log10(0.0001), 
      -3, -2, -0.5, 0.3
    ),
    hi = c(
      log10(2.0), 
      4, 13.46, 1, 5.0
    )
  ),
  fit = 'LD',
  N=length(flux)
)

pro_data$flux$cenwave = flux_data$cenwave

startpoint = (pro_data$intervals$lo+pro_data$intervals$hi)/2
names(startpoint) = pro_data$parm.names
startpoint["z"] = log10(0.5)
startpoint["mpeak"] = 2

highout = Highlander(startpoint, pro_data, ProSpectSEDlike, 
                     Niters=c(100, 100),  NfinalMCMC = 100, 
                     lower=pro_data$intervals$lo, upper=pro_data$intervals$hi,
                     seed=666, optim_iters = 2)

pro_data$fit = 'check'
bestfit = ProSpectSEDlike(highout$par, Data=pro_data)
zBest = 10^bestfit$parm["z"]
bestfit$zBest = zBest

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

sedData = list(

  bestfit = bestfit, 
  
  flux_data = flux_data, 
  
  pixC = pixC
)
saveRDS(
  sedData, 
  "~/jpdemo/data.rds"
)

sedData = readRDS()

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
  sedData$bestfit$Data$filtout[[1]]$wave,
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
  bestfit$SEDout$FinalFlux, 
  col = "black", 
  lwd = 2
)
lines(
  bestfit$SEDout$StarsAtten$wave * (1+zBest),
  CGS2Jansky(
    convert_wave2freq(
      flux_wave = Lum2Flux(
        wave = bestfit$SEDout$StarsAtten$wave, 
        lum = bestfit$SEDout$StarsAtten$lum, 
        z = zBest, 
        ref = "737", OmegaL = 0.7, OmegaM = 0.3, H0 = 70)[,2],
      wave = bestfit$SEDout$StarsAtten$wave * (1+zBest))
    ),
  col = rgb(0,0,1,0.8), 
  lwd = 2
)
magerr(
  wavelength, 
  flux, 
  ylo = fluxerr, 
  length = 0.1, 
  col = "red"
)
points(
  wavelength,
  flux, 
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
  c(0, cosdistTravelTime(z = zBest, ref = "737") + (bestfit$SEDout$Stars$agevec/1e9)), 
  c(0, bestfit$SEDout$Stars$SFR), 
  lwd = 3
)
dev.off()

