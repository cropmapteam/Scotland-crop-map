# PROJECT: Scot Crop Map #### 
# AREA: Kelso-Jedburgh 
# SATELLITE: Copernicus Sentinel-1 https://sentinel.esa.int/web/sentinel/ 
# IMAGES ACQUISITION DATE: Jan-Sept 2018 
# IMAGES PROCESSED BY: JNCC team http://jncc.defra.gov.uk 
# IMAGES CLEANEDUP BY: #ScotCropMap project team 
# AUTHOR: Beata Mielcarek 


# VERSION CONTROL #### 
# v1-16 - combined code with Exploratory Analysis 
# v17 - comparing models with different Train-Test ratios (ex: 70-30, 50-50, etc) 
# v18 - added Branding (colors, emojis, titles), updated dataset split variables 
# allCrops - code based on v18, model for ALL CROPS iteration 
# combinedCrops - code based on v18, model for COMBINED CROPS iteration (see COMBINE TGRS section)
# nTree300-mTry13 - code based on combinedCrops, nTree parameter change 
# Kelso_Random_Forest_nTree300_60-40split-mTry13 - best model 


# R ENVIRONMENT #### 
ls() 
rm(list=ls())
graphics.off()  # remove Plots 
cat("\014")     # remove Console text 


# R PACKAGES #### 
library(plyr)           # for re-naming columns 
library(dplyr)          # for splitting file into subsets 
library(ggplot2)        # for plots 
library(lattice)        # for multipanel plots 
library(grid)           # for displaying multiple graphs on same page 
library(gridExtra)      # for displaying multiple graphs on same page 
library(randomForest)   # for Random Forest modeling 
library(caret)          # for 
library(ggsn)           # for displaying multiple graphs on same page
library(TeachingDemos)  # for capturing commands and Console output in txt file


# ==> USER INPUT: SETUP output PDF and TXT files #### 

# create Plots output file (PDF) 
#pdf(file="Kelso_Random_Forest.pdf")

# create Commands output file (TXT) 
#txtStart(file="Kelso_Random_Forest.txt", commands=TRUE, results=TRUE, append=FALSE) 


# ==> USER INPUT: SETUP model parameters: Train/Test split, RF params #### 

# Train/Test dataset split 
# Model is trained in TRAIN dataset, an then tested on TEST dataset 
trainDataSplit <- 0.6
testDataSplit <- (1 - trainDataSplit) 

# ntree - Number of trees to grow. 
# mtry - Number of variables randomly sampled as candidates at each split. 
#   By default, randomForest() function sets m = sqrt(p) variables. 
# nodesize - Minimum size of terminal nodes. 
nTree = 300 
mTry = 7 
nodeSize = 1   # leave default=1 

# create small dataframe to collect initial parameters info 
# do NOT change anything here 
modelParams <- c(trainDataSplit*100, testDataSplit*100, nTree, mTry, nodeSize) 
names(modelParams) <- c("trainDataSplit", "testDataSplit", "nTree", "mTry", "nodeSize")
str(modelParams) 
modelParams 


# BRANDING TEMPLATES: Colors, Emojis, Titles #### 

# COLORS 
# ref: https://www.datanovia.com/en/blog/awesome-list-of-657-r-color-names/ 
# ref: https://www.datanovia.com/en/blog/top-r-color-palettes-to-know-for-great-data-visualization/ 

# R default color palette 
palette("default")
r_color <- colors()
head(r_color, 50)

# My brand colors palette 
myColors <- c("#6787b7", "#F4EDCA", "#CC79A7", "#0072B2", 
              "#C3D7A4", "#56B4E9", "#E69F00", "#52854C", 
              "saddlebrown", "#E7B800", "#999999", "darkseagreen", 
              "#4E84C4", "#FFDB6D", "#FF6666", "#00AFBB")

# set palette to myColors - will overwrite R default palette!! 
#myPalette <- palette(myColors) 

# show Colors in my Palette 
# ref: https://stackoverflow.com/questions/9563711/r-color-palettes-for-many-data-classes 
# pie(rep(1, 16), col = myColors, clockwise = TRUE, init.angle = 90, 
#    main = "#ScotCropMap project color palette") 


