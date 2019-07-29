# PROJECT: Scot Crop Map #### 
# AREA: Kelso  
# SATELLITE: Copernicus Sentinel-1 https://sentinel.esa.int/web/sentinel/ 
# IMAGES ACQUISITION DATE: Jan-Oct 2018 
# IMAGES PROCESSED BY: JNCC team http://jncc.defra.gov.uk 
# IMAGES CLEANEDUP BY: #ScotCropMap project team 
#
# AUTHOR: Beata Mielcarek 
# DATE: July 2019 

# VERSION CONTROL #### 
# ref: https://shirinsplayground.netlify.com/2018/06/keras_fruits/ 
# ref: https://jjallaire.github.io/deep-learning-with-r-notebooks/notebooks/5.3-using-a-pretrained-convnet.nb.html 
# ref: Deep learning with R, p.113 
# 
# v1 - initial code to view images  
# v2-6 - adding and testing NN model 

# R ENVIRONMENT #### 
ls() 
rm(list=ls())
graphics.off()  # remove Plots 
cat("\014")     # remove Console text 


# R PACKAGES #### 
library(ggplot2)        # create plots 
library(reshape2)       # shape images 
library(keras)          # build DNN 
library(lattice)        # for multipanel plots 
library(grid)           # for displaying multiple graphs on same page 
library(gridExtra)      # for displaying multiple graphs on same page 
library(ggsn)           # for displaying multiple graphs on same page
library(TeachingDemos)  # for capturing commands and Console output in txt file
library(tiff)           # read tif images 
library(raster)         # read tif images 
library(rgdal)          # read tif images 


# BRANDING TEMPLATES ####
# PLOT TEXT (title, subtitle, bottom #hashtag) 
plot_subtitle <- labs(subtitle = "Kelso-Jedburgh area") 
plot_caption <- labs(caption = "#ScotCropMap") 
plot_theme <- theme(
  plot.title = element_text(color = "black", size = 12, face = "bold"),
  plot.subtitle = element_text(color = "deepskyblue3"),
  plot.caption = element_text(color = "darkgreen", face = "italic"))


# ==> USER INPUT: SETUP output PDF and TXT files #### 

# create Plots output file (PDF) 
#pdf(file="Kelso_Neural_Network_Band-1.pdf")
pdf(file="Kelso_Neural_Network_Band-2.pdf")

# create Code inputs & results file 
#txtStart(file="Kelso_Neural_Network_Band-1.txt", commands=TRUE, results=TRUE, append=FALSE) 
txtStart(file="Kelso_Neural_Network_Band-2.txt", commands=TRUE, results=TRUE, append=FALSE) 


# ==> USER INPUT: FOLDERS MAPPING for Band-1 or Band-2 images #### 

base_dir <- getwd() 
base_dir

logs_dir <- file.path(base_dir, "Logs")
logs_dir

#train_dir <- file.path(base_dir, "TrainB1")
train_dir <- file.path(base_dir, "TrainB2")
train_dir 


#test_dir <- file.path(base_dir, "TestB1")
test_dir <- file.path(base_dir, "TestB2")
test_dir 


# ==> USER INPUT: VIEW A FEW RANDOM IMAGES #### 
# select and plot an image from TRAIN directory 

# list all class folders in Train folder to verify types of classes 
listTrainFolders <- list.dirs(train_dir, full.names=FALSE, recursive=FALSE) 
listTrainFolders 

# select a class folder under Test directory 
# [[1]] selects 1-st folder,  [[2]] selects 2-nd folder, etc 
myTrainClass <- listTrainFolders[[5]]   
myTrainClass 

# show selected Test class folder 
myTrainClassFolder <- file.path(train_dir, myTrainClass) 
myTrainClassFolder 

# show first TIF file in the slected Test class folder 
myTrainClassFiles <- list.files(myTrainClassFolder)
myTrainClassFiles[[2]] 

# plot image 
my_train_image <- raster(file.path(myTrainClassFolder, myTrainClassFiles[[2]])) 
plot(my_train_image) 


# select and plot an image from TEST directory 

# list all class folders in Test folder to verify types of classes 
# has to be exactly the same as in Train folders 
listTestFolders <- list.dirs(test_dir, full.names=FALSE, recursive=FALSE) 
listTestFolders 

