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
from matplotlib import pyplot as plt
from swmmtoolbox_SWMMHEAT_NEWVERSION import extract
# from swmmtoolbox_SWMMHEAT import extract

if __name__=="__main__":
    c_water = 4179.6 ## J/L*K
    refT = 0 ## °C


    ## Energy Balance Residential (with/without HR)
    # workingDir = "Q:/Abteilungsprojekte/eng/SWWData/SWMM-HEAT/Framework_template/Scenarios/stitched"
    workingDir = 'C:/Users/hadengbr/04_Programming/tmp'

    noHR = "{}/SWMM-HEAT/FullNetwork_Reference.out".format(workingDir)
    HR = "{}/SWMM-HEAT/FullNetwork_PHR_1_100.out".format(workingDir)
    # noHR = "{}/ReferenceFullNetwork_ReferenceMINUHET_ReferencePC_Reference_20190302-20190316/OUTPUT/FullNetwork.out".format(workingDir)
    # HR = "{}/ReferenceFullNetwork_ReferenceMINUHET_ReferencePC_PHR_1_100_20190302-20190316/OUTPUT/FullNetwork.out".format(workingDir)


    df_noHR = pd.DataFrame()
    df_HR = pd.DataFrame()
    print('extracting noHR...')
    df_noHR = extract(noHR, ['node', 'Node_1', 'Total_inflow'])
    df_noHR = pd.concat([df_noHR, extract(noHR, ['node', 'Node_1', 'wtemperature'])], axis=1, sort=False)
    print('extracting HR...')
    df_HR = extract(HR, ['node', 'Node_1', 'Total_inflow'])
    df_HR = pd.concat([df_HR, extract(HR, ['node', 'Node_1', 'wtemperature'])], axis=1, sort=False)

    # Processing
    df_noHR_dry = df_noHR.resample('1S').bfill().loc["2019-03-04 00:00:00":"2019-03-09 00:00:00"]
    df_HR_dry = df_HR.resample('1S').bfill().loc["2019-03-04 00:00:00":"2019-03-09 00:00:00"]

    df_noHR_wet = df_noHR.resample('1S').bfill().loc["2019-03-11 00:00:00":"2019-03-16 00:00:00"]
    df_HR_wet = df_HR.resample('1S').bfill().loc["2019-03-11 00:00:00":"2019-03-16 00:00:00"]

    print(df_noHR_dry, df_noHR_wet)

    # (df_noHR_dry['node_Node_1_Total_inflow'] * (df_noHR_dry['node_Node_1_wtemperature'] - refT)).plot(label='no_HR')
    # (df_HR_dry['node_Node_1_Total_inflow'] * (df_HR_dry['node_Node_1_wtemperature'] - refT)).plot(label='HR')
    # plt.legend()
    # plt.show()
    #
    # (df_noHR_wet['node_Node_1_Total_inflow'] * (df_noHR_wet['node_Node_1_wtemperature'] - refT)).plot(label='no_HR')
    # (df_HR_wet['node_Node_1_Total_inflow'] * (df_HR_wet['node_Node_1_wtemperature'] - refT)).plot(label='HR')
    # plt.legend()
    # plt.show()

    # Dry Period
    totalHeat_noHR_dry = (df_noHR_dry['node_Node_1_Total_inflow'] * (df_noHR_dry['node_Node_1_wtemperature'] - refT)).sum() * c_water / 3600000
    totalHeat_HR_dry = (df_HR_dry['node_Node_1_Total_inflow'] * (df_HR_dry['node_Node_1_wtemperature'] - refT)).sum() * c_water / 3600000

    print("DRY")
    print("no heat recovery total heat flow: {} kWh".format(totalHeat_noHR_dry))
    print("heat recovery total heat flow: {} kWh".format(totalHeat_HR_dry))

    print("total flow: {} Ls".format(df_noHR_dry['node_Node_1_Total_inflow'].sum()))
    print("average temp (data): {} °C".format(df_noHR_dry['node_Node_1_wtemperature'].mean()))
    print("median temp (data): {} °C".format(df_noHR_dry['node_Node_1_wtemperature'].median()))
    print("average temp: {} °C".format(totalHeat_noHR_dry * 3600000 / (c_water * df_noHR_dry['node_Node_1_Total_inflow'].sum())))
    print("mean temp noHR: {} °C".format(df_noHR_dry['node_Node_1_wtemperature'].mean()))
    print("mean temp HR: {} °C".format(df_HR_dry['node_Node_1_wtemperature'].mean()))
    print("average temp diff ARA: {} °C".format((totalHeat_noHR_dry-totalHeat_HR_dry) * 3600000 / (c_water * df_noHR_dry['node_Node_1_Total_inflow'].sum())))
    # print("average temp diff household: {} °C".format((16818.340683000017) * 3600000 / (c_water * df_noHR_dry['node_Node_1_Total_inflow'].sum())))


    #Wet Period
    totalHeat_noHR_wet = (df_noHR_wet['node_Node_1_Total_inflow'] * (df_noHR_wet['node_Node_1_wtemperature'] - refT)).sum() * c_water / 3600000
    totalHeat_HR_wet = (df_HR_wet['node_Node_1_Total_inflow'] * (df_HR_wet['node_Node_1_wtemperature'] - refT)).sum() * c_water / 3600000

    print("\n\nWET")
    print("no heat recovery total heat flow: {} kWh".format(totalHeat_noHR_wet))
    print("heat recovery total heat flow: {} kWh".format(totalHeat_HR_wet))

    print("total flow: {} Ls".format(df_noHR_wet['node_Node_1_Total_inflow'].sum()))
    print("average temp (data): {} °C".format(df_noHR_wet['node_Node_1_wtemperature'].mean()))
    print("median temp (data): {} °C".format(df_noHR_wet['node_Node_1_wtemperature'].median()))
    print("average temp: {} °C".format(totalHeat_noHR_wet * 3600000 / (c_water * df_noHR_wet['node_Node_1_Total_inflow'].sum())))
    print("mean temp noHR: {} °C".format(df_noHR_wet['node_Node_1_wtemperature'].mean()))
    print("mean temp HR: {} °C".format(df_HR_wet['node_Node_1_wtemperature'].mean()))
    print("average temp diff ARA: {} °C".format((totalHeat_noHR_wet-totalHeat_HR_wet) * 3600000 / (c_water * df_noHR_wet['node_Node_1_Total_inflow'].sum())))