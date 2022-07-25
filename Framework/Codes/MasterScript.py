# -*- coding: utf-8 -*-
from __future__ import print_function
"""
Created on Thu June 10 09:44:46 2020

@author: hadengbr

Master Script for the simulation of 
    (i) Household thermo-hydrographs using the WaterHub Framework
    (ii) private household connections using SWMM-Temp
"""

import os, sys
import pandas as pd
if sys.version_info.major == 2:
    from Python.SimulationHouseholds import mainLoopHouseholds
from Python.SimulationLateralConnections import mainLoopLatConnections, randomLatConnection, checkOutputFlows
from Python.SimulationHouseholdsStitching import stitch
from Python.SimulationFullNetwork import mainLoopFullNetwork
from datetime import timedelta


def readWriteSimFile(simFile):
    """
    Used in Poor Man's Parallelization scheme. Read the current simulation step and increase it by 1 for the next
    process reading it.
    :param simFile: file containing the current simulation step
    :return: step number to be simulated
    """
    with open(simFile, 'r+') as inpf:
        inpf.seek(0)
        step = int(inpf.readline())
        inpf.seek(0)
        inpf.write('{}'.format(step+1))
    return step

def readSimFile(simFile):
    """
    Used in Poor Man's Parallelization scheme. Read the current simulation step
    :param simFile: file containing the current simulation step
    :return: step number to be simulated
    """
    with open(simFile, 'r+') as inpf:
        inpf.seek(0)
        step = int(inpf.readline())
        inpf.seek(0)
    return step

def simFileReset(simFile):
    """
    Used in Poor Man's Parallelization scheme. Reset the simulation file to start at zero.
    :param simFile: filename of simulation file containing the current sumulation step.
    """
    with open(simFile, 'r+') as inpf:
        inpf.seek(0)
        inpf.write('{}'.format(0))
        inpf.seek(0)
    return 0

def periodFormat(period):
    """
    Some formatting actions to convert a [DDMMYYYY, DDMMYYYY] date period to a short string format, the number of days
    and the total time in seconds.
    :param period: [DDMMYYYY, DDMMYYYY] date period
    :return: short string period format, number of days, total time in seconds
    """
    periodShort = "{}-{}".format(pd.to_datetime(period[0]).date().strftime('%Y%m%d'), pd.to_datetime(period[1]).date().strftime('%Y%m%d'))  # just a nice format change
    nDays = (pd.to_datetime(period[1]) - pd.to_datetime(period[0]) + timedelta(days=1)).days  # assuming closed interval
    print("Simulating for period {}, i.e. {} days".format(periodShort, nDays))
    totSimTime = nDays*86400

    return periodShort, nDays, totSimTime

def readPatternsFromInp(fileName, patternNames):
    with open(fileName, 'r+') as inpf:
        inp = inpf.readlines()
    for x in range(len(inp)):
        if "PATTERNS" in inp[x]:
            pat = x
    patterns = {}
    for patternName in patternNames:
        pattern = []
        for x in range(pat, int(len(inp)), 1):
            if patternName in inp[x]:
                for i in inp[x].split():
                    try:
                        pattern.append(float(i))
                    except ValueError:
                        continue
                patterns.update({patternName:pattern})
    return patterns

