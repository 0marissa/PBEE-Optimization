## Function that modifies JSON component fragility files

import json
import os
from pathlib import Path
import sys

def improveComponents(scale, componentName):

    # Ensure scale always interpreted as a float value
    scale = float(scale)
    
    # Add the (modified) fragility component folder to path
    currpath = Path().absolute()
    os.chdir("Fragility Data with modifications")

    with open(componentName + '.json','rb') as f:
        file_dict = json.load(f) 

    n_groups = len(file_dict['DSGroups'])
    new_groups_list = []
    print('Initial')
    print(file_dict['DSGroups'][0]['MedianEDP'])
    for DSgroup_dict in file_dict['DSGroups']:
        #new_median_EDP_list = []
        medianEDP = DSgroup_dict['MedianEDP']
        theta = medianEDP
        theta = float(theta)*scale
        theta = str(theta)
        medianEDP = theta
        #new_median_EDP_list.append(medianEDP)
        DSgroup_dict['MedianEDP'] = medianEDP
        new_groups_list.append(DSgroup_dict)

    file_dict['DSGroups'] = new_groups_list
    print('Final')
    print(file_dict['DSGroups'][0]['MedianEDP'])

    with open(componentName + '.json','w') as f:
        json.dump(file_dict,f) 


if __name__ == "__main__":
    improveComponents(*sys.argv[1:])
