# PROJECT: Scot Crop Map #### 
# AREA: Scotland 
# Data source: Stephen Smith 
# AUTHOR: Beata Mielcarek 


# VERSION CONTROL #### 
# v1 - initial data analysis 


# R ENVIRONMENT #### 
# CLEAR EMVIRONMENT: PLOTS AND CONSOLE WINDOWS 
ls() 
rm(list=ls())
# graphics.off()  # remove Plots 
cat("\014")     # remove Console text 


# R PACKAGES #### 
library(plyr)           # for re-naming columns 
library(ggplot2)        # for plots 
library(lattice)        # for multipanel plots 
library(grid)           # for displaying multiple graphs on same page 
library(gridExtra)      # for displaying multiple graphs on same page 
library(ggsn)           # for displaying multiple graphs on same page
library(TeachingDemos)   # for capturing commands and Console output in txt file
# library(emojifont)      # for displaying emojis 


# ==> USER INPUT: SETUP output PDF and TXT files #### 

# create Plots output file (PDF) 
pdf(file="Crop-Growing-Seasons_Analysis.pdf")

# create console output file (TXT) 
#sink(file="Kelso_Exploratory_Analysis.txt")
txtStart(file="Crop-Growing-Seasons_Analysis.txt", commands=TRUE, results=TRUE, append=FALSE) 


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
#pie(rep(1, 16), col = myColors, clockwise = TRUE, init.angle = 90, main = "#ScotCropMap project color palette") 


# EMOJIS - current version does NOT WORK with RStudio yet!! 
# ref: https://cran.r-project.org/web/packages/emojifont/vignettes/emojifont.html 
# ref: https://guangchuangyu.github.io/emojifont/ 
# myEmojis <- c() 


# PLOT TEXT (title, subtitle, bottom #hashtag) 
plot_subtitle <- labs(subtitle = "Source: Stephen Smith, May 2019") 
plot_caption <- labs(caption = "#ScotCropMap") 
plot_theme <- theme(
        plot.title = element_text(color = "black", size = 12, face = "bold"),
        plot.subtitle = element_text(color = "deepskyblue3"),
        plot.caption = element_text(color = "darkgreen", face = "italic"))


# DATASET IMPORT #### 
cropsData<- read.csv("crop-growing-seasons.csv") 


# DATASET CHECK #### 
str(cropsData)

# Delete useless variables: Notes, X, X.1, X.2  
cropsData <- subset(cropsData, select = -c(Notes, X, X.1, X.2)) 
str(cropsData)
# data.frame:	58 obs. of  15 variables

# Check factor variables levels 
levels(cropsData$LandSize)

# EXPLORATORY ANALYSIS - Tables #### 

# table by LCTYPE 
table(cropsData$LCTYPE)

# table by LandSize
table(cropsData$LandSize)

# table by LandSize by LCTYPE 
table(cropsData$LCTYPE, cropsData$LandSize) 


# EXPLORATORY ANALYSIS - Plots #### 

# plot by LandSize 
ggplot(cropsData, aes(x=LandSize)) + 
    geom_bar(fill="#6787b7") + 
    labs(title="Crop Types by Land Size", 
         x = "Land Size", 
         y = "Number of crop types") + 
    coord_flip() + 
    plot_subtitle + 
    plot_caption + 
    plot_theme 


# Create Time-Series #### 

# Re-arrange order of variables (ie bind columns) 
cropsData <- cbind(cropsData[1:2], cropsData[15], cropsData[3:14])
str(cropsData)

# Recode Factor month variables to Numeric 
cropsData$January <- as.numeric(as.character(cropsData$January))
cropsData$February <- as.numeric(as.character(cropsData$February))
cropsData$October <- as.numeric(as.character(cropsData$October))
cropsData$November <- as.numeric(as.character(cropsData$November))
cropsData$December <- as.numeric(as.character(cropsData$December))
str(cropsData)

# Stack month columns 
cropsTimeSeries <- cbind(cropsData[1:3], stack(cropsData[4:15]))
str(cropsTimeSeries)

# Recode Factor IND variable to Integer 
cropsTimeSeries$ind <- as.integer(cropsTimeSeries$ind)
str(cropsTimeSeries)

# Export stacked dataset and check that it's correct 
#write.csv(cropsTimeSeries, "cropsTimeSeries.csv")


# plot crops growth lifecycle 
ggplot(data=cropsTimeSeries, aes(x=ind, y=values, colour=LCTYPE )) +
    geom_line() + 
    geom_smooth() + 
    theme(legend.position="bottom", legend.direction = "horizontal") + 
    scale_x_discrete(name = "2018", 
                     limits = c("Jan", "Feb", "Mar", "Apr", "May", "June", 
                                "July", "Aug", "Sept", "Oct", "Nov", "Dec")) + 
    labs(title="Scottish Crops Growth by Month", 
         y = "Crop Growth") + 
    plot_subtitle + 
    plot_caption + 
    plot_theme 


#subset by specific LCTYPE 
a<- subset(cropsTimeSeries, LCTYPE=="WO")
str(a)
a$LCTYPE 

ggplot(data=a, aes(x=ind, y=values, colour=LCTYPE )) +
    geom_line() +
    geom_smooth() + 
    theme(legend.position="bottom", legend.direction = "horizontal") + 
    scale_x_discrete(name = "2018", 
                     limits = c("Jan", "Feb", "Mar", "Apr", "May", "June", 
                                "July", "Aug", "Sept", "Oct", "Nov", "Dec")) + 
    labs(title="Scottish Crops Growth by Month - WINTER OATS (WO)", 
         y = "Crop Growth") + 
    plot_subtitle + 
    plot_caption + 
    plot_theme 



### End of Exploratory Analysis #### 
# use dev.off() at the end of the file to stop saving to pdf. 
dev.list() 
#sink()
#txtStop()
dev.off() 
