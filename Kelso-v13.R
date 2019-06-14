# PROJECT: Scot Crop Map #### 
# AREA: Kelso-Jedburgh 
# SATELLITE: Copernicus Sentinel-1 
# ACQUISITION DATE: Jan-Sept 2018 


# SETUP ENVIRONMENT & LOAD DATASET #### 
# CLEAR EMVIRONMENT: PLOTS AND CONSOLE WINDOWS 
ls() 
rm(list=ls())
graphics.off()  # remove Plots 
cat("\014")     # remove Console text 

# OPEN PACKAGES 
library(plyr)           # for re-naming columns 
library(dplyr)          # for splitting file into 2 samples 
library(ggplot2)        # for plots 
library(lattice)        # for multipanel plots 
library(grid)          # for displaying multiple graphs on same page 
library(gridExtra)     # for displaying multiple graphs on same page 
library(randomForest)   # for Random Forest modeling 
library("ggsn")         # for displaying multiple graphs on same page

# SET DIRECTORY 
#getwd()
#setwd("/Users/quantoid/Desktop/cropsMap/analysis")

#### READ DATA FROM csv FILE 
allData<- read.csv("kelso-monthlyzonal-2018-fixed.csv") 



# PLOTS TEMPLATE #### 
plot_subtitle <- labs(subtitle = "Kelso-Jedburgh area") 
plot_caption <- labs(caption = "#ScotCropMap") 
plot_theme <- theme(
        plot.title = element_text(color = "black", size = 12, face = "bold"),
        plot.subtitle = element_text(color = "deepskyblue3"),
        plot.caption = element_text(color = "darkgreen", face = "italic"))


# EXPLORATORY ANALYSIS #### 
# VIEW CONTENTS OF IMPORTED DATASET 
str(allData)
summary(allData)

# RECODE LCGROUP variable from Factor to Numeric 
# Arable=1, Permanent Crops=2, Permanent Grassland=3 
allData$LCgroup <- ifelse(allData$LCGROUP == "Arable", 1, 
                   ifelse(allData$LCGROUP == "Permanent Crops", 2, 3))
names(allData) 
allData$LCgroup 

# SUMMARY TABLES & PLOTS 

# table by LCGROUP (Land Cover Group; there are 3 groups) 
table(allData$LCGROUP)

# table by LCTYPE (Land Cover Type; there are 33 types) 
table(allData$LCTYPE)

# table by LCGROUP by LCTYPE 
table(allData$LCGROUP, allData$LCTYPE) 

# plot by AREA 
# source: https://www.r-bloggers.com/how-to-make-a-histogram-with-ggplot2/ 
ggplot(allData, aes(x=AREA)) + 
        geom_histogram(breaks=seq(0, 30, by = 4), 
                       fill="saddlebrown", 
                       aes(fill=..count..)) + 
        labs(title="Fields by Area Size (AREA)", 
             x = "Area (in hectares??)", 
             y = "Number of farm fields") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme 

# Density plot by AREA 
# source: http://www.sthda.com/english/wiki/ggplot2-density-plot-quick-start-guide-r-software-and-data-visualization 
ggplot(allData, aes(x=AREA)) + 
        geom_histogram(aes(y=..density..), fill="saddlebrown", bins=30)+
        geom_density(alpha=.2, fill="#FF6666") + 
        labs(title="Fields by Area Size (AREA)", 
             x = "Area (in hectares??)", 
             y = "Number of farm fields") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme 

# plot by LCGROUP (Land Cover Group) 
ggplot(allData, aes(x=LCGROUP)) + 
        geom_bar(fill="#6787b7") + 
        labs(title="Fields by Land Cover Group (LCGROUP)",
             x="Land Cover Group (LCGROUP)", 
             y="Number of farm fields") +
        plot_subtitle + 
        plot_caption + 
        plot_theme 

# plot by LCTYPE(Land Cover Type) 
ggplot(allData, aes(x=LCTYPE)) + 
        geom_bar(fill="#6787b7") + 
        coord_flip() + 
        labs(title="Fields by Land Cover Type (LCTYPE)", 
             x="Land Cover Type (LCTYPE)", 
             y="Number of farm fields") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme 


# AREA size subsets: Small, Med, Large 
# define AREA subsets criteria 
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
             x="Land Cover Type (LCTYPE)", 
             y="Number of SMALL farm fields") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme 


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
             x="Land Cover Type (LCTYPE)", 
             y="Number of MEDIUM size Fields") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme 


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
             x="Land Cover Type (LCTYPE)", 
             y="Number of LARGE farm fields") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme


