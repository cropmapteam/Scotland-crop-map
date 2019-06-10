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
library(plyr)           # for re-naming columns 
library(dplyr)          # for splitting file into 2 samples 
library(ggplot2)        # for plots 
library(lattice)        # for multipanel plots 
library(grid)           # for displaying multiple graphs on same page 
library(gridExtra)      # for displaying multiple graphs on same page 
library(randomForest)   #for Random Forest modeling 

# SET DIRECTORY 
#getwd()
#setwd("/Users/quantoid/Desktop/cropsMap/analysis")

# READ DATA FROM csv FILE #### 
allData<- read.csv("kelso-monthlyzonal-2018.csv") 

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

######## SUMMARY TABLES & PLOTS ###########################

# table by LCGROUP (Land Cover Group; there are 3 groups) 
table(allData$LCGROUP)

# table by LCTYPE (Land Cover Type; there are 33 types) 
table(allData$LCTYPE)

# table by LCGROUP by LCTYPE 
table(allData$LCGROUP, allData$LCTYPE) 


# plot by AREA 
hist(allData$AREA, 
     main = "Fields by Area Size",
     xlab = "Area (in hectares??)", 
     ylab = "Number of farm fields", 
     xlim = c(0,35),
     ylim = c(0,200), 
     col = "saddlebrown") 

# plot by LCGROUP (Land Cover Group) 
a <- ggplot(allData, aes(x=LCGROUP)) + 
        geom_bar(fill="#6787b7") + 
        labs(title="Fields by Land Cover Group (LCGROUP)", 
             subtitle="",
             x="Land Cover Group (LCGROUP)", 
             y="Number of farm fields") 
a 

# plot by LCTYPE(Land Cover Type) 
b <- ggplot(allData, aes(x=LCTYPE)) + 
        geom_bar(fill="#6787b7") + 
        coord_flip() + 
        labs(title="Fields by Land Cover Type (LCTYPE)", 
             subtitle="",
             x="Land Cover Type (LCTYPE)", 
             y="Number of farm fields")
b 

# plot a and b with sorted counts 
# ......... to do ......... 



# plot graphs "a", "b" on the same page
grid.arrange(a,b)


# by AREA size: Small, Med, Large 
smallArea = 10 
largeArea = 20 
smallField <- subset(allData, AREA <= smallArea)
largeField <- subset(allData, AREA > largeArea) 
medField <- subset(allData, (AREA > smallArea & AREA < largeArea)) 

# smallField  
# do not show levels with ZERO counts 
# table by LCGROUP  
table(smallField$LCGROUP) 
# table by LCTYPE 
table(droplevels(smallField$LCTYPE))
# table by LCGROUP by LCTYPE 
table(smallField$LCGROUP, droplevels(smallField$LCTYPE)) 

# LCTYPE growth in SMALL fields 
ggplot(smallField, aes(x=LCTYPE)) + 
        geom_bar(fill="darkslategray4") + 
        coord_flip() + 
        labs(title="Land Cover Type (LCTYPE) on SMALL fields", 
             subtitle="",
             x="Land Cover Type (LCTYPE)", 
             y="Number of SMALL farm fields")


# medField 
# do not show levels with ZERO counts 
# table by LCGROUP  
table(medField$LCGROUP) 
# table by LCTYPE 
table(droplevels(medField$LCTYPE))
# table by LCGROUP by LCTYPE 
table(medField$LCGROUP, droplevels(medField$LCTYPE)) 

# LCTYPE growth in MEDIUM size Fields 
ggplot(medField, aes(x=LCTYPE)) + 
        geom_bar(fill="darkslategray4") + 
        coord_flip() + 
        labs(title="Land Cover Type (LCTYPE) on MEDIUM size Fields", 
             subtitle="",
             x="Land Cover Type (LCTYPE)", 
             y="Number of MEDIUM size Fields")


# largeField 
# do not show levels with ZERO counts 
# table by LCGROUP  
table(largeField$LCGROUP) 
# table by LCTYPE 
table(droplevels(largeField$LCTYPE)) 
# table by LCGROUP by LCTYPE 
table(largeField$LCGROUP, droplevels(largeField$LCTYPE)) 

