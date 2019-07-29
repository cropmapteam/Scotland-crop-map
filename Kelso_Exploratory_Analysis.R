# PROJECT: Scot Crop Map #### 
# AREA: Kelso-Jedburgh 
# SATELLITE: Copernicus Sentinel-1 https://sentinel.esa.int/web/sentinel/ 
# IMAGES ACQUISITION DATE: Jan-Sept 2018 
# IMAGES PROCESSED BY: JNCC team http://jncc.defra.gov.uk 
# IMAGES CLEANEDUP BY: #ScotCropMap project team 
# AUTHOR: Beata Mielcarek 


# VERSION CONTROL #### 
# v1-17 - initial code includes preliminary Random Forest work 
# v18 - added Branding (colors, emojis, titles), updated dataset split variables 
# v19 - split dataset into VV & VH subsets for MEAN and VARIANCE, added LCTYPE plots 
# v20 - added double plots for VV mean/variance, VH mean/variance 


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
pdf(file="Kelso_Exploratory_Analysis.pdf")

# create console output file (TXT) 
txtStart(file="Kelso_Exploratory_Analysis.txt", commands=TRUE, results=TRUE, append=FALSE) 


# BRANDING TEMPLATES: Colors, Emojis, Titles #### 

# COLORS 
# ref: https://www.datanovia.com/en/blog/awesome-list-of-657-r-color-names/ 
# ref: https://www.datanovia.com/en/blog/top-r-color-palettes-to-know-for-great-data-visualization/ 

# R default color palette 
palette("default")
r_color <- colors()
head(r_color, 50)

# My brand colors palette 
myColors <- c("#6787b7", "#00AFBB", "#CC79A7", "#0072B2", 
              "#C3D7A4", "#56B4E9", "#E69F00", "#52854C", 
              "saddlebrown", "#E7B800", "#999999", "darkseagreen", 
              "#4E84C4", "#FFDB6D", "#FF6666", "#F4EDCA")

# set palette to myColors - will overwrite R default palette!! 
#myPalette <- palette(myColors) 

# show Colors in my Palette 
# ref: https://stackoverflow.com/questions/9563711/r-color-palettes-for-many-data-classes 
pie(rep(1, 16), col = myColors, clockwise = TRUE, init.angle = 90, 
    main = "#ScotCropMap project color palette") 


# EMOJIS - current version does NOT WORK with RStudio yet!! 
# ref: https://cran.r-project.org/web/packages/emojifont/vignettes/emojifont.html 
# ref: https://guangchuangyu.github.io/emojifont/ 
# myEmojis <- c() 


# PLOT TEXT (title, subtitle, bottom #hashtag) 
plot_subtitle <- labs(subtitle = "Kelso-Jedburgh area") 
plot_caption <- labs(caption = "#ScotCropMap") 
plot_theme <- theme(
        plot.title = element_text(color = "black", size = 12, face = "bold"),
        plot.subtitle = element_text(color = "deepskyblue3"),
        plot.caption = element_text(color = "darkgreen", face = "italic"))


# DATASET IMPORT #### 
allData<- read.csv("kelso-monthlyzonal-2018-fixed.csv") 


# DATASET CHECK #### 
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

# EXPLORATORY ANALYSIS #### 

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
             x = "Area (in hectares)", 
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
             x = "Area (in hectares)", 
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
        geom_bar(fill="darkseagreen") + 
        coord_flip() + 
        labs(title="Fields by Land Cover Type (LCTYPE)", 
             x="Land Cover Type (LCTYPE)", 
             y="Number of farm fields") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme 


# AREA subsets: Small, Med, Large #### 

# by small AREA ( <= 10 hectares)
table(allData$AREA <= 10)
table(allData$LCGROUP, allData$AREA <= 10) 
table(allData$LCTYPE, allData$AREA <= 10) 

# small AREA by LCGROUP 
ggplot(data=subset(allData, AREA <= 10), aes(x=LCGROUP)) + 
        geom_histogram(fill="#6787b7", stat="count") + 
        theme(legend.position="top", legend.direction = "horizontal") + 
        labs(title="Land Cover Group (LCGROUP) on SMALL fields (AREA less than 10 hectares)", 
             x="Land Cover Group (LCGROUP)") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme

# small AREA by LCTYPE
ggplot(data=subset(allData, AREA <= 10), aes(x=LCTYPE)) + 
        geom_histogram(fill="darkseagreen", stat="count") + 
        theme(legend.position="top", legend.direction = "horizontal") + 
        labs(title="Land Cover Type (LCTYPE) on SMALL fields (AREA less than 10 hectares)", 
             x="Land Cover Type (LCTYPE)") + 
        coord_flip() + 
        plot_subtitle + 
        plot_caption + 
        plot_theme 


