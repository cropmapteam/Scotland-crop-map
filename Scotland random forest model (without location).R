# SCOTLAND DATA FOR 2019 #
# This code is for creating a random forest model for Scotland data (2019) WITHOUT a location variable

# R PACKAGES #### 
library(plyr)           # for re-naming columns 
library(dplyr)          # for splitting file into subsets 
library(ggplot2)        # for plots 
library(lattice)        # for multipanel plots 
library(grid)           # for displaying multiple graphs on same page 
library(gridExtra)      # for displaying multiple graphs on same page 
library(randomForest)   # for Random Forest modeling 
library(caret)  
library(reshape2)
library(data.table)


# create a pdf file of plot output
pdf(file="no_location_randomforest.pdf")


# CHANGE PARAMETERS HERE ####

# ntree - number of trees
ntree_param <- 200
# p - split parameter
p_param <- 0.6


# final nulls data 
final_nulls <- read.csv("Final_NullsRemoved.csv")
# Final_NullsRemoved.csv
table(final_nulls$LCTYPE)


# TIDYING ####

# removing zero's
final_nulls <- final_nulls[!rowSums(final_nulls[,colnames(final_nulls)[(3:ncol(final_nulls))]] == 0) >= 1, ] 

# removing NA's
final_nulls <- final_nulls[complete.cases(final_nulls), ]  

# creating the unlabelled dataset
final_nulls_unlabelled <- subset(final_nulls, select = -c(LCGROUP, LCTYPE)) 

set.seed(1234)

# removing useless variables from labelled data
to_delete <- c(grep(pattern = "range", names(final_nulls)))

# new dataset
new_final_nulls <- subset(final_nulls, select = -c(Id, FID_1, LCGROUP, to_delete))
table(new_final_nulls$LCTYPE)

# combining PGRS and TGRS
# removing non-crops
new_final_nulls <- new_final_nulls[(new_final_nulls$LCTYPE != "FALW"), ]
new_final_nulls <- new_final_nulls[(new_final_nulls$LCTYPE != "NETR_NA"), ]
new_final_nulls <- new_final_nulls[(new_final_nulls$LCTYPE != "RGR"), ]
new_final_nulls <- new_final_nulls[(new_final_nulls$LCTYPE != "WDG"), ]
# also need to remove non-crops in the scotland dataset (not just kelso)
new_final_nulls <- new_final_nulls[(new_final_nulls$LCTYPE != "NETR_A"), ]
new_final_nulls <- new_final_nulls[(new_final_nulls$LCTYPE != "FALW_5"), ]
new_final_nulls <- new_final_nulls[(new_final_nulls$LCTYPE != "PC"), ]

# removing grass:
# comment out - including pgrs
# not commented out - not including pgrs
# new_final_nulls <- new_final_nulls[(new_final_nulls$LCTYPE != "PGRS"), ]

table(new_final_nulls$LCTYPE)
table(droplevels(new_final_nulls$LCTYPE)) 
# droplevels - drops unused levels from a factor or, more commonly, from factors in a data frame

# combine and delete TGRS ####
new_final_nulls$LCTYPE[new_final_nulls$LCTYPE == "TGRS2"] <- "TGRS1"
new_final_nulls$LCTYPE[new_final_nulls$LCTYPE == "TGRS3"] <- "TGRS1"
new_final_nulls$LCTYPE[new_final_nulls$LCTYPE == "TGRS4"] <- "TGRS1"
new_final_nulls$LCTYPE[new_final_nulls$LCTYPE == "TGRS5"] <- "TGRS1"

# grouping pgrs to tgrs
# comment out - not grouping pgrs and tgrs
# not commented out - grouping pgrs and tgrs
# new_final_nulls$LCTYPE[new_final_nulls$LCTYPE == "PGRS"] <- "TGRS1"

# comment out - keep tgrs in
# not commented out - remove tgrs
new_final_nulls <- new_final_nulls[(new_final_nulls$LCTYPE != "TGRS1"), ]

