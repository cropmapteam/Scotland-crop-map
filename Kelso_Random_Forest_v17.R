# PROJECT: Scot Crop Map #### 
# AREA: Kelso-Jedburgh 
# SATELLITE: Copernicus Sentinel-1 
# IMAGES ACQUISITION DATE: Jan-Sept 2018 

# SETUP ENVIRONMENT & LOAD DATASET #### 
# CLEAR EMVIRONMENT: PLOTS AND CONSOLE WINDOWS 
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
library(randomForest)   # for Random Forest modeling 
library(caret)          # for 
library(ggsn)           # for displaying multiple graphs on same page

# SET DIRECTORY 
#getwd()
#setwd("/Users/quantoid/Desktop/cropsMap/analysis")

# READ DATA FROM csv FILE #### 
allData<- read.csv("kelso-monthlyzonal-2018-fixed.csv") 


# PLOTS TEMPLATE #### 

# not using these for now, to keep things clear while I'm learning 
#plot_geom_boxplot_thistle <- geom_boxplot(size=1, colour="thistle2") 
#plot_geom_jitter_thistle <- geom_jitter(size=2, colour="thistle3") 
#plot_geom_boxplot_class <- geom_boxplot(size=1, show.legend = FALSE) 
#plot_geom_jitter_class <- geom_jitter(size=2, show.legend = FALSE)

plot_subtitle <- labs(subtitle = "Kelso-Jedburgh area") 
plot_caption <- labs(caption = "#ScotCropMap") 
plot_theme <- theme(
        plot.title = element_text(color = "black", size = 12, face = "bold"),
        plot.subtitle = element_text(color = "deepskyblue3"),
        plot.caption = element_text(color = "darkgreen", face = "italic"))

# SAVE PLOTS to PDF file #### 
#pdf(file="Kelso_Random_Forest_70train-30test_split.pdf")

pdf(file="Kelso_Random_Forest_50train-50test_split.pdf")

# use dev.off() at the end of the fie to stop saving to pdf. 


### Start of Random Forest Model Building #### 

# CONTENTS OF IMPORTED DATASET #### 
str(allData)
summary(allData)

# RECODE LCGROUP variable from Factor to Numeric 
# Arable=1, Permanent Crops=2, Permanent Grassland=3 
allData$LCgroup <- ifelse(allData$LCGROUP == "Arable", 1, 
                   ifelse(allData$LCGROUP == "Permanent Crops", 2, 3))
names(allData) 
allData$LCgroup 

levels(allData$LCTYPE)
levels(allData$LCGROUP)


# DATA CLEANUP:  #### 
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
# Needed to make sure there are enough observations after we split the 
# dataset into Test and Train subsets. 
keyData <- ddply(keyData, "LCTYPE", function(d) {if(nrow(d)>=4) d else NULL})
table(droplevels(keyData$LCTYPE)) # don't show zero counts 

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
trainIndex <- sample(nrow(keyData), 0.5*nrow(keyData)) 
train <- keyData[trainIndex, ]
test <- keyData[-trainIndex, ]


# check that there is at least one observatin for each LCTYPE in each dataset 
table(droplevels(train$LCTYPE))
table(droplevels(test$LCTYPE)) 

trainLCTYPE <- ggplot(train, aes(x=LCTYPE)) + 
        geom_bar(fill="darkseagreen") + 
        #        coord_flip() + 
        labs(title="Land Cover Type (LCTYPE) - TRAIN dataset", 
             x="Land Cover Type (LCTYPE)", 
             y="Number of farm fields") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme 

# Plot by LCTYPE (Land Cover Type) 
testLCTYPE <- ggplot(test, aes(x=LCTYPE)) + 
        geom_bar(fill="#6787b7") + 
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
#   By default, randomForest() function sets m = sqrt(p) variables. 
# nodesize - Minimum size of terminal nodes. 
# importance - Should importance of predictors be assessed? 

# Parameters to use in all models below 
nTree = 100 
mTry = 7 
nodeSize = 1   # leave default=1 

# RANDOM FOREST model - using all variables (56 vars) #### 
modelAll <- randomForest(LCTYPE ~ ., data = train, mtry=mTry, ntree=nTree, 
                         nodesize=nodeSize, importance=T, do.trace=T)