# PLOT TEXT (title, subtitle, bottom #hashtag) 
plot_subtitle <- labs(subtitle = "Kelso-Jedburgh area") 
plot_caption <- labs(caption = "#ScotCropMap") 
plot_theme <- theme(
  plot.title = element_text(color = "black", size = 12, face = "bold"),
  plot.subtitle = element_text(color = "deepskyblue3"),
  plot.caption = element_text(color = "darkgreen", face = "italic"))


# LABELLED DATASET - IMPORT AND CHECK #### 
# import Kelso LABELLED dataset (413 obs) 
allData <- read.csv("ground_truth_v5_2018_inspection_kelso_250619_zonal_stats_for_ml.csv") 
str(allData)


# UN-LABELLED DATASET - IMPORT AND CHECK #### 
noLabels <- read.csv("kelso_to_be_classified.csv") 
str(noLabels)

# delete LCGROUP, LCTYPE variables (not needed)
noLabels <- subset(noLabels, select = -c(LCGROUP, LCTYPE)) 
str(noLabels) 
# data.frame:	7616 obs. of  297 variables 


# REMOVE rows with any ZERO's in them 
# source: https://stackoverflow.com/questions/25203813/remove-rows-from-dataframe-that-contains-only-0-or-just-a-single-0 

noLabels <- noLabels[ !rowSums(noLabels[,colnames(noLabels)[(3:ncol(noLabels))]]==0)>=1, ] 
str(noLabels) 
# data.frame:	7595 obs. of  297 variables 


# REMOVE rows with NA's in them 
# source: https://stackoverflow.com/questions/4862178/remove-rows-with-all-or-some-nas-missing-values-in-data-frame 

# check for NA's  
colSums(is.na(noLabels)) 

# count number of NA's (not rows with NA's, just NA's) 
length(na.omit(noLabels))

# remove NA's 
noLabels <- noLabels[complete.cases(noLabels), ]  
str(noLabels) 


# LABELLED DATA CLEANUP: remove variables, remove crop types  #### 
set.seed(1234)

# Remove useless variables: 
# make a list of Range variables to delete 
deleteRangeVars <- c(grep(pattern="range", names(allData))) 
deleteRangeVars 

# create new dataset (keyData) without Range and other useless variables 
keyData <- subset(allData, select = -c(Id, FID_1, LCGROUP, deleteRangeVars)) 
str(keyData)
table(keyData$LCTYPE) 


# Remove fields with non-crops  
# FAWL = FALLOW no production 15 January to 15 July (11 rows) 
# NETR_NA = NEW WOODLAND AND FORESTRY (1 row) 
# RGR = Rough Grazing (4 rows) 
# WDG = OPEN WOODLAND (GRAZED) (8 rows) 

keyData <- keyData[(keyData$LCTYPE != "FALW"), ]
keyData <- keyData[(keyData$LCTYPE != "NETR_NA"), ]
keyData <- keyData[(keyData$LCTYPE != "RGR"), ]
keyData <- keyData[(keyData$LCTYPE != "WDG"), ]
table(keyData$LCTYPE) 
table(droplevels(keyData$LCTYPE)) 


# COMBINE and DELETE TGRS 1-5 CROPS #### 
#TGRS1     TGRS2     TGRS3     TGRS4     TGRS5   =  Total 
#  5        13         8         5         8     =    39 
  
# Recode LCTYPE for TGRS1,TGRS2,TGRS3,TGRS4,TGRS5 = TGRS1
keyData$LCTYPE[keyData$LCTYPE == "TGRS2"] <- "TGRS1"
keyData$LCTYPE[keyData$LCTYPE == "TGRS3"] <- "TGRS1"
keyData$LCTYPE[keyData$LCTYPE == "TGRS4"] <- "TGRS1"
keyData$LCTYPE[keyData$LCTYPE == "TGRS5"] <- "TGRS1"

