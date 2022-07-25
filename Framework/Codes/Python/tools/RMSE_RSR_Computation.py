# -*- coding: utf-8 -*-
from __future__ import print_function
"""
Created on Thu June 10 09:44:46 2020

@author: hadengbr

Compute RMSE and RME from validation and calibration output files
"""

import pandas as pd

def RMSE(df, name):
    RMSE = ((df['{}_sim'.format(name)] - df['{}_obs'.format(name)]) ** 2).mean() ** .5
    return RMSE

def RSR(df, name):
    return RMSE(df, name)/df['{}_obs'.format(name)].std()

def NSE(df, name):
    nom =  ((df['{}_sim'.format(name)] - df['{}_obs'.format(name)]) ** 2).sum()
    denom = ((df['{}_obs'.format(name)] - df['{}_obs'.format(name)].mean()) ** 2).sum()
    return 1 - (nom/denom)

if __name__=='__main__':
    PATH = "Q:\Abteilungsprojekte\eng\SWWData\BrunoHadengue\PMP_Processes\FehraltorfClean\SWMM_temp\SWMMfiles\Results"
    scenario = "Sc"

    print("reading {}\{}_Obs.txt".format(PATH, scenario))
    df = pd.read_csv("{}\{}1_Obs.txt".format(PATH, scenario), sep='\t', index_col=[0], parse_dates=True).add_suffix('_obs')
    df = df[df.index < "04.19.2019"]
    # dropping morning peak hours
    df = df.drop(df.between_time("06:00", "10:00").index)
    print(df)

    # print(df[df.index < "04-10-2019"])
    #Flow - OBSERVED
    ARA_flow = df['ARA_obs'].dropna()
    N166_flow = df['N166_obs'].dropna()
    N23_flow = df['N23_obs'].dropna()

    #Temp - OBSERVED
    ARA_temp = df['ARA_Temp_obs'].dropna()
    N166_temp = df['N166_Temp_obs'].dropna().resample('1min').mean().dropna()
    N23_temp = df['N22a_Temp_obs'].dropna().resample('1min').mean().dropna()

    print("reading {}\{}20_Sim.txt".format(PATH, scenario))
    df_sim = pd.read_csv("{}\{}1_Sim.txt".format(PATH, scenario), sep='\t', index_col=[0], parse_dates=True).add_suffix('_sim')
    df_sim = df_sim[df_sim.index < "04.19.2019"]
    # dropping morning peak hours
    df_sim = df_sim.drop(df_sim.between_time("06:00", "10:00").index)
    print(df_sim)

    #Flow - SIMULATED
    ARA_flow = pd.concat([ARA_flow, df_sim['ARA_sim']], join='inner', axis=1)
    N166_flow = pd.concat([N166_flow, df_sim['N166_sim']], join='inner', axis=1)
    N23_flow = pd.concat([N23_flow, df_sim['N23_sim']], join='inner', axis=1)

    #Temp - SIMULATED
    ARA_temp = pd.concat([ARA_temp, df_sim['ARA_Temp_sim']], join='inner', axis=1)
    N166_temp = pd.concat([N166_temp, df_sim['N166_Temp_sim']], join='inner', axis=1)
    N23_temp = pd.concat([N23_temp, df_sim['N22a_Temp_sim']], join='inner', axis=1)


    ### RMSE
    RMSE_ARA_flow = RMSE(ARA_flow, "ARA")
    RMSE_N166_flow = RMSE(N166_flow, "N166")
    RMSE_N23_flow = RMSE(N23_flow, "N23")
    RMSE_ARA_temp = RMSE(ARA_temp, "ARA_Temp")
    RMSE_N166_temp = RMSE(N166_temp, "N166_Temp")
    RMSE_N23_temp = RMSE(N23_temp, "N22a_Temp")
    print("RMSE_ARA_flow = {}".format(RMSE_ARA_flow))
    print("RMSE_N166_flow = {}".format(RMSE_N166_flow))
    print("RMSE_N23_flow = {}".format(RMSE_N23_flow))
    print("RMSE_ARA_temp = {}".format(RMSE_ARA_temp))
    print("RMSE_N166_temp = {}".format(RMSE_N166_temp))
    print("RMSE_N23_temp = {}".format(RMSE_N23_temp))

    ### RSR
    RSR_ARA_flow = RSR(ARA_flow, "ARA")
    RSR_N166_flow = RSR(N166_flow, "N166")
    RSR_N23_flow = RSR(N23_flow, "N23")
    RSR_ARA_temp = RSR(ARA_temp, "ARA_Temp")
    RSR_N166_temp = RSR(N166_temp, "N166_Temp")
    RSR_N23_temp = RSR(N23_temp, "N22a_Temp")
    print("\n\nRSR_ARA_flow = {}".format(RSR_ARA_flow))
    print("RSR_N166_flow = {}".format(RSR_N166_flow))
    print("RSR_N23_flow = {}".format(RSR_N23_flow))
    print("RSR_ARA_temp = {}".format(RSR_ARA_temp))
    print("RSR_N166_temp = {}".format(RSR_N166_temp))
    print("RSR_N23_temp = {}".format(RSR_N23_temp))


    ### NSE
    NSE_ARA_flow = NSE(ARA_flow, "ARA")
    NSE_N166_flow = NSE(N166_flow, "N166")
    NSE_N23_flow = NSE(N23_flow, "N23")
    NSE_ARA_temp = NSE(ARA_temp, "ARA_Temp")
    NSE_N166_temp = NSE(N166_temp, "N166_Temp")
    NSE_N23_temp = NSE(N23_temp, "N22a_Temp")
    print("\n\nNSE_ARA_flow = {}".format(NSE_ARA_flow))
    print("NSE_N166_flow = {}".format(NSE_N166_flow))
    print("NSE_N23_flow = {}".format(NSE_N23_flow))
    print("NSE_ARA_temp = {}".format(NSE_ARA_temp))
    print("NSE_N166_temp = {}".format(NSE_N166_temp))
    print("NSE_N23_temp = {}".format(NSE_N23_temp))