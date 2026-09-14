# Build gc_cuttings and inst/extdata/cuttings_workbook.xlsx: one well of
# cuttings through four formations, every method a commercial cuttings-
# analysis deliverable carries (LECO + pyrolysis TOC, traditional pyrolysis,
# multi-ramp PAM pyrolysis, XRD bulk + clay speciation, XRF elements), laid
# out the way such workbooks are: a group row, an analyte row, a unit row, a
# QC row, then one sample per row with the *bottom* depth of each interval.
# Every number is synthetic.
set.seed(20260914)
devtools::load_all(".", quiet = TRUE)

bottom <- seq(6030, 7950, by = 30)                # 65 cuttings samples, 30 ft intervals
n <- length(bottom)
fm <- cut(bottom, c(0, 6500, 7100, 7600, Inf), labels = c("Upper Shale", "Target Shale", "Carbonate", "Lower Sand"))
zone <- ifelse(fm == "Target Shale", ifelse(bottom < 6800, "TS-A", "TS-B"), as.character(fm))
fi <- as.integer(fm)
noise <- function(sd) rnorm(n, 0, sd)
mid <- bottom - 15

# --- XRD bulk (wt%) ----------------------------------------------------------
quartz  <- c(28, 34, 8, 62)[fi] + noise(4)
kspar   <- c(4, 3, 1, 7)[fi] + noise(1)
plag    <- c(6, 5, 1, 9)[fi] + noise(1.2)
calcite <- c(12, 20, 70, 5)[fi] + noise(4)
dolomite <- c(4, 6, 12, 2)[fi] + noise(1.5)
siderite <- c(1, 1.5, 0.3, 0.5)[fi] + noise(0.4)
pyrite  <- c(2, 3.5, 0.5, 0.5)[fi] + noise(0.6)
clay    <- pmax(100 - (quartz + kspar + plag + calcite + dolomite + siderite + pyrite), 3)
bulk <- data.frame(QUARTZ = quartz, `K-SPAR` = kspar, PLAG = plag, CALCITE = calcite, DOLOMITE = dolomite, SIDERITE = siderite,
                   PYRITE = pyrite, `TOTAL CLAY` = clay, check.names = FALSE)
bulk[] <- lapply(bulk, function(v) pmax(v, 0))
bulk <- round(100 * bulk / rowSums(bulk), 1)
# clay speciation as % of total clay (sums to 100)
chl <- c(12, 8, 15, 10)[fi] + noise(3); kao <- c(10, 6, 5, 25)[fi] + noise(3); ill <- c(55, 50, 60, 45)[fi] + noise(5); ml <- pmax(100 - chl - kao - ill, 2)
spec <- data.frame(CHLORITE = chl, KAOLINITE = kao, `ILLITE/MICA` = ill, `MIX I/S` = ml, check.names = FALSE)
spec[] <- lapply(spec, function(v) pmax(v, 0)); spec <- round(100 * spec / rowSums(spec), 1)

# --- TOC + pyrolysis -----------------------------------------------------------
toc <- c(1.2, 4.5, 0.4, 0.3)[fi] + ifelse(fi == 2, 1.5 * sin((bottom - 6500) / 120), 0) + noise(0.3)
toc <- pmax(toc, 0.05)
toc_hawk <- toc * (1 + noise(0.04))
tmax <- 432 + 0.012 * (bottom - 6000) + noise(2.5)
hi <- ifelse(fi == 2, 420 - 2.5 * (tmax - 440), c(220, NA, 150, 90)[fi]) + noise(25)
s2 <- pmax(toc * hi / 100, 0.02)
s1 <- pmax(0.12 * s2 + 0.1 * toc + noise(0.08), 0.02)
s3 <- pmax(0.25 + 0.3 * (fi != 2) + noise(0.08), 0.03)
# --- PAM fractions (mg HC/g): light oils grow with maturity/free oil ---------
oil1 <- pmax(0.05 * s1 + noise(0.01), 0.005); oil2 <- pmax(0.35 * s1 + noise(0.03), 0.01)
oil3 <- pmax(0.45 * s1 + noise(0.04), 0.01); oil4 <- pmax(0.25 * s1 + 0.05 * s2 + noise(0.05), 0.01)
k1 <- pmax(s2 - 0.05 * s2, 0.02)
tmax_o <- function(base) round(base + 0.01 * (bottom - 6000) + noise(3))

