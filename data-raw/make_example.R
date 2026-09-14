# Build gc_example: a synthetic 12-hole grid with XRD, XRF and SRA results.
# Three units — sandstone over an organic-rich calcareous mudstone over a
# limestone — with a lateral TOC trend (richer to the east) so maps mean
# something, plus censored XRF trace elements and a few blanks.
set.seed(20260914)
devtools::load_all(".", quiet = TRUE)

holes <- expand.grid(col = 1:4, row = 1:3)
holes$hole_id <- sprintf("H%02d", seq_len(nrow(holes)))
holes$x <- 500000 + (holes$col - 1) * 400 + rnorm(nrow(holes), 0, 15)
holes$y <- 4200000 + (holes$row - 1) * 400 + rnorm(nrow(holes), 0, 15)
holes$z <- 1250 + 0.01 * (holes$x - 500000) + rnorm(nrow(holes), 0, 2)

samples <- do.call(rbind, lapply(seq_len(nrow(holes)), function(i) {
  tops <- seq(0, 140, by = 10) + round(runif(1, 0, 4))   # per-hole offset so intervals do not line up exactly
  data.frame(hole_id = holes$hole_id[i], x = holes$x[i], y = holes$y[i], z = holes$z[i],
             depth_top = tops, depth_base = tops + 10, stringsAsFactors = FALSE)
}))
samples$sample_id <- sprintf("%s-%03d", samples$hole_id, as.integer(samples$depth_top))
samples$sample_type <- ifelse(ave(seq_len(nrow(samples)), samples$hole_id, FUN = seq_along) %% 3 == 1, "core", "cuttings")  # every third interval cored
samples$date <- as.Date("2026-06-01") + as.integer(factor(samples$hole_id))
mid <- (samples$depth_top + samples$depth_base) / 2
east <- (samples$x - 500000) / 1200        # 0..1 west->east
# unit: 0 sandstone (<50 ft), 1 mudstone (50-110), 2 limestone (>110), with a gently dipping base
unit <- ifelse(mid < 50 - 8 * east, 0, ifelse(mid < 110 - 8 * east, 1, 2))

n <- nrow(samples)
noise <- function(sd) rnorm(n, 0, sd)
quartz  <- c(65, 25, 6)[unit + 1] + noise(4)
kspar   <- c(6, 3, 1)[unit + 1] + noise(1)
plag    <- c(8, 4, 1)[unit + 1] + noise(1)
calcite <- c(4, 28, 80)[unit + 1] + noise(4)
dolomite <- c(2, 6, 8)[unit + 1] + noise(1.5)
pyrite  <- c(0.5, 3, 0.5)[unit + 1] + noise(0.4)
illite  <- c(8, 18, 2)[unit + 1] + noise(2)
ml      <- c(3, 9, 1)[unit + 1] + noise(1.5)
kaol    <- c(2, 2, 0.3)[unit + 1] + noise(0.5)
chl     <- c(1.5, 2, 0.2)[unit + 1] + noise(0.4)
xrd <- data.frame(sample_id = samples$sample_id, Quartz = quartz, "K-Feldspar" = kspar, Plagioclase = plag, Calcite = calcite,
                  Dolomite = dolomite, Pyrite = pyrite, Illite = illite, "I/S" = ml, Kaolinite = kaol, Chlorite = chl, check.names = FALSE)
xrd[, -1] <- pmax(xrd[, -1], 0)
xrd[, -1] <- round(100 * xrd[, -1] / rowSums(xrd[, -1]), 1)
xrd$`Total Clay` <- round(rowSums(xrd[, c("Illite", "I/S", "Kaolinite", "Chlorite")]), 1)

# XRF: oxides in wt% consistent with the mineralogy, trace elements in ppm
sio2  <- 0.99 * quartz + 0.65 * (kspar + plag) + 0.5 * illite + 0.45 * (ml + kaol + chl) + noise(1)
al2o3 <- 0.18 * (kspar + plag) + 0.25 * illite + 0.2 * (ml + kaol + chl) + noise(0.5)
cao   <- 0.56 * calcite + 0.30 * dolomite + noise(0.5)
mgo   <- 0.22 * dolomite + 0.03 * (illite + chl) + noise(0.2)
k2o   <- 0.16 * kspar + 0.07 * illite + noise(0.15)
na2o  <- 0.11 * plag + noise(0.05)
fe2o3 <- 0.5 * pyrite + 0.05 * (illite + chl) + noise(0.2)
tio2  <- 0.02 * (illite + kspar + plag) + noise(0.03)
loi   <- 0.44 * calcite + 0.48 * dolomite + 0.1 * (illite + ml + kaol + chl) + noise(0.5)
zr    <- round(c(220, 120, 25)[unit + 1] + noise(20))
v     <- round(c(40, 160, 15)[unit + 1] + 60 * east * (unit == 1) + noise(15))
mo    <- round(c(1, 12, 1)[unit + 1] + 8 * east * (unit == 1) + noise(2), 1)
ni    <- round(c(15, 60, 8)[unit + 1] + noise(6))
xrf <- data.frame(sample_id = samples$sample_id, SiO2 = round(sio2, 2), Al2O3 = round(pmax(al2o3, 0), 2), CaO = round(pmax(cao, 0), 2),
                  MgO = round(pmax(mgo, 0), 2), K2O = round(pmax(k2o, 0), 2), Na2O = round(pmax(na2o, 0), 2), Fe2O3 = round(pmax(fe2o3, 0), 2),
                  TiO2 = round(pmax(tio2, 0), 3), LOI = round(pmax(loi, 0), 2),
                  Zr_ppm = as.character(pmax(zr, 0)), V_ppm = as.character(pmax(v, 0)), Mo_ppm = ifelse(mo < 2, "<2", as.character(pmax(mo, 0))),
                  Ni_ppm = ifelse(ni < 5, "<5", as.character(pmax(ni, 0))), check.names = FALSE)

# SRA: TOC rich in the mudstone, increasing east; Tmax increasing with depth (maturity)
toc  <- c(0.3, 2.5, 0.2)[unit + 1] + 2.0 * east * (unit == 1) + noise(0.25)
toc  <- pmax(toc, 0.05)
tmax <- 425 + 0.15 * mid + 6 * east + noise(3)
hi   <- ifelse(unit == 1, 520 - 3 * (tmax - 430) - 100 * east, 120) + noise(30)
s2   <- pmax(toc * hi / 100, 0.02)
s1   <- pmax(0.08 * s2 + 0.05 * toc + noise(0.05), 0.01)
s3   <- pmax(0.3 + 0.4 * (unit != 1) + noise(0.1), 0.05)
sra <- data.frame(sample_id = samples$sample_id, TOC = round(toc, 2), S1 = round(s1, 2), S2 = round(s2, 2), S3 = round(s3, 2),
                  Tmax = round(tmax), check.names = FALSE)
sra$Tmax[sra$TOC < 0.3] <- NA   # labs do not report Tmax on lean samples
sra <- sra[samples$sample_type == "core" | runif(n) < 0.6, ]  # not every cuttings sample was run

m <- dplyr::bind_rows(read_xrd(xrd, lab = "Example XRD Lab", source = "synthetic"),
                      read_xrf(xrf, lab = "Example XRF Lab", source = "synthetic"),
                      read_sra(sra, lab = "Example SRA Lab", source = "synthetic"))
gc_example <- gc_data(read_samples(samples), m, crs = 26914, depth_unit = "ft", sources = "synthetic example built by data-raw/make_example.R")
print(gc_example)
usethis::use_data(gc_example, overwrite = TRUE)