# LCTYPE growth in LARGE fields 
ggplot(largeField, aes(x=LCTYPE)) + 
        geom_bar(fill="darkslategray4") + 
        coord_flip() + 
        labs(title="Land Cover Type (LCTYPE) on LARGE fields", 
             subtitle="",
             x="Land Cover Type (LCTYPE)", 
             y="Number of LARGE farm fields")


# LCGROUP and their crops: Arable, Permanent Crops, Permanent Grassland 
# which crops grow on which type of land 

# Arable subset: LCGroup==1  
arable <- subset(allData, LCgroup == 1)
# verify that only arable group is in this sebset 
table(arable$LCGROUP) 
# table by LCTYPE by LCGROUP 
table((droplevels(arable$LCTYPE)), arable$LCGROUP) 
table(arable$LCGROUP, arable$LCTYPE) 

# Arable fields and their crop types 
ggplot(arable, aes(x=LCTYPE)) + 
        geom_bar(fill="#ffba08") + 
        coord_flip() + 
        labs(title="Land Cover Type (LCTYPE) on ARABLE fields", 
             subtitle="",
             x="Land Cover Type (LCTYPE)", 
             y="Number of farm fields")


# Permanent Crops subset: LCGroup==2 
permCrops <- subset(allData, LCgroup == 2) 
# verify that only arable group is in this sebset 
table(permCrops$LCGROUP) 
# table by LCTYPE by LCGROUP 
table((droplevels(permCrops$LCTYPE)), permCrops$LCGROUP) 

# Permanent Crops fields and their crop types 
ggplot(permCrops, aes(x=LCTYPE)) + 
        geom_bar(fill="#ffba08") + 
        coord_flip() + 
        labs(title="Land Cover Type (LCTYPE) on PERMANENT CROPS fields", 
             subtitle="",
             x="Land Cover Type (LCTYPE)", 
             y="Number of farm fields")


# Permanent Grassland subset: LCGroup==3 
permGrass <- subset(allData, LCgroup == 3)
# verify that only arable group is in this sebset  
table(permGrass$LCGROUP) 
# table by LCTYPE by LCGROUP 
table((droplevels(permGrass$LCTYPE)), permGrass$LCGROUP) 

# Permanent Grassland fields and their crop types 
ggplot(permGrass, aes(x=LCTYPE)) + 
        geom_bar(fill="#ffba08") + 
        coord_flip() + 
        labs(title="Land Cover Type (LCTYPE) on PERMANENT GRASSLAND fields", 
             subtitle="",
             x="Land Cover Type (LCTYPE)", 
             y="Number of farm fields")

#### IGNORE - DO NOT RUN THIS SECTION  ############################################
# To comment out o block of code: 
#        select your code then click Ctrl + shift + C 