# delete TGRS1 
keyData <- keyData[(keyData$LCTYPE != "TGRS1"), ] 
table(keyData$LCTYPE)
# list again ignoring classes with zero counts 
table(droplevels(keyData$LCTYPE))


# Remove rows where LCTYPE count < 4 ####  
# Needed to make sure there are enough observations after we split the 
# dataset into Test and Train subsets. 
keyData <- ddply(keyData, "LCTYPE", function(d) {if(nrow(d)>=4) d else NULL})
table(droplevels(keyData$LCTYPE)) 


# Reset factor levels after subsetting else the model fails 
# example: https://stackoverflow.com/questions/13495041/random-forests-in-r-empty-classes-in-y-and-argument-legth-0 
levels(keyData$LCTYPE);
keyData$LCTYPE <- factor(keyData$LCTYPE) 
levels(keyData$LCTYPE);


# Move LCTYPE variable to the end (ie, to be the last column) 
keyData <- select(keyData, -LCTYPE, everything())
str(keyData)


# TEST and TRAIN DATASETS SPLIT #### 

# Split allData into Train and Test subsets 
trainIndex <- sample(nrow(keyData), trainDataSplit*nrow(keyData)) 

# use "droplevel" to 
train <- droplevels(keyData[trainIndex, ]) 
test <- droplevels(keyData[-trainIndex, ]) 
str(train) 
str(test)

# check that there is at least one observatin for each LCTYPE in each dataset 
table(droplevels(train$LCTYPE))
table(droplevels(test$LCTYPE)) 

trainLCTYPE <- ggplot(train, aes(x=LCTYPE)) + 
        geom_bar(fill="darkseagreen") + 
        labs(title=paste("Land Cover Type (LCTYPE) - TRAIN dataset (", trainDataSplit, " data split)"), 
             x="Land Cover Type (LCTYPE)", 
             y="Number of farm fields") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme 


# Plot by LCTYPE (Land Cover Type) 
testLCTYPE <- ggplot(test, aes(x=LCTYPE)) + 
        geom_bar(fill="#6787b7") + 
        labs(title=paste("Land Cover Type (LCTYPE) - TEST dataset (", testDataSplit, " data split)"), 
             x="Land Cover Type (LCTYPE)", 
             y="Number of farm fields") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme 

grid.arrange(trainLCTYPE, testLCTYPE)


# RANDOM FOREST model - using ALL VARIABLES (198 vars) #### 
# Build and fit a RF model using all available variables 
# code source: Practical Data Science with R, Zumel N, Mount J, Manning Pub, 2014 
# code source: https://www.r-bloggers.com/how-to-implement-random-forests-in-r/ 
# good example https://github.com/saraswatmks/Machine-Learning-in-R/blob/master/RandomForest.R 
# good example https://www.guru99.com/r-random-forest-tutorial.html 

#number of all variables in the first model (minus 1 coz it's Y var.)
varsAll <- length(train[1,])-1   
varsAll 

modelAll <- randomForest(LCTYPE ~ ., data = train, mtry=mTry, ntree=nTree, 
                         nodesize=nodeSize, importance=T, do.trace=F)
modelAll 
summary(modelAll)
str(modelAll)

modelAll_CM_train_plot <- ggplot(train, aes(x=LCTYPE, y=modelAll$predicted, 
                                             color = LCTYPE)) + 
  geom_boxplot(size=1, show.legend = FALSE) + 
  geom_jitter(size=2, show.legend = FALSE) + 
  labs(title=paste("Random Forest Model (", varsAll, " vars): TRAIN data Confusion Matrix"), 
       x="Actual class", 
       y="Predicted class") + 
  coord_flip() + 
  plot_subtitle + 
  plot_caption + 
  plot_theme
modelAll_CM_train_plot 

# Predict Output  
modelAllPredicted <- predict(modelAll, test, type="class") 
summary(modelAllPredicted) 

# Confusion Matrix: classification accuracy (Actual VS Predicted) 
modelAll_CM <- table(test$LCTYPE, modelAllPredicted, dnn = c("Actual", "Predicted"))
modelAll_CM 
summary(modelAll_CM)
str(modelAll_CM)