# select a class folder under Test directory 
# [[1]] selects 1-st folder,  [[2]] selects 2-nd folder, etc 
myTestClass <- listTestFolders[[1]]   
myTestClass 

# show selected Test class folder 
myTestClassFolder <- file.path(test_dir, myTestClass) 
myTestClassFolder 

# show first TIF file in the slected Test class folder 
myTestClassFiles <- list.files(myTestClassFolder)
myTestClassFiles[[1]] 

# plot image 
my_test_image <- raster(file.path(myTestClassFolder, myTestClassFiles[[1]])) 
plot(my_test_image) 


# SETUP CLASSES #### 
# list of crops to model 
# This is based on the folders under Train directory 

crops_list <- listTrainFolders 
crops_list

# number of output classes 
output_n <- length(crops_list)
output_n

# SETUP IMAGE INFO #### 
# image size 
img_width <- 64
img_height <- 64
target_size <- c(img_width, img_height)

# channels (aka bands, or layers of colors) of the input images 
# channels = 3 is color(rgb), channels = 1 is grayscale 
channels <- 1


# TRAINING DATASET #### 
# Training data re-scaling (other options help augment photos) 
train_data_gen = image_data_generator(
        rescale = 1 / 255 #,
        #rotation_range = 40,
        #width_shift_range = 0.2,
        #height_shift_range = 0.2,
        #shear_range = 0.2,
        #zoom_range = 0.2,
        #horizontal_flip = TRUE,
        #fill_mode = "nearest"
)
train_data_gen 

# Training images 
train_image_array_gen <- flow_images_from_directory(train_dir, 
                                                    generator = train_data_gen,
                                                    target_size = target_size,
                                                    color_mode="grayscale",
                                                    class_mode = "categorical",
                                                    classes = crops_list,
                                                    seed = 42)
train_image_array_gen 

# Number of images per class:
cat("Number of images per class:") 
table(factor(train_image_array_gen$classes))

# BAND 1 
#  0    1    2    3    4    6    7    8    9   10   11 
#204 4662 1918  348  123  634  184  551  737  224 1575 

#train_classes_plot <- ggplot(train_image_array_gen$classes)
#train_classes_plot 


# Index mapping 
cat("\nClass label vs index mapping:\n") 
train_image_array_gen$class_indices

# Class label vs index mapping 
crops_classes_indices <- train_image_array_gen$class_indices

save(crops_classes_indices, file = "/Users/quantoid/Desktop/cropsMap/analysis/Kelso/crops_classes_indices.RData")


# TESTING DATASET #### 
# Testing data re-scaling 
test_data_gen = image_data_generator(rescale = 1/255)

# Testing images 
test_image_array_gen <- flow_images_from_directory(test_dir, 
                                                   test_data_gen,
                                                   target_size = target_size,
                                                   color_mode="grayscale",
                                                   class_mode = "categorical",
                                                   classes = crops_list,
                                                   seed = 42)

# Number of images per class:
cat("Number of images per class:") 
table(factor(test_image_array_gen$classes)) 

# BAND 1 
#  0    1    2    3    4    6    7    8    9   10   11 
#163 2927 1206  286   82  430  102  388  492  123 1064 



#test_classes_plot <- ggplot(factor(test_image_array_gen$classes)) 
#test_classes_plot 

#grid.arrange(test_classes_plot,train_classes_plot)


# CREATE SAMPLE DATASETS #### 
# number of training samples
train_samples <- train_image_array_gen$n
train_samples

# number of testing samples
test_samples <- test_image_array_gen$n
test_samples 


# ==> USER INPUT: SETUP MODEL VARIABLES #### 
# batch_size - Number of images to use in each epoch 
# epochs - Number of times a model is run 
# k_folds - 

batch_size <- 200 
epochs <- 30


# MODEL 1 - layers 64-12, Relu #### 
# Network Structure: layers 64-12, Relu 
# keras_model_sequential, and CNN (Convolutional Neural Network) 
# Activation Functions: can try Relu, Sigmoid or Tanh for hidden layers 
# Activation Function: softmax, ALWAYS for output layer for multi-class classification 