# SPLIT allData FILE into subsets: MEAN, RANGE, VARIANCE 
# MEAN columns subset 
# create a list of Means columns 
# meanColumns <- c("Id", "FID_1", "LCGROUP", "LCTYPE", "AREA", "GROSS_AREA", 
#                  "X_1mean", "X_2mean", "X_3mean", "X_4mean", "X_5mean", 
#                  "X_6mean", "X_7mean", "X_8mean", "X_9mean") 
# create new dataset using only Means columns 
#meanData <- allData[meanColumns] 
# re-name dataset columns 
# meanData <- rename(meanData, c("X_1mean"="1", "X_2mean"="2", "X_3mean"="3", 
#                                "X_4mean"="4", "X_5mean"="5", "X_6mean"="6", 
#                                "X_7mean"="7", "X_8mean"="8", "X_9mean"="9")) 
# 
# # check what new Means dataset looks like 
# str(meanData)
# head(meanData, 10)
# summary(meanData[, c("AREA", "1", "2", "3", "4", "5", "6", "7", "8", "9")]) 
# 
# summary(meanData) 
# 
# 
# # plot Means subset 
# plot(meanData[, c("1", "2", "3", "4", "5", "6", "7", "8", "9")], 
#      main = "Farm Fields by Pixel MEAN from Jan(1) - Sept(9), 2018", 
#      col = "#ffdeed")
# 
# # RANGE columns subset 
# rangeColumns <- c("Id", "FID_1", "LCGROUP", "LCTYPE", "AREA", "GROSS_AREA", 
#                   "X_1range", "X_2range", "X_3range", "X_4range", "X_5range", 
#                   "X_6range", "X_7range", "X_8range", "X_9range") 
# rangeData <- allData[rangeColumns] 
# rangeData <- rename(rangeData, c("X_1range"="1", "X_2range"="2", "X_3range"="3", 
#                 "X_4range"="4", "X_5range"="5", "X_6range"="6", 
#                 "X_7range"="7", "X_8range"="8", "X_9range"="9"))
# str(rangeData)
# summary(rangeData[, c("AREA", "1", "2", "3", "4", "5", "6", "7", "8", "9")]) 
# 
# # plot Range subset 
# plot(rangeData[, c("1", "2", "3", "4", "5", "6", "7", "8", "9")], 
#      main = "Farm Fields by Pixel RANGE from Jan(1) - Sept(9), 2018", 
#      col = "#ffbedc")
# 
# 
# # VARIANCE columns subset 
# varColumns <- c("Id", "FID_1", "LCGROUP", "LCTYPE", "AREA", "GROSS_AREA", 
#                "X_1variance", "X_2variance", "X_3variance", "X_4variance", 
#                "X_5variance", "X_6variance", "X_7variance", "X_8variance", 
#                "X_9variance") 
# varData <- allData[varColumns] 
# varData <- rename(varData, c("X_1variance"="1", "X_2variance"="2", "X_3variance"="3", 
#                 "X_4variance"="4", "X_5variance"="5", "X_6variance"="6", 
#                 "X_7variance"="7", "X_8variance"="8", "X_9variance"="9"))
# 
# str(varData) 
# summary(varData[, c("AREA", "1", "2", "3", "4", "5", "6", "7", "8", "9")]) 
# 
# # plot Variance subset 
# plot(varData[, c("1", "2", "3", "4", "5", "6", "7", "8", "9")], 
#      main = "Farm Fields by Pixel VARIABLE from Jan(1) - Sept(9), 2018", 
#      col = "#f9207f")

 

# 
########################################################### 
# DATA CLEANUP for RANDOM FOREST model build 
########################################################### 
set.seed(1234)

# Remove useless variables: Id, FID_1, LCGROUP, GROSS_AREA, X_count, X_sum, X_mean 
keyData <- subset(allData, select = -c(Id, FID_1, LCGROUP, GROSS_AREA, X_count, X_sum, X_mean)) 
str(keyData)
table(keyData$LCTYPE) 

keyAll <- ggplot(keyData, aes(x=LCTYPE)) + 
        geom_bar(fill="darkorange") + 
#        coord_flip() + 
        labs(title="Land Cover Type (LCTYPE) - dataset: keyData", 
             x="Land Cover Type (LCTYPE)", 
             y="Number of farm fields")
keyAll

# Remove rows where LCTYPE = FALW (11 rows), NETR_NA (1 row), WDG (8 rows) 
keyData <- keyData[(keyData$LCTYPE != "FALW"), ]
keyData <- keyData[(keyData$LCTYPE != "NETR_NA"), ]
keyData <- keyData[(keyData$LCTYPE != "WDG"), ]
table(keyData$LCTYPE) 
table(droplevels(keyData$LCTYPE)) 

# Remove rows where LCTYPE count < 4. This came to 17 rows. 
# Needed to make sure there are enough observations after 
# we split the dataset into Test and Train subsets. 
keyData <- ddply(keyData, "LCTYPE", function(d) {if(nrow(d)>=4) d else NULL})
table(droplevels(keyData$LCTYPE)) # remove zero counts 

