###############################################################################

# Built by Natacha Chenevoy, univeristy of Leeds - September 2017.
# Works on R version 3.4.2
# Works on Windows

# Finds the tweets whose coordinates fall within Lancashire and save as a new csv file 

# input: "Lancashire_all_tweets.csv" (the name is important), the file comes from the Twitter API
# input: "Shapefile/Lancashire". Shapefile of Lancashire Police Force Area boundary
# input: "Towns_List.csv". List of towns in the UK, sorted by county

# output: "Lancashire_geotag_tweets.csv"

###############################################################################

# Install packages
list.of.packages <- c("rgdal", "maptools", "ggplot2", "plyr", "utils" )
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

library(rgdal)
library(maptools)
library(ggplot2) # for fortify function
library(plyr)
library(utils)


# -----------------------------------------------------------------
# Import tweets within Lancashire boundary box - csv file #
# -----------------------------------------------------------------


#setwd(choose.dir(caption = "Select project folder called Twitter Analysis")) # This step does not seem to work on Mac
tweets = read.csv("Lancashire_all_tweets.csv", header = TRUE, encoding = "UTF-8") # data is a dataframe at this stage

###############################################################################
######################      GEOTAGGED TWEETS      #############################
###############################################################################

#----------------------------------------------------------
# Select only geotagged tweets
#----------------------------------------------------------

geo_tweets = tweets[which(!is.na(tweets$lat)),]

# ----------------------------------------------------------
# PFA Lancashire boundary shapefile
# -----------------------------------------------------------

lanc <- readOGR("./Shapefile","Lancashire")

# fortify: transform a spatial polygon object into a dataframe you can work on and plot on a map
# Basically it shows the lat/long of the polygons on a dataframe
lanc.points = fortify(lanc)

#----------------------------------------------------------
# Select only geotagged tweets WITHIN Lancashire boundary
#----------------------------------------------------------

new_subset = geo_tweets

# get boundaries of Lancashire
pol_x = lanc.points$lon
pol_y = lanc.points$lat

list_Lanc = vector()
for (i in 1:dim(geo_tweets)[1]) {
  
  # get lat/lon of the tweet
  lat = geo_tweets$lat[i]
  lon = geo_tweets$lon[i]
  
  # check the tweet is within boundaries of Lancashire
  r = point.in.polygon(lon, lat, pol_x, pol_y)
  
  if (r != 0) {
    # if tweet in lancashire
    #outliers = rbind(outliers, data.frame(lat = lat, lon = lon, row = i))
    list_Lanc = c(list_Lanc, TRUE)
  }
  
  else {
    
    list_Lanc = c(list_Lanc, FALSE)
  }
}

# remove tweets that are not in Lancashire
new_subset$geotagInLanc = list_Lanc
new_subset = new_subset[new_subset$geotagInLanc == TRUE,]

# ---------- WRITE CSV FILE OF GEOTAGGED LANCASHIRE TWEETS ------------
write.csv(new_subset, "Lancashire_geotag_tweets.csv")
#----------------------------------------------------------------------


###############################################################################
######################      HOME TOWN LOCATION TWEETS      ####################
###############################################################################

#----------------------------------------------------------
# Select only tweets with home town location 
#----------------------------------------------------------
town_tweets = tweets[which(!is.na(tweets$place.full_name)),]

#----------------------------------------------------------
# Get the town and the country for tweets
#----------------------------------------------------------
get_town <- function(value) {
  vec = unlist(strsplit(value, "_"))
  return(vec[1])
}

get_country <- function(value) {
  vec = unlist(strsplit(value, "_"))
  return(vec[length(vec)])
}

df2 = town_tweets

# transform factor into string
df2$place.full_name <- as.character(df2$place.full_name)

# extract the town and the country the tweet is from
df2$town = lapply(df2$place.full_name, get_town)
df2$country = lapply(df2$place.full_name, get_country)

# select only tweets in "England" or "UK" 
# (Despite the boundary box, some tweets were from outside of Lancashire)
# The white space at the beginning of the contry name had to be kept at this stage
# to circumvent the non UTF-8 character in country names (n of Espana), as trimws() does not support it.
df2 = df2[(df2$country == " England") | (df2$country == " United Kingdom"),]

# trim white space 
df2$country = trimws(df2$country)

#----------------------------------------------------------
# Open the list of towns in Lancashire
#----------------------------------------------------------
towns = read.csv("Towns_List.csv", sep = ";")

#----------------------------------------------------------
# Get tweets with home town in Lancashire (UK)
#----------------------------------------------------------
towns_lanc = towns$Town[towns$County ==  "Lancashire"]
df2_subset = df2[which(df2$town %in% towns_lanc),]

# transform these two columns to be able to save as csv (list --> string)
df2_subset$town = as.character(df2_subset$town)
df2_subset$country = as.character(df2_subset$country)

# ---------- to csv ----------------
write.csv(df2_subset, "Lancashire_towns_tweets.csv")



