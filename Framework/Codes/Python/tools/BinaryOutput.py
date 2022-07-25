# -*- coding: utf-8 -*-
from __future__ import print_function

"""
Created on 04.10.2021

@author: hadengbr

Script test to output results in binary format instead of ASCII.
"""

import pandas as pd
import numpy as np
from collections import OrderedDict
from matplotlib import pyplot as plt
# from codetiming import Timer  # For optimization purposes


def writeToBinary(df, outputFile, columns=None, recordTypeDict=None, parse=True, format='<f4'):
    # Set defaults
    if recordTypeDict is None:
        recordTypeDict = OrderedDict([("fieldformat", "<u1"), ("month", "<u1"), ("day", "<u1"), ("year", "<u2"),
                                      ("hour", "<u1"), ("minute", "<u1"), ("second", "<u1")])

    # Merge columns into recordTypeDict
    if columns is None:
        if parse:
            columns = df.columns
        else:
            raise Exception("No columns dictionary were provided and parse=False")

    for column in columns:
        recordTypeDict.update({column: format})

    # Merge columns into recordTypeDict
    # Create dtype format
    # recordTypeDtype = np.dtype({"names": [key for key in recordTypeDict.keys()],
    #                             "formats": [recordTypeDict[key] for key in recordTypeDict.keys()]})

    # Datetime column split
    dfTmp = df.copy(deep=True)  # We need a copy to make sure we do not alter the original dataframe
    dfTmp.index = pd.to_datetime(dfTmp.index)
    dfFormat = pd.DataFrame()
    dfFormat['fieldformat'] = np.ones(len(df)) * 3
    dfFormat['month'] = dfTmp.index.month
    dfFormat['day'] = dfTmp.index.day
    dfFormat['year'] = dfTmp.index.year
    dfFormat['hour'] = dfTmp.index.hour
    dfFormat['minute'] = dfTmp.index.minute
    dfFormat['second'] = dfTmp.index.second

    # Reindex before column transfer
    dfTmp.index = dfFormat.index

    # Column transfer
    for column in columns:
        dfFormat[column] = dfTmp[column].fillna(0)

    # Transform to records array
    recordArray = dfFormat.to_records(index=False, column_dtypes=recordTypeDict)  # .astype(recordTypeDtype)

    # Print to binary file
    recordArray.tofile(outputFile)

    return 0

def readFromBinary(filename, columns, format='<f4', recordTypeDict=None):
    """
    Read from a binary file with default format. You can override the format to specify how the binary file looks like.
    Make sure of using ordered dictionaries if you are using Python 2.7!!
    :param filename: binary file to read from
    :param columns: column names
    :param format: format of the columns. By default, this is '<f2'
    :param recordTypeDict: format of the date. By default, this is an ordered dictionary starting with 'fieldformat'
    :return: pandas dataframe
    """
    # Set defaults
    if recordTypeDict is None:
        recordTypeDict = OrderedDict([("fieldformat", "<u1"), ("month", "<u1"), ("day", "<u1"), ("year", "<u2"),
                                      ("hour", "<u1"), ("minute", "<u1"), ("second", "<u1")])

    # Merge columns into recordTypeDict
    for column in columns:
        recordTypeDict.update({column: format})

    # Create dtype format - cannot use dict keys in Python 2 because the order is not respected
    tempDict = {"names": [key for key in recordTypeDict.keys()],
                                "formats": [recordTypeDict[key] for key in recordTypeDict.keys()]}
    recordTypeDtype = np.dtype(tempDict)

    # Read binary into unformatted dataframe
    # with Timer():
    df = pd.DataFrame.from_records(np.fromfile(filename, dtype=recordTypeDtype))

    # with Timer():
    df.index = pd.to_datetime(df[['month', 'day', 'year', 'hour', 'minute', 'second']], infer_datetime_format=True)
    df = df.drop(columns=['month', 'day', 'year', 'hour', 'minute', 'second', 'fieldformat'])

    return df


if __name__ == "__main__":
    df = readFromBinary("C:/Users/hadengbr/04_Programming/tmp/FlowTemp_5h_1.bin", ['flow', 'temperature'])
    print(df)