modelAll_CM_test_plot <- ggplot(test, aes(x=LCTYPE, y=modelAllPredicted, 
                                           color = LCTYPE)) + 
  geom_jitter(size=2, show.legend = FALSE) + 
  labs(title=paste("Random Forest Model (", varsAll, " vars): TEST data Confusion Matrix"), 
             x="Actual class", 
             y="Predicted class") + 
  coord_flip() + 
  plot_subtitle + 
  plot_caption + 
  plot_theme
modelAll_CM_test_plot 

grid.arrange(modelAll_CM_train_plot, modelAll_CM_test_plot) 


# Model Accuracy 
modelAll_Acc <- mean(modelAllPredicted == test$LCTYPE) 
modelAll_Acc 


# Error Rate (err.rate) 
plot(modelAll$err.rate[,1], 
     ylab = "Error Rate (%)", 
     col = "deepskyblue3") 
title(main = paste("Random Forest Model Results: ERROR RATE (", varsAll, " vars)"), 
      sub = "#ScotCropMap", 
      cex.main= 1, font.main= 2, col.main= "black", 
      cex.sub=0.75, font.sub=3, col.sub="darkgreen") 


# https://dinsdalelab.sdsu.edu/metag.stats/code/randomforest.html 
# VARIABLE IMPORTANCE PLOT: tells you how important that variable is 
# in classifying the data. Look for a large break between variables 
# to decide how many important variables to choose. 

# DECREASE IN ACCURACY: The more the accuracy of the random forest decreases due to the EXCLUSION 
# of a single variable, the more important that variable is deemed. 
# The mean decrease in Gini coefficient is a measure of how each variable 
# contributes to the HOMOGENEITY of the nodes and leaves in the resulting 
# random forest. 0 = homogeneous, 1 = heterogeneous. 

# Extract info about Important Variables for the model 
varImp <- importance (modelAll) 

# Counts the number of variables 
# (used later to plot variables VS error rate for various models run) 
varsAll <- length(varImp[,1])   
varsAll 

# Plot Important Variables: Type 1 = mean decrease in accuracy 
varImpPlot(modelAll, type=1, n.var=varsAll, 
           col="deepskyblue3", 
           bty="o", 
           cex.main=1.2, cex.lab=1, cex.axis=1, 
           main = paste("RF Model (", varsAll, "vars): Mean Decrease in Accuracy"), 
           las=2) 

# Plot Important Variables: Type 2 = mean decrease in node impurity
varImpPlot(modelAll, type=2, n.var=varsAll, 
           col="deepskyblue3", 
           bty="o", 
           cex.main=1.2, cex.lab=1, cex.axis=1, 
           main = paste("RF Model (", varsAll, "vars): Mean Decrease in Node Impurity"), 
           las=2) 


# PREDICTIONS: ALL variables model #### 

modelAllPredictedNoLabels <- predict(modelAll, noLabels, type="class")
summary(modelAllPredictedNoLabels)
str(modelAllPredictedNoLabels)


# Plot Actuals - TRAINING data  
actuals_plot <- ggplot(train, aes(x=LCTYPE)) +
  geom_bar(fill="darkseagreen") + 
  labs(title="RF Model: ACTUAL Crop Types", 
       x="Crop Type", 
       y="No. fields") + 
  plot_subtitle + 
  plot_caption + 
  plot_theme
#actuals_plot

# Plot Predicted - modelAll NO-LABELS data (kelso_to_be_classified.csv)

modelAllPredictedNoLabels_plot <- ggplot(noLabels, aes(x=modelAllPredictedNoLabels)) + 
  geom_bar(fill="#6787b7") + 
  labs(title=paste("RF Model (", varsAll, " variables): \nPREDICTED Crop Types for NO_LABELS dataset"), 
       x="Crop Type", 
       y="No. fields") + 
  plot_subtitle + 
  plot_caption + 
  plot_theme
#modelAllPredictedNoLabels_plot

# Plot actuals and no-labels precdictions 
grid.arrange(actuals_plot, modelAllPredictedNoLabels_plot, nrow = 2, ncol = NULL) 


