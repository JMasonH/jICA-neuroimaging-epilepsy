#!/bin/bash

module load GCC/5.4.0-2.26 
module load OpenMPI/1.10.3
module load FSL/5.0.10


melodic -i /fs1/neurdylab/projects/jICA/all_paths_mri.txt -d 40 -o /fs1/neurdylab/projects/jICA/spatial_ICA_out_full --Oorig --report --tr=2.1 -v
