# Load all storm footprints from spatially explicit TCE-DAT, and combine it with distances to coastline data
# to compute storm exposure indicators
library(readr)
library(raster)
library(tidyverse)
library(here)

project_root = here()
data_root = sprintf("%s/data/raw/TCE-DAT_single_events_historical/TC_data",
                    project_root)

# Load coastline distances
# ----
cl_distance_files = dir(
  path = sprintf("%s/data/processed/distance_to_coastline", project_root),
  pattern = "*.tif"
)
cl_dist_rasters = list()
countries = c()
for (f in cl_distance_files) {
  iso = str_split(f, "[.]")[[1]][1]
  countries = c(countries, iso)
  # Load the country distances to coastline
  r_c = raster(sprintf("%s/data/processed/distance_to_coastline/%s.tif", project_root, iso))
  # seems to speed up computations ?
  r_c = extend(r_c, extent(r_c) + 0.2, value = NA)
  cl_dist_rasters[[iso]] = r_c
}
print("Loaded coastline distance raster files")

# Load storm footprint files
# ----
files = dir(
  path = data_root,
  pattern = "*.csv"
)
print(sprintf("Extracting indicators for %d storm events", length(files)))

# Create empty dataframe
# ----
df = data.frame(
  year = integer(),
  IBTrACS_ID = character(),
  ISO3 = character(),
  pop_34kn = double(),
  pop_64kn = double(),
  pop_96kn = double(),
  assets_34kn = double(),
  assets_64kn = double(),
  assets_96kn = double(),
  pop_34kn_5km = double(),
  pop_64kn_5km = double(),
  pop_96kn_5km = double(),
  assets_34kn_5km = double(),
  assets_64kn_5km = double(),
  assets_96kn_5km = double(),
  pop_34kn_15km = double(),
  pop_64kn_15km = double(),
  pop_96kn_15km = double(),
  assets_34kn_15km = double(),
  assets_64kn_15km = double(),
  assets_96kn_15km = double(),
  pop_34kn_30km = double(),
  pop_64kn_30km = double(),
  pop_96kn_30km = double(),
  assets_34kn_30km = double(),
  assets_64kn_30km = double(),
  assets_96kn_30km = double()
)


# Iterate through the files
# ----
compute_exposure_values = function(df, r, iso, min_cl_dist) {
  #' r : raster of the storm footprint for the country `iso`.
  #' A column for coastline distances (named `iso`) is required if we want to select only
  #' people close to the coast (i.e if `min_cl_dist` is not -1).
  
  # minimum windspeed
  for (v in c(34, 64, 96)) {
    # select relevant cells
    if (min_cl_dist == -1)
      r_vd = r[r$windspeed > v, drop = FALSE]
    else
      r_vd = r[(r$windspeed > v) & (r[[iso]] < d), drop = FALSE]
    
    # sum exposed assets/ppl for the event
    if (length(r_vd) > 0) {
      names(r_vd) = names(r)
      sum = cellStats(r_vd, stat = 'sum')
      assets_vd = sum["exposed_assets"]
      people_vd = sum["exposed_pop"]
    }
    else {
      assets_vd = 0.
      people_vd = 0.
    }
    
    # add it to the dataframe
    if (min_cl_dist == -1) {
      assets_str = sprintf("assets_%dkn", v)
      people_str = sprintf("pop_%dkn", v)
    } else {
      assets_str = sprintf("assets_%dkn_%dkm", v, min_cl_dist)
      people_str = sprintf("pop_%dkn_%dkm", v, min_cl_dist)
    }
    df[nrow(df), assets_str] = assets_vd
    df[nrow(df), people_str] = people_vd
  }
  return(df)
}

for (file in files) {
  ibtracs_id = str_split(file, "_")[[1]][1]
  year = strtoi(substr(ibtracs_id, start = 1, stop = 4))
  
  # Load TCE-DAT windspeed and ppl/assets exposed
  df_event = read_csv(
    sprintf(
      "%s/%s",
      data_root,
      file
    ),
    col_types = cols() # to remove the parsing message
  )
  
  affected_countries = unique(df_event$ISO)
  for (iso in affected_countries) {
    print(sprintf("%d %s %s...", year, iso, ibtracs_id))
    
    # Get country exposure as a multi layer raster
    # -> fix the order to lon/lat, and drop the ISO column
    y = data.frame(df_event[df_event$ISO == iso, c(3:2, 4:6)])
    # Workaround to load data
    # https://stackoverflow.com/questions/63244491/rasterfromxyz-warning-data-length-is-not-a-sub-multiple-or-multiple-of-the-numb/63245731#63245731
    r_event = rasterFromXYZ(y[, 1:2], res = 0.1)
    r_event = rasterize(y[, 1:2], r_event, field = y[, 3:5])
    crs(r_event) = "+init=epsg:4326"
    
    df = df %>% add_row(year = year,
                        IBTrACS_ID = ibtracs_id,
                        ISO3 = iso)
    
    # Compute regular exposures for all countries
    df = compute_exposure_values(
      df = df,
      r = r_event,
      iso = iso,
      min_cl_dist = -1
    )
    
    # Compute coastline exposures for countries with coastline distance raster data
    if (iso %in% countries) {
      # Get the country distances to coastline and combine it with the storm footprint raster
      r_cl_dist = cl_dist_rasters[[iso]]
      r_event_with_cl = raster::stack(r_event, resample(r_cl_dist, r_event))
      for (d in c(5, 15, 30)) {
        # maximum distance to the coast
        df = compute_exposure_values(
          df = df,
          r = r_event_with_cl,
          iso = iso,
          min_cl_dist = d
        )
      }
    }
    else {
      print(sprintf(
        "Warning! no coastline data for country %s, event %s",
        iso,
        ibtracs_id
      ))
    }
  }
}

write_csv(df, sprintf("%s/data/processed/tce_dat_cl_distances_r_output.csv", project_root))

print(
  sprintf(
    "All done! Computed exposure indicators for %d country-events",
    nrow(df),
  )
)
