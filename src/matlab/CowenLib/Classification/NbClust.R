#############################################
# Clustering data example
#
# Requires NbClust package: install.packages("NbClust")
#
# Cowen 2016
#
#############################################
library("NbClust")
input_text_file = "C:/Temp/R_input.txt"
output_text_file = "C:/Temp/R_output.txt"
output_text_file2 = "C:/Temp/R_output_2.txt"
res <- new.env() # create a structure (called env in R)
res$Best.partition <- -1 # Return this if there is an error.
res$All.index <- -1

# Read the data
D <- read.csv(input_text_file, header=FALSE)
# Using euclidean Ward.D and kl index works well with sample data.
try(res<-NbClust(D, distance = "euclidean", min.nc=3, max.nc=45, method = "ward.D", index = "kl")) # single is the default in matlab. I am not 100% which index to use. Using all takes a LONG time. This
#try(res<-NbClust(D, distance = "euclidean", min.nc=3, max.nc=45, method = "ward.D", index = "kl"))
#try(res<-NbClust(D, distance = "euclidean", min.nc=3, max.nc=45, method = "ward.D", index = "all")) # WAAAY TOO SLOW
# res$All.index
# res$Best.nc
# res$All.CriticalValues
# res$Best.partition

write.table(res$Best.partition,output_text_file,row.names = FALSE,col.names = FALSE)
write.table(res$All.index,output_text_file2,row.names = FALSE,col.names = TRUE)