table(new_final_nulls$LCTYPE)
table(droplevels(new_final_nulls$LCTYPE))

# plot of classes
number_of_classes_plot <- ggplot(new_final_nulls, aes(x = new_final_nulls$LCTYPE)) +
        geom_bar(fill = "mediumpurple1") +
        coord_flip()
number_of_classes_plot


# REDUCING CROPS WITH HIGH NUMBER OF ENTRIES #####

# number of entries of PGRS is nrow PGRS
nrow(new_final_nulls[which(new_final_nulls$LCTYPE == "PGRS"),])     # 9139 this shows the number of entries for grass
new_pgrs_size <- sample_n(subset(new_final_nulls, new_final_nulls$LCTYPE == "PGRS"), size = 8939, replace = FALSE)
# the size in line 132 is 8939 as 200 is the desired number to be left with. size is the number to remove from the total to get the number wanted.
new_final_nulls <- anti_join(new_final_nulls, new_pgrs_size)
table(new_final_nulls$LCTYPE)

# also reducing spring barley
nrow(new_final_nulls[which(new_final_nulls$LCTYPE == "SB"),])       # 850
new_sb_size <- sample_n(subset(new_final_nulls, new_final_nulls$LCTYPE == "SB"), size = 650, replace = FALSE)
new_final_nulls <- anti_join(new_final_nulls, new_sb_size)
table(new_final_nulls$LCTYPE)

# also reducing ww
nrow(new_final_nulls[which(new_final_nulls$LCTYPE == "WW"),])       # 289
new_ww_size <- sample_n(subset(new_final_nulls, new_final_nulls$LCTYPE == "WW"), size = 89, replace = FALSE)
new_final_nulls <- anti_join(new_final_nulls, new_ww_size)
table(new_final_nulls$LCTYPE)

# plot of classes after reductions
# reduced_classes_plot <- ggplot(new_final_nulls, aes(x = new_final_nulls$LCTYPE)) +
#         geom_bar(fill = "mediumpurple1") +
#         coord_flip()
# reduced_classes_plot


# changing the LCTYPE restriction to only show crops with greater than x entries ####
new_final_nulls <- ddply(new_final_nulls, "LCTYPE", function(d) {if(nrow(d)>=50) d else NULL})
table(droplevels(new_final_nulls$LCTYPE)) 

# resetting factor levels after subsetting (or else the model fails)
levels(new_final_nulls$LCTYPE);
new_final_nulls$LCTYPE <- factor(new_final_nulls$LCTYPE) 
levels(new_final_nulls$LCTYPE);

# Move LCTYPE variable to the end (to be the last column) 
new_final_nulls <- select(new_final_nulls, -LCTYPE, everything())
str(new_final_nulls)


# TRAIN - TEST SPLIT ####

# train and test split
trainDataSplit <- p_param
testDataSplit <- 1 - trainDataSplit

# split data into train and test subsets 
trainIndex <- sample(nrow(new_final_nulls), trainDataSplit*nrow(new_final_nulls)) 

train1 <- droplevels(new_final_nulls[trainIndex, ]) 
test1 <- droplevels(new_final_nulls[-trainIndex, ]) 
str(train1) 
str(test1)

# check that there is at least one observation for each LCTYPE in each dataset 
table(droplevels(train1$LCTYPE))
table(droplevels(test1$LCTYPE)) 

# plot of actual data
p1 <- ggplot(new_final_nulls, aes(x=LCTYPE)) + 
        geom_bar(fill="lightskyblue") + 
        labs(title="ACTUAL dataset (Final_NullsRemoved)", 
             x="Land Cover Type (LCTYPE)", 
             y="Number of farm fields") +
        theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5))
# p1

# plot of training set
p2 <- ggplot(train1, aes(x=LCTYPE)) + 
        geom_bar(fill="lightpink") + 
        labs(title="TRAINING dataset (Final_NullsRemoved)", 
             x="Land Cover Type (LCTYPE)", 
             y="Number of farm fields") +
        theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5))
# p2

