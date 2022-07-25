# -*- coding: utf-8 -*-
from __future__ import print_function

"""
Function to batch households together based on their cumulated wastewater flow volume.
"""

import pandas as pd

def batch(cumulFlow, minimumVolume):
    """
    Based on solution found here: https://stackoverflow.com/questions/42928710/sort-numbers-into-groups-so-that-the-difference-of-their-sums-is-minimal
    :param cumulFlow:
    :param minimumVolume:
    :return:
    """
    sorted = cumulFlow.sort_values(by=["cumulFlow"], inplace=False, ascending=False)

    nbHouses = 6 ## Start number, 6 households per batch
    while True:
        nbAgg = max(int(len(cumulFlow) / nbHouses), 1)
        aggregation = [[i, []] for i in range(1, nbAgg+1, 1)]
        clock = 0

        sumFlows = [0 for i in range(0, nbAgg, 1)]
        for house, index in zip(sorted["house"], sorted.index):
            house = int(house)
            aggregation[clock][1].append(house)
            sumFlows[clock] += float(sorted.loc[index]["cumulFlow"])
            clock = (clock+1)%nbAgg
        # sumFlows = [sum(sorted[sorted["house"] == i[1]) for i in aggregation]

        if all(i >= minimumVolume for i in sumFlows):
            return aggregation
        elif nbAgg == 1:
            return aggregation
        else:
            nbHouses += 1