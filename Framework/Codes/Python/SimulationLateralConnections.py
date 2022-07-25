# -*- coding: utf-8 -*-
from __future__ import print_function
"""
Created on Thu June 10 09:44:46 2020

@author: hadengbr

This script:
    * Generates times series as inputs to the private connection models based on the output from WaterHub
    * Generates random private connection SWMM-Temp models based on a unique template
    * Simulates private household connection
    * Performs a post-processing step:
        * extract flow an temperature of outflow of private connection
        * removes existing .out output file
        * decrease resolution from 1 second to 5 seconds
"""

import os
import subprocess as sp
import pandas as pd
import numpy as np
from datetime import datetime as dt
from datetime import timedelta
import scipy

## Reading of SWMM-Temp output files and binary IO handling
from Python.tools.swmmtoolbox_SWMMHEAT import extract
from Python.tools.BinaryOutput import writeToBinary, readFromBinary

from matplotlib import pyplot as plt

def read_inp(filename):
    """
    Simply reads the SWMM-Temp input model and returns a list of lines
    :param filename: .inp file
    :return: list of lines
    """
    with open(filename, 'r+') as inpf:
        inp = inpf.readlines()
    return inp


def mainLoopLatConnections(node, aggregation, scenario, period, periodShort, dirLatConnections, dirHouseholds,
                           latConModel, timeResolution, simParametersLatCon, dirMINUHET, file_inp_MainTemplate,
                           timeResolutionFullNetwork, simDir, binary=True, overwrite=False, SWMMHEATEXE=None):
    """
    Main loop for the simulation of Private Connections
    :param node: node number
    :param aggregation: list of batches (aggregated households)
    :param scenario: household scenario name
    :param period: time period
    :param periodShort: formatted time period
    :param dirLatConnections: Directory for Lateral Connection simulations
    :param nodeDirHouseholds: Directory for Households simulations
    :param latConModel: name of lateral connection scenario
    :param overwrite: Boolean >> True if existing output should to be overwritten
    :return: 0
    """
    temperaturesLatCon, temperaturesMain, baseFlow = simParametersLatCon

    nodeDirHouseholds = '{}/{}'.format(dirHouseholds, node)
    if not os.path.exists('{}/INPUT/{}'.format(dirLatConnections, node)):
        os.mkdir('{}/INPUT/{}'.format(dirLatConnections, node))
    if not os.path.exists('{}/OUTPUT/{}'.format(dirLatConnections, node)):
        os.mkdir('{}/OUTPUT/{}'.format(dirLatConnections, node))

    for agg in aggregation:
        file = '{}/OUTPUT/{}/{}_{}_{}'.format(dirLatConnections, node, node, periodShort, agg[0])

        ### No Private connection case >>> No SWMM-Temp simulation, direct aggregation of WH outputs
        if lengthSelection(latConModel) == 0:
            print("Special case: no private connections")
            flowFile = '{}/INPUT/{}/Flow_{}_{}.{}'.format(dirLatConnections, node, node, agg[0], "bin" if binary else "csv")
            tempFile = '{}/INPUT/{}/Temp_{}_{}.{}'.format(dirLatConnections, node, node, agg[0], "bin" if binary else "csv")
            generatePCInputs(flowFile, tempFile, nodeDirHouseholds, node, agg, temperaturesLatCon['soil_temp'], baseFlow)
            out = pd.read_csv(flowFile, delimiter='\t', index_col=[0], names=['node_B_Total_inflow'])
            out = pd.concat([out, pd.read_csv(tempFile, delimiter='\t', index_col=[0], names=['node_B_wtemperature'])], axis=1, sort=False)
            out.index = pd.to_datetime(out.index, format="%m/%d/%Y %H:%M:%S")
            out = out.resample(timeResolutionFullNetwork).mean()
            if binary:
                writeToBinary(out, "{}_{}.bin".format(file, scenario))
            else:
                out.to_csv("{}_{}.csv".format(file, scenario))
            continue

        # generate a private connection SWMM-Temp model if it does not exist
        if not os.path.exists('{}/../templateModels/{}/{}/template_{}_{}.inp'.format(dirLatConnections, latConModel, node, node, agg[0])):
            randomLatConnection(dirLatConnections, node, agg[0], latConModel, file_inp_MainTemplate)

        outFile = '{}_{}.{}'.format(file, scenario, "bin" if binary else "csv")

        if overwrite:
            os.remove(outFile)

        if not os.path.exists(outFile):
            # randomPC(SWMMTempDir, node, agg[0], latConModel)  # CAREFUL: Use only if you want to overwrite the current .inp file

            flowFile = '{}/INPUT/{}/Flow_{}_{}.{}'.format(dirLatConnections, node, node, agg[0], "bin" if binary else "csv")
            tempFile = '{}/INPUT/{}/Temp_{}_{}.{}'.format(dirLatConnections, node, node, agg[0], "bin" if binary else "csv")

            ### Read output from WaterHub
            generatePCInputs(flowFile, tempFile, nodeDirHouseholds, node, agg, temperaturesMain, baseFlow, binary)

            ### Load TIMESERIES into SWMM Temp model
            file_inp_template = '{}/../templateModels/{}/{}/template_{}_{}.inp'.format(dirLatConnections, latConModel, node, node, agg[0])
            file_inp = '{}.inp'.format(file)
            file_rpt = '{}_{}.rpt'.format(file, scenario)
            ## file_out is written locally to increase writing efficiency
            file_out = "{}/{}_{}_{}_{}.out".format(simDir, node, periodShort, agg[0], scenario)

            ### Read template SWMM-Temp model and modify [TIMESERIES] and dates section
            inpOriginal = read_inp(file_inp_template)
            inp = []
            startDate = dt.strftime(dt.strptime(period[0], "%m/%d/%Y") - timedelta(days=1), "%m/%d/%Y")
            for x in range(len(inpOriginal)):
                if 'START_DATE' in inpOriginal[x][0:10]: # necessary to avoid changing 'REPORT_START_DATE' at the same time.
                    inp.append("""START_DATE\t{}\n""".format(startDate))

                elif 'REPORT_START_DATE' in inpOriginal[x]:
                    inp.append("""REPORT_START_DATE\t{}\n""".format(period[0]))

                elif 'END_DATE' in inpOriginal[x]:
                    inp.append("""END_DATE\t{}\n""".format(period[1]))

                # Changing time resolutions
                elif 'REPORT_STEP' in inpOriginal[x]:
                    inp.append("""REPORT_STEP\t00:00:0{}\n""".format(timeResolution[:-1]))
                elif 'WET_STEP' in inpOriginal[x]:
                    inp.append("""WET_STEP\t00:00:0{}\n""".format(timeResolution[:-1]))
                elif 'DRY_STEP' in inpOriginal[x]:
                    inp.append("""DRY_STEP\t00:00:0{}\n""".format(timeResolution[:-1]))
                elif 'ROUTING_STEP' in inpOriginal[x]:
                    inp.append("""ROUTING_STEP\t00:00:0{}\n""".format(timeResolution[:-1]))
                elif 'TSBINARY' in inpOriginal[x]:
                    inp.append("""TSBINARY\t{}""".format(int(binary)))
                elif 'timeseries' in inpOriginal[x].lower(): #reconstruct timeseries section
                    inp.append(inpOriginal[x])
                    inp.append(inpOriginal[x+1])
                    inp.append(inpOriginal[x+2])
                    inp.append("""FlowUp FILE "{}" \n""".format(flowFile))
                    inp.append("""TempUp FILE "{}" \n""".format(tempFile))

                elif ('timeseries' in inpOriginal[x-1].lower()) or ('timeseries' in inpOriginal[x-2].lower()) or ('timeseries' in inpOriginal[x-3].lower()) or ('timeseries' in inpOriginal[x-4].lower()):
                    pass #avoid original timeseries section
                else:
                    inp.append(inpOriginal[x])

            ### Write new model
            with open(file_inp, 'w+') as inpf:
                inpf.seek(0)
                inpf.writelines(inp)

            ### Simulate with SWMM Temp
            if SWMMHEATEXE is None:
                SWMMHEATEXE = "Q:/Abteilungsprojekte/eng/SWWData/SWMM-HEAT/SWMM-HEAT_src/swmmT_v1.001.exe"
            sp.call([SWMMHEATEXE, file_inp, file_rpt, file_out], shell=True)

            ### Post-processing step - extract variables
            try:
                print("Post-processing output file...")
                out = extract(file_out, ['node', 'B', 'Total_inflow'])
                out = pd.concat([out, extract(file_out, ['node', 'B', 'wtemperature'])], axis=1, sort=False)
                out['virtualHeatFlow'] = out['node_B_Total_inflow']*out['node_B_wtemperature']  # Trick to compute weighted mean temperature and not arithmetic mean.
                out = out.resample('5s').mean()  ## upsample to 5s resolution
                out['node_B_wtemperature'] = out['virtualHeatFlow']/out['node_B_Total_inflow']
                out = out.drop(columns=['virtualHeatFlow'])
                if binary:
                    writeToBinary(out, outFile)
                else:
                    out.to_csv(outFile)
                os.remove(file_out)

            except IOError:
                # raw_input("Error in SWMM-Temp simulation, press enter to overwrite '.inp' file (CAREFUL! you may not want to do that)")
                # randomPC(SWMMTempDir, node, agg[0], latConModel)
                continue

        else:
            print("Private Connection {} already simulated".format(agg[0]))

    # Aggregate all into one timeseries per node as SWMM-Temp input
    finalOut = pd.DataFrame()
    outFlowFile = "{}/INPUT/{}_flow.{}".format(dirMINUHET, node, "bin" if binary else "txt")
    outTempFile = "{}/INPUT/{}_temp.{}".format(dirMINUHET, node, "bin" if binary else "txt")
    if not os.path.exists(outFlowFile) or not os.path.exists(outTempFile):
        for agg in aggregation:
            file = '{}/OUTPUT/{}/{}_{}_{}_{}.{}'.format(dirLatConnections, node, node, periodShort, agg[0], scenario, "bin" if binary else "csv")
            if binary:
                out = readFromBinary(file, ['flow', 'temperature'])
            else:
                out = pd.read_csv(file, index_col=[0])
            out["limTemp"] = [temperaturesMain['soil_temp'][m - 1] for m in out.index.month]
            out.loc[(out["flow"] < baseFlow) | out["flow"].isnull(), "flow"] = baseFlow
            out.loc[(out["temperature"] < out['limTemp']) | out["temperature"].isnull(), "temperature"] = out["limTemp"]
            out = out.drop(columns=['limTemp'])
            if agg[0] == 1:
                finalOut['flow'] = out["flow"]
                finalOut["heatFlow"] = out["flow"] * out["temperature"]
            else:
                finalOut["flow"] = finalOut["flow"] + out["flow"]
                finalOut["heatFlow"] = finalOut["heatFlow"] + (out["flow"] * out["temperature"])
        # finalOut["flow"].loc[(finalOut["flow"] < 0.0005) | finalOut["flow"].isnull()] = 0.0005

        finalOut["temperature"] = finalOut["heatFlow"]/finalOut["flow"]
        if binary:
            writeToBinary(finalOut, outFlowFile, columns=['flow'])
            writeToBinary(finalOut, outTempFile, columns=['temperature'])
        else:
            finalOut['flow'].to_csv(outFlowFile, date_format='%m/%d/%Y %H:%M:%S', sep='\t', float_format='%f')
            finalOut['temperature'].to_csv(outTempFile, date_format='%m/%d/%Y %H:%M:%S', sep='\t', float_format='%f')

    return 0