#### LCGROUP subsets: Arable, Permanent Crops, Permanent Grassland 
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
             x="Land Cover Type (LCTYPE)", 
             y="Number of farm fields") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme


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
             x="Land Cover Type (LCTYPE)", 
             y="Number of farm fields") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme


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
             x="Land Cover Type (LCTYPE)", 
             y="Number of farm fields") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme


# Remove no longer needed dataframes and variables 
# rm(arable, permCrops, permGrass, 
#   smallField, medField, largeField, 
#   smallArea, largeArea)


# DATA CLEANUP #### 
set.seed(1234)

# Remove useless variables: 
# Id, FID_1, LCGROUP, LCgroup, GROSS_AREA, X_count, X_sum, X_mean 
keyData <- subset(allData, select = -c(Id, FID_1, LCGROUP, LCgroup, GROSS_AREA, X_count, X_sum, X_mean)) 
str(keyData)
table(keyData$LCTYPE) 

# Remove rows where LCTYPE = FALW, NETR_NA, WDG  
# FAWL = FALLOW no production 15 January to 15 July (11 rows) 
# NETR_NA = NEW WOODLAND AND FORESTRY (1 row) 
# WDG = OPEN WOODLAND (GRAZED) (8 rows) 

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
keyData <- select(keyData, -LCTYPE, everything())
str(keyData)

# we are left with a dataset: 376 obs. of 56 variables 


# CREATE TEST and TRAIN samples #### 

# Split allData into # Train (70%), Test (30%) subsets 
# We get: Train with 263 obs, Test with 114 obs and 56 variables each. 
trainIndex <- sample(nrow(keyData), 0.7*nrow(keyData)) 
train <- keyData[trainIndex, ]
test <- keyData[-trainIndex, ]


# check that there is at least one observatin for each LCTYPE in each dataset 
table(droplevels(train$LCTYPE))
table(droplevels(test$LCTYPE)) 

trainLCTYPE <- ggplot(train, aes(x=LCTYPE)) + 
        geom_bar(fill="darkorange") + 
        #        coord_flip() + 
        labs(title="Land Cover Type (LCTYPE) - TRAIN dataset", 
             x="Land Cover Type (LCTYPE)", 
             y="Number of farm fields") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme 

# Plot by LCTYPE (Land Cover Type) 
testLCTYPE <- ggplot(test, aes(x=LCTYPE)) + 
        geom_bar(fill="darkorange3") + 
        #        coord_flip() + 
        labs(title="Land Cover Type (LCTYPE) - TEST dataset", 
             x="Land Cover Type (LCTYPE)", 
             y="Number of farm fields") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme 

grid.arrange(trainLCTYPE, testLCTYPE)


# RANDOM FOREST model - setup #### 
# Build and fit a simple Random Forest model 
# Model samples from all available variables 
# code source: Practical Data Science with R, Zumel N, Mount J, Manning Pub, 2014 
# code source: https://www.r-bloggers.com/how-to-implement-random-forests-in-r/ 
# good example https://github.com/saraswatmks/Machine-Learning-in-R/blob/master/RandomForest.R 
# good example https://www.guru99.com/r-random-forest-tutorial.html 


# Build basic FR model 
# ntree - Number of trees to grow. 
# mtry - Number of variables randomly sampled as candidates at each split. 
# nodesize - Minimum size of terminal nodes. 
# importance - Should importance of predictors be assessed? 

# Parameters to use in all models below 
nTree = 100 
mTry = 7 
nodeSize = 1 

# RANDOM FOREST model - using all variables (56 vars) #### 
modelAll <- randomForest(LCTYPE ~ ., data = train, mtry=mTry, ntree=nTree, 
                         nodesize=nodeSize, importance=T, do.trace=T)
modelAll 
str(modelAll)

# Predict Output  
modelAllPredicted <- predict(modelAll,test, type="class") 

# Confusion Matrix: classification accuracy (Actual VS Predicted) 
modelAll_CM <- confusionMatrix(test$LCTYPE, modelAllPredicted) 
modelAll_CM 

confusionMatrix_plot  <- ggplot(test, aes(x=LCTYPE, y=modelAllPredicted)) + 
        geom_boxplot(size=1, colour="deepskyblue3") + 
        geom_jitter(size=2, colour="deepskyblue1") + 
        labs(title = "Random Forest Models Results: Confusion Matrix", 
             x="Actual class", 
             y="Predicted class") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme
confusionMatrix_plot 

# Model Accuracy 
modelAll_Acc <- mean(modelAllPredicted == test$LCTYPE) 
modelAll_Acc 