# plot of test set
p3 <- ggplot(test1, aes(x=LCTYPE)) + 
        geom_bar(fill="lightgreen") + 
        labs(title="TEST dataset (Final_NullsRemoved)", 
             x="Land Cover Type (LCTYPE)", 
             y="Number of farm fields") +
        theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5))
# p3

grid.arrange(p1,p2,p3)


# looking at the data
glimpse(new_final_nulls)
glimpse(train1)

all <- length(train1[1,])-1


# MODEL ####

model_all <- randomForest(LCTYPE~., data = train1,
                          mtry = sqrt(length(table(train1$LCTYPE))),
                          ntree = ntree_param,
                          importance = TRUE)
model_all

# plot for training set
model_all_train_plot <- ggplot(train1, aes(x=LCTYPE, y=model_all$predicted, color=LCTYPE)) + 
        geom_boxplot(size=1, show.legend = FALSE) + 
        geom_jitter(size=2, show.legend = FALSE) + 
        labs(title=paste("Random Forest Model (", all, " vars): TRAIN data Confusion Matrix"), 
             x="Actual class", 
             y="Predicted class") + 
        coord_flip()
# model_all_train_plot

# predict output
model_all_predicted <- predict(model_all, test1, type="class")
summary(model_all_predicted)

# confusion matrix 1
model_all_conf_matrix <- table(test1$LCTYPE, model_all_predicted, dnn=c("Actual","Predicted"))
model_all_conf_matrix
summary(model_all_conf_matrix)

# plot of test set
model_all_test_plot <- ggplot(test1, aes(x=LCTYPE, y=model_all_predicted, color=LCTYPE)) + 
        geom_jitter(size=2, show.legend = FALSE) + 
        labs(title=paste("Random Forest Model (", all, " vars): TRAIN data Confusion Matrix"), 
             x="Actual class", 
             y="Predicted class") + 
        coord_flip()
# model_all_test_plot

grid.arrange(model_all_train_plot, model_all_test_plot)

# confusion matrix 2 (this is just a check of the first confusion matrix)
model_all_conf <- confusionMatrix(test1$LCTYPE, model_all_predicted)
model_all_conf


# MODEL ACCURACY 
model_all_accuracy <- mean(model_all_predicted == test1$LCTYPE)
model_all_accuracy

model_all_accuracy_kappa <- postResample(pred = model_all_predicted, obs = test1$LCTYPE)
model_all_accuracy_kappa


# ERROR RATE 
plot(model_all$err.rate[,1],
     xlab = "Number of trees",
     ylab="Error rate (%)",
     type = "l",
     col="mediumpurple1")
title(main = paste("Random Forest Model Results: ERROR RATE (", all, " vars"), 
      cex.main= 1, font.main= 2, col.main= "black") 

# getting info about important variables in the model ####
var_importance <- importance (model_all)

all <- length(var_importance[,1])
all

# Plot Important Variables: Type 1 = mean decrease in accuracy 
varImpPlot(model_all, type=1, n.var=all, 
           col="deepskyblue3", 
           bty="o", 
           cex.main=1.2, cex.lab=1, cex.axis=1, 
           main = paste("RF Model (", all, "vars): Mean Decrease in Accuracy"), 
           las=2) 

# Plot Important Variables: Type 2 = mean decrease in node impurity
varImpPlot(model_all, type=2, n.var=all, 
           col="deepskyblue3", 
           bty="o", 
           cex.main=1.2, cex.lab=1, cex.axis=1, 
           main = paste("RF Model (", all, "vars): Mean Decrease in Node Impurity"), 
           las=2) 


# PREDICTIONS #### 

model_all_predicted_no_labels <- predict(model_all, final_nulls_unlabelled, type="class")
summary(model_all_predicted_no_labels)

# Plot actuals - TRAINING data  
actuals_plot <- ggplot(train1, aes(x=LCTYPE)) +
        geom_bar(fill="darkseagreen") + 
        labs(title="RF Model: ACTUAL Crop Types", 
             x="Crop Type", 
             y="No. fields") +
        theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5))
# actuals_plot

