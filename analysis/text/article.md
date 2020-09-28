# Abstract

short summary of the goal of the study and the findings

# Introduction

Background & context to the paper, definition of concept and terms, outline of key issues, aims and purpose of the paper, thesis statement. Why is this paper needed ?

- What are we studying ?
  - mechanisms of adaptation to climate change
  - role of technological innovation in natural hazard mitigation (reducing damages and losses)
  - in particular tropical cyclones (available data, intensity of events (&frequency?) should increase because of climate change, hits developing/vulnerable countries), but could have been other EM-DAT disasters (floods)
- Limits of current research on the matter ?
  - Mainly look directly at the effects of investment/GDP on reducing damages
  - Not considering/modelling innovation explicitly 
- What is our contribution to the field ?

  - Like [^Miao2017], use patent data as a proxy for technical innovation (new Y02A classification), while also looking at the effects of social learning/past experience
  - Using reference tropical cyclone data (IBTrACS), panel study
  - Use various different indicators (& estimators) for robustness (technological knowledge, experience, and exposition)

# Relevant literature

In the growing field of economics of natural disasters, there are two distinct but related approaches: looking at the economic effects of natural disasters, which can be indirect and long-term, or studying the determinants of their immediate impacts, such as fatalities or direct economic losses [^Cavallo2009].

Although being focused on climate-related disasters, [^Dell2014] reviews past work studying the impact of climatic variables variations (such as temperature, precipitation, or windstorms) on various outcomes (e.g. aggregate economic outcomes, labor productivity, political stability, agriculture productivity, or innovation) using experimental, cross-sectional and panel studies. With a specific focus on the effects of natural disasters on innovation, [^Miao2014] links floods, droughts and earthquakes to certain mitigation technologies and certain patents. Using this data in a panel study of 28 countries, they find that recent and severe events boost risk-mitigating innovation. <u>Other work (from Simon?) studying the impacts of disasters on innovation ?</u>

This paper belongs to the other body of research and studies the determinants of natural disasters impacts, in order to better understand the mechanisms of disaster mitigation and climate adaptation. In the existing literature, income and institutions are usually considered key determinants of natural disaster fatalities and damages, e.g. through inequality, governance, or democracy indicators (<u>todo : check references in Miao2017 : Anbarci et al., 2005; Kahn, 2005; Rashky, 2008; Keefer et al., 2011; Ferreira et al., 2013; Escaleras and Register, 2016</u>).

<u>todo: find references for studies using R&D input data (investment, etc)</u>.

A few recent studies however have used patent data as a proxy for innovation output to assess the role of technological innovation on reducing natural disaster impacts. [^Abdelzaher2020] investigates the impact of both innovation and institutional factors on a climate change vulnerability index, the ND-GAIN index. They find that innovation input (R&D as a % of GDP), regulatory quality and global connectedness can reduce a country's vulnerability index, but they do not find a significant effect of innovation output (patents/GDP)[^abdelzaher-details]. Although not on climate change, [^Miao2017] is the “first study to empirically examine the role of technological change and social learning in disaster mitigation”. Using a cross-sectional model, they find that both technological innovation (measured as a stock of relevant patent counts) and experience (measured as a stock of exposure to past events) have a significant effect on reducing earthquake fatalities. Contrary to previous literature, [^Miao2017] does not use a time-invariant measure for a population's exposure to disasters (e.g. average frequency of events), but an evolving stock variable, arguing that it betters represents perceived risk.

Although they do not consider technological innovation, [^Sadowski2008] study the impact of past exposure to storms on economic damages, in the US. Using an event-level regression model, they find “somewhat fragile” results suggesting that prior hurricanes (at least 10 years before) lead to damage reduction in future ones.

[^abdelzaher-details]: They do a panel study, but with random effects. They support this result by saying that there can be barriers to innovation and refer to [^Adenle2015], which itself argues that absolute innovation is not enough, there needs to be diffusion. <u>Diffusion literature ?</u>

# Modeling

