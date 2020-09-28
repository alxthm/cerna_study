# Innovation and adaptation to tropical cyclones

## Folder structure

- `code`
  - data processing : run the following files in the right order, to process raw data into a final dataset we can use for our regressions
    - `1-compute_country_dist_to_coastline.R` : Compute, for selected countries, raster files with distances to the coastline. Generated data is in the `data/processed/distance_to_coastline` folder
    - `2-tce_dat_surge_affected_pop.R` : Load the generated coastline distances, and combine them with the spatially explicit TCE-DAT dataset to get improved indicators for pop/assets exposed (e.g. pop/assets located up to 5km from the coast)
    - `3-build_patent_dataset.do` : Combine patent data from Simon into a single Stata dataset with the right indicators (patents for storms, hvi/all, stock/count)
    - `4-make_datasets.py` : Combine the processed pop/assets indicators and patents datasets into a single "storm/patent" dataset at a country-year level, that we can use for our regressions
  - regressions script : file `do_regression.do`
- `data`
  - `raw`
  - `processed`
  - `doc`

## Reproduce results

### Installation

A recent version of R should work (I used R  3.6.0), and the following libraries should be installed prior to running the scripts:
```
sf, readr, tidyverse, raster, rnaturalearth, tmap, rgdal, countrycode, here
```

A recent version of python 3, with the libraries `pandas` and `numpy` installed should work. I used versions 1.0.3 and 1.18.1 respectively (on python 3.8.2).

The regressions made with Stata MP 15.1

### Run the scripts

You can run the data processing scripts in the order, you just need the `root` variable at the beginning of the `3-build_patent_dataset.do` file to the absolute path of your project folder.

You should then be able to run the `do_regression.do` file.