# Plot predicted - model_all unlabelled data 
model_all_predicted_no_labels_plot <- ggplot(final_nulls_unlabelled, aes(x=model_all_predicted_no_labels)) + 
        geom_bar(fill="mediumpurple1") + 
        labs(title=paste("RF Model (", all, " variables): \nPREDICTED Crop Types for NO_LABELS dataset"), 
             x="Crop Type", 
             y="No. fields") +
        theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5))
# model_all_predicted_no_labels_plot

# Plot actuals and no-labels precdictions 
grid.arrange(actuals_plot, model_all_predicted_no_labels_plot, nrow = 2, ncol = NULL) 


# OUTPUT FILE ####
# creating an output file of classified crops 
crops_all <- cbind.data.frame(final_nulls_unlabelled, model_all_predicted_no_labels)

# remove all variables except FID_1 and the classification result 
classified_crops_all <- subset(crops_all, select = c(FID_1, model_all_predicted_no_labels))

colnames(classified_crops_all)[ncol(classified_crops_all)] <- "Predicted LCTYPE"

# predicted classified crops (all variables. this is a large file - don't run unless necessary)
# write.csv(crops_all, file = "crops_all_variables_no_location.csv")

# predicted classified crops
write.csv(classified_crops_all, file = "all_variables_no_location.csv")


# INDIVIDUAL BY CLASS ACCURACY ####

# confusion matrix
conf_matrix_all <- confusionMatrix(model_all_predicted, test1$LCTYPE)
conf_matrix_all

# converts confusion matrix to a matrix
as_matrix_conf_matrix_all <- as.matrix(x = conf_matrix_all, what = "xtabs")

# manually calculating the overall accuracy
sum(diag(as_matrix_conf_matrix_all))/sum(as_matrix_conf_matrix_all)
# this should be the same as value in model_all_accuracy
# check:
model_all_accuracy

# positive predicticted value is the precision
# converting to data frame 
by_class_accuracies_all <- as.data.frame(conf_matrix_all$byClass)["Pos Pred Value"]
by_class_accuracies_all


## creating a tidy dataset in order to plot individual by class accuracies ####

tidy_by_class_accuracies_all <- by_class_accuracies_all

tidy_by_class_accuracies_all[ncol(tidy_by_class_accuracies_all)+1] <- row.names(tidy_by_class_accuracies_all)
tidy_by_class_accuracies_all <- tidy_by_class_accuracies_all %>%
        select(V2, everything())
row.names(tidy_by_class_accuracies_all) <- 1:nrow(tidy_by_class_accuracies_all)
colnames(tidy_by_class_accuracies_all)[1] <- "Class"

tidy_by_class_accuracies_all$Class <- gsub("Class: ","",tidy_by_class_accuracies_all$Class)

tidy_by_class_accuracies_all <- as.tbl(tidy_by_class_accuracies_all)

tidy_by_class_accuracies_all <- melt(tidy_by_class_accuracies_all)
tidy_by_class_accuracies_all <- tidy_by_class_accuracies_all[,-2]

colnames(tidy_by_class_accuracies_all) <- c("Class","Accuracy")

tidy_by_class_accuracies_all

ggplot(na.omit(tidy_by_class_accuracies_all)) +
        geom_bar(aes(x = Class, y = Accuracy), stat = 'identity', fill = "darkseagreen") +
        labs(x = "Class",
             y = "By class accuracy") +
        coord_flip() 


# RESULTS ALL TOGETHER ####
rf_results_all <- data.frame(
        # No. of variables in the model 
        Variables = all, 
        # Error Rate for TRAIN model, rounded to 4 decimals, then * 100  
        Accuracy_train = c(((1-round((model_all$err.rate[100,1]), 4))*100)), 
        # Accuracy for TEST model 
        Accuracy_test = c(
                (round(model_all_accuracy *100, digits=2))), 
        # Kappa stats 
        Model_Kappa = c(
                (round(model_all_conf$overall[2]*100, digits=2))))


rf_results_all$Accuracy_test
rf_results_all

dev.off()