###################################################################
# Built by Natacha Chenevoy, Univeristy of Leeds - September 2017.
# Works on R version 3.4.2

# input: "Lancashire_geotag_tweets.csv"
# ouput: density maps of 4 main towns in Lancashire + general density map of Lancashire
##################################################################

install.packages("sp")
library(sp)
install.packages("maptools")
library(maptools)
install.packages("raster")
library(raster)
install.packages("rgdal")
library(rgdal)
install.packages("ggplot2")
library(ggplot2)
install.packages("plyr")
library(plyr)
install.packages("ggmap")
library(ggmap)

#----------------------------------------------------------------------------------
# Read filtered geotagged tweets from Lancashire
#-------------------------------------------------------------------------------
setwd(choose.dir(caption = "Select folder called Twitter Analysis")) # this does not seem to work on Mac

tweets = read.csv("classified_Lancashire_geotag_tweets.csv") # data is a dataframe at this stage


# remove spam bots when the specific user ID is known
tweets = tweets[tweets$user.id != "37402072" & tweets$user.id != "37402072" & tweets$user.id != "37402072" 
                & tweets$user.id != "37402072" & tweets$user.id != "37402072",]


#----------------------------------------------------------------------------------
# Boundaries of Lancashire (for the Lancashire map only)
#-------------------------------------------------------------------------------

# PFA Lancashire boundary
lanc <- readOGR("./Shapefile","Lancashire")

# fortify: transform a spatial polygon object into a dataframe you can work on and plot on a map
# Basically it shows the lat/long of the polygons on a dataframe
lanc.points = fortify(lanc)

#----------------------------------------------------------------------------------
# Select only HATEFUL geotagged tweets 
#-------------------------------------------------------------------------------

tweets = tweets[tweets$label == 1,]


#----------------------------------------------------------------------------------
# Density map of LANCASHIRE
#-------------------------------------------------------------------------------

load(file="Maps/lancashire.rda")

jpeg('Maps/NewMaps/lancashire.png')

ggmap(lanc.map, extent = "panel", maprange=FALSE) +
  geom_density2d(data = tweets, aes(x = lon, y = lat)) +
  geom_point(data=tweets,aes(x = lon, y = lat), color = "red", alpha = 1/2, size = 2) + 
  stat_density2d(data = tweets, aes(x = lon, y = lat, fill = ..level.., alpha = ..level..),
                 size = 0.01, bins = 16, geom = 'polygon') +
  scale_fill_gradient(low = "green", high = "red") +
  scale_alpha(range = c(0.00, 0.25), guide = FALSE) +
  theme(legend.position = "none", axis.title = element_blank(), text = element_text(size = 12)) +
  geom_polygon(data = lanc.points, aes(x=long,y=lat, group=group), colour = "black", fill =NA)

dev.off()


#----------------------------------------------------------------------------------
# Density map of PRESTON
#-------------------------------------------------------------------------------

load(file="Maps/preston.rda")

jpeg('Maps/NewMaps/preston.png')

ggmap(preston, extent = "panel", maprange=FALSE) +
    geom_density2d(data = tweets, aes(x = lon, y = lat)) +
    geom_point(data=tweets,aes(x = lon, y = lat), color = "red", alpha = 1/2, size = 2) + 
    stat_density2d(data = tweets, aes(x = lon, y = lat, fill = ..level.., alpha = ..level..),
                   size = 0.01, bins = 16, geom = 'polygon') +
    scale_fill_gradient(low = "white", high = "red") +
    scale_alpha(range = c(0.00, 0.25), guide = FALSE) +
    theme(legend.position = "none", axis.title = element_blank(), text = element_text(size = 12))
dev.off()



#----------------------------------------------------------------------------------
# Density map of LANCASTER
#-------------------------------------------------------------------------------


load(file="Maps/lancaster.rda")

jpeg('Maps/NewMaps/lancaster.png')

ggmap(lancaster, extent = "panel", maprange=FALSE) +
  geom_density2d(data = tweets, aes(x = lon, y = lat)) +
  geom_point(data=tweets,aes(x = lon, y = lat), color = "red", alpha = 1/2, size = 2) + 
  stat_density2d(data = tweets, aes(x = lon, y = lat, fill = ..level.., alpha = ..level..),
                 size = 0.01, bins = 16, geom = 'polygon') +
  scale_fill_gradient(low = "white", high = "red") +
  scale_alpha(range = c(0.00, 0.25), guide = FALSE) +
  theme(legend.position = "none", axis.title = element_blank(), text = element_text(size = 12))
dev.off()



#----------------------------------------------------------------------------------
# Density map of BLACKBURN
#-------------------------------------------------------------------------------


load(file="Maps/blackburn.rda")

jpeg('Maps/NewMaps/blackburn.png')

ggmap(blackburn, extent = "panel", maprange=FALSE) +
  geom_density2d(data = tweets, aes(x = lon, y = lat)) +
  geom_point(data=tweets,aes(x = lon, y = lat), color = "red", alpha = 1/2, size = 2) + 
  stat_density2d(data = tweets, aes(x = lon, y = lat, fill = ..level.., alpha = ..level..),
                 size = 0.01, bins = 16, geom = 'polygon') +
  scale_fill_gradient(low = "white", high = "red") +
  scale_alpha(range = c(0.00, 0.25), guide = FALSE) +
  theme(legend.position = "none", axis.title = element_blank(), text = element_text(size = 12))

dev.off()



#----------------------------------------------------------------------------------
# Density map of BLACKPOOL
#-------------------------------------------------------------------------------


load(file="Maps/blackpool.rda")

jpeg('Maps/NewMaps/blackpool.png')

ggmap(blackpool, extent = "panel", maprange=FALSE) +
  geom_density2d(data = tweets, aes(x = lon, y = lat)) +
  geom_point(data=tweets,aes(x = lon, y = lat), color = "red", alpha = 1/2, size = 2) + 
  stat_density2d(data = tweets, aes(x = lon, y = lat, fill = ..level.., alpha = ..level..),
                 size = 0.01, bins = 16, geom = 'polygon') +
  scale_fill_gradient(low = "white", high = "red") +
  scale_alpha(range = c(0.00, 0.25), guide = FALSE) +
  theme(legend.position = "none", axis.title = element_blank(), text = element_text(size = 12))

dev.off()


#----------------------------------------------------------------------------------
# TAILORED LOCATION --> put lat/long
#-------------------------------------------------------------------------------

#lancashire = c(lat = 53.864075, lon = -2.6) # coordinates of the center of the box
#lanc.map = get_map(location = lancashire, zoom = 9, color = "bw")