# Network Structure - layers 64-12, Relu 
model <- keras_model_sequential() %>%
  # First layer
  layer_conv_2d(input_shape = c(img_width, img_height, channels), 
                filter = 64, kernel_size = c(3,3), activation="relu") %>%

  # Use max pooling
  layer_max_pooling_2d(pool_size = c(2,2)) %>% 

  # Flatten max filtered output into feature vector and feed into dense layer
  layer_flatten() %>% 
  layer_dense(units = 12, activation = "relu") %>%

  # Outputs from dense layer onto numver of classes 
  layer_dense(units = output_n, activation="softmax")

summary(model)


# Compile the model 

# optimizer: rmsprop is the default and universally used 
# loss: categorical crossentropy for single-label multi-class classification
# metrics: accuracy, commonly used for balanced classification probalms 

model %>% compile(
  optimizer = "rmsprop", 
  loss = "categorical_crossentropy",
  metrics = c("accuracy"))


# Fit Model to Training data 

history <- model %>% fit_generator(
  # training data 
  train_image_array_gen, 
  
  # epochs
  steps_per_epoch = as.integer(train_samples / batch_size), 
  epochs = epochs, 
  
  # test data
  validation_data = test_image_array_gen,
  validation_steps = as.integer(test_samples / batch_size), 

  # print progress
  verbose = 1,
  callbacks = list(
    
    # save best model after every epoch
    callback_model_checkpoint("/Users/quantoid/Desktop/cropsMap/analysis/Kelso/Logs/crops_checkpoints.h5", 
                              save_best_only = TRUE), 
    
    # only needed for visualising with TensorBoard
    callback_tensorboard(log_dir = "/Users/quantoid/Desktop/cropsMap/analysis/Kelso/Logs")
  )
) 

  
# Results: Loss & Accuracy 
str(history)
plot(history) 


# Loss 
head(history$metrics$loss,100) 

# Accuracy 
head(history$metrics$acc,100) 


# MODEL IMPROVEMENTS #### 
# To improve the model & mitigate overfitting: 
# 1 - add Layers or neurons, 
# 2 - use Validation Split (validation_split=0.2) 
# 3 - add L2 Regularisation (layer_dense(kernel_regularizer=regularizer_l2(0.001)))
# 4 - use Dropout (layer_dropout(rate=0.5)) 
# 5 - change Activation Function: RELU, Sigmoid, Tanh 


# MODEL 2 - layers 64-12, Relu, L2 Reg #### 
# Network Structure - layers 64-12, Relu, Reg L2 

model <- keras_model_sequential() %>%
  # First layer
  layer_conv_2d(input_shape = c(img_width, img_height, channels), 
                filter = 64, kernel_size = c(3,3), activation="relu", 
                kernel_regularizer = regularizer_l2(0.001)) %>%
  layer_max_pooling_2d(pool_size = c(2,2)) %>% 
  
  # Flatten max filtered output into feature vector and feed into dense layer
  layer_flatten() %>% 
  layer_dense(units = 12, activation = "relu") %>%
  
  # Outputs from dense layer onto numver of classes 
  layer_dense(units = output_n, activation="softmax")

summary(model)


# compile 
model %>% compile(
  optimizer = "rmsprop", 
  loss = "categorical_crossentropy",
  metrics = c("accuracy"))

# fit 
history <- model %>% fit_generator(
  # training data 
  train_image_array_gen, 
  
  # epochs
  steps_per_epoch = as.integer(train_samples / batch_size), 
  epochs = epochs, 
  
  # test data
  validation_data = test_image_array_gen,
  validation_steps = as.integer(test_samples / batch_size), 
  
  # print progress
  verbose = 1,
  callbacks = list(
    
    # save best model after every epoch
    callback_model_checkpoint("/Users/quantoid/Desktop/cropsMap/analysis/Kelso/Logs/crops_checkpoints.h5", 
                              save_best_only = TRUE)
  )
) 

# results: Loss & Accuracy 
str(history)
plot(history) 

# Loss 
head(history$metrics$loss,100) 

# Accuracy 
head(history$metrics$acc,100) 


# MODEL 3 - layers 64-12, Relu, Dropout #### 
# Network Structure - layers 64-12, Relu, Dropout 

