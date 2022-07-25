# -*- coding: utf-8 -*-
from __future__ import print_function

"""
Created on 28.06.2021

@author: hadengbr

Objective: generate SWMM-HEAT input time series from the stitching of existing one-day time series.
"""

import os
import pandas as pd
from datetime import timedelta
import numpy as np
from Python.tools.BinaryOutput import writeToBinary, readFromBinary
from Python.tools.batchHouseholds import batch

def stitch(node, houses, dirDataset, period, HouseholdScenario, dirHouseholds, timeResolution, binary=False):
    # Create Node-specific Directories
    nodeDirHouseholds = '{}/{}'.format(dirHouseholds, node)
    if not os.path.exists(nodeDirHouseholds):
        os.makedirs(nodeDirHouseholds)

    nDays = (pd.to_datetime(period[1]) - pd.to_datetime(period[0]) + timedelta(days=1)).days  # assuming closed interval

    cumulFlow = pd.DataFrame(columns=["house", "cumulFlow"])

    for house in range(1, int(houses) + 1, 1):
        print("house {}".format(house))
        householdFile = '{}/FlowTemp_{}_{}.{}'.format(nodeDirHouseholds, node, house, 'bin' if binary else 'csv.gz')
        if not os.path.exists(householdFile):
            nbInhabitants = np.random.choice([1, 2, 3, 4, 5], p=[0.355, 0.323, 0.133, 0.128, 0.061])
            print("Inhabitants File: {}".format('{}person.csv'.format(nbInhabitants)))
            nbInhabitantsDf = pd.read_csv('{}/{}person.csv'.format(dirDataset, nbInhabitants), header=None)
            rand = list(nbInhabitantsDf.sample(n=nDays)[0])
            dfFinal = pd.DataFrame(columns=["Flow", "Temperature"])

            for r, i in zip(rand, range(0, nDays, 1)):
                df = pd.read_csv("{}/{}".format(dirDataset, r), compression='gzip')[:86400]  ## Make sure we do not overlap with following day

                # Hot fix due to bad formatting of database for stitching procedure of heat recovery scenarios
                if not 'Heat Flow' in df.columns:
                    df = df.rename(columns={"Wastewater.cumulatedWaterT": "Temperature", "der(Wastewater.cumulatedWater)":"Flow"})
                    df = df.drop(columns=['Unnamed: 0', 'Unnamed: 0.1', 'time', 'Wastewater.cumulatedWater'])
                    df['Heat Flow'] = (df['Temperature'] - 273.15) * df['Flow'] * 4179.6
                # End of hot fix

                df = df.set_index(
                    pd.date_range(pd.to_datetime(period[0]) + i * timedelta(days=1), periods=len(df), freq='1S'))
                if timeResolution.lower() != '1s':
                    df = df.resample(timeResolution).mean()
                    df['Temperature'] = (df['Heat Flow'] / (df['Flow'] * 4179.6))  # Use already existing Heat Flow column to compute weighted temperature mean
                    df['Temperature'] = df['Temperature'].fillna(0)  # Avoid the zero flow problem above with a hacky hack
                df = df.drop(columns=['Heat Flow'])
                dfFinal = pd.concat([dfFinal, df], ignore_index=False)

            if binary:
                writeToBinary(dfFinal, householdFile, columns=['Flow', 'Temperature'])
            else:
                dfFinal.to_csv("{}".format(householdFile), sep='\t',
                       date_format='%m/%d/%Y %H:%M:%S')

            cumulFlow = cumulFlow.append(pd.DataFrame([[house, float(dfFinal["Flow"].sum())*int(timeResolution[:-1])]],
                                          columns=["house", "cumulFlow"]), ignore_index=True)
            # print(cumulFlow.tail(1))

        else:
            if binary:
                dfFinal = readFromBinary(householdFile, ['Flow', 'Temperature'])
            else:
                dfFinal = pd.read_csv(householdFile, compression='gzip', index_col=[0], sep='\t')
            cumulFlow = cumulFlow.append(pd.DataFrame([[house, float(dfFinal["Flow"].sum())*int(timeResolution[:-1])]],
                                          columns=["house", "cumulFlow"]), ignore_index=True)
            # print(cumulFlow.tail(1))
            print("Node {}, house {} already simulated".format(node, house))

    aggregation = batch(cumulFlow, 2750. * nDays)
    print("Node {} is separated into batches: {}".format(node, aggregation))

    return aggregation