modelAll 
#summary(modelAll)
#str(modelAll) 

modelAll_CM_train_plot  <- ggplot(train, aes(x=LCTYPE, y=modelAll$predicted, 
                                             color = LCTYPE)) + 
  geom_boxplot(size=1, show.legend = FALSE) + 
  geom_jitter(size=2, show.legend = FALSE) + 
  labs(title = "Random Forest Model (all vars): TRAIN data Confusion Matrix", 
       x="Actual class", 
       y="Predicted class") + 
  plot_subtitle + 
  plot_caption + 
  plot_theme
modelAll_CM_train_plot 

# Predict Output  
modelAllPredicted <- predict(modelAll,test, type="class") 
summary(modelAllPredicted) 

# Confusion Matrix: classification accuracy (Actual VS Predicted) 
modelAll_CM <- table(test$LCTYPE, modelAllPredicted, dnn = c("Actual", "Predicted"))
modelAll_CM 
#summary(modelAll_CM)
#str(modelAll_CM)

modelAll_CM_test_plot <- ggplot(test, aes(x=LCTYPE, y=modelAllPredicted, 
                                           color = LCTYPE)) + 
  geom_boxplot(size=1, show.legend = FALSE) + 
  geom_jitter(size=2, show.legend = FALSE) + 
  labs(title = "Random Forest Model (all vars): TEST data Confusion Matrix", 
             x="Actual class", 
             y="Predicted class") + 
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
title(main = "Random Forest Models Results: ERROR RATE (all vars)",
      sub = "#ScotCropMap", 
      cex.main= 1,   font.main= 2, col.main= "black", 
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
str(varImp)
#varImp 

# Counts the number of variables 
# (used later to plot variables VS error rate for various models run) 
varsAll <- length(varImp[,1])   
varsAll 

# Plot Important Variables: Type 1 = mean decrease in accuracy 
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
# Select top 25 most important variables  
varTopImp <- names(sort(varImp[,1], decreasing=T))[1:25] 
varTopImp 

# Count the number of variables 
# (used later to plot variables VS eror rate for various models run) 
varsTop <- length(varTopImp) 
varsTop 

# Build basic model 
modelTopVars <- randomForest(x=train[,varTopImp], y=train$LCTYPE, mtry=mTry, ntree=nTree, nodesize=nodeSize, importance=T)
modelTopVars
#summary(modelTopVars)
#str(modelTopVars)

modelTopVars_CM_train_plot  <- ggplot(train, aes(x=LCTYPE, y=modelTopVars$predicted, 
  color = LCTYPE)) + 
  geom_boxplot(size=1, show.legend = FALSE) + 
  geom_jitter(size=2, show.legend = FALSE) + 
  labs(title = "Random Forest Model (top 25 vars): TRAIN data Confusion Matrix", 
       x="Actual class", 
       y="Predicted class") + 
  plot_subtitle + 
  plot_caption + 
  plot_theme
modelTopVars_CM_train_plot


# Predict Output  
modelTopVarsPredicted = predict(modelTopVars,test)
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
        labs(title = "Random Forest Model (top 25 vars): TEST data Confusion Matrix", 
             x="Actual class", 
             y="Predicted class") + 
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
title(main = "Random Forest Models Results: ERROR RATE (top 25 vars)",
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
           col="deepskyblue2", 
           bty="o",
           main="RF Model (top 25 vars): Mean Decrease in Accuracy", 
           sub = "#ScotCropMap", 
           las=2) 

# Plot Important Variables: Type 2 = mean decrease in node impurity
varImpPlot(modelTopVars, type=2, n.var=varsTop, 
           cex.main=1.2, font.main= 2, col.main= "black", 
           cex.sub=0.75, font.sub=3, col.sub="darkgreen", 
           cex.lab=1, font.main= 2, col.main= "black", 
           cex.axis=1, font.main= 2, col.main= "black", 
           col="deepskyblue2", 
           bty="o",
           main="RF Model (top 25 vars): Mean Decrease in Node Impurity", 
           sub = "#ScotCropMap", 
           las=2)


# RANDOM FOREST model - using Top 15 variables #### 
# Select top 15 most important variables & count them 
varLessImp <- names(sort(varImp[,1], decreasing=T))[1:15] 
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
  labs(title = "Random Forest Model (top 15 vars): TRAIN data Confusion Matrix", 
       x="Actual class", 
       y="Predicted class") + 
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
  labs(title = "Random Forest Model (model 15 Vars): TEST data Confusion Matrix", 
       x="Actual class", 
       y="Predicted class") + 
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
title(main = "Random Forest Models Results: ERROR RATE (15 vars)",
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
           col="deepskyblue2", 
           bty="o",
           main="RF Model (top 15 vars): Mean Decrease in Accuracy", 
           sub = "#ScotCropMap", 
           las=2) 

# Plot Important Variables: Type 2 = mean decrease in node impurity
varImpPlot(modelLessVars, type=2, n.var=varsLess, 
           cex.main=1.2, font.main= 2, col.main= "black", 
           cex.sub=0.75, font.sub=3, col.sub="darkgreen", 
           cex.lab=1, font.main= 2, col.main= "black", 
           cex.axis=1, font.main= 2, col.main= "black", 
           col="deepskyblue2", 
           bty="o",
           main="RF Model (top 15 vars): Mean Decrease in Node Impurity", 
           sub = "#ScotCropMap", 
           las=2)

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

# Plot Predicted - modelAll 
modelAll_plot <- ggplot(test, aes(x=modelAllPredicted)) +
        geom_bar(fill="#6787b7") + 
        labs(title=paste("RF Model (", varsAll, " variables ): PREDICTED Crop Types"), 
             x="Crop Type", 
             y="No. fields") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme

# Plot Predicted - modelTopVars 
modelTopVars_plot <- ggplot(test, aes(x=modelTopVarsPredicted)) +
        geom_bar(fill="#6787b7") + 
        labs(title=paste("RF Model (", varsTop, " variables ): PREDICTED Crop Types"), 
             x="Crop Type", 
             y="No. fields") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme

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

grid.arrange(actuals_plot, modelAll_plot, modelTopVars_plot, modelLessVars_plot, 
             nrow = 4, ncol = NULL) 


# RANDOM FOREST models Results #### 
# Collect and graph number of variables used VS model Error Rate 
# OOB (error rate) for a specific model where ntree=100 can be found 
# by using this command, example: modelAll$err.rate[100,1]

rfResults <- data.frame(
        # No. of varisbles in the model 
        Variables = c(varsAll, varsTop, varsLess), 
        # Error Rate for TRAIN model, rounded to 4 decimals, then * 100  
        ErrorRate_train = c((round((modelAll$err.rate[100,1]), 4)*100), 
                            (round((modelTopVars$err.rate[100,1]), 4)*100), 
                            (round((modelLessVars$err.rate[100,1]), 4)*100)), 
        # Accuracy for TEST model
        Accuracy = c((round((1-modelAll_Acc), 4)*100), 
                     (round((1-modelTopVars_Acc), 4)*100),
                     (round((1-modelLessVars_Acc), 4)*100))) 
rfResults 

# plot Model variables VS Accuracy (100-ErrorRate :) 
rfResults_ErrorRate_plot <- ggplot(rfResults, aes(x=Variables, y=(100-ErrorRate_train))) + 
        geom_line(size=1, colour="darkseagreen") + 
        geom_point(size=2, colour="darkseagreen") + 
        geom_text(aes(label=(100-ErrorRate_train)), hjust=0.5, vjust=1.6) + 
        ylim(0, 100) + 
        labs(title="Random Forest Models Results: ACCURACY (TRAIN dataset)", 
             x="No. of variables in the model", 
             y="Accuracy (%)") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme

# plot Model variables VS Accuracy 
rfResults_Accuracy_plot  <- ggplot(rfResults, aes(x=Variables, y=(100-Accuracy))) + 
        geom_line(size=1, colour="#6787b7") + 
        geom_point(size=2, colour="#6787b7") + 
        geom_text(aes(label=(100-Accuracy)), hjust=0.5, vjust=1.6) + 
        ylim(0, 100) + 
        labs(title = "Random Forest Models Results: ACCURACY (TEST dataset)", 
             x="No. of variables in the model", 
             y="Accuracy (%)") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme

grid.arrange(rfResults_ErrorRate_plot, rfResults_Accuracy_plot, 
             ncol = NULL) 


# END OF Random Forest Model BUILDING 


### End of Random Forest Model Building #### 
# use dev.off() at the end of the fie to stop saving to pdf. 
dev.off()





# TRYING SOMETHING #### 
#source code: https://huahuahuahua.github.io/Machine_Learning/machine_learning_course_project.html 

pdf(file="RF_testing.pdf")


tc <- trainControl(method = "cv", 3)
modFitP <- train(LCTYPE ~., method = "rf", data = train, 
                 trControl = tc, importance=TRUE, ntree = 100) 
modFitP

# Random Forest 
# 
# 263 samples
# 55 predictor
# 13 classes: 'PC', 'PGRS', 'RGR', 'SB', 'SO', 'SPOT', 'TGRS1', 'WB', 'WBS', 'WO', 'WOSR', 'WPOT', 'WW' 
# 
# No pre-processing
# Resampling: Cross-Validated (3 fold) 
# Summary of sample sizes: 176, 172, 178 
# Resampling results across tuning parameters:
#   
#   mtry  Accuracy   Kappa    
# 2    0.7272308  0.6552499
# 28    0.7752531  0.7214179
# 55    0.7721191  0.7167653
# 
# Accuracy was used to select the optimal model using the largest value.
# The final value used for the model was mtry = 28.


# predictions 
prdval <- predict(modFitP, test)
confusionMatrix(test$LCTYPE, prdval)

# accuracy 
accuracy <- postResample(prdval, test$LCTYPE)
outsamperr <- 1 - as.numeric(confusionMatrix(test$LCTYPE, prdval)$overall[1])
print(accuracy); print(outsamperr)

# plot accuracy  
qplot(LCTYPE, prdval, data=test,  colour=LCTYPE, 
      geom = c("boxplot", "jitter"), 
      main = "Actual VS Predicted LCTYPE in TEST dataset", 
      xlab = "Actual LCTYPE", 
      ylab = "Predicted LCTYPE")

dev.off() 


# adding arrows #### 
# code http://www.sthda.com/english/wiki/ggplot2-add-straight-lines-to-a-plot-horizontal-vertical-and-regression-lines 
geom_segment(aes(x = 5, y = 30, xend = 3.5, yend = 25),
             arrow = arrow(length = unit(0.5, "cm")))

geom_segment(aes(x = "PC", y = "WB", xend = "WBS", yend = "WOSR"),
             arrow = arrow(length = unit(0.5, "cm"))) + 
  
geom_hline(yintercept=20, linetype="dashed", color = "red", size=1) + 
geom_abline() + 
geom_vline() + 
geom_segment() + 
geom_segment(aes(x = "PC", y = "WB", xend = "WBS", yend = "WOSR"),
               arrow = arrow(length = unit(0.5, "cm"))) +  

# other testing #### 
# Run algorithms using 10-fold cross validation 
control <- trainControl(method="cv", number=10)
metric <- "Accuracy"

# Build Models 
# a) linear algorithms
set.seed(7)
fit.lda <- train(Species~., data=dataset, method="lda", metric=metric, trControl=control)

# b) nonlinear algorithms
# CART
set.seed(7)
fit.cart <- train(Species~., data=dataset, method="rpart", metric=metric, trControl=control)
# kNN
set.seed(7)
fit.knn <- train(Species~., data=dataset, method="knn", metric=metric, trControl=control)

# c) advanced algorithms
# SVM
set.seed(7)
fit.svm <- train(Species~., data=dataset, method="svmRadial", metric=metric, trControl=control)
# Random Forest
set.seed(7)
fit.rf <- train(Species~., data=dataset, method="rf", metric=metric, trControl=control)

# summarize accuracy & select best model 
results <- resamples(list(lda=fit.lda, cart=fit.cart, knn=fit.knn, svm=fit.svm, rf=fit.rf))
summary(results) 

# compare accuracy of models
dotplot(results)

# summarize Best Model
print(fit.lda) 

# estimate skill of LDA on the validation dataset
predictions <- predict(fit.lda, validation)
confusionMatrix(predictions, validation$Species) 