if __name__=='__main__':
    """
    Household Scenarios (scenario variable):
    
    Private connection scenarios (latConModel variable):
    """
    workingDir = "Q:/Abteilungsprojekte/eng/SWWData/SWMM-HEAT/Framework_template"
    simDir = "C:/Users/hadengbr/Documents/tmp"  # Temporary simulation folder (make it local to increase speed) C:/Users/figueral/Documents/temp_files 
    HouseholdScenario = 'PHR_1_100'  #  `Reference` is the status quo. use `PHR_1_XX` for heat recovery implemented in XX % of the catchment's households
    LatConnectionScenario = 'ReferencePC'  # `ReferencePC` is stochastic sampling of lateral connection characteristics. Use `PC_XXm` for lateral connections of all the same length of XX meters
    MINUHETScenario = 'ReferenceMINUHET'
    FullNetworkScenario = 'ReferenceFullNetwork'
    period = ['03/02/2019', '03/16/2019']  # Beginning, End, with both included in interval
    periodShort, nDays, totSimTime = periodFormat(period)  # Format period
    timeResolution = '3S'  # Time resolution of residential part (not above 5 seconds)
    timeResolutionFullNetwork = '10S'  # Time resolution of full network part
    stitched = True  # if True, household hydrographs will be stitched together from a database, else each household will
                     # be simulated with the WaterHub Framework. Note: you need python 2.x to simulate households
    if (not stitched) and (sys.version_info.major == 3):
        raise Exception("You have chosen the `simulation mode` for the generation of households thermo-hydrographs. Please"
                        "run `MasterScript.py` from a JModelica terminal running Python 2.7.")
    binary = True  # True to make all the IO binary-based, otherwise it will use `.csv`
    residential = True # if True, run the residential part of the code (Households + Lateral Connections)
    reset = True  # if True, starts simulation over from first node, otherwise reads from the `NodeFile` which node it should simulate next.
    runFullNetwork = True  # if True, runs the "Full Network" part of the code (MINUHET + Full Network)
    diagnostics = False  # Diagnotics tools - When True, make sure to run a single process (no parallelization)

    latConnection_template_inp = "{}/Residential/LateralConnections/Data/templateLateralConnection.inp".format(
            workingDir)
    fullNetwork_inp = "Q:/Abteilungsprojekte/eng/SWWData/SWMM-HEAT/Framework_template/Data/first_faf_css_apr20_v03_SCall_xs_gampt_SH.inp"

    # Simulation parameters full network
    temperaturesMain = readPatternsFromInp(fullNetwork_inp, ['soil_temp', 'air_temp'])
    maxIndTemp = 18  # Industrial temperature (that needs calibration); note that there is one 'main' industry with 30oC, which is already included.
    IndOpen=7  # Opening time of industries
    IndClose = 20  # Closing time of industries
    mainIndustryFlow = 6  # L/s
    mainIndustryTemp = 30  # Celsius
    simParametersFullNet = [temperaturesMain, maxIndTemp, IndOpen, IndClose, mainIndustryFlow, mainIndustryTemp]

    # Simulation parameters lateral connections
    temperaturesLatCon = readPatternsFromInp(latConnection_template_inp, ['soil_temp', 'air_temp'])
    baseFlow = 0.0005  # L/s
    simParametersLatCon = [temperaturesLatCon, temperaturesMain, baseFlow]

    # Paths definitions
    dirHouseholds = '{}/Residential/Households/{}/{}_{}'.format(workingDir, 'stitched' if stitched else 'simulated',
                                                                HouseholdScenario, periodShort)
    if not os.path.exists(dirHouseholds):
        os.makedirs(dirHouseholds)
    dirLatConnections = '{}/Residential/LateralConnections/{}/{}_{}_{}'.format(workingDir,
                                                                               'stitched' if stitched else 'simulated',
                                                                               LatConnectionScenario, HouseholdScenario,
                                                                               periodShort)
    if not os.path.exists(dirLatConnections):
        os.makedirs(dirLatConnections)
    dirMINUHET = "{}/MINUHET/Scenarios/{}/{}_{}_{}_{}".format(workingDir, 'stitched' if stitched else 'simulated', MINUHETScenario, LatConnectionScenario, HouseholdScenario, periodShort)
    if not os.path.exists(dirMINUHET):
        os.makedirs(dirMINUHET)
    dirFullNetwork = '{}/Scenarios/{}/{}_{}_{}_{}_{}'.format(workingDir, 'stitched' if stitched else 'simulated', FullNetworkScenario, MINUHETScenario, LatConnectionScenario, HouseholdScenario, periodShort)
    if not os.path.exists(dirFullNetwork):
        os.makedirs(dirFullNetwork)

    # Reading node name and # of people per node, as well as industrial nodes
    nodesDf = pd.read_excel('Q:/Abteilungsprojekte/eng/SWWData/SWMM-HEAT/Framework_template/Data/Residential.xlsx')
    nodesIndustrial = pd.read_excel('Q:/Abteilungsprojekte/eng/SWWData/SWMM-HEAT/Framework_template/Data/Industrial.xlsx', index_col=[0])
    dirStitchDataset = "Q:/Abteilungsprojekte/eng/SWWData/SWMM-HEAT/Framework_template/Residential/Households/stitching_Dataset/{}_Dataset".format(HouseholdScenario)

    # SWMM-HEAT Executable
    SWMMHEATEXE = "Q:/Abteilungsprojekte/eng/SWWData/SWMM-HEAT/SWMM-HEAT_src/swmmT_v1.001.exe"

    # Loop over node - script read current node from an external file for parallelization purposes
    simFile = "./NodeFile-{}-{}.txt".format(HouseholdScenario, LatConnectionScenario)
    try:
        if reset:
            simFileReset(simFile)
        node_i = readWriteSimFile(simFile)
    except IOError:
        with open(simFile, 'w+') as inpf:
            inpf.write("0")
        node_i = readWriteSimFile(simFile)

    if diagnostics:  # Setup the dataframes containing the diagnostics numbers if required
        outputFlows = pd.DataFrame(columns = ['totalUnsimTime', 'totalUnsimFlow'])
        nbHouses = pd.DataFrame(columns = ['node', 'PC_nb', 'nb_Houses'])

    # Create directories
    if not os.path.exists('{}/INPUT'.format(dirLatConnections)):
        os.mkdir('{}/INPUT'.format(dirLatConnections))
    if not os.path.exists('{}/OUTPUT'.format(dirLatConnections)):
        os.mkdir('{}/OUTPUT'.format(dirLatConnections))
    if not os.path.exists("{}/INPUT".format(dirFullNetwork)):
        os.makedirs("{}/INPUT".format(dirFullNetwork))
    if not os.path.exists("{}/OUTPUT".format(dirFullNetwork)):
        os.makedirs("{}/OUTPUT".format(dirFullNetwork))
    if not os.path.exists("{}/INPUT".format(dirMINUHET)):
        os.makedirs("{}/INPUT".format(dirMINUHET))
    if not os.path.exists("{}/OUTPUT".format(dirMINUHET)):
        os.makedirs("{}/OUTPUT".format(dirMINUHET))

    while node_i < len(nodesDf) and residential:
        node = nodesDf.iloc[node_i]["Node"]

        # Simulate each house in node
        houses = int(round(nodesDf[nodesDf['Node'] == node]['HousesPerNode']))

        if houses == 0:
            continue # we bypass nodes with no households.

        print("Processing node {} ({}/{})...".format(node, node_i, len(nodesDf)))

        # Check if the input files to MINUHET exists before running the residential node functions
        if (not os.path.exists("{}/INPUT/{}_flow.{}".format(dirMINUHET, node, 'bin' if binary else 'csv'))) or (not os.path.exists("{}/INPUT/{}_temp.{}".format(dirMINUHET, node, 'bin' if binary else 'csv'))):
            #Stitching procedure
            if stitched:
                aggregation = stitch(node, houses, dirStitchDataset, period, HouseholdScenario, dirHouseholds,
                                     timeResolution, binary=binary)
            else:
                aggregation = mainLoopHouseholds(node, houses, period, periodShort, HouseholdScenario, totSimTime,
                                                 dirHouseholds, timeResolution, simDir, binary=binary)

            # Simulate private connections
            mainLoopLatConnections(node, aggregation, HouseholdScenario, period, periodShort, dirLatConnections,
                                   dirHouseholds, LatConnectionScenario, timeResolution, simParametersLatCon,
                                   dirMINUHET, latConnection_template_inp, timeResolutionFullNetwork, simDir, binary=binary, SWMMHEATEXE=SWMMHEATEXE)

            # Check number of household per private connection - DO ONLY ONCE WITHIN A SINGLE PROCESS (NOT PARALLELIZED)
            if diagnostics:
                # check number of households connected to each lateral connection
                for agg in aggregation:
                    nbHouses = nbHouses.append({'node':node, 'PC_nb':agg[0], 'nb_Houses':len(agg[1])}, ignore_index=True)
                print(nbHouses)
                # check Output Flows (unsimulated part) - DO ONLY ONCE WITHIN A SINGLE PROCESS (NOT PARALLELIZED)
                outputFlows = checkOutputFlows(outputFlows, node, dirLatConnections, LatConnectionScenario, periodShort, HouseholdScenario)

        else:
            print("node {} already processed".format(node))


        node_i = readWriteSimFile(simFile)

    if diagnostics:
        outputFlows.to_csv("OutputFlows_{}_{}_{}.csv".format(periodShort, LatConnectionScenario, HouseholdScenario))
        nbHouses.to_csv("nbHouses_{}_{}_{}.csv".format(periodShort, LatConnectionScenario, HouseholdScenario))

    if runFullNetwork:
        mainLoopFullNetwork(dirFullNetwork, period, simParametersFullNet, nodesIndustrial, timeResolutionFullNetwork,
                            fullNetwork_inp, dirMINUHET, workingDir, nodesDf, FullNetworkScenario,
                            binary=binary, SWMMHEATEXE=SWMMHEATEXE)