# create output file with Kelso classified crops 
write.csv(modelAllPredictedNoLabels, file = "Kelso_classified_crops_AllVariables.csv") 


# RANDOM FOREST model - using TOP variables (30 vars or something diff.) #### 
# ==> USER INPUT: numbner of variables to use in model ####

# enter number of variables for the model to use, 
#    based on varImpPlot (Mean Decrease in Accuracy) [1:30 or more or fewer]
varTopImp <- names(sort(varImp[,1], decreasing=T))[1:30] 
varTopImp 

# Count the number of variables 
# (used later to plot variables VS eror rate for various models run) 
varsTop <- length(varTopImp) 
varsTop 

# Build basic model 
modelTopVars <- randomForest(x=train[,varTopImp], y=train$LCTYPE, mtry=mTry, 
                             ntree=nTree, nodesize=nodeSize, importance=T, 
                             na.action = na.omit)
modelTopVars
summary(modelTopVars)
str(modelTopVars)

modelTopVars_CM_train_plot  <- ggplot(train, aes(x=LCTYPE, y=modelTopVars$predicted, 
  color = LCTYPE)) + 
  geom_boxplot(size=1, show.legend = FALSE) + 
  geom_jitter(size=2, show.legend = FALSE) + 
  labs(title=paste("Random Forest Model (", varsTop, "vars): TRAIN data Confusion Matrix"),  
       x="Actual class", 
       y="Predicted class") + 
  coord_flip() + 
  plot_subtitle + 
  plot_caption + 
  plot_theme
modelTopVars_CM_train_plot


# Predict Output  
modelTopVarsPredicted <- predict(modelTopVars,test)
summary(modelTopVarsPredicted)

# Confusion Matrix: classification accuracy (Actual VS Predicted) 
modelTopVars_CM <- table(test$LCTYPE, modelTopVarsPredicted, dnn = c("Actual", "Predicted"))
modelTopVars_CM 
summary(modelTopVars_CM)
str(modelTopVars_CM)

modelTopVars_CM_test_plot  <- ggplot(test, aes(x=LCTYPE, y=modelTopVarsPredicted, 
                                               color = LCTYPE)) + 
  geom_boxplot(size=1, show.legend = FALSE) + 
  geom_jitter(size=2, show.legend = FALSE) + 
  labs(title=paste("Random Forest Model (", varsTop, "vars): TEST data Confusion Matrix"),
             x="Actual class", 
             y="Predicted class") + 
  coord_flip() + 
  plot_subtitle + 
  plot_caption + 
  plot_theme
modelTopVars_CM_test_plot

grid.arrange(modelTopVars_CM_train_plot, modelTopVars_CM_test_plot)

# Model Accuracy 
modelTopVars_Acc <- mean(modelTopVarsPredicted == test$LCTYPE) 
modelTopVars_Acc 

# Error Rate (err.rate) 
plot(modelTopVars$err.rate[,1], 
     ylab = "Error Rate (%)", 
     col = "deepskyblue3") 
title(main = paste("Random Forest Model Results: ERROR RATE (", varsTop, " vars)"), 
      sub = "#ScotCropMap", 
      cex.main= 1,   font.main= 2, col.main= "black", 
      cex.sub=0.75, font.sub=3, col.sub="darkgreen") 


# Important Variables 
varImp <- importance (modelTopVars) 
#varImp

# Plot Important Variables: Type 1 = mean decrease in accuracy
varImpPlot(modelTopVars, type=1, n.var=varsTop, 
           cex.main=1.2, font.main= 2, col.main= "black", 
           cex.sub=0.75, font.sub=3, col.sub="darkgreen", 
           cex.lab=1, font.main= 2, col.main= "black", 
           cex.axis=1, font.main= 2, col.main= "black", 
           col="deepskyblue3", 
           bty="o",
           main = paste("RF Model (", varsTop, "vars): Mean Decrease in Accuracy"),
           sub = "#ScotCropMap", 
           las=2) 

