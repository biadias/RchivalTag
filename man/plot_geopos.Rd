

\name{plot_geopos}
\alias{plot_geopos}
\title{
plot geolocation estimates derived from archival tagging data
}
\description{
In case that geolocations are provided by csv-files or data frames, line and scatter plots are implemented.
In case of ncdf-files, generated by the \href{http://my.wildlifecomputers.com/}{Wildlife Computers-data portal}, are selected, surface probability maps are illustrated. The latter procedure is based on the R-code given in the \href{http://wildlifecomputers.com/wp-content/uploads/manuals/Location-Processing-User-Guide.pdf}{location processing user guide} by \href{http://wildlifecomputers.com/}{Wildlife Computers}.
}
\usage{
plot_geopos(file, pos, xlim, ylim, 
            prob_lim=.75, pal="jet", alpha=70, type="p", pch=19, add=FALSE, ...)
}
 

\arguments{
\item{file}{
path and file name of \code{.csv} or \code{.nc}-file.
}

\item{pos}{
alternative \link{data.frame} containing horziontal position records (allowed column names are 'Most.Likely.Longitude', 'Longitude' or 'Lon' and 'Most.Likely.Latitude', 'Latitude' or 'Lat', respectively.
}


%\item{v_area}{
%Character string used as a short key by the \link{oceanmap}-package to identify region (limits) to be plotted. See   \link{region_definitions} for existing for region definitions and use add.region to define new ones.
%}

\item{xlim, ylim}{
Numeric vector, defining the limts of the x and y-axes.
}

\item{prob_lim}{
in case that a netcdf-file (.nc) is selected, the value defines the limit of the probability surfaces in \% (By default 75\%). Otherwise ignored.
}

\item{pal}{
  color map to be plotted in case of polygon (.nc-files) or scatter plots (default is the 'jet'-colormap). See \link{cmap} for pre-installed color maps. Note that tracking data with constant time steps is being assumed in the color assignment. To verify this, a \link{data.frame} containing the colors at each time steps will be returned for polygon and scatter plots.
}


\item{alpha}{transparency of polygons and dots to be plotted in percent (By default 70\%).
}

\item{type}{
character string giving the type of plot desired. The following values are possible, for details (By default "p" for points, but "l" for lines is also implemented).
}

\item{pch}{
dot-type to be plotted if 'points' have been selected (By default '19' for solid dots).
}

\item{add}{
whether the a the plot should be added to an existent figure (default is \code{FALSE})
}

\item{\dots}{
additional arguments to be passed to \link{plot}.
}

}



\seealso{\link{plotmap}, \link{plot_DepthTS}, \link{hist_tat}, \link{hist_tad}} 


\author{
Robert K. Bauer
}

\examples{
## example 1a) line plot from csv-file:
csv_file <- system.file("example_files/15P1019-104659-1-GPE3.csv",package="RchivalTag")
plot_geopos(csv_file, type='l', add=FALSE) ## show tracks as line plot

## example 1b) scatter plot from csv-file on existing landmask:
require('oceanmap')
plotmap('lion') ## use keyword to derive area limits
plot_geopos(csv_file, add=TRUE) ## show tracks as scatter plot

## example 1c) scatter plot from csv-file on existing landmask:
require('oceanmap')
plotmap('lion') ## use keyword to derive area limits
pos <- read.csv(csv_file, header = TRUE, sep = ",", skip = 5)
plot_geopos(file="",pos=pos, add=TRUE) ## show tracks as scatter plot


## example 2) probability surfaces of horizontal tracks from nc-file:
## this can take some time as it inlcudes time consuming data processing
nc_file <- system.file("example_files/15P1019-104659-1-GPE3.nc",package="RchivalTag") 
# plot_geopos(nc_file)

}

