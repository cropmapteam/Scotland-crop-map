###########################################################
# PROJECT: Scot Crop Map #### 
# AREA: Kelso-Jedburgh 
# SATELLITE: Copernicus Sentinel-1 
# ACQUISITION DATE: January 2018 
########################################################### 

# SETUP WORKING SPACE AND LOAD DATASET 
########################################################### 
# CLEAR EMVIRONMENT: PLOTS AND CONSOLE WINDOWS #### 
ls() 
rm(list=ls())
graphics.off()  # remove Plots 
cat("\014")     # remove Console text 

# OPEN PACKAGES #### 
library(car)       # for re-coding observations 
library(plyr)      # for re-naming columns 
library(ggplot2)   # for plots 
library(lattice)   # for multipanel plots 
library(grid)      # for displaying multiple graphs on same page 
library(gridExtra) # for displaying multiple graphs on same page 

# SET DIRECTORY 
#getwd()
#setwd("/Users/quantoid/Desktop/cropsMap/analysis")

# READ DATA FROM csv FILE #### 
allData<- read.csv("monthlyzonalstats18.csv") 


# VIEW CONTENTS OF IMPORTED DATASET #### 
str(allData)
summary(allData)

# RECODE LCGROUP variable from Factor to Numeric 
# Arable=1, Permanent Crops=2, Permanent Grassland=3 
allData$LCgroup <- ifelse(allData$LCGROUP == "Arable", 1, 
                   ifelse(allData$LCGROUP == "Permanent Crops", 2, 3))
names(allData) 
allData$LCgroup 


########################################################### 
# EXPLORATORY ANALYSIS 
########################################################### 

# SUMMARY TABLES 
# table by LCGROUP (Land Cover Group; there are 3 groups) 
table(allData$LCGROUP)

# table by LCTYPE (Land Cover Type; there are 33 types) 
table(allData$LCTYPE)

# table by LCGROUP by LCTYPE 
table(allData$LCGROUP, allData$LCTYPE) 


# PLOTS 
# by LCGROUP (Land Cover Group) 
a <- ggplot(allData, aes(x=LCGROUP)) + 
        geom_bar(fill="#6787b7") + 
        labs(title="Fields by Land Cover Group (LCGROUP)", 
             subtitle="",
             x="Land Cover Group (LCGROUP)", 
             y="Number of farm fields") 
a 

# by LCTYPE(Land Cover Type) 
b <- ggplot(allData, aes(x=LCTYPE)) + 
        geom_bar(fill="#ffba08") + 
        coord_flip() + 
        labs(title="Fields by Land Cover Type (LCTYPE)", 
             subtitle="",
             x="Land Cover Type (LCTYPE)", 
             y="Number of farm fields")
b 

# plot graphs "a" and "b" on the same page 
#grid.arrange(a,b)


# LCTYPEs and their crops  
# Arable Land by LCTYPE (which crops grow on which type of land) 
# subset on only Arable LCGroup 
arable <- subset(allData, LCgroup == 1)
# verify that only arable group is in this sebset 
table(arable$LCGROUP) 

permCrops <- subset(allData, LCgroup == 2)
table(permCrops$LCGROUP) 

permGrass <- subset(allData, LCgroup == 3)
table(permGrass$LCGROUP) 

# Arable fields and their crop types        
ggplot(arable, aes(x=LCTYPE)) + 
        geom_bar(fill="darkseagreen3") + 
        coord_flip() + 
        labs(title="Land Cover Type (LCTYPE) on _Arable_ fields", 
             subtitle="",
             x="Land Cover Type (LCTYPE)", 
             y="Number of farm fields")

# Permanent Crops fields and their crop types 
ggplot(permCrops, aes(x=LCTYPE)) + 
        geom_bar(fill="darkseagreen3") + 
        coord_flip() + 
        labs(title="Land Cover Type (LCTYPE) on _Permanent Crops_ fields", 
             subtitle="",
             x="Land Cover Type (LCTYPE)", 
             y="Number of farm fields")