# Recode LCTYPE for TGRS1,TGRS2,TGRS3,TGRS4,TGRS5 = TGRS1 
# Must recode to an existing factor else the model doesn't recognise the new level. 
# Can overcome this with a bunch of code, but there is no real need for extra processing. 
keyData$LCTYPE[keyData$LCTYPE == "TGRS2"] <- "TGRS1"
keyData$LCTYPE[keyData$LCTYPE == "TGRS3"] <- "TGRS1"
keyData$LCTYPE[keyData$LCTYPE == "TGRS4"] <- "TGRS1"
keyData$LCTYPE[keyData$LCTYPE == "TGRS5"] <- "TGRS1"
table(droplevels(keyData$LCTYPE)) 

# Reset factor levels after subsetting 
# (else there are factors with 0 observations and the model fails) 
levels(keyData$LCTYPE);
keyData$LCTYPE <- factor(keyData$LCTYPE) 
levels(keyData$LCTYPE);

# Move LCTYPE variable to the end (ie, to be the last column) 
library(dplyr)
keyData <- select(keyData, -LCTYPE, everything())
str(keyData)
 

# Plot by LCTYPE (Land Cover Type) 
keyClean <- ggplot(keyData, aes(x=LCTYPE)) + 
        geom_bar(fill="darkorange3") + 
#        coord_flip() + 
        labs(title="Land Cover Type (LCTYPE) - dataset: keyData (clean)", 
             x="Land Cover Type (LCTYPE)", 
             y="Number of farm fields") 
keyClean

grid.arrange(keyAll, keyClean)


########################################################### 
# CREATE TEST and TRAIN samples for RANDOM FOREST model build 
########################################################### 

# Split allData into # Train (70%), Test (30%) subsets 
trainIndex <- sample(nrow(keyData), 0.7*nrow(keyData)) 
train <- keyData[trainIndex, ]
test <- keyData[-trainIndex, ]


# check that there is at least one observatin for each LCTYPE in each dataset 
table(droplevels(train$LCTYPE))
table(droplevels(test$LCTYPE)) 


########################################################### 
# RANDOM FOREST model - using all variables 
########################################################### 
# Build and fit a simple Random Forest model 
# Model can sample from all available variables 
# code source: Practical Data Science with R, Zumel N, Mount J, Manning Pub, 2014 
# code source: https://www.r-bloggers.com/how-to-implement-random-forests-in-r/ 
        
# Build basic model 
rfModel <- randomForest(LCTYPE ~ ., data = train, ntree=100, nodesize=1, importance=T)
rfModel
# summary(rfModel)

# Predict Output  
predicted <- predict(rfModel,test)
# predicted 

# Show model performance (Actual VS Predicted) 
confMatrix <- table(test$LCTYPE, predicted, dnn = c("Actual", "Predicted"))
confMatrix 

# Plot Actual 
actCrop <- ggplot(train, aes(x=LCTYPE)) +
        geom_bar(fill="deepskyblue1") + 
        labs(title="rfModel (allVars): ACTUAL Crop Types", 
             x="Crop Type", 
             y="Number of farm fields") 
actCrop 
     
# Plot Predicted 
predCrop <- ggplot(test, aes(x=predicted)) +
        geom_bar(fill="deepskyblue1") + 
        labs(title="rfModel (allVars): PREDICTED Crop Types", 
             x="Crop Type", 
             y="Number of farm fields") 
predCrop

grid.arrange(actCrop, predCrop)


# Look for the most Important Variables based on mean contribution 
# to the model predictive capability. Use these variables to build 
# a better model. 
varImp <- importance (rfModel) 
varImp[1:56, ]

importance(rfModel, type=1)

# Plot Important Variables: Type 1 = mean decrease in accuracy
varImpPlot(rfModel, type=1, 
           col="deepskyblue2", 
           bty="o", 
           cex.main=1.2, cex.lab=1, cex.axis=1, 
           main="rfModel (allVars): Mean Decrease in Accuracy", 
           las=2) 

# Plot Important Variables: Type 2 = mean decrease in node impurity
varImpPlot(rfModel, type=2, 
           col="deepskyblue3", 
           bty="o", 
           cex.main=1.2, cex.lab=1, cex.axis=1, 
           main="rfModel (allVars): Mean Decrease in Node Impurity",
           las=2) 


########################################################### 
# RANDOM FOREST model - using only Top 25 variables 
########################################################### 

# Select top 25 most important variables 
topVars <- names(sort(varImp[,1], decreasing=T))[1:25] 

