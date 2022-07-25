# -*- coding: utf-8 -*-
from __future__ import print_function

from pandas.compat import FileNotFoundError

"""
Created on Thu June 10 09:44:46 2020

@author: hadengbr

Master Script for the simulation of 
    (i) Household thermo-hydrographs using WaterHub Framework
    (ii) private household connections using SWMM-Temp
"""

import sys, os

import pandas as pd
from datetime import timedelta
from multiprocessing import Pool
import numpy as np
from contextlib import closing


def main(node):
    # waterHubDir = 'C:/Users/hadengbr/polybox/EAWAG/12_Projects/07_TempSensX/FehraltorfClean/WaterHub'
    waterHubDir = 'Q:/Abteilungsprojekte/eng/SWWData/BrunoHadengue/PMP_Processes/FehraltorfClean/WaterHub'
    nodesDf = pd.read_excel(
        'Q:/Abteilungsprojekte/eng/SWWData/BrunoHadengue/PMP_Processes/FehraltorfClean/SWMM_temp/outputFiles/Calculations.xlsx')

    for house in range(1, int(nodesDf[nodesDf['Node'] == node]['HousesPerNode']) + 1, 1):
        try:
            df = pd.read_csv("{}/nodes/{}/FlowTemp_{}_{}.csv".format(waterHubDir, node, node, house))
            df.to_csv("{}/nodes/{}/FlowTemp_{}_{}.csv.gz".format(waterHubDir, node, node, house), compression='gzip')
            os.remove("{}/nodes/{}/FlowTemp_{}_{}.csv".format(waterHubDir, node, node, house))
            print("done: node {}, house {}".format(node, house))
        except FileNotFoundError:
            print('no problem, will do node {}, house {} later'.format(node, house))


if __name__ == '__main__':

    # WaterHub
    # waterHubDir = 'Q:/Abteilungsprojekte/eng/SWWData/BrunoHadengue/PMP_Processes/FehraltorfClean/WaterHub'
    nodesDf = pd.read_excel(
        'Q:/Abteilungsprojekte/eng/SWWData/BrunoHadengue/PMP_Processes/FehraltorfClean/SWMM_temp/outputFiles/Calculations.xlsx')

    # Reading node name and # of people per node from Calculations.xlsx


    with closing(Pool(processes=8)) as pool:
        pool.map(main, list(nodesDf['Node']))
        pool.terminate()

    # with Pool(4) as p:
      #  p.map(main, list(nodesDf['Node']))

    #
    # for node in nodesDf['Node']:
    #     for house in range(1, nodesDf[nodesDf['Node'] == node]['HousesPerNode'] + 1, 1):
    #         try:
    #             df = pd.read_csv("{}/nodes/{}/FlowTemp_{}_{}.csv".format(waterHubDir, node, node, house))
    #             df.to_csv("{}/nodes/{}/FlowTemp_{}_{}.csv.gz".format(waterHubDir, node, node, house),
    #                       compression='gzip')
    #             os.remove("{}/nodes/{}/FlowTemp_{}_{}.csv".format(waterHubDir, node, node, house))
    #             print("done: node {}, house {}".format(node, house))
    #         except FileNotFoundError:
    #             print('no problem, will do node {}, house {} later'.format(node, house))
