from pathlib import Path
import pandas as pd
import numpy as np

project_dir = Path(__file__).resolve().parents[1]
# Column names for initial non-exclusive bins (34+, 64+, 96+)
cols = [f'{exposed}_{v}kn' for exposed in ['pop', 'assets'] for v in [34, 64, 96]]
exposure_names = cols + [c + f'_{d}km' for c in cols for d in [5, 15, 30]]
# Column names for exclusive bins
exclusive_bins = [f'{exposed}{v}' for exposed in ['pop', 'assets'] for v in [34, 64, 96]]
exclusive_bins = exclusive_bins + [c + f'_d{d}' for c in exclusive_bins for d in [5, 15, 30]]

# Files to be loaded
# TCE-DAT raw data set, with indicators at the country-event level (https://doi.org/10.5880/pik.2017.005)
TCE_RAW = 'TCE-DAT_historic-exposure_1950-2015.csv'
# Country-event level indicators with distance to coastline, computed from TCE-DAT spatially explicit dataset (https://doi.org/10.5880/pik.2017.008)
TCE_COASTLINES = 'tce_dat_cl_distances_r_output.csv'
# EM-DAT disaster database
EMDAT_RAW = 'em_dat.xlsx'
# Patent dataset, processed with Stata
PATENT_DATASET = 'patent_dataset.dta'

# Files that will be computed with this script
# Name of the exposure dataset, combining all TCE-DAT indicators, also with distance to coastline
EXPOSURE_DATASET = 'TCE-DAT_historic-exposure_1950-2015_cl_distances.csv'
# Exposure data from TCE-DAT merged with EM-DAT storm impact data
STORM_DATASET = 'emdat_tcedat_merged_all_storm_types.xlsx'
# Final dataset with storm data (exposure+impact) and patent data
FINAL_DATASET = 'final_storm_patent_data.xlsx'
# Dataset with all matches between tcedat/ibtracs events and emdat disasters
ID_MATCH_DATASET = 'emdat_tcedat_id_match.xlsx'


# Main data processing functions
def compute_exposure_dataset():
    #---- 1. Load and merge
    # - TCE-DAT raw data: exposure indicators at country-event level and other storm info (name, v_land, etc)
    # - Our TCE-DAT derived dataset: same, but with additional exposure indicators 
    #   (pop/assets located close to the coastline only), computed in compute_country_dist_to_coastline.R
    # 
    # We make sure our TCE-DAT derived dataset is identical to the original one (except for the additional indicators),
    # and we combine both datasets to have all indicators as well as all storm info data (not present in our derived dataset).
    # This gives us a final exposure dataset derived exclusively from TCE-DAT
    print('1. Constructing the final exposure dataset (derived from TCE-DAT)...')

    # TCE-DAT raw data set, indicators at the country-event level
    df_tce = pd.read_csv(project_dir.joinpath(f'data/raw/{TCE_RAW}'), skiprows=6)
    for v in [34, 64, 96]:
        df_tce.rename(columns={f'{v}kn_pop': f'pop_{v}kn', f'{v}kn_assets': f'assets_{v}kn'}, inplace=True)
    # Indicators combined by us in R, with coastline distances conditions
    df_cl = pd.read_csv(project_dir.joinpath(f'data/processed/{TCE_COASTLINES}'))

    print_sanity_check1(df_tce, df_cl)

    # join the 2 datasets and drop redundant columns
    df_inner = df_tce.join(df_cl.set_index(['IBTrACS_ID', 'ISO3', 'year']), on=['IBTrACS_ID', 'ISO3', 'year'], 
                        lsuffix='_tce', rsuffix='_cl', how='inner')
    df_final = df_inner.drop(columns=[c + '_tce' for c in cols]).rename(columns={c + '_cl': c for c in cols})

    # check that we still have the same number of events
    assert len(df_final) == len(df_tce)
    for c in df_tce.columns:
        assert c in df_final.columns

    # save the merged dataframe
    df_final.to_csv(project_dir.joinpath(f'data/processed/{EXPOSURE_DATASET}'), index=False)
    print('Exposure dataset saved.')