# by medium AREA ( > 10 and <= 20 hectares)
table((allData$AREA > 10) & (allData$AREA < 20)) 
table(allData$LCGROUP, ((allData$AREA > 10) & (allData$AREA < 20)))
table(allData$LCTYPE, ((allData$AREA > 10) & (allData$AREA < 20)))

# medium AREA by LCGROUP 
ggplot(data=subset(allData, AREA > 10 & AREA <= 20), aes(x=LCGROUP)) + 
        geom_histogram(fill="#6787b7", stat="count") + 
        theme(legend.position="top", legend.direction = "horizontal") + 
        labs(title="Land Cover Group (LCGROUP) on MEDIUM size fields (AREA between 10 & 20 hectares)", 
             x="Land Cover Group (LCGROUP)") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme

# medium AREA by LCTYPE
ggplot(data=subset(allData, AREA > 10 & AREA <= 20), aes(x=LCTYPE)) + 
        geom_histogram(fill="darkseagreen", stat="count") + 
        theme(legend.position="top", legend.direction = "horizontal") + 
        labs(title="Land Cover Type (LCTYPE) on MEDIUM size fields (AREA between 10 & 20 hectares)", 
             x="Land Cover Type (LCTYPE)") + 
        coord_flip() + 
        plot_subtitle + 
        plot_caption + 
        plot_theme 


# by large AREA ( > 20 hectares)
table(allData$AREA > 20)
table(allData$LCGROUP, allData$AREA > 20) 
table(allData$LCTYPE, allData$AREA > 20) 

# large AREA by LCGROUP 
ggplot(data=subset(allData, AREA > 20), aes(x=LCGROUP)) + 
        geom_histogram(fill="#6787b7", stat="count") + 
        theme(legend.position="top", legend.direction = "horizontal") + 
        labs(title="Land Cover Group (LCGROUP) on LARGE fields (AREA greather than 20 hectares)", 
             x="Land Cover Group (LCGROUP)") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme 

# large AREA by LCTYPE
ggplot(data=subset(allData, AREA > 20), aes(x=LCTYPE)) + 
        geom_histogram(fill="darkseagreen", stat="count") + 
        theme(legend.position="top", legend.direction = "horizontal") + 
        labs(title="Land Cover Type (LCTYPE) on LARGE fields (AREA greather than 20 hectares)", 
             x="Land Cover Type (LCTYPE)") + 
        coord_flip() + 
        plot_subtitle + 
        plot_caption + 
        plot_theme 


# LCGROUP subsets: Arable, Permanent Crops, Permanent Grassland #### 
table(allData$LCGROUP)
table(allData$LCGROUP, allData$LCTYPE) 

# by LCGROUP (single graph) 
ggplot(allData, aes(x=LCTYPE, fill=LCGROUP)) + 
        geom_histogram(stat="count") + 
        scale_fill_manual(values = myColors) +
        theme(legend.position="top", legend.direction = "horizontal") + 
        coord_flip() + 
        labs(title="Land Cover Type (LCTYPE) by Land Cover Group (LCGROUP)", 
             x="Land Cover Type (LCTYPE)") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme

# by LCGROUP (multiple graphs) 
ggplot(allData, aes(x=LCTYPE, fill=LCGROUP)) + 
        geom_histogram(stat="count") + 
        scale_fill_manual(values = myColors) +
        theme(legend.position="top", legend.direction = "horizontal") + 
        facet_wrap(~LCGROUP) + 
        coord_flip() + 
        labs(title="Land Cover Type (LCTYPE) by Land Cover Group (LCGROUP)", 
             x="Land Cover Type (LCTYPE)") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme 

# by Arable land 
table(allData$LCGROUP == "Arable") 
table(allData$LCGROUP == "Arable", allData$LCTYPE) 

ggplot(data=subset(allData, LCGROUP == "Arable"), aes(x=LCTYPE)) + 
        geom_histogram(stat="count", fill="#6787b7") + 
        theme(legend.position="top", legend.direction = "horizontal") + 
        coord_flip() + 
        labs(title="Land Cover Type (LCTYPE) on ARABLE Land", 
             x="Land Cover Type (LCTYPE)") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme


# by Permanent Crops 
table(allData$LCGROUP == "Permanent Crops") 
table(allData$LCGROUP == "Permanent Crops", allData$LCTYPE) 

ggplot(data=subset(allData, LCGROUP == "Permanent Crops"), aes(x=LCTYPE)) + 
        geom_histogram(stat="count", fill="#00AFBB") + 
        theme(legend.position="top", legend.direction = "horizontal") + 
        coord_flip() + 
        labs(title="Land Cover Type (LCTYPE) on PERMANENT CROPS Land", 
             x="Land Cover Type (LCTYPE)") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme 