# Build basic model 
topVarsModel <- randomForest(x=train[,topVars], y=train$LCTYPE, ntree=100, nodesize=1, importance=T)
topVarsModel
# summary(topVarsModel)

# Predict Output  
predicted = predict(topVarsModel,test)
# predicted 

# Show model performance (Actual VS Predicted)
confMatrix <- table(test$LCTYPE, predicted, dnn = c("Actual", "Predicted"))
confMatrix 

# Plot Actual 
actCrop <- ggplot(train, aes(x=LCTYPE)) +
        geom_bar(fill="darkseagreen3") + 
        labs(title="rfModel (top25Vars): ACTUAL Crop Types", 
             x="Crop Type", 
             y="Number of farm fields") 
actCrop 

# Plot Predicted 
predCrop <- ggplot(test, aes(x=predicted)) +
        geom_bar(fill="darkseagreen4") + 
        labs(title="rfModel (top25Vars): PREDICTED Crop Types", 
             x="Crop Type", 
             y="Number of farm fields") 
predCrop

grid.arrange(actCrop, predCrop)

# Important Variables 
varImp <- importance (topVarsModel) 
varImp[1:15, ]

# Plot Important Variables: Type 1 = mean decrease in accuracy
varImpPlot(topVarsModel, type=1, 
           col="darkseagreen3", 
           bty="o", 
           cex.main=1.2, cex.lab=1, cex.axis=1, 
           main="rfModel (top25Vars): Mean Decrease in Accuracy", 
           las=2) 

# Plot Important Variables: Type 2 = mean decrease in node impurity
varImpPlot(topVarsModel, type=2, 
           col="darkseagreen4", 
           bty="o", 
           cex.main=1.2, cex.lab=1, cex.axis=1, 
           main="rfModel (top25Vars): Mean Decrease in Node Impurity", 
           las=2)


#### TO DO ################################################### 
# Evaluation - ROC for multi-class classification ##
# https://stats.stackexchange.com/questions/2151/how-to-plot-roc-curves-in-multiclass-classification/2155#2155 
# https://link.springer.com/article/10.1023%2FA%3A1010920819831 
# https://bmcbioinformatics.biomedcentral.com/articles/10.1186/1471-2105-12-77 
# https://www.researchgate.net/publication/215991778_A_Simple_Generalisation_of_the_Area_Under_the_ROC_Curve_for_Multiple_Class_Classification_Problems 
# https://www.sciencedirect.com/science/article/abs/pii/S016786550500303X?via%3Dihub 
# https://www.datascienceblog.net/post/machine-learning/performance-measures-multi-class-problems/ 
# code source: https://stats.stackexchange.com/questions/71700/how-to-draw-roc-curve-with-three-response-variable/110550#110550 

library(pROC)
library(ROCR)
library(klaR)

# ..........to do .........  
data(iris)

lvls = levels(iris$Species)
testidx = which(1:length(iris[, 1]) %% 5 == 0) 
iris.train = iris[testidx, ]
iris.test = iris[-testidx, ]

aucs = c()
plot(x=NA, y=NA, xlim=c(0,1), ylim=c(0,1),
     ylab='True Positive Rate',
     xlab='False Positive Rate',
     bty='n')
for (type.id in 1:3) {
        type = as.factor(iris.train$Species == lvls[type.id])
        
        nbmodel = NaiveBayes(type ~ ., data=iris.train[, -5])
        nbprediction = predict(nbmodel, iris.test[,-5], type='raw')
        
        score = nbprediction$posterior[, 'TRUE']
        actual.class = iris.test$Species == lvls[type.id]
        
        pred = prediction(score, actual.class)
        nbperf = performance(pred, "tpr", "fpr")
        
        roc.x = unlist(nbperf@x.values)
        roc.y = unlist(nbperf@y.values)
        lines(roc.y ~ roc.x, col=type.id+1, lwd=2)
        
        nbauc = performance(pred, "auc")
        nbauc = unlist(slot(nbauc, "y.values"))
        aucs[type.id] = nbauc
}
lines(x=c(0,1), c(0,1))
mean(aucs) 