# Plot Important Variables: Type 2 = mean decrease in node impurity
varImpPlot(modelTopVars, type=2, n.var=varsTop, 
           cex.main=1.2, font.main= 2, col.main= "black", 
           cex.sub=0.75, font.sub=3, col.sub="darkgreen", 
           cex.lab=1, font.main= 2, col.main= "black", 
           cex.axis=1, font.main= 2, col.main= "black", 
           col="deepskyblue3", 
           bty="o",
           main = paste("RF Model (", varsTop, "vars): Mean Decrease in Node Impurity"),
           sub = "#ScotCropMap", 
           las=2)


# PREDICTIONS: TOP variables model #### 

modelTopVarsPredictedNoLabels <- predict(modelTopVars, noLabels, type="class")
summary(modelTopVarsPredictedNoLabels)
str(modelTopVarsPredictedNoLabels)


# Plot Actuals - TRAINING data  
actuals_plot <- ggplot(train, aes(x=LCTYPE)) +
  geom_bar(fill="darkseagreen") + 
  labs(title="RF Model: ACTUAL Crop Types", 
       x="Crop Type", 
       y="No. fields") + 
  plot_subtitle + 
  plot_caption + 
  plot_theme
#actuals_plot


# Plot Predicted - model TopVariables NO-LABELS data (kelso_to_be_classified.csv)
modelTopVarsPredictedNoLabels_plot <- ggplot(noLabels, aes(x=modelTopVarsPredictedNoLabels)) + 
  geom_bar(fill="#6787b7") + 
  labs(title=paste("RF Model (", varsTop, " variables): \nPREDICTED Crop Types for NO_LABELS dataset"), 
       x="Crop Type", 
       y="No. fields") + 
  plot_subtitle + 
  plot_caption + 
  plot_theme
#modelTopVarsPredictedNoLabels_plot

# Plot actuals and no-labels precdictions 
grid.arrange(actuals_plot, modelTopVarsPredictedNoLabels_plot, nrow = 2, ncol = NULL) 


# create output file with Kelso classified crops 
write.csv(modelTopVarsPredictedNoLabels, file = "Kelso_classified_crops_TopVariables.csv") 




# RANDOM FOREST model - using LESS variables (13 vars or something diff.) #### 
# ==> USER INPUT: numbner of variables to use in model #### 

# enter number of variables for the model to use, 
#    based on varImpPlot (Mean Decrease in Accuracy) [1:13 or more or fewer]
varLessImp <- names(sort(varImp[,1], decreasing=T))[1:13] 
varLessImp 

# Counts the number of variables 
# (used later to plot variables VS error rate for various models run) 
varsLess <- length(varLessImp) 
varsLess 

# Build basic model 
modelLessVars <- randomForest(x=train[,varLessImp], y=train$LCTYPE, mtry=mTry, ntree=nTree, nodesize=nodeSize, importance=T)
modelLessVars
#summary(modelLessVars)
#str(modelLessVars)

modelLessVars_CM_train_plot  <- ggplot(train, aes(x=LCTYPE, y=modelLessVars$predicted, 
                                                  color = LCTYPE)) + 
  geom_boxplot(size=1, show.legend = FALSE) + 
  geom_jitter(size=2, show.legend = FALSE) + 
  labs(title=paste("Random Forest Model (", varsLess, "vars): TRAIN data Confusion Matrix"), 
       x="Actual class", 
       y="Predicted class") + 
  coord_flip() + 
  plot_subtitle + 
  plot_caption + 
  plot_theme
modelLessVars_CM_train_plot

# Predict Output  
modelLessVarsPredicted = predict(modelLessVars,test)
summary(modelLessVarsPredicted)

# Confusion Matrix: classification accuracy (Actual VS Predicted) 
modelLessVars_CM <- table(test$LCTYPE, modelLessVarsPredicted, dnn = c("Actual", "Predicted"))
modelLessVars_CM 
summary(modelLessVars_CM)
str(modelLessVars_CM)

