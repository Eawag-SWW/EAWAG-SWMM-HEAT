import os
import pandas as pd

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


if __name__=="__main__":

    dir = "Q:/Abteilungsprojekte/eng/SWWData/BrunoHadengue/PMP_Processes/FehraltorfClean"
    nodesDf = pd.read_excel('{}/Calculations.xlsx'.format(dir))
    periodShort = "20190408-20190410"
    PCModel = 'ReferencePC'
    scenario = 'Reference'

    for node in nodesDf['Node']:
        aggregation = batch(int(round(nodesDf[nodesDf['Node'] == node]['HousesPerNode'])))
        for agg in aggregation:
            try:
                os.rename('{}/SWMM_Temp/PCoutputFiles/{}/{}/{}_{}_{}.out'.format(dir, PCModel, node, node, agg[0], scenario), '{}/SWMM_Temp/PCoutputFiles/{}/{}/{}_{}_{}_{}.out'.format(dir, PCModel, node, node, periodShort, agg[0], scenario))
                print("renamed {}_{}.inp".format(node, agg[0]))
            except:
                print("File not found, skipping")
                continue