According to the IPCC [^IPCC1] [^IPCC2], disaster risk results from the interaction of *hazard*, *exposure* and *vulnerability* [^disaster-risk]. Similarly, we model impacts from a natural disaster as a function of the potential of the disaster ($\mathit{Disaster Potential}$ — a combination of both the physical intensity of the disaster and the exposed population or assets) and the capacity to cope with the disaster ($\mathit{Adaptive Capacity}$).
$$
\mathit{Impact} = f(\mathit{Disaster Potential}, \mathit{Adaptive Capacity})
$$
In practice, $\mathit{Disaster Potential}$ can be modelled by combining multiple indicators, e.g. the maximum windspeed of the storm and the number of people exposed, or bins with the number of people exposed to different categories of wind.

In this study however, we are interested in the effect of innovation and experience on tropical cyclones impacts. Similarly to [^Miao2017], we model the adaptive capacity of a country as a function of hazard technical and informal knowledge ($\mathit{TK}, \mathit{IK}$) as well as socio-economic characteristics that we use as control variables ($X$). We also call $Storms$ our $\mathit{Disaster Potential}$ variable.
$$
\mathit{Impact} = f(\mathit{Storms}, TK, IK, X)
$$
In order to avoid as much as possible the omitted variable bias and to control for time-invariant country characteristics (e.g. hard-to-observe institutional factors) and across-countries time trends, we choose to do a panel study with country and year fixed effects (<u>Why not country/year fixed effects but no panel data aggregation, event level regression instead?</u>). Therefore, we aggregate the disaster potential variables and the disaster impact variables (fatalities or economic damages) from the storm event level to the country-year level. We also lag our $TK$ and $IK$ variables by one year to avoid endogeneity concerns, as disasters impacts can lead to increased innovation or adaptation measures in the future (<u>ref: miao/simon</u>). Our model becomes
$$
Y_{it} = f(\mathit{Storms}_{it}, \mathit{Patent Stock}_{it-1}, \mathit{Experience Stock}_{it-1}, X_{it}, \mu_i, \theta_t)
$$
where $Y_{it}$ is the impact (either number of deaths or economic damages in \$) from tropical cyclones in country $i$ in year $t$ ; $\mathit{Storms}_{it}$ is the sum of storm potential indicators (e.g. number of people exposed or number of storms) ; $\mathit{Patent Stock_{it-1}}$ (a proxy for $TK$) is the accumulated stock of patents in storm mitigation related technologies at year $t-1$; $\mathit{Experience Stock_{it-1}}$ (a proxy for $IK$) is the accumulated stock of country $i$ past exposure to tropical cyclones, until year $t-1$ ; $X_{it}$ is the additional control variables we consider: $\log(GDPperCapita_{it})$ and $\log(Population_{it})$ ; $\mu_i$ and $\theta_t$ are respectively the country and year fixed effect dummies.

[^disaster-risk]: Disaster risk is also represented “as probability of occurrence of hazardous events or trends multiplied by the impacts if these events or trends occur” [^IPCC2].

# Data and estimation

## Disaster data

We take the disaster impact data from the publicly available EM-DAT database [^emdat]. The EM-DAT database holds records of various mass disasters in the world, from 1900 to the present day. The data comes “from various sources including UN, governmental and non-governmental agencies, insurance companies, research institutes and press agencies”, and includes events that fulfil at least one of the following criteria: 10 or more people were killed ; 100 or more people were affected, injured or homeless ; a declaration by the country of a state of emergency and/or an appeal for international assistance was made ; the event did significant damage [^emdat-about]. Among other disaster types, the database holds more than 4000 storm-related disasters, half of it being tropical storms, the other being extra-tropical, convective and unclassified storms.

For data quantity and availability reasons, we choose to focus on tropical cyclone events and we use the TCE-DAT dataset [^tcedat] to obtain the disaster potential indicators: physical intensity of the cyclone and exposed population or assets. The TCE-DAT dataset is based on the widely used IBTrACS dataset (version v03r09)[^ibtracs], which combines data from numerous meteorological agencies and provides best tracks for more than 7000 tropical cyclones globally, between 1950 and 2015. The tracks consist of the cyclone center coordinates and physical variables with a 6-hourly time step. Using variables such as minimal central pressure, maximum sustained wind speed or radius of maximum winds (not always available) and a wind speed model [^Holland2008], the authors construct estimates of the storm wind footprints, i.e. spatially explicit maximum wind speeds. The authors then combine this data with spatially explicit population and GDP data [^hyde3.2][^geiger-gdp] to obtain spatially explicit exposure data for each event, at a 0.1° resolution. This allows them to compute estimates of the number of people and the total assets exposed to wind speeds above 34, 64 and 96 knots. These thresholds correspond to the Saffir-Simpson hurricane wind scale classification of tropical storms, hurricanes and major hurricanes respectively [^saffir-simpson-damages].