# by Permanent Grassland 
table(allData$LCGROUP == "Permanent Grassland") 
table(allData$LCGROUP == "Permanent Grassland", allData$LCTYPE) 

ggplot(data=subset(allData, LCGROUP == "Permanent Grassland"), aes(x=LCTYPE)) + 
        geom_histogram(stat="count", fill="#CC79A7") + 
        theme(legend.position="top", legend.direction = "horizontal") + 
        coord_flip() + 
        labs(title="Land Cover Type (LCTYPE) on PERMANENT GRASSLAND", 
             x="Land Cover Type (LCTYPE)") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme


# VV and VH CROPS PLOTS #### 
# Remove non-crop fields #### 
#   ie rows where LCTYPE = FALW, NETR_NA, WDG  
# FAWL = FALLOW no production 15 January to 15 July (11 rows) 
# NETR_NA = NEW WOODLAND AND FORESTRY (1 row) 
# WDG = OPEN WOODLAND (GRAZED) (8 rows) 

allData <- allData[(allData$LCTYPE != "FALW"), ]
allData <- allData[(allData$LCTYPE != "NETR_NA"), ]
allData <- allData[(allData$LCTYPE != "WDG"), ]
table(allData$LCTYPE) 
table(droplevels(allData$LCTYPE)) 


# Remove useless variables #### 
str(allData)
## we're left with data.frame:	393 obs. of  64 variables 


# make a list of RANGE variables 
rangeVars <- c(grep(pattern="range", names(allData))) 

# create new dataset (newData) excluding useless variables 
newData <- subset(allData, select = -c(GROSS_AREA, X_count, X_sum, X_mean, 
                                       LCgroup, rangeVars)) 
str(newData)
## we're left with data.frame:	393 obs. of  41 variables 


# Create MEANS VV and VH datasets #### 
# ref: https://stackoverflow.com/questions/24561936/grep-to-search-column-names-of-a-dataframe 
# newData = {meanData} + {varData} 
# meanData = {meanVVdata} + {meanVHdata} 
# varData = {varVVdata} + {varVHdata} 


# create variance variables list 
varVars <- c(grep(pattern="varian", names(newData))) # all Variance variables 
varVHvars <- c(grep(pattern="[.]2varian", names(newData)))  # only VH Variance variables 

# create Means-only dataset (allData MINUS Variance variables) 
meanData <- subset(newData, select = -c(varVars)) 
str(meanData) 
## data.frame:	393 obs. of  23 variables 

# create mean VH variables 
meanVHvars <- c(grep(pattern="[.]2mean", names(meanData)))  # only VH Mean variables 

# create mean VV dataset 
meanVVdata <- subset(meanData, select = -c(meanVHvars)) 
str(meanVVdata)
# data.frame:	393 obs. of  14 variables

# create mean VH dataset 
meanVHdata <- subset(meanData, select = c(Id, FID_1, LCGROUP, LCTYPE, AREA, meanVHvars)) 
str(meanVHdata)
# data.frame:	393 obs. of  14 variables 


# Create VARIANCE VV and VH datasets #### 
# create mean variables list 
meanVars <- c(grep(pattern="mean", names(newData))) # all Mean variables 
meanVHvars <- c(grep(pattern="[.]2mean", names(newData)))  # only VH Mean variables 

# create Variables-only dataset (allData MINUS Means variables) 
varData <- subset(newData, select = -c(meanVars)) 
str(varData) 
## data.frame:	393 obs. of  23 variables 

# create variance VH variables 
varVHvars <- c(grep(pattern="[.]2varian", names(varData)))  # only VH Variance variables 

# create variance VV dataset 
varVVdata <- subset(varData, select = -c(varVHvars)) 
str(varVVdata)
# data.frame:	393 obs. of  14 variables

# create variance VH dataset 
varVHdata <- subset(varData, select = c(Id, FID_1, LCGROUP, LCTYPE, AREA, varVHvars)) 
str(varVHdata)
# data.frame:	393 obs. of  14 variables 


# Create Time-Series and Plot VV mean #### 
# draft code by Zarah Pattison, Env. Researcher on ScotCropMap team 

# Stack each set of columns for mean VV
meanVVtime <- cbind(meanVVdata[1:5], stack(meanVVdata[6:14]))
str(meanVVtime)

# Replace the name given to column when stacked
meanVVtime$VVmean <- meanVVtime$values
str(meanVVtime)

# Recode Factor variable of month to Integer 
meanVVtime$ind <- as.integer(meanVVtime$ind)
str(meanVVtime)