modelLessVars_CM_test_plot  <- ggplot(test, aes(x=LCTYPE, y=modelLessVarsPredicted, 
                                                color = LCTYPE)) + 
  geom_boxplot(size=1, show.legend = FALSE) + 
  geom_jitter(size=2, show.legend = FALSE) + 
  labs(title=paste("Random Forest Model (", varsLess, "vars): TEST data Confusion Matrix"), 
       x="Actual class", 
       y="Predicted class") + 
  coord_flip() + 
  plot_subtitle + 
  plot_caption + 
  plot_theme
modelLessVars_CM_test_plot

grid.arrange(modelLessVars_CM_train_plot, modelLessVars_CM_test_plot) 


# Model Accuracy 
modelLessVars_Acc <- mean(modelLessVarsPredicted == test$LCTYPE) 
modelLessVars_Acc

# Error Rate (err.rate) 
plot(modelLessVars$err.rate[,1], 
     ylab = "Error Rate (%)", 
     col = "deepskyblue3") 
title(main = paste("Random Forest Model Results: ERROR RATE (", varsLess, " vars)"), 
      sub = "#ScotCropMap", 
      cex.main= 1,   font.main= 2, col.main= "black", 
      cex.sub=0.75, font.sub=3, col.sub="darkgreen") 


# Important Variables 
varImp <- importance (modelLessVars) 
#varImp

# Plot Important Variables: Type 1 = mean decrease in accuracy
varImpPlot(modelLessVars, type=1, n.var=varsLess, 
           cex.main=1.2, font.main= 2, col.main= "black", 
           cex.sub=0.75, font.sub=3, col.sub="darkgreen", 
           cex.lab=1, font.main= 2, col.main= "black", 
           cex.axis=1, font.main= 2, col.main= "black", 
           col="deepskyblue3", 
           bty="o",
           main = paste("RF Model (", varsLess, "vars): Mean Decrease in Accuracy"), 
           sub = "#ScotCropMap", 
           las=2)

# Plot Important Variables: Type 2 = mean decrease in node impurity
varImpPlot(modelLessVars, type=2, n.var=varsLess, 
           cex.main=1.2, font.main= 2, col.main= "black", 
           cex.sub=0.75, font.sub=3, col.sub="darkgreen", 
           cex.lab=1, font.main= 2, col.main= "black", 
           cex.axis=1, font.main= 2, col.main= "black", 
           col="deepskyblue3", 
           bty="o",
           main = paste("RF Model (", varsLess, "vars): Mean Decrease in Node Impurity"), 
           sub = "#ScotCropMap", 
           las=2) 



# PREDICTIONS: LESS variables model #### 

modelLessVarsPredictedNoLabels <- predict(modelLessVars, noLabels, type="class")
summary(modelLessVarsPredictedNoLabels)
str(modelLessVarsPredictedNoLabels)


# Plot Actuals - TRAINING data  
actuals_plot <- ggplot(train, aes(x=LCTYPE)) +
  geom_bar(fill="darkseagreen") + 
  labs(title="RF Model: ACTUAL Crop Types", 
       x="Crop Type", 
       y="No. fields") + 
  plot_subtitle + 
  plot_caption + 
  plot_theme
#actuals_plot

# Plot Predicted - modelLessVars NO-LABELS data (kelso_to_be_classified.csv)

modelLessVarsPredictedNoLabels_plot <- ggplot(noLabels, aes(x=modelLessVarsPredictedNoLabels)) + 
  geom_bar(fill="#6787b7") + 
  labs(title=paste("RF Model (", varsLess, " variables): \nPREDICTED Crop Types for NO_LABELS dataset"), 
       x="Crop Type", 
       y="No. fields") + 
  plot_subtitle + 
  plot_caption + 
  plot_theme

#modelLessVarsPredictedNoLabels_plot

# Plot actuals and no-labels precdictions 
grid.arrange(actuals_plot, modelLessVarsPredictedNoLabels_plot, nrow = 2, ncol = NULL) 


# create output file with Kelso classified crops 
write.csv(modelLessVarsPredictedNoLabels, file = "Kelso_classified_crops_LessVariables.csv") 


# RANDOM FOREST model - Plots: Actual VS Predicted #### 

