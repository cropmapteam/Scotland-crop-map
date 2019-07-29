# Scotland-crop-map: Analysis Instructions

Analysis folder contains datasets and R code for analysing the Scottish crops data. 
Download all files (datasets and code) into the same folder before running the code. 


  SYSTEM REQUIREMENTS 
================
 - Latest R version from https://www.r-project.org/ 
 - Latest RStudio from https://www.rstudio.com/products/rstudio/download/ 
 - Install Packages listed at the beginning of each R code 
 
 
  DATASETS 
============ 
THERE ARE 3 DATASETS INCLUDED IN SCOTTISH CROPS ANALYSIS: 

1 - crop-growing-seasons.csv 
Format: CSV 
Size: 5 kb (tiny) 
Contents: information about crops growing life-cycle. 
Use: shows a generic crops growth pattern through the year (Jan to Dec). It will give you an idea of the data pattern you should expect to see in satellite images. 

2 - kelso-monthlyzonal-2018-fixed.csv
Format: CSV 
Size: 303 kb (very small) 
Contents: includes VV and VH means and variances for Jan to Oct 2018. 
Use: use to build Random Forest model. 

3 - images in Train and Test folders (see James Crone at EDINA for folders location) 
Format: TIF 
Size: 150 meg x 4 folders (huge!) 
Contents: images of individual fields, split between Train and Test sets, and by crop-type withing each set. 
Use: use to build Neural Network model. 


  CODE 
======== 
THERE ARE 5 PROGRAMS INCLUDED IN SCOTTISH CROPS ANALYSIS: 

1 - Kelso.Rproj 
Always open this file first. It recognizes saved R/RStudio environment, and directory you are running the code from. You should NOT have to make any dirctory changes when running code from this R project. 

2 - Crop-Growing-Seasons.R 
Uses crop-growing-seasons.csv data to look at general crops life-cycle info. 

3 - Kelso_Exploratory_Analysis.R 
Uses kelso-monthlyzonal-2018-fixed.csv data to look at Kelso area fields details. 

4 - Kelso_Random_Forest.R 
Uses kelso-monthlyzonal-2018-fixed.csv data to build and select the best Random Forest classification model. 

5 - Kelso_NeuralNet.R 
Uses TIF images stored in Train and Test folders to build a Neural Net classification model. 