Based on this data and in order to reduce the collinearity between these variables, we create exclusive bins of population and assets exposed to different wind speeds (34 to 64kn., 64 to 96kn. and over 96kn.), for each storm event. Considering the fact that storm surges rather than high winds are the first cause of deaths, at least in the U.S. [^Rappaport2014], we re-construct the exposed population bins but considering only population close to the coastline (up to 5km). While this indicator is highly correlated to the initial one, we expect it to be slightly more relevant to predict the number of fatalities.

Finally, we combine impact data from EM-DAT[^storm-category] with the exposure data constructed from TCE-DAT and we match the storm events of the two datasets by event name and year. Given that our patent data restricts the panel study to 1990 and later, and that the IBTrACS archive is less reliable before 1980, we only consider events between 1980 and 2015. Events prior 1990 are still considered to be able to build stock variables of exposure to past storms. Out of the 3099 EM-DAT registered disasters (including 1637 with a name) and the 3118 TCE-DAT storms (including 2576 with a name), we were able to match 916 storms, across 179 countries. For the few storms that were registered as a single disaster entry in EM-DAT (e.g. two storms hitting the country a few days apart), we choose to sum the exposure indicators, resulting in a total of 896 matched disasters.

<u>Analysis on unmatched storms: different across countries/storm size ? mostly small storms?</u>

For the regression on the number of fatalities, our baseline $\mathit{Storms_{it}}$ indicator consists in the `pop3464_d5` and the `pop96_d5` variables, respectively the number of people close to the coastline (up to 5km) and affected by storm winds between 34-96 knots, or over 96 knots. For the regression on the economic damages, we choose the `assets3464` and the `assets96` variables, respectively the estimated assets exposed to storm winds between 34-96 knots, or over 96 knots. In order to get panel data, for each country $i$ we sum storm indicators for all events over the year $t$, which means that people or assets hit by multiple storms will be counted multiple times (<u>todo: try with max instead of sum?</u>). We choose to use 2 bins of wind speeds to have some granularity while limiting collinearity between these indicators (<u>todo: check that results are the same with 1 or 3 bins</u>). According to [^saffir-simpson], 34-96kn winds will produce “some damage” to “extensive damage” and can already be life-threatening storms, while winds over 96kn will cause “devastating damage”. As an alternative indicator for the storm potential, we also try the variables `evt_count3464` and `evt_count96`, respectively the number of storms with wind speed at landfall between 34-96 knots, or over 96 knots (<u>todo: with or without avg_pop ?</u>).

All this historical disaster data also allows us to construct indicators for $\mathit{Experience Stock}_{it-1}$, the stock of experience and non-technical knowledge (it could be organisational changes, better communication, etc), using past exposure to storms as a proxy. For regressions on both fatalities and economic damages, we construct a stock variable of past fatalities from storms, considering that the more victims the stronger the reaction and the measures for disaster mitigation. Following [^Miao2017], instead of a time-invariant indicator such as the average number of deaths over a year, we use the perpetual inventory method to build our stock variable:
$$
\mathit{Experience Stock Deaths}_{it} = \mathit{Deaths_{it}} + (1-\rho) \mathit{Experience Stock Deaths}_{it-1}
$$
We use $\rho = 0.15$ as the depreciation rate, following [^Miao2017] (<u>todo: try with 0, 0.05, 0.3?, detail fade out periods</u>).

As alternative indicators of past disaster shock, we considered the economic damages instead of the number of people killed, however the high disparity of reported economic losses between countries (in particular due to the U.S.A.) made the results less stable. We also consider the number of storms with windspeed at landfall of at least 64 knots, and we present the results in section *Results*.

[^saffir-simpson-damages]: Although this scale does not account for rain, storm surges and other important factors, Category 1 & 2 storms (with wind speeds between 64 and 96 knots) can be expected to make “some damage” to “extensive damage”, while storms of Category 3 and above (wind speeds over 96 knots) can be expected to make “devastating” to “catastrophic” damage[^saffir-simpson].
[^storm-category]: Although EM-DAT has a TC category, we consider all storms types to have a chance to match events that have no storm type registered, or events that later evolved into hurricanes and may not have been registered as a TC in EM-DAT. In practice, this increased the number of matched events (without duplicates) from 876 to 896.