model <- keras_model_sequential() %>%
  # First layer
  layer_conv_2d(input_shape = c(img_width, img_height, channels), 
                filter = 64, kernel_size = c(3,3), activation="relu") %>%
  layer_max_pooling_2d(pool_size = c(2,2)) %>% 
  
  # Flatten max filtered output into feature vector and feed into dense layer
  layer_flatten() %>% 
  layer_dropout(rate = 0.5) %>% 
  layer_dense(units = 12, activation = "relu") %>% 
  
  # Outputs from dense layer onto numver of classes 
  layer_dense(units = output_n, activation="softmax")

summary(model)


# compile 
model %>% compile(
  optimizer = "rmsprop", 
  loss = "categorical_crossentropy",
  metrics = c("accuracy"))

# fit 
history <- model %>% fit_generator(
  # training data 
  train_image_array_gen, 
  
  # epochs
  steps_per_epoch = as.integer(train_samples / batch_size), 
  epochs = epochs, 
  
  # test data
  validation_data = test_image_array_gen,
  validation_steps = as.integer(test_samples / batch_size), 
  
  # print progress
  verbose = 1,
  callbacks = list(
    
    # save best model after every epoch
    callback_model_checkpoint("/Users/quantoid/Desktop/cropsMap/analysis/Kelso/Logs/crops_checkpoints.h5", 
                              save_best_only = TRUE)
  )
) 

# results: Loss & Accuracy 
str(history)
plot(history) 

# Loss 
head(history$metrics$loss,100) 

# Accuracy 
head(history$metrics$acc,100) 


# MODEL 4 - layers 64-32-12, Relu #### 
# Network Structure - layers 64-32-12, Relu 

model <- keras_model_sequential() %>%
  # First layer
  layer_conv_2d(input_shape = c(img_width, img_height, channels), 
                filter = 64, kernel_size = c(3,3), activation="relu") %>%
  layer_max_pooling_2d(pool_size = c(2,2)) %>% 
  
  # Second hidden layer
  layer_conv_2d(filter = 32, kernel_size = c(3,3), activation="relu") %>% 
  layer_max_pooling_2d(pool_size = c(2,2)) %>% 
  
  # Flatten max filtered output into feature vector and feed into dense layer
  layer_flatten() %>% 
  layer_dense(units = 12, activation = "relu") %>%
  
  # Outputs from dense layer onto numver of classes 
  layer_dense(units = output_n, activation="softmax")

summary(model)

# compile 
model %>% compile(
  optimizer = "rmsprop", 
  loss = "categorical_crossentropy",
  metrics = c("accuracy"))

# fit 
history <- model %>% fit_generator(
  # training data 
  train_image_array_gen, 
  
  # epochs
  steps_per_epoch = as.integer(train_samples / batch_size), 
  epochs = epochs, 
  
  # test data
  validation_data = test_image_array_gen,
  validation_steps = as.integer(test_samples / batch_size), 
  
  # print progress
  verbose = 1,
  callbacks = list(
    
    # save best model after every epoch
    callback_model_checkpoint("/Users/quantoid/Desktop/cropsMap/analysis/Kelso/Logs/crops_checkpoints.h5", 
                              save_best_only = TRUE)
    )
) 

# results: Loss & Accuracy 
str(history)
plot(history) 

# Loss 
head(history$metrics$loss,100) 

# Accuracy 
head(history$metrics$acc,100) 


# MODEL 5 - layers 64-32-12, Relu, L2 Reg #### 
# Network Structure - layers 64-32-12, Relu, Reg L2 

model <- keras_model_sequential() %>%
  # First layer
  layer_conv_2d(input_shape = c(img_width, img_height, channels), 
                filter = 64, kernel_size = c(3,3), activation="relu", 
                kernel_regularizer = regularizer_l2(0.001)) %>%
  layer_max_pooling_2d(pool_size = c(2,2)) %>% 
  
  # Second hidden layer
  layer_conv_2d(filter = 32, kernel_size = c(3,3), activation="relu", 
                kernel_regularizer = regularizer_l2(0.001)) %>%  
  layer_max_pooling_2d(pool_size = c(2,2)) %>% 
  
  # Flatten max filtered output into feature vector and feed into dense layer
  layer_flatten() %>% 
  layer_dense(units = 12, activation = "relu") %>%
  
  # Outputs from dense layer onto numver of classes 
  layer_dense(units = output_n, activation="softmax")

summary(model)


# compile 
model %>% compile(
  optimizer = "rmsprop", 
  loss = "categorical_crossentropy",
  metrics = c("accuracy"))