# --- XRF elements (%) and traces (ppm) ----------------------------------------
si <- 0.467 * (0.99 * bulk$QUARTZ + 0.65 * (bulk$`K-SPAR` + bulk$PLAG) + 0.5 * bulk$`TOTAL CLAY`) + noise(0.5)
al <- 0.529 * (0.18 * (bulk$`K-SPAR` + bulk$PLAG) + 0.24 * bulk$`TOTAL CLAY`) + noise(0.3)
ca <- 0.715 * (0.56 * bulk$CALCITE + 0.30 * bulk$DOLOMITE) + noise(0.3)
mg <- 0.603 * (0.22 * bulk$DOLOMITE + 0.03 * bulk$`TOTAL CLAY`) + noise(0.1)
fe <- 0.70 * (0.5 * bulk$PYRITE + 0.6 * bulk$SIDERITE + 0.05 * bulk$`TOTAL CLAY`) + noise(0.15)
k  <- 0.83 * (0.16 * bulk$`K-SPAR` + 0.07 * bulk$`TOTAL CLAY`) + noise(0.1)
ti <- 0.6 * 0.02 * (bulk$`TOTAL CLAY` + bulk$`K-SPAR` + bulk$PLAG) + noise(0.02)
mn <- 0.02 + 0.004 * bulk$CALCITE + noise(0.01); p <- 0.03 + 0.01 * (fi == 2) + noise(0.01); s <- 0.53 * bulk$PYRITE + noise(0.1)
le <- pmax(100 - (si + al + ca + mg + fe + k + ti + mn + p + s) * 1.05, 5)
majors <- si + al + ca + mg + fe + k + ti + mn + p + s + le
egr <- 16 * k + 8 * (toc / 2) + 4 * (0.5 + 0.2 * (fi == 2)) + noise(5) + 30
tr <- function(base, rich = 0) round(pmax(base[fi] + rich * (fi == 2) * toc + noise(base[fi] * 0.15), 0))
xrf <- data.frame(EGR = round(egr), Si = round(si, 2), Ti = round(ti, 3), Al = round(al, 2), Fe = round(fe, 2), Mn = round(mn, 3),
                  Mg = round(mg, 2), Ca = round(ca, 2), K = round(k, 2), P = round(p, 3), S = round(s, 2),
                  `Light Elements` = round(le, 1), `MAJORS + LE` = round(majors, 1),
                  Cl = tr(c(300, 500, 200, 150)), V = tr(c(90, 150, 30, 40), 40), Cr = tr(c(70, 80, 20, 40)), Co = tr(c(12, 15, 5, 8)),
                  Ni = tr(c(35, 60, 15, 20), 15), Cu = tr(c(25, 45, 10, 12), 8), Zn = tr(c(70, 110, 25, 30), 20), As = tr(c(8, 15, 3, 4), 4),
                  Rb = tr(c(90, 80, 20, 60)), Sr = tr(c(150, 250, 600, 120)), Zr = tr(c(120, 100, 30, 220)), Mo = tr(c(2, 8, 1, 1), 6),
                  Pb = tr(c(15, 20, 5, 10)), Th = tr(c(9, 8, 2, 7)), U = tr(c(3, 6, 1, 2), 3), Ba = tr(c(400, 350, 150, 500)),
                  check.names = FALSE)
# censor a few traces the way a lab does
cens <- function(v, lod) ifelse(v < lod, paste0("<", lod), as.character(v))
xrf$Mo <- cens(xrf$Mo, 2); xrf$As <- cens(xrf$As, 3); xrf$U <- cens(xrf$U, 2); xrf$Co <- cens(xrf$Co, 5)

# --- assemble the sheet in the deliverable layout ------------------------------
groups <- c("SAMPLE INFO", rep("", 3), "TOC", "", "TRADITIONAL PYROLYSIS", rep("", 9), "PAM PYROLYSIS", rep("", 12),
            "XRD BULK MINERALOGY", rep("", 10), "XRD CLAY SPECIATION", rep("", 3), "XRF ELEMENTAL CONCENTRATIONS", rep("", 28))