# Error Rate (err.rate) 
plot(modelAll$err.rate[,1], 
     main = "Random Forest Models Results: ERROR RATE (modelAll)",
     sub = "Kelso-Jedburgh area", 
#     caption = "#ScotCropMap", 
     ylab = "Error Rate (%)", 
     col = "deepskyblue3") 


# https://dinsdalelab.sdsu.edu/metag.stats/code/randomforest.html 
# VARIABLE IMPORTANCE PLOT: tells you how important that variable is 
# in classifying the data. Look for a large break between variables 
# to decide how many important variables to choose. 

# DECREASE IN ACCURACY: The more the accuracy of the random forest decreases due to the EXCLUSION 
# of a single variable, the more important that variable is deemed. 
# The mean decrease in Gini coefficient is a measure of how each variable 
# contributes to the HOMOGENEITY of the nodes and leaves in the resulting 
# random forest. 0 = homogeneous, 1 = heterogeneous. 

# Plot Important Variables: Type 1 = mean decrease in accuracy 
varImp <- importance (modelAll) 
#varImp 

# counts the number of variables 
varsAll <- length(varImp[,1])   
varsAll 

varImpPlot(modelAll, type=1, n.var=varsAll, 
           col="deepskyblue1", 
           bty="o", 
           cex.main=1.2, cex.lab=1, cex.axis=1, 
           main="RF Model (all vars): Mean Decrease in Accuracy", 
           las=2) 

# Plot Important Variables: Type 2 = mean decrease in node impurity
varImpPlot(modelAll, type=2, n.var=varsAll, 
           col="deepskyblue1", 
           bty="o", 
           cex.main=1.2, cex.lab=1, cex.axis=1, 
           main="RF Model (all vars): Mean Decrease in Node Impurity",
           las=2) 




# RANDOM FOREST model - using Top 25 variables #### 
# Select top 25 most important variables & count them 
topVars <- names(sort(varImp[,1], decreasing=T))[1:25] 
topVars 
varsTop <- length(topVars) 
varsTop 

# Build basic model 
modelTopVars <- randomForest(x=train[,topVars], y=train$LCTYPE, mtry=mTry, ntree=nTree, nodesize=nodeSize, importance=T)
modelTopVars

# Predict Output  
modelTopVarsPredicted = predict(modelTopVars,test)

# Confusion Matrix: classification accuracy (Actual VS Predicted) 
modelTopVars_CM <- table(test$LCTYPE, modelTopVarsPredicted, dnn = c("Actual", "Predicted"))
modelTopVars_CM 

# Model Accuracy 
modelTopVars_Acc <- mean(modelTopVarsPredicted == test$LCTYPE) 
modelTopVars_Acc 

# Important Variables 
varImp <- importance (modelTopVars) 
#varImp

# Plot Important Variables: Type 1 = mean decrease in accuracy
varImpPlot(modelTopVars, type=1, n.var=varsTop, 
           col="deepskyblue2", 
           bty="o", 
           cex.main=1.2, cex.lab=1, cex.axis=1, 
           main="RF Model (top 25 vars): Mean Decrease in Accuracy", 
           las=2) 

# Plot Important Variables: Type 2 = mean decrease in node impurity
varImpPlot(modelTopVars, type=2, n.var=varsTop, 
           col="deepskyblue2", 
           bty="o", 
           cex.main=1.2, cex.lab=1, cex.axis=1, 
           main="RF Model (top 25 vars): Mean Decrease in Node Impurity", 
           las=2)

 
# RANDOM FOREST model - using Top 15 variables #### 
# Select top 15 most important variables & count them 
lessVars <- names(sort(varImp[,1], decreasing=T))[1:15] 
lessVars 
varsLess <- length(lessVars) 
varsLess 

# Build basic model 
modelLessVars <- randomForest(x=train[,lessVars], y=train$LCTYPE, mtry=mTry, ntree=nTree, nodesize=nodeSize, importance=T)
modelLessVars

# Predict Output  
modelLessVarsPredicted = predict(modelLessVars,test)

# Confusion Matrix: classification accuracy (Actual VS Predicted) 
modelLessVars_CM <- table(test$LCTYPE, modelLessVarsPredicted, dnn = c("Actual", "Predicted"))
modelLessVars_CM 

# Model Accuracy 
modelLessVars_Acc <- mean(modelLessVarsPredicted == test$LCTYPE) 
modelLessVars_Acc

# Important Variables 
varImp <- importance (modelLessVars) 
#varImp