def randomLatConnection(dirLatConnections, node, aggNb, latConModel, file_inp_MainTemplate):
    """
    Generate a SWMM-Temp PC input file
    :param dirLatConnections: SWMM-Temp directory
    :param node: node number
    :param aggNb: household batch number
    :param latConModel: name of lateral connection scenario
    :return: 0
    """
    # Length selection
    length = lengthSelection(latConModel)
    
    if not os.path.exists('{}/../templateModels'.format(dirLatConnections)):
        os.makedirs('{}/../templateModels'.format(dirLatConnections))
    if not os.path.exists('{}/../templateModels/{}'.format(dirLatConnections, latConModel)):
        os.makedirs('{}/../templateModels/{}'.format(dirLatConnections, latConModel))
    if not os.path.exists('{}/../templateModels/{}/{}'.format(dirLatConnections, latConModel, node)):
        os.makedirs('{}/../templateModels/{}/{}'.format(dirLatConnections, latConModel, node))
    file_inp = '{}/../templateModels/{}/{}/template_{}_{}.inp'.format(dirLatConnections, latConModel, node, node, aggNb)
    inp = read_inp(file_inp_MainTemplate)

    nbSegments = int(length / 15)
    # Nominal Diameter selection
    DN = np.random.choice([0.10, 0.15, 0.20, 0.25, 0.30])  # Sampling of Diameter
    thickness = 0.0294 * DN  # Thickness selection, based on regression analysis of PVC pipes

    # Slope selection
    elevationA = 100
    slope = np.random.choice([0.01, 0.015, 0.02, 0.025, 0.03, 0.035, 0.04])  # Sampling of slope
    elevationOutfall = elevationA - length * slope

    # Roughness
    roughness = 0.011 # from EPA SWMM coefficients

    junctionsString = []
    conduitString = []
    xsectionsString = []
    for i in range(1, nbSegments+1, 1):
        junctionsString.append("""A{}               {}     3.23       0.14       0          0\n""".format(i, 100 - ((i-1)*slope*15)))
    for i in range(1, nbSegments, 1):
        conduitString.append("""A{}_A{}	A{}   		A{}	15.0	{}	   0		0		0		0	{}		0.30	3.45	1500		1430		"air_temp"		"soil_temp"  \n""".format(i, i+1, i, i+1, roughness, thickness))
        xsectionsString.append("""A{}_A{}             CIRCULAR     {}              0          0          0          1\n""".format(i, i+1, DN))
        
    conduitString.append("""A{}_B	A{}   		B	15.0	{}	   0		0		0		0	{}		0.30	3.45	1500		1430		"air_temp"		"soil_temp"  \n""".format(nbSegments, nbSegments, roughness, thickness))
    xsectionsString.append("""A{}_B             CIRCULAR     {}              0          0          0          1\n""".format(nbSegments,
                                                                                                           DN))

    inp = refactorModel(inp, 'junctions', junctionsString)
    inp = refactorModel(inp, 'conduits', conduitString)
    inp = refactorModel(inp, 'xsections', xsectionsString)
    inp = refactorModel(inp, 'outfalls', ["""B              {}          FREE                        NO\n""".format(elevationOutfall)])

    ### Write new model
    with open(file_inp, 'w+') as inpf:
        inpf.seek(0)
        inpf.writelines(inp)

    return 0