# fit 
history <- model %>% fit_generator(
  # training data 
  train_image_array_gen, 
  
  # epochs
  steps_per_epoch = as.integer(train_samples / batch_size), 
  epochs = epochs, 
  
  # test data
  validation_data = test_image_array_gen,
  validation_steps = as.integer(test_samples / batch_size), 
  
  # print progress
  verbose = 1,
  callbacks = list(
    
    # save best model after every epoch
    callback_model_checkpoint("/Users/quantoid/Desktop/cropsMap/analysis/Kelso/Logs/crops_checkpoints.h5", 
                              save_best_only = TRUE)
  )
) 

# results: Loss & Accuracy 
str(history)
plot(history) 

# Loss 
head(history$metrics$loss,100) 

# Accuracy 
head(history$metrics$acc,100) 


# MODEL 6 - layers 64-32-12, Relu, Dropout #### 
# Network Structure - layers 64-32-12, Relu, Dropout 

model <- keras_model_sequential() %>%
  # First layer
  layer_conv_2d(input_shape = c(img_width, img_height, channels), 
                filter = 64, kernel_size = c(3,3), activation="relu") %>%
  layer_max_pooling_2d(pool_size = c(2,2)) %>% 
  
  # Second hidden layer
  layer_conv_2d(filter = 32, kernel_size = c(3,3), activation="relu", 
                kernel_regularizer = regularizer_l2(0.001)) %>%  
  layer_max_pooling_2d(pool_size = c(2,2)) %>% 
  
  # Flatten max filtered output into feature vector and feed into dense layer
  layer_flatten() %>% 
  layer_dropout(rate = 0.5) %>% 
  layer_dense(units = 12, activation = "relu") %>%
  
  # Outputs from dense layer onto numver of classes 
  layer_dense(units = output_n, activation="softmax")

summary(model)


# compile 
model %>% compile(
  optimizer = "rmsprop", 
  loss = "categorical_crossentropy",
  metrics = c("accuracy"))

# fit 
history <- model %>% fit_generator(
  # training data 
  train_image_array_gen, 
  
  # epochs
  steps_per_epoch = as.integer(train_samples / batch_size), 
  epochs = epochs, 
  
  # test data
  validation_data = test_image_array_gen,
  validation_steps = as.integer(test_samples / batch_size), 
  
  # print progress
  verbose = 1,
  callbacks = list(
    
    # save best model after every epoch
    callback_model_checkpoint("/Users/quantoid/Desktop/cropsMap/analysis/Kelso/Logs/crops_checkpoints.h5", 
                              save_best_only = TRUE)
  )
) 

# results: Loss & Accuracy 
str(history)
plot(history) 

# Loss 
head(history$metrics$loss,100) 

# Accuracy 
head(history$metrics$acc,100) 

 
# MODEL 7 - layers 64-12, Sigmoid #### 

model <- keras_model_sequential() %>%
  # First layer
  layer_conv_2d(input_shape = c(img_width, img_height, channels), 
                filter = 64, kernel_size = c(3,3), activation="sigmoid") %>% 
  layer_max_pooling_2d(pool_size = c(2,2)) %>% 
  
  # Flatten max filtered output into feature vector and feed into dense layer
  layer_flatten() %>% 
  layer_dense(units = 12, activation = "sigmoid") %>%
  
  # Outputs from dense layer onto numver of classes 
  layer_dense(units = output_n, activation="softmax")

summary(model)


# compile 
model %>% compile(
  optimizer = "rmsprop", 
  loss = "categorical_crossentropy",
  metrics = c("accuracy"))

# fit 
history <- model %>% fit_generator(
  # training data 
  train_image_array_gen, 
  
  # epochs
  steps_per_epoch = as.integer(train_samples / batch_size), 
  epochs = epochs, 
  
  # test data
  validation_data = test_image_array_gen,
  validation_steps = as.integer(test_samples / batch_size), 
  
  # print progress
  verbose = 1,
  callbacks = list(
    
    # save best model after every epoch
    callback_model_checkpoint("/Users/quantoid/Desktop/cropsMap/analysis/Kelso/Logs/crops_checkpoints.h5", 
                              save_best_only = TRUE)
  )
) 

# results: Loss & Accuracy 
str(history)
plot(history) 

