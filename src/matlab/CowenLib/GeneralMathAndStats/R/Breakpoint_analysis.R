#############################################
# Change point analysis for effort-reward data. 
#
# Requires strucchange package: install.packages("strucchange")
#
# Cowen 2011
#
#############################################
library("strucchange")
#library("rscproxy")
# INPUT: Format - a single col of numbers from which to perform the change point analysis.
input_text_file = "C:/Temp/R_input.txt"
# OUTPUT: Format - a single col of numbers. First number is the estimated change point.
output_text_file = "C:/Temp/R_output.txt"

#getwd() 
#setwd("C:/FolderShare/Src/matlab/Effort_Reward/SPike_Analyses")
# Read the data
input_data <- read.table(input_text_file, header=TRUE)
y <- input_data$DataFromML
yts = ts(y,1,length(y)) # May not need to do this.
ocus.yts <- efp(yts ~ 1, type = "OLS-CUSUM")
sc_out <- sctest(ocus.yts)

#plot(yts)
#hist(yts)


fs.yts <- Fstats(yts ~ 1)
#plot(fs.yts )
bp <- breakpoints(fs.yts )
#cc = c(bp)
#ccc$bp <= bp$breakpoints
#ccc$p <- sc_out$p.value

write.table(bp$breakpoints,output_text_file)
write.table(sc_out$p.value, output_text_file, append = TRUE)

#summary(bp)y
#lines(breakpoints(fs.yts ))
#ocus2.yts <- efp(yts ~ 1, type = "OLS-CUSUM")
#ybound.ocus  <-  boundary(ocus2.yts,  alpha  =  0.05) # This means NOTHING_- same for the nile data - totall different.
#threshold <- ybound.ocus[1]
#sctest(ocus2.yts)