def lengthSelection(latConModel):
    """
    :param latConModel: Lateral connection scenario name
    :return: pipe length corresponding to private connection scenario name
    """
    try:
        if latConModel == 'ReferencePC':
            # return np.random.normal(20, 10, 1)[0]  # Sampling of Length
            # return scipy.stats.truncnorm.rvs(loc=18.7790166262, scale= 9.07274768785, a=5.0, b=150.0) ## truncated normal with mean 20m and std 8m
            return np.random.choice([15, 30, 45])
        else:
            length = int(latConModel.split('_')[1])
            return (length if (length % 15 == 0) else 15)
    except IndexError:
        raise Exception("Invalid private connection model")

def refactorModel(inpOriginal, section, string):
    """
    Replaces first line of section by string in inpOriginal model
    """
    inp = []
    for x in range(len(inpOriginal)):
        if section in inpOriginal[x].lower(): #reconstruct section
            inp.append(inpOriginal[x])
            inp.append(inpOriginal[x + 1])
            inp.append(inpOriginal[x + 2])
            inp += string
        elif (section in inpOriginal[x - 1].lower()) or (section in inpOriginal[x - 2].lower()) or (
                section in inpOriginal[x - 3].lower()):
            pass  # avoid original section

        else:
            inp.append(inpOriginal[x])

    return inp