# Loss 
head(history$metrics$loss,100) 

# Accuracy 
head(history$metrics$acc,100) 


# MODEL 8 - layers 64-12, Sigmoid, L2 Reg #### 
# Network Structure - layers 64-12, Relu, Reg L2 

model <- keras_model_sequential() %>%
  # First layer
  layer_conv_2d(input_shape = c(img_width, img_height, channels), 
                filter = 64, kernel_size = c(3,3), activation="sigmoid", 
                kernel_regularizer = regularizer_l2(0.001)) %>%
  layer_max_pooling_2d(pool_size = c(2,2)) %>% 
  
  # Flatten max filtered output into feature vector and feed into dense layer
  layer_flatten() %>% 
  layer_dense(units = 12, activation = "sigmoid") %>%
  
  # Outputs from dense layer onto numver of classes 
  layer_dense(units = output_n, activation="softmax")

summary(model)


# compile 
model %>% compile(
  optimizer = "rmsprop", 
  loss = "categorical_crossentropy",
  metrics = c("accuracy"))

# fit 
history <- model %>% fit_generator(
  # training data 
  train_image_array_gen, 
  
  # epochs
  steps_per_epoch = as.integer(train_samples / batch_size), 
  epochs = epochs, 
  
  # test data
  validation_data = test_image_array_gen,
  validation_steps = as.integer(test_samples / batch_size), 
  
  # print progress
  verbose = 1,
  callbacks = list(
    
    # save best model after every epoch
    callback_model_checkpoint("/Users/quantoid/Desktop/cropsMap/analysis/Kelso/Logs/crops_checkpoints.h5", 
                              save_best_only = TRUE)
  )
) 

# results: Loss & Accuracy 
str(history)
plot(history) 

# Loss 
head(history$metrics$loss,100) 

# Accuracy 
head(history$metrics$acc,100) 


# MODEL 9 - layers 64-12, Sigmoid, Dropout #### 

model <- keras_model_sequential() %>%
  # First layer
  layer_conv_2d(input_shape = c(img_width, img_height, channels), 
                filter = 64, kernel_size = c(3,3), activation="sigmoid") %>%
  layer_max_pooling_2d(pool_size = c(2,2)) %>% 
  
  # Flatten max filtered output into feature vector and feed into dense layer
  layer_flatten() %>% 
  layer_dropout(rate = 0.5) %>% 
  layer_dense(units = 12, activation = "sigmoid") %>% 
  
  # Outputs from dense layer onto numver of classes 
  layer_dense(units = output_n, activation="softmax")

summary(model)


# compile 
model %>% compile(
  optimizer = "rmsprop", 
  loss = "categorical_crossentropy",
  metrics = c("accuracy"))

# fit 
history <- model %>% fit_generator(
  # training data 
  train_image_array_gen, 
  
  # epochs
  steps_per_epoch = as.integer(train_samples / batch_size), 
  epochs = epochs, 
  
  # test data
  validation_data = test_image_array_gen,
  validation_steps = as.integer(test_samples / batch_size), 
  
  # print progress
  verbose = 1,
  callbacks = list(
    
    # save best model after every epoch
    callback_model_checkpoint("/Users/quantoid/Desktop/cropsMap/analysis/Kelso/Logs/crops_checkpoints.h5", 
                              save_best_only = TRUE)
  )
) 

# results: Loss & Accuracy 
str(history)
plot(history) 

# Loss 
head(history$metrics$loss,100) 

# Accuracy 
head(history$metrics$acc,100) 


# MODEL 10 - layers 64-12, Tanh #### 

model <- keras_model_sequential() %>%
  # First layer
  layer_conv_2d(input_shape = c(img_width, img_height, channels), 
                filter = 64, kernel_size = c(3,3), activation="tanh") %>% 
  layer_max_pooling_2d(pool_size = c(2,2)) %>% 
  
  # Flatten max filtered output into feature vector and feed into dense layer
  layer_flatten() %>% 
  layer_dense(units = 12, activation = "tanh") %>%
  
  # Outputs from dense layer onto numver of classes 
  layer_dense(units = output_n, activation="softmax")

summary(model)


# compile 
model %>% compile(
  optimizer = "rmsprop", 
  loss = "categorical_crossentropy",
  metrics = c("accuracy"))