# Permanent Grassland fields and their crop types 
ggplot(permGrass, aes(x=LCTYPE)) + 
        geom_bar(fill="darkseagreen3") + 
        coord_flip() + 
        labs(title="Land Cover Type (LCTYPE) on _Permanent Grassland_ fields", 
             subtitle="",
             x="Land Cover Type (LCTYPE)", 
             y="Number of farm fields")


# by AREA 
hist(allData$AREA, 
     main = "Fields by Area Size",
     xlab = "Area (in hectares??)", 
     ylab = "Number of farm fields", 
     xlim = c(0,35),
     ylim = c(0,200), 
     col = "thistle3")


########################################################### 
# SPLIT allData FILE into SUBSETS: mean, range, variance 
########################################################### 

# MEAN columns subset 
# create a list of Means columns 
meanColumns <- c("Id", "FID_1", "LCGROUP", "LCTYPE", "AREA", "GROSS_AREA", 
                 "X_1mean", "X_2mean", "X_3mean", "X_4mean", "X_5mean", 
                 "X_6mean", "X_7mean", "X_8mean", "X_9mean") 
# create new dataset using only Means columns 
meanData <- allData[meanColumns] 
# re-name dataset columns 
meanData <- rename(meanData, c("X_1mean"="1", "X_2mean"="2", "X_3mean"="3", 
                                     "X_4mean"="4", "X_5mean"="5", "X_6mean"="6", 
                                     "X_7mean"="7", "X_8mean"="8", "X_9mean"="9")) 

# check what new Means dataset looks like 
str(meanData)
head(meanData, 10)
summary(meanData[, c("AREA", "1", "2", "3", "4", "5", "6", "7", "8", "9")]) 

# plot Means subset 
plot(meanData[, c("1", "2", "3", "4", "5", "6", "7", "8", "9")], 
     main = "Farm Fields by Pixel MEAN from Jan(1) - Sept(9), 2018", 
     col = "#ffdeed")

#hist(meanData$"1",
#     main = "Farm Fields by Pixel MEAN from Jan-Sept 2018",
#     xlab = "", 
#     ylab = "Number of farm fields", 
#     xlim = c(-16,-5),
#     ylim = c(0,150), 
#     col = "#e3e9e5")


# RANGE columns subset 
rangeColumns <- c("Id", "FID_1", "LCGROUP", "LCTYPE", "AREA", "GROSS_AREA", 
                  "X_1range", "X_2range", "X_3range", "X_4range", "X_5range", 
                  "X_6range", "X_7range", "X_8range", "X_9range") 
rangeData <- allData[rangeColumns] 
rangeData <- rename(rangeData, c("X_1range"="1", "X_2range"="2", "X_3range"="3", 
                "X_4range"="4", "X_5range"="5", "X_6range"="6", 
                "X_7range"="7", "X_8range"="8", "X_9range"="9"))
str(rangeData)
summary(rangeData[, c("AREA", "1", "2", "3", "4", "5", "6", "7", "8", "9")]) 

# plot Range subset 
plot(rangeData[, c("1", "2", "3", "4", "5", "6", "7", "8", "9")], 
     main = "Farm Fields by Pixel RANGE from Jan(1) - Sept(9), 2018", 
     col = "#ffbedc")


# VARIANCE columns subset 
varColumns <- c("Id", "FID_1", "LCGROUP", "LCTYPE", "AREA", "GROSS_AREA", 
               "X_1variance", "X_2variance", "X_3variance", "X_4variance", 
               "X_5variance", "X_6variance", "X_7variance", "X_8variance", 
               "X_9variance") 
varData <- allData[varColumns] 
varData <- rename(varData, c("X_1variance"="1", "X_2variance"="2", "X_3variance"="3", 
                "X_4variance"="4", "X_5variance"="5", "X_6variance"="6", 
                "X_7variance"="7", "X_8variance"="8", "X_9variance"="9"))

str(varData) 
summary(varData[, c("AREA", "1", "2", "3", "4", "5", "6", "7", "8", "9")]) 

# plot Variance subset 
plot(varData[, c("1", "2", "3", "4", "5", "6", "7", "8", "9")], 
     main = "Farm Fields by Pixel VARIABLE from Jan(1) - Sept(9), 2018", 
     col = "#f9207f")