# Plot Important Variables: Type 1 = mean decrease in accuracy
varImpPlot(modelLessVars, type=1, n.var=varsLess, 
           col="deepskyblue3", 
           bty="o", 
           cex.main=1.2, cex.lab=1, cex.axis=1, 
           main="RF Model (top 15 vars): Mean Decrease in Accuracy", 
           las=2) 

# Plot Important Variables: Type 2 = mean decrease in node impurity
varImpPlot(modelLessVars, type=2, n.var=varsLess, 
           col="deepskyblue3", 
           bty="o", 
           cex.main=1.2, cex.lab=1, cex.axis=1, 
           main="RF Model (top 15 vars): Mean Decrease in Node Impurity", 
           las=2)


# RANDOM FOREST model - Plots #### 

# Plot Actuals Training data  
actuals_plot <- ggplot(train, aes(x=LCTYPE)) +
        geom_bar(fill="darkseagreen2") + 
        labs(title="RF Model: ACTUAL Crop Types", 
             x="Crop Type", 
             y="No. fields") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme

# Plot Predicted - modelAll 
modelAll_plot <- ggplot(test, aes(x=modelAllPredicted)) +
        geom_bar(fill="deepskyblue1") + 
        labs(title=paste("RF Model (", varsAll, " variables ): PREDICTED Crop Types"), 
             x="Crop Type", 
             y="No. fields") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme

# Plot Predicted - modelTopVars 
modelTopVars_plot <- ggplot(test, aes(x=modelTopVarsPredicted)) +
        geom_bar(fill="deepskyblue2") + 
        labs(title=paste("RF Model (", varsTop, " variables ): PREDICTED Crop Types"), 
             x="Crop Type", 
             y="No. fields") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme

# Plot Predicted - modelLessVarsPredicted
modelLessVars_plot <- ggplot(test, aes(x=modelLessVarsPredicted)) +
        geom_bar(fill="deepskyblue3") + 
        labs(title=paste("RF Model (", varsLess, " variables ): PREDICTED Crop Types"), 
             caption = "#ScotCropMap",              
             x="Crop Type", 
             y="No. fields") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme

grid.arrange(actuals_plot, modelAll_plot, modelTopVars_plot, modelLessVars_plot, 
             nrow = 4, ncol = NULL) 


# RANDOM FOREST models Results #### 
# Collect and graph number of variables used VS model Error Rate 
# OOB (error rate) for a specific model where ntree=100 can be found 
# by using this command, example: modelAll$err.rate[100,1]

rfResults <- data.frame(
        # No. of varisbles in the model 
        Variables = c(varsAll, varsTop, varsLess), 
        # Accuracy 
        Accuracy = c((round((modelAll_Acc), 4)*100), 
                     (round((modelTopVars_Acc), 4)*100),
                     (round((modelLessVars_Acc), 4)*100)), 
        # Error Rate of the model, rounded to 4 decimals, then * 100  
        ErrorRate = c((round((modelAll$err.rate[100,1]), 4)*100), 
                      (round((modelTopVars$err.rate[100,1]), 4)*100), 
                      (round((modelLessVars$err.rate[100,1]), 4)*100))) 
rfResults 

# plot Model variables VS Error rate 
rfResults_ErrorRate_plot <- ggplot(rfResults, aes(x=Variables, y=ErrorRate)) + 
        geom_line(size=1, colour="deepskyblue3") + 
        geom_point(size=2, colour="deepskyblue3") + 
        geom_text(aes(label=ErrorRate), hjust=0.5, vjust=1.6) + 
        ylim(20, 32) + 
        labs(title="Random Forest Models Results: ERROR RATE", 
             x="No. of variables in the model", 
             y="Error Rate (%)") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme

# plot Model variables VS Accuracy 
rfResults_Accuracy_plot  <- ggplot(rfResults, aes(x=Variables, y=Accuracy)) + 
        geom_line(size=1, colour="deepskyblue3") + 
        geom_point(size=2, colour="deepskyblue3") + 
        geom_text(aes(label=Accuracy), hjust=0.5, vjust=1.6) + 
        ylim(60, 70) + 
        labs(title = "Random Forest Models Results: ACCURACY", 
             x="No. of variables in the model", 
             y="Accuracy (%)") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme

grid.arrange(rfResults_ErrorRate_plot, rfResults_Accuracy_plot, 
             ncol = NULL) 


# END OF Random Forest Model BUILDING 


##### different RF method ################### 
# Run the model
library(caret)
library(e1071) 

trControl <- trainControl(method = "cv",
                          number = 10,
                          search = "grid")

rf_default <- train(LCTYPE~., data = train,
                    method = "rf",
                    metric = "Accuracy",
                    trControl = trControl)
# Print the results
print(rf_default)


