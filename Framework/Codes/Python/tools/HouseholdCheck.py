# -*- coding: utf-8 -*-
"""
# Energy Balance Check

The goal is here to

* Quantify the impact of HR at household level
* Quantify the impact of HR at ARA level

The difference may be explained by lateral connections
"""
from __future__ import print_function
import pandas as pd

if __name__=="__main__":
    c_water = 4179.6 ## J/L*K
    refT = 10 ## °C

    ## Energy Balance Residential (with/without HR)
    FehraltorfClean = "Q:/Abteilungsprojekte/eng/SWWData/BrunoHadengue/PMP_Processes/FehraltorfClean"
    ResDir = "{}/WaterHub/outputFiles/Reference_20190415-20190419".format(FehraltorfClean)
    # dir_noHR = "{}/Reference_20190415-20190419".format(ResDir)  ## Validation Case
    nodesDf = pd.read_excel("{}/Calculations.xlsx".format(FehraltorfClean))
    nodesDf_Alternate = pd.read_excel("{}/Calculations_AlternateReality.xlsx".format(FehraltorfClean))

    # aggDf = pd.DataFrame(columns=['Flow', 'Temperature'])
    # aggDf_Alternate = pd.DataFrame(columns=['Flow', 'Temperature'])
    cumulFlow = 0
    cumulFlow_Alternate = 0
    for node in [40]:
    # for node in [8]:
        print("node {}".format(node))

        # Normal Life
        houses = int(round(nodesDf[nodesDf['Node'] == node]['HousesPerNode']))
        if houses == 0:
            continue

        for house in range(1, houses + 1, 1):
            print("reading house {}...".format(house))
            df = pd.read_csv("{}/{}/FlowTemp_{}_{}.csv.gz".format(ResDir, node, node, house), compression='gzip').loc[0:4*86400]

            cumulFlow += df['der(Wastewater.cumulatedWater)'].sum()

            if house == 1:
                aggDf = df
            else:
                aggDf['Wastewater.cumulatedWaterT'] = (aggDf['der(Wastewater.cumulatedWater)']*aggDf['Wastewater.cumulatedWaterT'] + df['der(Wastewater.cumulatedWater)']*df['Wastewater.cumulatedWaterT'])/(aggDf['der(Wastewater.cumulatedWater)'] + df['der(Wastewater.cumulatedWater)'])
                aggDf['der(Wastewater.cumulatedWater)'] += df['der(Wastewater.cumulatedWater)']

        ## Alternate Reality
        houses = int(round(nodesDf_Alternate[nodesDf_Alternate['Node'] == node]['HousesPerNode']))
        if houses == 0:
            continue

        for house in range(1, houses + 1, 1):
            print("reading house {}...".format(house))
            df_Alternate = pd.read_csv("{}/{}_AlternateReality/FlowTemp_{}_{}.csv.gz".format(ResDir, node, node, house), compression='gzip').loc[0:4*86400]

            cumulFlow_Alternate += df_Alternate['der(Wastewater.cumulatedWater)'].sum()

            if house == 1:
                aggDf_Alternate = df_Alternate
            else:
                aggDf_Alternate['Wastewater.cumulatedWaterT'] = (aggDf_Alternate['der(Wastewater.cumulatedWater)'] * aggDf_Alternate[
                    'Wastewater.cumulatedWaterT'] + df_Alternate['der(Wastewater.cumulatedWater)'] * df_Alternate[
                                                           'Wastewater.cumulatedWaterT']) / (
                                                                  aggDf_Alternate['der(Wastewater.cumulatedWater)'] + df_Alternate[
                                                              'der(Wastewater.cumulatedWater)'])
                aggDf_Alternate['der(Wastewater.cumulatedWater)'] += df_Alternate['der(Wastewater.cumulatedWater)']

        print(aggDf)
        print(aggDf_Alternate)