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
library(ggplot2)        # for plots 
library(lattice)        # for multipanel plots 
library(grid)           # for displaying multiple graphs on same page 
library(gridExtra)      # for displaying multiple graphs on same page 
library(ggsn)           # for displaying multiple graphs on same page

# SET DIRECTORY 
#getwd()
#setwd("/Users/quantoid/Desktop/cropsMap/analysis")

# READ DATA FROM csv FILE #### 
allData<- read.csv("kelso-monthlyzonal-2018-fixed.csv") 


# PLOTS TEMPLATE #### 
plot_subtitle <- labs(subtitle = "Kelso-Jedburgh area") 
plot_caption <- labs(caption = "#ScotCropMap") 
plot_theme <- theme(
        plot.title = element_text(color = "black", size = 12, face = "bold"),
        plot.subtitle = element_text(color = "deepskyblue3"),
        plot.caption = element_text(color = "darkgreen", face = "italic"))


# SAVE ALL PLOTS to PDF file #### 
pdf(file="Kelso_Exploratory_Analysis.pdf")
# use dev.off() at the end of the fie to stop saving to pdf. 


### Start of Exploratory Analysis #### 
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
#table(allData$LCTYPE, allData$AREA <= 10) 

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
#table(allData$LCTYPE, ((allData$AREA > 10) & (allData$AREA < 20)))

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
#table(allData$LCTYPE, allData$AREA > 20) 

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
        geom_histogram(stat="count", fill="#ffba08") + 
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
        geom_histogram(stat="count", fill="#ffba08") + 
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
        geom_histogram(stat="count", fill="#ffba08") + 
        theme(legend.position="top", legend.direction = "horizontal") + 
        coord_flip() + 
        labs(title="Land Cover Type (LCTYPE) on PERMANENT GRASSLAND", 
             x="Land Cover Type (LCTYPE)") + 
        plot_subtitle + 
        plot_caption + 
        plot_theme


### End of Exploratory Analysis #### 
# use dev.off() at the end of the fie to stop saving to pdf. 
dev.off()