def generatePCInputs(flowFile, tempFile, nodeDirHouseholds, node, agg, temperaturesMain, baseFlow, binary):
    """
    Generate .csv input files for the private connection models
    :param flowFile: flow input file to PC model
    :param tempFile: temperature input file to PC model
    :param nodeDirHouseholds: directory containing household output flows (from stitching procedure)
    :param scenario: household scenario name
    :param periodShort: formatted period
    :param node: node number
    :param agg: current household batch
    :param aggregation: household batch list (there is some redundancy here, we should make this cleaner someday)
    :return: 0
    """
    if not os.path.exists(flowFile) or not os.path.exists(tempFile):
        print("Generating Lateral Connection inputs: node {}, house batch {}: {}".format(node, agg[0], agg[1]))

        finalOut = pd.DataFrame()
        for house in agg[1]:
            flowTempFile = '{}/FlowTemp_{}_{}.{}'.format(nodeDirHouseholds, node, house, "bin" if binary else "csv.gz")

            if binary:
                out = readFromBinary(flowTempFile, ['flow', 'temperature'])
            else:
                out = pd.read_csv(flowTempFile, index_col=[0], compression='gzip', sep='\t')

            out["limTemp"] = [temperaturesMain['soil_temp'][m - 1] for m in out.index.month]
            out.loc[(out["flow"] < baseFlow) | out["flow"].isnull(), "flow"] = baseFlow
            out.loc[(out["temperature"] < out['limTemp']) | out["temperature"].isnull(), "temperature"] = out["limTemp"]
            out = out.drop(columns=['limTemp'])
            if house == agg[1][0]:
                finalOut['flow'] = out["flow"]
                finalOut["heatFlow"] = out["flow"] * out["temperature"]
            else:
                finalOut["flow"] = finalOut["flow"] + out["flow"]
                finalOut["heatFlow"] = finalOut["heatFlow"] + (out["flow"] * out["temperature"])
        # finalOut["flow"].loc[(finalOut["flow"] < 0.0005) | finalOut["flow"].isnull()] = 0.0005

        finalOut["temperature"] = finalOut["heatFlow"] / finalOut["flow"]
        if binary:
            writeToBinary(finalOut, flowFile, columns=['flow'])
            writeToBinary(finalOut, tempFile, columns=['temperature'])
        else:
            finalOut['flow'].to_csv(flowFile, date_format='%m/%d/%Y %H:%M:%S', sep='\t', float_format='%f')
            finalOut['temperature'].to_csv(tempFile, date_format='%m/%d/%Y %H:%M:%S', sep='\t', float_format='%f')

    return 0