# fit 
history <- model %>% fit_generator(
  # training data 
  train_image_array_gen, 
  
  # epochs
  steps_per_epoch = as.integer(train_samples / batch_size), 
  epochs = epochs, 
  
  # test data
  validation_data = test_image_array_gen,
  validation_steps = as.integer(test_samples / batch_size), 
  
  # print progress
  verbose = 1,
  callbacks = list(
    
    # save best model after every epoch
    callback_model_checkpoint("/Users/quantoid/Desktop/cropsMap/analysis/Kelso/Logs/crops_checkpoints.h5", 
                              save_best_only = TRUE)
  )
) 

# results: Loss & Accuracy 
str(history)
plot(history) 

# Loss 
head(history$metrics$loss,100) 

# Accuracy 
head(history$metrics$acc,100) 


# MODEL 11 - layers 64-12, Tanh, L2 Reg #### 

model <- keras_model_sequential() %>%
  # First layer
  layer_conv_2d(input_shape = c(img_width, img_height, channels), 
                filter = 64, kernel_size = c(3,3), activation="tanh", 
                kernel_regularizer = regularizer_l2(0.001)) %>%
  layer_max_pooling_2d(pool_size = c(2,2)) %>% 
  
  # Flatten max filtered output into feature vector and feed into dense layer
  layer_flatten() %>% 
  layer_dense(units = 12, activation = "tanh") %>%
  
  # Outputs from dense layer onto numver of classes 
  layer_dense(units = output_n, activation="softmax")

summary(model)


# compile 
model %>% compile(
  optimizer = "rmsprop", 
  loss = "categorical_crossentropy",
  metrics = c("accuracy"))

# fit 
history <- model %>% fit_generator(
  # training data 
  train_image_array_gen, 
  
  # epochs
  steps_per_epoch = as.integer(train_samples / batch_size), 
  epochs = epochs, 
  
  # test data
  validation_data = test_image_array_gen,
  validation_steps = as.integer(test_samples / batch_size), 
  
  # print progress
  verbose = 1,
  callbacks = list(
    
    # save best model after every epoch
    callback_model_checkpoint("/Users/quantoid/Desktop/cropsMap/analysis/Kelso/Logs/crops_checkpoints.h5", 
                              save_best_only = TRUE)
  )
) 

# results: Loss & Accuracy 
str(history)
plot(history) 

# Loss 
head(history$metrics$loss,100) 

# Accuracy 
head(history$metrics$acc,100) 


# MODEL 12 - layers 64-12, Tanh, Dropout #### 

model <- keras_model_sequential() %>%
  # First layer
  layer_conv_2d(input_shape = c(img_width, img_height, channels), 
                filter = 64, kernel_size = c(3,3), activation="tanh") %>%
  layer_max_pooling_2d(pool_size = c(2,2)) %>% 
  
  # Flatten max filtered output into feature vector and feed into dense layer
  layer_flatten() %>% 
  layer_dropout(rate = 0.5) %>% 
  layer_dense(units = 12, activation = "tanh") %>% 
  
  # Outputs from dense layer onto numver of classes 
  layer_dense(units = output_n, activation="softmax")

summary(model)

# compile 
model %>% compile(
  optimizer = "rmsprop", 
  loss = "categorical_crossentropy",
  metrics = c("accuracy"))

# fit 
history <- model %>% fit_generator(
  # training data 
  train_image_array_gen, 
  
  # epochs
  steps_per_epoch = as.integer(train_samples / batch_size), 
  epochs = epochs, 
  
  # test data
  validation_data = test_image_array_gen,
  validation_steps = as.integer(test_samples / batch_size), 
  
  # print progress
  verbose = 1,
  callbacks = list(
    
    # save best model after every epoch
    callback_model_checkpoint("/Users/quantoid/Desktop/cropsMap/analysis/Kelso/Logs/crops_checkpoints.h5", 
                              save_best_only = TRUE)
  )
) 

# results: Loss & Accuracy 
str(history)
plot(history) 

# Loss 
head(history$metrics$loss,100) 

# Accuracy 
head(history$metrics$acc,100) 


# Close device channels (pdf, txt) #### 
# use dev.off() at the end of the file to stop saving to pdf. 
dev.list() 
txtStop()
dev.off() 


# Session Info #### 
sessionInfo() 
