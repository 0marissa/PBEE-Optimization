

import pandas as pd
from sklearn.neural_network import MLPRegressor
from sklearn.preprocessing import StandardScaler
import pickle
import sys
import os

import warnings
warnings.filterwarnings("ignore")

str_input = sys.argv[1]
str_split = str_input.split(',')
flt_input = [float(ele) for ele in str_split]
input_data = pd.DataFrame(flt_input)
input_data = input_data.T

cwd = os.getcwd()

mlp = pickle.load(open(os.path.join(cwd, "model_fitted_475_imp0.pkl"),'rb'))
scaler = pickle.load(open(os.path.join(cwd, "scaler_475_imp.pkl"),'rb'))
input_data = scaler.transform(input_data)

return_value = mlp.predict(input_data)

print(return_value[0])