names_r <- c("SAMPLE NUMBER", "SAMPLE DEPTH (BOTTOM)", "FORMATION", "ZONE", "LECO TOC", "HAWK TOC",
             "S1", "S2", "Tmax", "S3", "HI", "OI", "PI", "S1/TOC*100", "S2/S3", "KQ",
             "FID Oil-1", "Tmax FID Oil-1", "FID Oil-2", "Tmax FID Oil-2", "FID Oil-3", "Tmax FID Oil-3", "FID Oil-4", "Tmax FID Oil-4",
             "FID K-1", "Tmax FID K-1", "Oil3/Oil2", "Oil4/Oil3", "K1/Oil4",
             "QUARTZ", "K-SPAR", "PLAG", "CALCITE", "DOLOMITE", "SIDERITE", "PYRITE", "TOTAL CLAY", "QUARTZ + FELDSPARS", "TOTAL CARB", "BRITTLENESS INDEX",
             "CHLORITE", "KAOLINITE", "ILLITE/MICA", "MIX I/S", names(xrf))
units_r <- c("#", "FT", "", "X - X", "%", "%", "mg/g", "mg/g", "°C", "mg/g", "", "", "", "", "", "HI-OI",
             "C4-C5", "°C", "C6-C10", "°C", "C11-C19", "°C", "C20-C36", "°C", "Kerogen + C37+", "°C", "", "", "",
             rep("WT %", 10), "%", rep("WT %", 4), "API EQUIV", rep("%", 12), rep("ppm", 16))
stopifnot(length(groups) == length(names_r), length(names_r) == length(units_r))
HI <- round(100 * s2 / toc); OI <- round(100 * s3 / toc); PI <- round(s1 / (s1 + s2), 2)
qf <- bulk$QUARTZ + bulk$`K-SPAR` + bulk$PLAG; carb <- bulk$CALCITE + bulk$DOLOMITE + bulk$SIDERITE
bi <- round(100 * (1.5 * qf + 1.5 * carb) / (1.5 * qf + 1.5 * carb + 2 * bulk$`TOTAL CLAY`), 1)
rows <- data.frame(seq_len(n), bottom, as.character(fm), zone, round(toc, 2), round(toc_hawk, 2),
                   round(s1, 2), round(s2, 2), round(tmax), round(s3, 2), HI, OI, PI, round(100 * s1 / toc), round(s2 / s3, 1), HI - OI,
                   round(oil1, 3), tmax_o(300), round(oil2, 3), tmax_o(340), round(oil3, 3), tmax_o(380), round(oil4, 3), tmax_o(420),
                   round(k1, 2), tmax_o(455), round(oil3 / oil2, 2), round(oil4 / oil3, 2), round(k1 / oil4, 1),
                   bulk, round(qf, 1), round(carb, 1), bi, spec, xrf, check.names = FALSE, stringsAsFactors = FALSE)
sheet <- rbind(matrix("", 4, ncol(rows)),
               c("SYNTHETIC CUTTINGS ANALYSIS WORKBOOK (geochemR example; every value is invented)", rep("", ncol(rows) - 1)),
               c("TABULATED DATA", rep("", ncol(rows) - 1)),
               matrix("", 1, ncol(rows)),
               groups, names_r, units_r,
               c("PARAMETER SPECIFIC ERROR", rep("", ncol(rows) - 1)),
               as.matrix(format(rows, trim = TRUE, justify = "none", nsmall = 0)))
sheet[sheet == "NA"] <- ""
dir.create("inst/extdata", showWarnings = FALSE, recursive = TRUE)
writexl::write_xlsx(list(`TABULATED DATA` = as.data.frame(sheet, stringsAsFactors = FALSE)), "inst/extdata/cuttings_workbook.xlsx", col_names = FALSE)

gc_cuttings <- read_workbook("inst/extdata/cuttings_workbook.xlsx", hole_id = "EX-1", x = 512300, y = 3898200, z = 2140, crs = 26914,
                             lab = "Example Cuttings Lab", source = "synthetic example built by data-raw/make_cuttings.R")
print(gc_cuttings)
usethis::use_data(gc_cuttings, overwrite = TRUE)
