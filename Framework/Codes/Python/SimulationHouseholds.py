# -*- coding: utf-8 -*-
from __future__ import print_function

"""
Created on Thu Jul 26 09:44:46 2018

@author: hadengbr

Simulation of household thermo-hydrograph using the WaterHub modeling framework
"""

import sys, os
from datetime import datetime as dt
from datetime import timedelta

print("Running on {}".format(os.environ['COMPUTERNAME']))
if os.environ['COMPUTERNAME'] == "SWW-CLIBU019":
    polyDir = "E:/Users/hadengbr/polybox"
    os.environ['MODELICAPATH'] = "E:\\Users\\hadengbr\\04_Programming;" + os.environ[
        'JMODELICA_HOME'] + "\\ThirdParty\\MSL;"
else:
    polyDir = "C:/Users/hadengbr/polybox"
    os.environ['MODELICAPATH'] = "C:\\Users\\hadengbr\\04_Programming;" + os.environ[
        'JMODELICA_HOME'] + "\\ThirdParty\\MSL;" + "C:\\Users\\hadengbr\\04_Programming\\Buildings"

# We assume the hydrogen package is installed using pip
import hydrogen.HydroGen as hy
import hydrogen.tools.tools as tt

# for simulation
from pymodelica import compile_fmu
from pyfmi import load_fmu

# for analysis
import pandas as pd
import numpy as np

# Binary reading and writing
from Python.tools.BinaryOutput import writeToBinary, readFromBinary

# Batching function
from Python.tools.batchHouseholds import batch

def generateHydrographs(appliances, DHW_InitDir, tmpDir, simDays, totSimTime, pid):
    """
    Generate hydrograph for each appliance in the household
    :param appliances: list of appliances in the household
    :param DHW_InitDir: Folder containing initialization files for the generation of water consumption events
    :param tmpDir: temporary local folder for the writing of hydrographs and simulation results
    :param totSimTime: total simulation time
    :param pid: process number (used for parallel computing)
    :return: 0
    """
    initDict = {}
    dfDict = {}
    flowDict = {}
    for appliance in appliances:
        print("reading {} initFile".format(appliance))
        initFile = "{}/{}Init.in".format(DHW_InitDir, appliance)
        with open(initFile, 'r+') as inpf:
            data = inpf.readlines()
            data[2] = " \"simDays\": {},\n".format(simDays)  # in this file, the simDays value is on line 2
            inpf.seek(0)
            inpf.writelines(data)
            inpf.truncate()
        initDict[appliance] = tt.initRead("{}/{}Init.in".format(DHW_InitDir, appliance))

        # read frequency distributions
        dfDict["{}_df".format(appliance)], dfDict["{}_dfSeconds".format(appliance)], dfDict[
            "{}_dfFreq".format(appliance)], dfDict["{}_startTime".format(appliance)], dfDict[
            "{}_timeDiff".format(appliance)] = hy.readConvert_Distribution(initDict[appliance].distroFile,
                                                                           initDict[appliance].totSimTime, False, initFile)

        ### Generate Hydrographs
        flowDict["{}_flowDf".format(appliance)], flowDict["{}_withDrawVol".format(appliance)] = hy.eventLoop(
            dfDict["{}_df".format(appliance)], dfDict["{}_dfFreq".format(appliance)], initDict[appliance],
            dfDict["{}_startTime".format(appliance)], dfDict["{}_timeDiff".format(appliance)])

        # save as temporary Modelica input files
        tmpFilename = "{}_{}_{}_tmp.csv".format(appliance, os.environ[
            'COMPUTERNAME'], pid)  # Add computer name to avoid conflicts with other machines when producing flows.
        try:
            if initDict[appliance].operationEnergy == "True":
                flowDict["{}_flowDf".format(appliance)].to_csv("{}/{}".format(tmpDir, tmpFilename),
                                                               columns=['flow', 'temp', 'opEn'])
            else:
                flowDict["{}_flowDf".format(appliance)].to_csv("{}/{}".format(tmpDir, tmpFilename),
                                                               columns=['flow', 'temp'])
        except AttributeError:  # do as if nothing happened
            flowDict["{}_flowDf".format(appliance)].to_csv("{}/{}".format(tmpDir, tmpFilename),
                                                           columns=['flow', 'temp'])
        tt.conversion_Modelica("{}/{}".format(tmpDir, tmpFilename), 86400, simDays,
                               len(flowDict["{}_flowDf".format(appliance)].columns))
    return 0

def modelSelection(scenario, node):
    """
    Select household model based on scenario name
    :param scenario: household scenario name
    :param node: node number
    :return: modelName
    """
    try:
        type, penetration = scenario.split('_')[1:]
        penetration = int(penetration)/100.  # as a ratio
        type = int(type)

        if "PHR" in scenario:  # Passive Heat Recovery
            if type == 1:  # Random spatial distribution
                modelName = np.random.choice(["Reference", "ShowerDWHR"], p=[1-penetration, penetration])
            elif type == 2:  # Non-random spatial distribution
                ### Do something with Node number
                raise(TypeError)

    except ValueError:
        modelName = scenario

    return modelName