def checkOutputFlows(outputFlows, node, dirLatConnections, latConModel, periodShort, scenario):
    """
    Check the integrity of the output flows from the private connection simulations. Computes (i) the percentage of
    unsimulated time, (ii) the percentage of unsimulated flow, (iii) additional heat (in percentage of total heat) in
    case unsimulated temperature values were set to 13°C or 25°C.
    :param outputFlows: DataFrame of already checked output flows
    :param node: node name
    :param dirLatConnections: directory
    :param latConModel: lateral connection model name
    :param periodShort: simulated period
    :param scenario: household scenario name
    :return: outputFlows DataFrame with concatenated computed values
    """
    PCoutputFilesDir = "{}/PCoutputFiles/{}".format(dirLatConnections, latConModel)

    for i in range(1, 20, 1):  # large enough number to avoid missing any PC
        file = "{}/{}/{}_{}_{}_{}.csv".format(PCoutputFilesDir, node, node, periodShort, i, scenario)

        try:
            out = pd.read_csv(file)

            totalUnsimTime = len(out[(out['node_B_wtemperature'] < 13.0) | out['node_B_wtemperature'].isna()]) * 100 / len(out)
            totalUnsimFlow = (out[(out['node_B_wtemperature'] < 13.0) | out['node_B_wtemperature'].isna()]['node_B_Total_inflow'].sum() * 5 * 100) / (
                            out['node_B_Total_inflow'].sum() * 5)
            artHeat13 = out[(out['node_B_wtemperature'] < 13.0) | out['node_B_wtemperature'].isna()]['node_B_Total_inflow'].sum() * 13 * 4179.6 / 3600000
            artHeat25 = out[(out['node_B_wtemperature'] < 13.0) | out['node_B_wtemperature'].isna()]['node_B_Total_inflow'].sum() * 25 * 4179.6 / 3600000
            totHeat = (out['node_B_Total_inflow'] * out['node_B_wtemperature']).sum() * 4179.6 / 3600000
            addHeat13 = artHeat13*100/totHeat
            addHeat25 = artHeat25*100/totHeat
            outputFlows = outputFlows.append(pd.DataFrame([[totalUnsimTime, totalUnsimFlow, addHeat13, addHeat25]],
                                                      columns=["totalUnsimTime", "totalUnsimFlow", "addHeat13", "addHeat25"]), ignore_index=True)

        except IOError:
            continue

    return outputFlows