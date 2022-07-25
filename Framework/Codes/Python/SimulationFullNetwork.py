# -*- coding: utf-8 -*-
from __future__ import print_function

"""

UNFINISHED - DO NOT USE

Created on Thu Dec 10 2020

@author: hadengbr

This script has functions to:
    * Generate times series as inputs to the full Fehraltorf model based on the output from Private Connection Simulations
    * Generate additional timeseries for industrial flow and rumlikon and russikon
    * Simulate the full Fehraltorf model with SWMM-HEAT
    * Retrieve relevant key signature values and plots flow/temperature at 3 locations in the system
    
"""

import os
import pandas as pd
import subprocess as sp
from Python.tools.BinaryOutput import writeToBinary, readFromBinary
from datetime import datetime as dt
from datetime import timedelta

def mainLoopFullNetwork(dirFullNetwork, period, simParametersFullNet, nodesIndustrial, timeResolutionFullNetwork,
                        fullNetwork_inp, dirMINUHET, workingDir, nodesDf, FullNetworkScenario,
                        SWMMHEATEXE=None, Industry=True, binary=True, overwrite=False):
    if SWMMHEATEXE is None:
        SWMMHEATEXE = 'Q:\\Abteilungsprojekte\\eng\\SWWData\\BrunoHadengue\\PMP_Processes\\FehraltorfClean\\SWMM_temp\\EAWAG-SWMM-TEMP\\EAWAG-SWMM-TEMP\\build\\swmmT_v1.001.exe'

    temperaturesMain, maxIndTemp, IndOpen, IndClose, mainIndustryFlow, mainIndustryTemp = simParametersFullNet

    ## Industrial Flows
    if Industry:
        print('Generating Industrial Flows...')
        for node in nodesIndustrial.index:
            flowFile = "{}/INPUT/{}_flow.{}".format(dirMINUHET, node, "bin" if binary else "txt")
            tempFile = "{}/INPUT/{}_temp.{}".format(dirMINUHET, node, "bin" if binary else "txt")
            if overwrite:
                try:
                    os.remove(flowFile)
                    os.remove(tempFile)
                except FileNotFoundError:
                    pass  # Nothing to overwrite

            if not os.path.exists(flowFile) or not os.path.exists(tempFile):
                print("Generating Industrial Flow - Node {}".format(node))
                tmpDf = pd.DataFrame(index=pd.date_range(start=period[0], end=(pd.to_datetime(period[1])+timedelta(days=1)).strftime('%m/%d/%Y'), freq=timeResolutionFullNetwork, closed='left'))
                tmpDf['flow'] = nodesIndustrial["Industrial"].loc[node] * 0.001
                tmpDf["temp"] = [temperaturesMain['soil_temp'][m - 1] for m in tmpDf.index.month]
                tmpDf.loc[(tmpDf.index.hour >= IndOpen) & (tmpDf.index.hour < IndClose) & (tmpDf.index.weekday < 5), 'flow'] = nodesIndustrial["Industrial"].loc[node]
                tmpDf.loc[(tmpDf.index.hour >= IndOpen) & (tmpDf.index.hour < IndClose) & (tmpDf.index.weekday < 5), 'temp'] = maxIndTemp

                if binary:
                    writeToBinary(tmpDf, flowFile, columns=['flow'])
                    writeToBinary(tmpDf, tempFile, columns=['temp'])
                else:
                    tmpDf['flow'].to_csv(flowFile, date_format='%m/%d/%Y %H:%M:%S', sep='\t', float_format='%f')
                    tmpDf['temp'].to_csv(tempFile, date_format='%m/%d/%Y %H:%M:%S', sep='\t', float_format='%f')

        # Main Industry
        mainIndustryFlowFile = "{}/INPUT/150b_flow.{}".format(dirMINUHET, "bin" if binary else "txt")
        mainIndustryTempFile = "{}/INPUT/150b_temp.{}".format(dirMINUHET, "bin" if binary else "txt")
        if overwrite:
            try:
                os.remove(mainIndustryFlowFile)
                os.remove(mainIndustryFlowFile)
            except FileNotFoundError:
                pass  # Nothing to overwrite

        if not os.path.exists(mainIndustryFlowFile) or not os.path.exists(mainIndustryTempFile):
            print("Generating Industrial Flow - Main Industry")
            tmpDf = pd.DataFrame(index=pd.date_range(start=period[0], end=(pd.to_datetime(period[1])+timedelta(days=1)).strftime('%m/%d/%Y'), freq=timeResolutionFullNetwork, closed='left'))
            tmpDf['flow'] = mainIndustryFlow * 0.001
            tmpDf["temp"] = [temperaturesMain['soil_temp'][m - 1] for m in tmpDf.index.month]
            tmpDf.loc[(tmpDf.index.hour >= IndOpen) & (tmpDf.index.hour < IndClose) & (tmpDf.index.weekday < 5), 'flow'] = mainIndustryFlow
            tmpDf.loc[(tmpDf.index.hour >= IndOpen) & (tmpDf.index.hour < IndClose) & (tmpDf.index.weekday < 5), 'temp'] = mainIndustryTemp
            if binary:
                writeToBinary(tmpDf, mainIndustryFlowFile, columns=['flow'])
                writeToBinary(tmpDf, mainIndustryTempFile, columns=['temp'])
            else:
                tmpDf['flow'].to_csv(mainIndustryFlowFile, date_format='%m/%d/%Y %H:%M:%S', sep='\t', float_format='%f')
                tmpDf['temp'].to_csv(mainIndustryTempFile, date_format='%m/%d/%Y %H:%M:%S', sep='\t', float_format='%f')

    ## MINUHET
    """
    binary
    """
    print('Running MINUHET Simulation...')
    SWMMOnly_inp = fullNetwork_inp.replace("first_faf_css_apr20_v03_SCall_xs_gampt_SH.inp", "210624_faf_css_apr20_v03_SCall_xs_gampt").replace('/', '\\')
    # SWMMOnly_inp = "210624_faf_css_apr20_v03_SCall_xs_gampt"
    initDate = pd.to_datetime(period[0])
    endDate = pd.to_datetime(period[1])
    auxPath = dirMINUHET.replace(dirMINUHET[:dirMINUHET.find('Scenarios/')]+"Scenarios/stitched/", "")  # just a hacky way to find the folder name itself without path
    massiveArgString = "{} {} {} {} {} {} {} {} {} {} {} {} {} {} {} {} {} {} {} {} {} {} {} {} {} {} {} {} {} ".format(
             initDate.year, initDate.month, initDate.day, initDate.hour, initDate.minute, initDate.second,
             endDate.year, endDate.month, endDate.day, endDate.hour, endDate.minute, endDate.second,
             int(binary), workingDir.replace('/', '\\'), FullNetworkScenario, auxPath, SWMMOnly_inp,
             temperaturesMain['soil_temp'][0], temperaturesMain['soil_temp'][1], temperaturesMain['soil_temp'][2],
             temperaturesMain['soil_temp'][3], temperaturesMain['soil_temp'][4], temperaturesMain['soil_temp'][5],
             temperaturesMain['soil_temp'][6], temperaturesMain['soil_temp'][7], temperaturesMain['soil_temp'][8],
             temperaturesMain['soil_temp'][9], temperaturesMain['soil_temp'][10], temperaturesMain['soil_temp'][11])
    print(massiveArgString)
    MINUHETEXE = "Q:/Abteilungsprojekte/eng/SWWData/SWMM-HEAT/Framework_template/Codes/Matlab/Minuhet_master/for_redistribution_files_only/Minuhet_master.exe"
    argList = massiveArgString.split()
    argList.insert(0, MINUHETEXE)
    sp.call(argList)

    """
    If, one day, we want to use the python matlab engine:
        1. Go to the MatlabRootFolder/extern/engines/python
        2. Run `python setup.py install` to install the engine
        3. In your python script, do
        
            import matlab.engine
            eng = matlab.engine.start_matlab()
            s = eng.genpath('Path/to/Folder/Containing/Matlab/Files')
            eng.addpath(s, nargout=0)
            eng.Minuhet_master( ... arguments ...)
    """

    ## Building the .inp file from the template
    print("Full Network Simulation...")
    file = "{}/OUTPUT/FullNetwork".format(dirFullNetwork)
    file_inp = "{}.inp".format(file)
    file_rpt = "{}.rpt".format(file)
    file_out = "{}.out".format(file)

    startDate = dt.strftime(dt.strptime(period[0], "%m/%d/%Y") - timedelta(days=1), "%m/%d/%Y")

    with open(fullNetwork_inp, 'r+') as f:
        inpOriginal = f.readlines()
    inp = []
    x = 0
    while x < len(inpOriginal):
        if 'START_DATE' in inpOriginal[x][0:10]:  # necessary to avoid changing 'REPORT_START_DATE' at the same time.
            inp.append("""START_DATE\t\t{}\n""".format(startDate))

        elif 'REPORT_START_DATE' in inpOriginal[x]:
            inp.append("""REPORT_START_DATE\t\t{}\n""".format(period[0]))

        elif 'END_DATE' in inpOriginal[x]:
            inp.append("""END_DATE\t\t{}\n""".format(period[1]))

        # Changing time resolutions
        elif 'REPORT_STEP' in inpOriginal[x]:
            inp.append("""REPORT_STEP\t\t00:00:0{}\n""".format(timeResolutionFullNetwork[:-1]))
        elif 'WET_STEP' in inpOriginal[x]:
            inp.append("""WET_STEP\t\t00:00:0{}\n""".format(timeResolutionFullNetwork[:-1]))
        elif 'DRY_STEP' in inpOriginal[x]:
            inp.append("""DRY_STEP\t\t00:00:0{}\n""".format(timeResolutionFullNetwork[:-1]))
        elif 'ROUTING_STEP' in inpOriginal[x]:
            inp.append("""ROUTING_STEP\t\t00:00:0{}\n""".format(timeResolutionFullNetwork[:-1]))
        elif 'TSBINARY' in inpOriginal[x]:
            inp.append("""TSBINARY\t\t{}\n""".format(int(binary)))

        # Update input files
        elif '[TIMESERIES]' in inpOriginal[x]:
            xTimeseries = x
            xTimeseriesEnd = x
            for j in range(xTimeseries, len(inpOriginal), 1):
                if j-xTimeseries < 15:
                    inp.append(inpOriginal[j])  # Append the first lines containing the paths to the observed values
                if '[PATTERNS]' in inpOriginal[j]:  # stop at next section [PATTERNS]
                    xTimeseriesEnd = j-1
                    break
            x = xTimeseriesEnd

            for node in nodesIndustrial.index:
                inp.append("""{}_flow\t\tFILE\t\t"{}/INPUT/{}_flow.{}"\n""".format(node, dirFullNetwork, node, 'bin' if binary else 'txt').replace('/', "\\"))
                inp.append("""{}_temp\t\tFILE\t\t"{}/INPUT/{}_temp.{}"\n""".format(node, dirFullNetwork, node, 'bin' if binary else 'txt').replace('/', "\\"))
            for node in nodesDf['Node']:
                inp.append("""{}_flow\t\tFILE\t\t"{}/INPUT/{}_flow.{}"\n""".format(node, dirFullNetwork, node, 'bin' if binary else 'txt').replace('/', "\\"))
                inp.append("""{}_temp\t\tFILE\t\t"{}/INPUT/{}_temp.{}"\n""".format(node, dirFullNetwork, node, 'bin' if binary else 'txt').replace('/', "\\"))
            inp.append("""150b_flow\t\tFILE\t\t"{}/INPUT/150b_flow.{}"\n""".format(dirFullNetwork, 'bin' if binary else 'txt').replace('/', "\\"))
            inp.append("""150b_temp\t\tFILE\t\t"{}/INPUT/150b_temp.{}"\n""".format(dirFullNetwork, 'bin' if binary else 'txt').replace('/', "\\"))


            inp.append("\n")  # just a space at the end

        else:
            inp.append(inpOriginal[x])

        x += 1

    with open(file_inp, 'w+') as inpf:
        inpf.seek(0)
        inpf.writelines(inp)

    ## Full network simulation
    print('executing...')
    # sp.call([SWMMHEATEXE, file_inp, file_rpt, file_out], shell=True)

if __name__=="__main__":
    pass