# Export stacked dataset and check that it's correct 
#write.csv(meanVVtime, "meanVVtime.csv")

vv_mean_plot <- ggplot(data=meanVVtime, aes(x=ind, y=values, colour=LCTYPE )) +
    geom_line() + 
    theme(legend.position="bottom", legend.direction = "horizontal") + 
#    theme(legend.position="none") + 
    scale_x_discrete(name = "2018", 
                     limits = c("Jan", "Feb", "Mar","Apr","May",
                                "June","July","Aug","Sept")) + 
    labs(title="VV Mean by Month by Land Cover Type", 
         y = "VV mean") + 
    plot_subtitle + 
    plot_caption + 
    plot_theme 

vv_mean_plot

# Create Time-Series and Plot VH mean #### 

# Stack each set of columns for mean VH 
meanVHtime <- cbind(meanVHdata[1:5], stack(meanVHdata[6:14]))
str(meanVHtime)

# Replace the name given to column when stacked
meanVHtime$VVmean <- meanVHtime$values
str(meanVHtime)

# Recode Factor variable of month to Integer 
meanVHtime$ind <- as.integer(meanVHtime$ind)
str(meanVHtime)

# Export stacked dataset and check that it's correct 
#write.csv(meanVHtime, "meanVHtime")

vh_mean_plot <- ggplot(data=meanVHtime, aes(x=ind, y=values, colour=LCTYPE )) +
    geom_line() + 
    theme(legend.position="bottom", legend.direction = "horizontal") + 
#    theme(legend.position="none") + 
    scale_x_discrete(name = "2018", 
                     limits = c("Jan", "Feb", "Mar","Apr","May",
                                "June","July","Aug","Sept")) + 
    labs(title="VH Mean by Month by Land Cover Type", 
         y = "VH mean") + 
    plot_subtitle + 
    plot_caption + 
    plot_theme 

vh_mean_plot

grid.arrange(vv_mean_plot, vh_mean_plot)


# Create Time-Series and Plot VV variance #### 

# Stack each set of columns for variance VV
varVVtime <- cbind(varVVdata[1:5], stack(varVVdata[6:14]))
str(varVVtime)

# Replace the name given to column when stacked
varVVtime$VVvar <- varVVtime$values
str(varVVtime)

# Recode Factor variable of month to Integer 
varVVtime$ind <- as.integer(varVVtime$ind)
str(varVVtime)

# Export stacked dataset and check that it's correct 
#write.csv(varVVtime, "varVVtime")

vv_var_plot <- ggplot(data=varVVtime, aes(x=ind, y=values, colour=LCTYPE )) +
    geom_line() + 
    theme(legend.position="bottom", legend.direction = "horizontal") + 
#    theme(legend.position="none") + 
    scale_x_discrete(name = "2018", 
                     limits = c("Jan", "Feb", "Mar","Apr","May",
                                "June","July","Aug","Sept")) + 
    labs(title="VV Variance by Month by Land Cover Type", 
         y = "VV variance") + 
    plot_subtitle + 
    plot_caption + 
    plot_theme 

vv_var_plot

# Create Time-Series and Plot VH variance #### 
# draft code by Zarah Pattison, Env. Researcher on ScotCropMap team 

# Stack each set of columns for variance VH 
varVHtime <- cbind(varVHdata[1:5], stack(varVHdata[6:14]))
str(varVHtime)

# Replace the name given to column when stacked
varVHtime$VVvar <- varVHtime$values
str(varVHtime)

# Recode Factor variable of month to Integer 
varVHtime$ind <- as.integer(varVHtime$ind)
str(varVHtime)

# Export stacked dataset and check that it's correct 
#write.csv(varVHtime, "varVHtime")

vh_var_plot <- ggplot(data=varVHtime, aes(x=ind, y=values, colour=LCTYPE )) +
    geom_line() + 
    theme(legend.position="bottom", legend.direction = "horizontal") + 
#    theme(legend.position="none") + 
    scale_x_discrete(name = "2018", 
                     limits = c("Jan", "Feb", "Mar","Apr","May",
                                "June","July","Aug","Sept")) + 
    labs(title="VH Variance by Month by Land Cover Type", 
         y = "VH variance") + 
    plot_subtitle + 
    plot_caption + 
    plot_theme 

vh_var_plot

grid.arrange(vv_var_plot, vh_var_plot)


# Plot VV means & vars 
grid.arrange(vv_mean_plot, vv_var_plot) 

# Plot VH means & vars 
grid.arrange(vh_mean_plot, vh_var_plot) 



### End of Exploratory Analysis #### 
# use dev.off() at the end of the file to stop saving to pdf. 
dev.list() 
txtStop()
dev.off() 
