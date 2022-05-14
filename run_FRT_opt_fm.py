#!/usr/bin/env python

import os

def mkdir_p(dir):
    '''make a directory (dir) if it doesn't exist'''
    if not os.path.exists(dir):
        os.mkdir(dir)

job_directory = os.getcwd()

# Make top level directories
mkdir_p(job_directory)

# For reference: MATLAB function:
    # fn_FRT_opt_fpm_main(
    # analysis_run_number, 
    # analysis_hazardLevel, 
    # analysis_nsim,  
    # analysis_n_CPU, ...                              
    # analysis_impeding_factors, 
    # analysis_platform, 
    # opt_pop,
    #  opt_T_target)

run_number = [1,2,3,4,5]
hazard = [475]
nsim_number = [40000]
nCPU_number = [24]
impeding_factor = [0]
population = [96]
T_target = [14]

for run in run_number:
    for nCPU in nCPU_number:
        for nsim in nsim_number:
            for haz in hazard:
                for imp in impeding_factor:
                    for Tt in T_target:
                        for pop in population:
                            job_name = "GA_run"+str(run)+"_T"+str(Tt)+"_"+str(haz)+"yr_imp"+str(imp)+"_N"+"_CPU"+str(nCPU)+"_pop"+str(pop)
                            job_file = os.path.join(job_directory, "%s.job" % job_name)
                            with open(job_file,'wb') as fh:
                                fh.writelines("#!/bin/bash\n")
                                fh.writelines("#SBATCH --job-name=%s.job\n" % job_name)
                                fh.writelines("#SBATCH --output=%s.log\n" % job_name)
                                fh.writelines("#SBATCH --time=96:00:00\n")
                                fh.writelines("#SBATCH --mem=256000\n")
                                fh.writelines("#SBATCH --nodes=1\n")
                                fh.writelines("#SBATCH --ntasks-per-node=1\n")
                                fh.writelines("#SBATCH --cpus-per-task=32\n")
                                fh.writelines("#SBATCH --qos=normal\n")
                                fh.writelines("#SBATCH --partition=cee\n")
                                fh.writelines("#SBATCH --mail-type=ALL\n")
                                fh.writelines("#SBATCH --mail-user=oissa@stanford.edu\n")
                                fh.writelines("ml python/3.6.1\n")
                                fh.writelines("ml load matlab\n")
                                fh.writelines("matlab -r \"fn_FRT_opt_fm_main %s %s %s %s %s %s %s %s \" \n" % (run, haz, nsim, nCPU, imp, "hpc", pop, Tt ))
                            os.system("sbatch %s" % job_file)