## Patent data

Similar to [^Miao2017], we choose to use counts of patents with relevant technologies as a measure of technological innovation in storm impact mitigation. Our data comes from the World Patent Statistical Database (PATSTAT), maintained by the European Patent Office (EPO), and we use the new Y02A classification for patents related to “technologies for adaptation to climate change”[^Y02A]. The Y02A classification defines 6 subcategories (Coastal and river protection being one of them) which are themselves divided in numerous items (e.g. “10/14: Sea-walls, surge or tidal barriers” or “10/27: Restoration or protection of coral reefs”)[^Y02A-doc]. All patent offices included in the PATSTAT database and all patents applications (including older ones) are covered by this classification, with one or multiple items being attributed to relevant patents.

Using the Y02A classification, we select a number of items containing technologies relevant to storm impact mitigation, i.e. technologies that will protect people and/or assets against precipitations, flooding, or strong winds (<u>list of examples, or table of all categories we used</u>). We then select patent applications related to at least one of these items (<u>or sum of patents in each category?</u>).

However, as there is significant variance in the value of individuals patents, simply using the count of all patent applications can result in a noisy measure of technological innovation. Similar to [^Dechezlepretre2020], we consider only high-value inventions, defined as inventions for which protection has been sought in more than one country.

Thus we compute $\mathit{Patent Count}_{it}$, the total number of storm impact mitigation inventions[^patent-family] filed in country $i$ during year $t$. This allows us to construct our variable of interest $\mathit{Patent Stock}_{it}$, an indicator of the formal technological knowledge capital in the country, for storm impact mitigation:
$$
\mathit{Patent Stock}_{it} = \mathit{Patent Count}_{it} + \delta \mathit{Patent Stock}_{it-1}
$$
We use $\delta = 0.85$ as the discount factor to capture the obsolescence of older patents (<u>todo: literature references, explain why no diffusion term like Miao, results with</u> $\delta = 0.70,0, etc$).

<u>Countries with reliable enough data: list of selected countries after combining with TCE-DAT</u>

[^patent-family]: We actually count patent families, which are sets of patents protecting the same invention. Most patent families include only one country.

## Other control variables

In addition to the country and year fixed effects, we use $\log(GDP/Capita_{it})$ and $\log(Population_{it})$ as control variables. We take data from (<u>source</u>) for the country GDP/capita, and data from (<u>source</u>) for the total country population.

## Descriptive statistics

Of the panel data

- Max/min/avg/std of evt_count_v64, pop, assets, pat_count by country ?

## Estimation method

Method used (Poisson? Nbin? Zero-inflated? missing data?)

- Do not use Poisson/ZIP, as there is over-dispersion (std 10x mean) so they would be biased and overconfident [^Land1996].
  - "Likelihood-ratio test of alpha=0" given by the command `nbreg`, https://www.stata.com/statalist/archive/2003-10/msg00113.html, as a test for over-dispersion
  - countfit does indicate negbin/zinb to be significantly better
- Nbin: are we using the right command ? https://stats.stackexchange.com/questions/33768/what-is-the-reason-for-differences-between-nbreg-and-glm-with-familynb-in-stat
  - It seems `family(nbin ml)` would be more appropriate, to match `nbreg` and to have a ML estimate of the k parameter instead of setting it to 1, thankfully the results don't seem very different
- ZINB or NegBin ?
  - Can we use countfit results ? AIC/BIC tests indicate "Very strong" evidence of preferring ZINB (diff ~270), Vuong test not adapted [^Wilson2015]
  - we choose neg bin as we don't see a separate process for 0, and we show ZINB in annexes



Doc

- Poisson
  - https://www.stata.com/manuals13/rpoisson.pdf
- NBin
  - https://ncss-wpengine.netdna-ssl.com/wp-content/themes/ncss/pdf/Procedures/NCSS/Negative_Binomial_Regression.pdf
  - https://www.stata.com/manuals13/rnbreg.pdf



# Results

**TODO**

Miao results with earthquakes:

- effects of the variable of interest, in different configurations (estimator, experience stock or fixed event frequency), effect of socio-economic controls (income, health, political rights), with/without separation for developed countries. Also tries with country FE (same results, but not significant)
- effects of adding a foreign knowledge stock variable (as we were looking at the effects of **domestic** knowledge stocks): no effects found, possibly due to multicollinearity

Our results

- Effect >0 (even though not significant?) of exp_stock_count, justification:
  - Justification for *exp_stock_count* not significant [^Anbarci2005]: For earth quakes, finds that frequency effect is <0 in only 2/3 cases, and is not significant
  - On storms [^Sadowski2008] has fragile results, with a negative effect of prior hurricanes landfall (count?), for storms at least 10 years before (and all storms, not major hurricanes only)
  - And [^Neumayer2014] has an interesting result, finding a negative effect of TC propensity (measured as the sum of $windspeed^3$) with a quantile regression, for the 0.5+ higher quantiles of the damage distribution only (i.e storms that did the most damages), but a positive (not significant?) effect at the lower quantiles
- Configurations
  - baseline
  - **Placebo control** : try with a stock of all patents (not just adaptation, not just storms) to make sure it's the effect of specific storm adaptation technologies. 

# Future works

- Method/indicator improvements
  - Use a "better" patent stock indicator, measuring the value of the patent?
  - Combine disaster data with precipitation data (to get a better sense of the flooding), as a better indicator for exposure+sensitivity? or experience ?
  - Re-compute TCE-DAT but with IBTrACS v4 instead of the initially used v3
  - Match "unnamed" storms to have more events matched
  - More precise technology mapping (distinction between patents categories that protect assets or people), or at least try with hazard=Storms only, or hazard=Precipitation only?
- Different approach for missing data? Left-censored model like Miao?
  - find GDP/cap data for Cuba, so we can add the country to the analysis ?
  
- Add other control variables, such as country regulatory quality/corruption level ? Should not affect results if time-invariant, thanks to the fixed effects, but still interesting to see the sign of this predictor
- Study the role of technology transfer across countries ?





# References

