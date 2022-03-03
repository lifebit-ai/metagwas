
df <- read.table("METAANALYSIS1.TBL", sep="\t", header = T)

sumstat_files <- list.files(pattern = "saige_results_.*\\.csv")
df2 <- do.call("rbind", lapply(sumstat_files, read.csv))
df2 <- df2[!duplicated(df2[,"SNPID"]), c("SNPID","CHR","POS")]

df <- merge(df, df2, by.x = "MarkerName", by.y = "SNPID")

source("plot_qqplot.R")

png("qqplot.png", width = 6, height = 6, units = "in", res=300)
plot_qqplot(df$P.value, ci=0.95)
dev.off()

source("plot_gwas_manhattan.R")

png("gwas_mahattan.png", width = 6, height = 3, units = "in", res=300)
plot_gwas_manahttan(df, p_cutoff = 5e-2, sumstats_cols=c("MarkerName","CHR","POS","P.value"))
dev.off()
