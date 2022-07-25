# -*- coding: utf-8 -*-
from __future__ import print_function
"""
Created on Thu June 10 09:44:46 2020

@author: hadengbr

Master Script for the simulation of 
    (i) Household thermo-hydrographs using WaterHub Framework
    (ii) private household connections using SWMM-Temp
"""

import sys, os

import pandas as pd
from SimulationWaterHub import mainLoopWaterHub
from SimulationPrivateConnections import mainLoopPC, randomPC
from datetime import timedelta

import numpy as np

def batch(houses):
    """
    :param houses: number of houses in the node
    :return: list of batches (nammed) aggregation, each with the form [i, j], where i is the batch number and j
             the number of houses in the batch.
    """
    if houses >= 5:
        nbAgg = houses / 5
        aggregation = [[i, 5] for i in range(1, nbAgg + 1, 1)]  # [bunch number, nbHousesPerBunch]
        i = 0
        while i < (houses % 5):  # distributes the rest to the available batches
            j = i % (nbAgg)
            aggregation[j] = [j + 1, aggregation[j][1] + 1]
            i += 1
    else:
        aggregation = [[1, houses]]

    return aggregation


def remainingNodes(nodesDf, model):
    remainingNodes = []
    SWMMTempDir_Server = "Q:\Abteilungsprojekte\eng\SWWData\BrunoHadengue\PMP_Processes\FehraltorfClean\SWMM_temp"
    for node in nodesDf["Node"]:
        houses = int(round(nodesDf[nodesDf['Node'] == node]['HousesPerNode']))
        aggregation = batch(houses)

        for agg in aggregation:
             if not os.path.exists(
                        '{}/outputFiles/{}/{}_{}_{}.out'.format(SWMMTempDir_Server, node, node, agg[0], model)):
                remainingNodes.append(node)
                break
    return remainingNodes

def remainingTimeSeries(nodesDf):
    remainingTimeSeries = []
    SWMMTempDir_Server = "Q:\Abteilungsprojekte\eng\SWWData\BrunoHadengue\PMP_Processes\FehraltorfClean\SWMM_temp"
    for node in nodesDf["Node"]:
        houses = int(round(nodesDf[nodesDf['Node'] == node]['HousesPerNode']))
        aggregation = batch(houses)

        for agg in aggregation:
             if not os.path.exists(
                        '{}/timeSeriesPrivateConnections/nodes/{}/Flow_{}_{}.out'.format(SWMMTempDir_Server, node, node, agg[0])):
                remainingTimeSeries.append(node)
                break
    return remainingTimeSeries


if __name__=='__main__':

    #Directories

    #SWMM Temp
    SWMMTempDir = './SWMM_temp'

    #WaterHub
    waterHubDir = './WaterHub'

    # for now: fixed total simulation time: we will shift to a time-interval based simulation later
    # Define period
    period = ['04/08/2019', '04/10/2019']  # Beginning, End, with both included in interval
    nDays = (pd.to_datetime(period[1]) - pd.to_datetime(period[0]) + timedelta(days=1)).days  # assuming closed interval
    totSimTime = nDays*86400

    # Reading node name and # of people per node from Calculations.xlsx
    nodesDf = pd.read_excel('./Calculations.xlsx')

    remainingNodes(nodesDf, 'Reference')
    remainingTimeSeries(nodesDf)

    cumulVol = []
    probs = []

    for node in nodesDf['Node']:
        houses = int(round(nodesDf[nodesDf['Node'] == node]['HousesPerNode']))
        dir = "{}/nodes/{}".format(waterHubDir, node)
        for house in range(1, houses+1, 1):
            print("node {}, house {}".format(node, house))
            try:
                cumulVol.append([node, pd.read_csv("{}/FlowTemp_{}_{}.csv.gz".format(dir, node, house), skiprows=[i for i in range(1,259201, 1)], compression='gzip').iloc[0]['Wastewater.cumulatedWater']])
            except:
                probs.append([node, house])
                continue

    print(cumulVol)
    # print(np.sum(cumulVol))
    print(probs)

    df = pd.DataFrame(cumulVol, columns=['Node','cumulVol [L]'])
    print(df)
    df.to_excel("cumulVol_check.xlsx")