def combine_exposure_emdat():
    #---- 2. Combine our final exposure dataset (derived from TCE-DAT) with EM-DAT data (disaster impact data)
    # We try to match storm events based on storm name and year.
    # We consider 
    # - all TCE-DAT events (tropical cyclones registered in IBTrACS v3, from 1950 to 2015)
    # - all EM-DAT disasters classified as 'Storms', from 1980 to mid-2020. This includes some non-tropical storms, but allows us to match more storm events (as a few tropical cyclones are not classified as such in EM-DAT)
    #
    # Some individual storms in TCE-DAT are registered as a single disaster event in EM-DAT (e.g. if the 2 storms are very close in time)
    # We choose to sum the exposure indicators from the storm events to get an estimate of the disaster exposure indicator.
    print('2. Combining previously computed exposure data with EM-DAT disaster impact data...')

    # Load event exposure and disaster impact datasets
    df_tce = pd.read_csv(project_dir.joinpath(f'data/processed/{EXPOSURE_DATASET}'))
    df_tce = df_tce.rename(columns={'ISO3': 'ISO'})
    df_emdat = pd.read_excel(project_dir.joinpath(f'data/raw/{EMDAT_RAW}'), header=6)
    df_emdat.columns = df_emdat.columns.str.replace(' ', '')
    df_emdat = df_emdat.rename(columns={'TotalDamages(\'000US$)': 'TotalDamages', 'ReconstructionCosts(\'000US$)': 'ReconstructionCosts', 'InsuredDamages(\'000US$)': 'InsuredDamages', 'Year': 'year'})

    # Register events start dates
    df_tce['start_date'] = pd.to_datetime(df_tce.IBTrACS_ID.str.slice(0, 7), format='%Y%j')
    df_tce['year'] = df_tce.start_date.dt.year
    df_tce['month'] = df_tce.start_date.dt.month
    df_tce['day'] = df_tce.start_date.dt.day

    # Consider all storm types, but only years after 1980
    df_emdat = df_emdat[(df_emdat.year >= 1980) & (df_emdat.DisasterType == 'Storm')]

    # Merge storm events and disasters based on country-year and name
    # Doing this in 2 steps allows for more flexibility on name matching: EM-DAT disasters will sometimes be called 
    # 'Typhoon Fanapi' or with 2 names for the same event, e.g. 'Nabi (Jolina/14W)', or for multiple events, 
    #  e.g. 'Eric, Nigel, Odette'. 
    # TCE-DAT events will simply be called 'FANAPI' or 'ERIC', so we combine events/disasters when the TCE-DAT name can be found in 
    # the EM-DAT name.
    #
    # 1) Merge on country, year, without looking at the event name. This will produce many wrong matches
    # that will need to be filtered using event's name
    df = df_emdat.merge(df_tce, on=['ISO', 'year'], suffixes=('', '_tce'))
    df.EventName = df.EventName.astype('str') # remove NaN values
    df[['ISO', 'year', 'EventName', 'TC_name']]
    # 2) Filter rows where ibtracs name is in the em-dat event name: in addition to country/year matching, the names match too.
    match = df.apply(lambda x: x.TC_name.casefold() in x.EventName.casefold(), axis=1)
    df_merged_inner = df[match]

    # Save all EMDAT disaster / ibtracs event matches, before removing duplicates
    df_match_ids = df_merged_inner[['ISO', 'year', 'EventName', 'DisNo', 'TC_name', 'IBTrACS_ID']]
    df_match_ids.to_excel(project_dir.joinpath(f'data/processed/{ID_MATCH_DATASET}'))

    # Handle the duplicates:
    # Multiple TCE-DAT cyclones considered as a single event in EM-DAT (same DisNo), so we add the indicators 
    # (pop/assets exposed) together.
    # 
    # The following command displays the duplicates :
    # df_merged_inner.loc[df_merged_inner.DisNo.duplicated(keep=False), ['ISO', 'year', 'EventName', 'DisNo', 'TC_name', 'IBTrACS_ID']]
    pd.set_option('mode.chained_assignment',None) # Ignore the warning as it works in our case
    is_dup = df_merged_inner.DisNo.duplicated(keep=False)
    df_merged_inner.loc[is_dup, exposure_names] = df_merged_inner.loc[is_dup, ['DisNo']+exposure_names].copy().groupby('DisNo').transform('sum')
    pd.set_option('mode.chained_assignment','warn')
    # Drop the duplicates
    df_merged_inner = df_merged_inner.drop_duplicates(subset='DisNo')

    # Create exclusive bins (34kn - 64kn, 64kn - 96kn, 96+, instead of 34+, 64+, 96+)
    df_merged_inner = compute_exclusive_bins(df_merged_inner)
    # todo: drop the old 34+, 64+, 96+ indicators to avoid confusion

    # df_merged has all df_emdat events, the ones that were merged with tce_dat and the ones that were not. 
    # This is useful to be able to get damages/fatalities for all disasters, or only the ones for which we have exposure data
    # 
    # (We already merged df_emdat to get df_merged_inner, so all df_emdat columns are present in df_merged_inner.)
    df_merged = df_emdat.merge(df_merged_inner, on=df_emdat.columns.tolist(), how='outer')
    df_merged['is_match'] = ~df_merged.v_land_kn.isna()

    # Save the merged data
    df_merged.to_excel(project_dir.joinpath(f'data/processed/{STORM_DATASET}'), index=False)

    print(f'Data merged. Out of {len(df_tce[df_tce.start_date.dt.year>=1980])} TCE-DAT storms and {len(df_emdat[df_emdat.year<=2015])} EM-DAT disasters, we were able to match :')
    print(f'{len(df_match_ids)} ibtracs/tcedat events with a EMDAT disaster')
    print(f'{len(df_merged_inner)} disasters (after regrouping events that appear in the same disaster)')