# Plot Actuals Training data  
actuals_plot <- ggplot(train, aes(x=LCTYPE)) +
        geom_bar(fill="darkseagreen") + 
        labs(title="RF Model: ACTUAL Crop Types", 
             x="Crop Type", 
             y="No. fields") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme
#actuals_plot

# Plot Predicted - modelAll 
modelAll_plot <- ggplot(test, aes(x=modelAllPredicted)) +
        geom_bar(fill="#6787b7") + 
        labs(title=paste("RF Model (", varsAll, " variables ): PREDICTED Crop Types"), 
             x="Crop Type", 
             y="No. fields") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme
#modelAll_plot

# Plot Predicted - modelTopVars 
modelTopVars_plot <- ggplot(test, aes(x=modelTopVarsPredicted)) +
        geom_bar(fill="#6787b7") + 
        labs(title=paste("RF Model (", varsTop, " variables ): PREDICTED Crop Types"), 
             x="Crop Type", 
             y="No. fields") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme
#modelTopVars_plot 

# Plot Predicted - modelLessVarsPredicted
modelLessVars_plot <- ggplot(test, aes(x=modelLessVarsPredicted)) +
        geom_bar(fill="#6787b7") + 
        labs(title=paste("RF Model (", varsLess, " variables ): PREDICTED Crop Types"), 
             caption = "#ScotCropMap",              
             x="Crop Type", 
             y="No. fields") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme
#modelLessVars_plot

grid.arrange(actuals_plot, modelAll_plot, modelTopVars_plot, modelLessVars_plot, 
             nrow = 4, ncol = NULL) 


# RANDOM FOREST models - Summary Results #### 
# Collect and graph number of variables used VS model Error Rate 
# OOB (error rate) for a specific model where ntree=300 can be found 
# by using this command, example: modelAll$err.rate[300,1] 

# Models Results 
rfResults <- data.frame(
        # No. of variables in the model 
        Variables = c(varsAll, varsTop, varsLess), 
        # Error Rate for TRAIN model, rounded to 4 decimals, then * 100  
        Accuracy_train = c(((1-round((modelAll$err.rate[100,1]), 4))*100), 
                           ((1-round((modelTopVars$err.rate[100,1]), 4))*100), 
                           ((1-round((modelLessVars$err.rate[100,1]), 4))*100)), 
        # Accuracy for TEST model
        Accuracy_test = c((round((modelAll_Acc), 4)*100), 
                     (round((modelTopVars_Acc), 4)*100),
                     (round((modelLessVars_Acc), 4)*100))) 
# Print Models Parameters 
modelParams 

# Print Models Results 
rfResults 

# plot Model variables VS Accuracy (100-ErrorRate :) 
rfResults_AccuracyTrain_plot <- ggplot(rfResults, aes(x=Variables, y=(Accuracy_train))) + 
        geom_line(size=1, colour="darkseagreen") + 
        geom_point(size=2, colour="darkseagreen") + 
        geom_text(aes(label=(Accuracy_train)), hjust=0.5, vjust=1.6) + 
        ylim(0, 100) + 
        labs(title=paste("Random Forest Models Results: ACCURACY (TRAIN dataset - ", trainDataSplit*100, "%)"), 
             x="No. of variables in the model", 
             y="Accuracy (%)") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme


# plot Model variables VS Accuracy 
rfResults_AccuracyTest_plot  <- ggplot(rfResults, aes(x=Variables, y=(Accuracy_test))) + 
        geom_line(size=1, colour="#6787b7") + 
        geom_point(size=2, colour="#6787b7") + 
        geom_text(aes(label=(Accuracy_test)), hjust=0.5, vjust=1.6) + 
        ylim(0, 100) + 
        labs(title=paste("Random Forest Models Results: ACCURACY (TEST dataset - ", testDataSplit*100, "%)"), 
             x="No. of variables in the model", 
             y="Accuracy (%)") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme

grid.arrange(rfResults_AccuracyTrain_plot, rfResults_AccuracyTest_plot, 
             ncol = NULL) 


# END OF Random Forest Model BUILDING #### 
dev.list() 
txtStop()
dev.off()

# SESSION INFO #### 
sessionInfo() 