def mainLoopHouseholds(node, houses, period, periodShort, scenario, totSimTime, dirHouseholds, timeResolution, simDir, binary=True):
    """
    Main Loop for the simulation of single households using the WaterHub Framework
    :param node: node number
    :param house: house number in node
    :param periodShort: formatted time period
    :param scenario: household scenario name
    :param totSimTime: total simulation time
    :param waterHubDir: WaterHub simulation folder
    :return: 0
    """
    # Create Node-specific Directories
    nodeDirHouseholds = '{}/{}'.format(dirHouseholds, node)
    if not os.path.exists(nodeDirHouseholds):
        os.makedirs(nodeDirHouseholds)

    # Process number (used for parallel computing)
    pid = os.getpid()

    cumulFlow=pd.DataFrame(columns=["house", "cumulFlow"])
    # cumulFlow.append(pd.DataFrame([[1, 3500]], columns=["house", "cumulFlow"]))

    simDays = (totSimTime + 1) / 86400  # integer division to get number of days for simulation

    for house in range(1, int(houses) + 1, 1):
        # Result filename
        resultFile = "{}/FlowTemp_{}_{}".format(nodeDirHouseholds, node, house)

        if not os.path.exists(simDir):
            os.mkdir(simDir)

        ## Simulate only if the house has not been simulated previously
        if not os.path.exists("{}.{}".format(resultFile, 'bin' if binary else 'csv.gz')):
            print("simulating node {}, house {}".format(node, house))
            ### Useful Paths
            modelDir = "{}/../../../simulated_Data/ModelicaModels".format(nodeDirHouseholds)  # main directory where model is stored
            # Choose random number of inhabitants in the household
            nbInhabitants = np.random.choice([1, 2, 3, 4, 5], p=[0.355, 0.323, 0.133, 0.128, 0.061])
            initDir = '{}/../../../simulated_Data/InitFiles/InitFiles_{}'.format(nodeDirHouseholds, nbInhabitants)

            ### Read Initialization Files and generate hydrographs
            appliances = ["Shower", "TapAdults", "TapChildren", "TapHousehold", "WashingMachine", "Dishwasher", "Toilet"]
            generateHydrographs(appliances, initDir, simDir, simDays, totSimTime, pid)  # generates hydrographs and stores them in tmpDir

            ### compile and load model with relevant options -
            modelName = modelSelection(scenario, node)
            modelFile = "{}/{}.mo".format(modelDir, modelName)

            if not os.path.exists("{}/{}.fmu".format(simDir, modelName)):
                print("compiling Modelica model...")
                model_fmu = compile_fmu(modelName, modelFile, target='cs', compile_to=simDir )  # , compiler_options={"cc_split_function_limit":100}
            else:
                model_fmu = "{}/{}.fmu".format(simDir, modelName)

            print("Loading model {}...".format(model_fmu))
            crunchFactor = int(timeResolution[:-1])  # factor dividing number of output points to decrease file size and increase efficiency

            model = load_fmu(model_fmu, log_level=3, log_file_name="{}/{}_{}_{}.txt".format(simDir, modelName, os.environ['COMPUTERNAME'], pid))

            # Load Hydrographs into model
            print("Loading hydrograph files...")
            HydVarList = ["{}Hyd.fileName".format(appliance) for appliance in appliances]
            hydrographs = ["{}/{}_{}_{}_tmp.csv".format(simDir, appliance, os.environ['COMPUTERNAME'], pid) for appliance in appliances]
            model.set(HydVarList, hydrographs)  # set HydVarList variables to just generated hydrographs

            # Set Simulation Options
            opts = model.simulate_options()  # how to change simulation options.
            opts['ncp'] = int(totSimTime / crunchFactor)
            opts['initialize'] = True
            opts['result_handling'] = "file"
            opts['result_file_name'] = "{}/{}_{}_{}.mat".format(simDir, modelName, os.environ['COMPUTERNAME'], pid)

            # Simulate model
            print("simulating model...")
            res = model.simulate(final_time=totSimTime, options=opts)
            print("done")

            # Extract specific variables
            print("zipping results...")

            ## Variables to export
            varList = []
            with open('{}/../../../simulated_Data/UsefulVariableNames.csv'.format(nodeDirHouseholds), 'r+') as inpf:
                inpf.seek(0)
                for line in inpf:
                    varList.append(line[:-1])

            tmpDf = pd.DataFrame(list(res['time']), columns=['time'])
            for var in varList:
                tmpDf["{}".format(var)] = list(res[var])

            ## export of cumulated flow
            cumulFlow = cumulFlow.append(pd.DataFrame([[house, float(tmpDf.iloc[-1:]["Wastewater.cumulatedWater"])]],
                                                      columns=["house", "cumulFlow"]), ignore_index=True)

            # Export results
            print("export results")
            tmpDf = tmpDf.set_index(
                pd.date_range(start=period[0], end=(pd.to_datetime(period[1])+timedelta(days=1)).strftime('%m/%d/%Y'), freq=timeResolution))
            print(tmpDf)
            if binary:
                writeToBinary(tmpDf, "{}.bin".format(resultFile), columns=['der(Wastewater.cumulatedWater)', 'Wastewater.cumulatedWaterT'])
            else:
                tmpDf.to_csv("{}.csv.gz".format(resultFile), compression='gzip')

        else:
            if binary:
                dfFinal = readFromBinary("{}.bin".format(resultFile), ['Flow', 'Temperature'])
                cumulFlow = cumulFlow.append(
                    pd.DataFrame([[house, float(dfFinal["Flow"].sum()) * int(timeResolution[:-1])]],
                                 columns=["house", "cumulFlow"]), ignore_index=True)
            else:
                tmpDf = pd.read_csv("{}.csv.gz".format(resultFile), compression='gzip', index_col=[0])
                cumulFlow = cumulFlow.append(pd.DataFrame([[house, float(tmpDf.iloc[-1:]["Wastewater.cumulatedWater"])]],
                                                          columns=["house", "cumulFlow"]), ignore_index=True)
            print("Node {}, house {} already simulated".format(node, house))

    aggregation = batch(cumulFlow, 2750.*simDays)
    print("Node {} is separated into batches: {}".format(node, aggregation))

    return aggregation



