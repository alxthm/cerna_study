# Compute, for selected countries, individual raster files with distance to the coast (in km)
# To make computations quicker, only consider points of interest, i.e points 
# that are not too far from the coast (~1°, ~100km+)
#
# Inspired from https://dominicroye.github.io/en/2019/calculating-the-distance-to-the-sea-in-r/
# ---

library(sf)
library(raster)
library(rnaturalearth)
library(tmap)
library(rgdal)
library(countrycode)
library(here)

project_root = here()
#countries = c("AUS", "CAN", "CHN", "DOM", "HND", "JPN", "KOR", "MEX", "NIC", "PHL", "SLV", "USA", "VNM")
# All the countries with at least one event in TCE-DAT
countries = c('ABW', 'AIA', 'AND', 'ANT', 'ASM', 'ATG', 'AUS', 'BGD', 'BHS',
              'BLZ', 'BRA', 'BRB', 'BRN', 'CAN', 'CHN', 'COL', 'COM', 'CPV',
              'CRI', 'CUB', 'DMA', 'DOM', 'DZA', 'ESP', 'FJI', 'FRA', 'FRO',
              'GBR', 'GIN', 'GLP', 'GNB', 'GRD', 'GTM', 'HKG', 'HND', 'HTI',
              'IDN', 'IMN', 'IND', 'IRL', 'IRN', 'ISL', 'JAM', 'JPN', 'KHM',
              'KNA', 'KOR', 'LAO', 'LCA', 'LKA', 'MAR', 'MDG', 'MEX', 'MMR',
              'MOZ', 'MSR', 'MTQ', 'MUS', 'MWI', 'MYS', 'MYT', 'NCL', 'NIC',
              'NOR', 'NZL', 'OMN', 'PAK', 'PAN', 'PHL', 'PNG', 'PRI', 'PRK',
              'PRT', 'REU', 'RUS', 'SAU', 'SGP', 'SLB', 'SLV', 'SOM', 'SPM',
              'TCA', 'THA', 'TLS', 'TON', 'TTO', 'TWN', 'TZA', 'USA', 'VCT',
              'VEN', 'VIR', 'VNM', 'VUT', 'WSM', 'YEM', 'ZAF', 'ZWE')
res = 0.1  # lat/lon °

log_msg = function(s) {
  print(sprintf("[%s] %s", Sys.time(), s))
}

for (iso in countries) {
  if (iso == "USA")
    country = "United States of America"
  else
    country = countrycode(iso, origin="iso3c", destination="country.name")
  
  if (is.na(country)) {
    print(country)
    log_msg(sprintf("Country with ISO code %s not found, skipping", iso))
    next
  }
  
  log_msg(country)
  
  # ---- 
  # Create point grid and load coastline
  country_coastline = tryCatch(ne_countries(scale = 10, country = country, returnclass = "sf"), error=function(e) NA)
  if (is.na(country_coastline)) {
    log_msg(sprintf("Borders for country %s not found, skipping", country))
    next
  }
    
  # slightly higher resolution to avoid problems after when rasterizing
  # also, use full extent, not just the points inside of the country
  grid = st_make_grid(st_as_sfc(st_bbox(country_coastline)), cellsize = res * 0.9, what = "centers")
  # increase a little the spatial extent
  ext = extent(as(grid, "Spatial")) + 10 * res
  # from polygon shape to line
  country_coastline = st_cast(country_coastline, "MULTILINESTRING")
  
  # ----
  # Filter and keep points close to the coastline
  # Use Euclidean distance for quick (but approximate) results
  dist = st_distance(country_coastline, grid, which="Euclidean")
  df = data.frame(dist = as.vector(dist), st_coordinates(grid))
  df = df[df$dist < 1,]
  # convert the points to a spatial object class sf
  grid = st_as_sf(df, coords = c("X", "Y")) %>%
    st_set_crs("+init=epsg:4326")
  
  # ----
  # Compute exact distances
  log_msg(sprintf("Computing distances for %d points...", nrow(grid)))
  dist = st_distance(country_coastline, grid)
  # this time, result is in meter, so we convert it to km
  df = data.frame(dist = as.vector(dist)/1000, st_coordinates(grid))
  # convert the points to a spatial object class sf
  dist_sf = st_as_sf(df, coords = c("X", "Y")) %>%
    st_set_crs("+init=epsg:4326")
  log_msg("Ok!")
  
  # ----
  # Convert to a raster
  r <- raster(resolution = res, ext = ext, crs = "+init=epsg:4326")
  dist_raster <- rasterize(dist_sf, r, "dist", fun = mean)
  
  writeRaster(dist_raster, sprintf("%s/data/processed/distance_to_coastline/%s.tif", project_root, iso), overwrite=TRUE)
}

log_msg("All done!")