def match_with_patstat():
    # 3. Match patent data from PATSTAT (Y02A classification) with countries where we have storm disaster data (from EM-DAT and TCE-DAT)
    print('3. Merging patent data (at country-year level) with storm disaster data (impact data, and exposure data when available, also aggregated to country-year level)...')
    df_storms = pd.read_excel(project_dir.joinpath(f'data/processed/{STORM_DATASET}'))
    df_patents = pd.read_stata(project_dir.joinpath(f'data/processed/{PATENT_DATASET}'))

    # All EM-DAT events, whether or not they were matched with TCE-DAT
    df_storms['event_count'] = 1
    # All recorded events that were merged with TCE-DAT
    # Potentially helpful to reduce the reporting bias of developed countries reporting more events, 
    # here this is a physical min wind speed criteria
    df_storms['event_count_v34'] = 0
    df_storms.loc[df_storms.v_land_kn >= 34, 'event_count_v34'] = 1
    # Category 1+ hurricane on saffir simpson scale (strictly speaking, only valid for western hemisphere cyclones..)
    df_storms['event_count_v64'] = 0
    df_storms.loc[df_storms.v_land_kn >= 64, 'event_count_v64'] = 1
    # Category 3+ hurricanes
    df_storms['event_count_v96'] = 0
    df_storms.loc[df_storms.v_land_kn >= 96, 'event_count_v96'] = 1

    # Sum all storm event indicators to the country-year level
    df = df_storms.groupby(['ISO', 'year']).sum().reset_index()
    df = df.rename(columns={'ReconstructionCosts(\'000US$)': 'ReconstructionCosts', 'InsuredDamages(\'000US$)': 'InsuredDamages'})
    # Keep variables of interest and exclusive bins of exposure data (event_counts bins however are not exclusive)
    df = df[['ISO', 'year', 'TotalDeaths', 'TotalDamages']
            + exclusive_bins + ['event_count', 'event_count_v34', 'event_count_v64', 'event_count_v96']]
    # Compute indicators considering only events that were matched with TCE-DAT data
    df_match_only = df_storms.loc[df_storms.is_match, ['ISO', 'year', 'TotalDeaths', 'TotalDamages', 'event_count']]
    df_match_only = df_match_only.groupby(['ISO', 'year']).sum().reset_index()
    df = pd.merge(df, df_match_only, on=['ISO', 'year'], how='left', suffixes=('', '_match_only'))

    df = merge_df(df_patents, df)

    df.to_excel(project_dir.joinpath(f'data/processed/{FINAL_DATASET}'))