[^Miao2017]: Miao, Q. (2017). Technological innovation, social learning and natural hazard mitigation: Evidence on earthquake fatalities. Environment and Development Economics, 22(3), 249–273. https://doi.org/10.1017/S1355770X1700002X 
[^Miao2014]: Miao, Q., & Popp, D. (2014). Necessity as the mother of invention: Innovative responses to natural disasters. *Journal of Environmental Economics and Management*, *68*(2), 280–295. https://doi.org/10.1016/j.jeem.2014.06.003
[^Dell2014]: Dell, M., Jones, B. F., & Olken, B. A. (2014). What do we learn from the weather? The new climate-economy literature. *Journal of Economic Literature*, *52*(3), 740–798. https://doi.org/10.1257/jel.52.3.740
[^Land1996]: LAND, K. C., McCALL, P. L., & NAGIN, D. S. (1996). A Comparison of Poisson, Negative Binomial, and Semiparametric Mixed Poisson Regression Models. *Sociological Methods & Research*, *24*(4), 387–442. https://doi.org/10.1177/0049124196024004001
[^Wilson2015]: Wilson, P. (2015). The misuse of the Vuong test for non-nested models to test for zero-inflation. *Economics Letters*, *127*, 51–53. https://doi.org/10.1016/j.econlet.2014.12.029
[^Abdelzaher2020]: Abdelzaher, D. M., Martynov, A., & Abdel Zaher, A. M. (2020). Vulnerability to climate change: Are innovative countries in a better position? *Research in International Business and Finance*, *51*(November 2018), 101098. https://doi.org/10.1016/j.ribaf.2019.101098
[^Adenle2015]: Adenle, A. A., Azadi, H., & Arbiol, J. (2015). Global assessment of technological innovation for climate change adaptation and mitigation in developing world. *Journal of Environmental Management*, *161*, 261–275. https://doi.org/10.1016/j.jenvman.2015.05.040
[^Anbarci2005]: Anbarci, N., Escaleras, M., & Register, C. A. (2005). Earthquake fatalities: The interaction of nature and political economy. *Journal of Public Economics*, *89*(9–10), 1907–1933. https://doi.org/10.1016/j.jpubeco.2004.08.002
[^Neumayer2014]: Neumayer, E., Plümper, T., & Barthel, F. (2014). *The political economy of natural disaster damage*. https://doi.org/10.1016/j.gloenvcha.2013.03.011
[^Sadowski2008]: Sadowski, N. C., & Sutter, D. (2008). Mitigation motivated by past experience: Prior hurricanes and damages. *Ocean and Coastal Management*, *51*(4), 303–313. https://doi.org/10.1016/j.ocecoaman.2007.09.003
[^Cavallo2009]: Cavallo, E. A., & Noy, I. (2009). The Economics of Natural Disasters: A Survey. *SSRN Electronic Journal*, *86*(1). https://doi.org/10.2139/ssrn.1817217
[^Holland2008]: Holland, G. (2008). A revised hurricane pressure-wind model. *Monthly Weather Review*, *136*(9), 3432–3445. https://doi.org/10.1175/2008MWR2395.1
[^IPCC1]: Cardona, O. D., Van Aalst, M. K., Birkmann, J., Fordham, M., Mc Gregor, G., Rosa, P., … Thomalla, F. (2012). Determinants of risk: Exposure and vulnerability. *Managing the Risks of Extreme Events and Disasters to Advance Climate Change Adaptation: Special Report of the Intergovernmental Panel on Climate Change*, *9781107025*, 65–108. https://doi.org/10.1017/CBO9781139177245.005
[^IPCC2]: Oppenheimer, M., Campos, M., Warren, R., Birkmann, J., Luber, G., O’Neill, B., & Takahashi, K. (2014). IPCC-WGII-AR5-19. Emergent Risks and Key Vulnerabilities. *Climate Change 2014: Impacts, Adaptation, and Vulnerability. Part A: Global and Sectoral Aspects. Contribution of Working Group II to the Fifth Assessment Report of the Intergovernmental Panel on Climate Change*, 1039–1099. https://doi.org/10.1017/CBO9781107415379
[^emdat]: EM-DAT, CRED / UCLouvain, Brussels, Belgium – [www.emdat.be](https://www.emdat.be/) (D. Guha-Sapir)
[^emdat-about]: https://public.emdat.be/about
[^tcedat]: Geiger, T., Frieler, K., & Bresch, D. N. (2018). A global historical data set of tropical cyclone exposure (TCE-DAT). *Earth System Science Data*, *10*(1), 185–194. https://doi.org/10.5194/essd-10-185-2018
[^ibtracs]: Knapp, K. R., Kruk, M. C., Levinson, D. H., Diamond, H. J., & Neumann, C. J. (2010). The international best track archive for climate stewardship (IBTrACS). *Bulletin of the American Meteorological Society*, *91*(3), 363–376. https://doi.org/10.1175/2009BAMS2755.1
[^hyde3.2]: Klein Goldewijk, Dr. ir. C.G.M. (Utrecht University) (2017): Anthropogenic land-use estimates for the Holocene; HYDE 3.2. DANS. https://doi.org/10.17026/dans-25g-gez3
[^geiger-gdp]: Geiger, Tobias; Daisuke, Murakami; Frieler, Katja; Yamagata, Yoshiki (2017): Spatially-explicit Gross Cell Product (GCP) time series: past observations (1850-2000) harmonized with future projections according to the Shared Socioeconomic Pathways (2010-2100). GFZ Data Services. https://doi.org/10.5880/pik.2017.007
[^Y02A]: https://worldwide.espacenet.com/classification?locale=en_EP#!/CPC=Y02A
[^Y02A-doc]: https://www.cooperativepatentclassification.org/cpc/scheme/Y/scheme-Y02A.pdf
[^saffir-simpson]: https://en.wikipedia.org/wiki/Saffir-Simpson_scale
[^Rappaport2014]: Rappaport, E. N. (2014). Fatalities in the united states from atlantic tropical cyclones: New data and interpretation. *Bulletin of the American Meteorological Society*, *95*(3), 341–346. https://doi.org/10.1175/BAMS-D-12-00074.1
[^Dechezlepretre2020]: Dechezlepretre, A., Fankhauser, S., Glachant, M., Stoever, J., & Touboul, S. (2020). Invention and Global Diffusion of Technologies for Climate Change Adaptation. In *Invention and Global Diffusion of* 