# Helper functions
def merge_df(df_p, df_s):
    # Merge the patent dataset with the storm dataset (already aggregated to country-year level)
    print(f'Patent data: {len(df_p)} country-years, {len(df_p.ISO.unique())} countries')
    print(f'Storm data: {df_s.event_count.sum()} events, {len(df_s)} country-years, {len(df_s.ISO.unique())} countries')

    # Make sure the 2 datasets have the same time span (1980-2015)
    print(f'Restricting storm data ({df_s.year.min()}-{df_s.year.max()}) to patent data time span '
            f'({df_p.year.min()}-{df_p.year.max()})')
    df_s = df_s[(df_s.year <= df_p.year.max()) & (df_s.year >= df_p.year.min())]

    # Only keep countries where we have both patent data (i.e. country is in the df_p dataframe) and at 
    # least one storm event recorded in TCE-DAT (i.e. country is in the df_s dataframe)
    df_s = df_s[df_s.ISO.isin(df_p.ISO.unique())]
    df_p = df_p[df_p.ISO.isin(df_s.ISO.unique())]

    # Merge between 2 datasets. Left merge to have all years thanks to the patent dataset, even when we don't have storm data
    df = pd.merge(df_p, df_s, on=['ISO', 'year'], how='left')
    print('After merging:')
    print(f'Countries with patent data and at least 1 storm event: {len(df.ISO.unique())}')
    print(f'Country-years total: {len(df)}, with at least 1 storm event: {df.event_count.count()}')
    print(f'Total events kept: {df.event_count.sum()}')
    return df


def print_sanity_check1(df_tce, df_cl):
    # Join the 2 datasets in different ways to see if we missed events somewhere
    df_left = df_tce.join(df_cl.set_index(['IBTrACS_ID', 'ISO3']), on=['IBTrACS_ID', 'ISO3'], lsuffix='_tce', rsuffix='_cl')
    df_right = df_tce.join(df_cl.set_index(['IBTrACS_ID', 'ISO3']), on=['IBTrACS_ID', 'ISO3'], lsuffix='_tce', rsuffix='_cl', how='right')
    df_outer = df_tce.join(df_cl.set_index(['IBTrACS_ID', 'ISO3', 'year']), on=['IBTrACS_ID', 'ISO3', 'year'], 
                            lsuffix='_tce', rsuffix='_cl', how='outer')
    df_inner = df_tce.join(df_cl.set_index(['IBTrACS_ID', 'ISO3', 'year']), on=['IBTrACS_ID', 'ISO3', 'year'], 
                        lsuffix='_tce', rsuffix='_cl', how='inner')

    print('Check that we roughly have the same events (the following numbers should be 0 or small)')
    print(f'- Country-events in TCE-DAT, but not computed by us: {len(df_left) - len(df_inner)}')
    # should be 2 from 1 very small country-event: http://ibtracs.unca.edu/index.php?name=v04r00-1957245N13339
    print(f'- Country-events computed by us, but not in TCE-DAT: {len(df_right) - len(df_inner)}')
    print(f'- Country-events matched : {len(df_inner)} / {len(df_outer)}')

    # compute errors between the 2 datasets
    df_tmp = df_inner.drop(columns=['NatCatSERVICE_ID', 'genesis_basin', 'countries_affected', 'v_land_SI'])
    for c in cols:
        df_tmp[c + '_error'] = df_tmp[c + '_cl'] - df_tmp[c + '_tce']
    df_error = df_tmp[['year', 'IBTrACS_ID', 'ISO3'] + [c + '_error' for c in cols]]
    print('The following mean and max errors should be quite small:')
    print(df_error.mean())
    print(df_error.max())


def compute_exclusive_bins(df):
    for exposed in ['pop', 'assets']:
        df[f'{exposed}34'] = df[f'{exposed}_34kn'] - df[f'{exposed}_64kn']
        df[f'{exposed}64'] = df[f'{exposed}_64kn'] - df[f'{exposed}_96kn']
        df[f'{exposed}96'] = df[f'{exposed}_96kn']
        
        # Same for pop/assets below a certain distance from the coastline
        for d in [5, 15, 30]:
            df[f'{exposed}34_d{d}'] = df[f'{exposed}_34kn_{d}km'] - df[f'{exposed}_64kn_{d}km']
            df[f'{exposed}64_d{d}'] = df[f'{exposed}_64kn_{d}km'] - df[f'{exposed}_96kn_{d}km']
            df[f'{exposed}96_d{d}'] = df[f'{exposed}_96kn_{d}km']

    return df


# todo: analysis, summary tables and plots of merged TCE-DAT/EM-DAT data


if __name__ == "__main__":
    compute_exposure_dataset()
    combine_exposure_emdat()
    match_with_patstat()
