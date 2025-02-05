#!/bin/bash

# Directory containing the result files
results_dir="/fs1/neurdylab/projects/jICA/jICA_dual_reg/sub_spec_jICA/8_comp/t-test/results/results"

threshold=0.05

# Function to check if AFNI is available
check_afni() {
    if ! command -v 3dclust &> /dev/null; then
        echo "Error: AFNI (3dclust) is not available. Please ensure AFNI is installed and in your PATH."
        exit 1
    fi
}

# Function to check if a file contains significant results
check_significance() {
    local file=$1
    local threshold=$2
    
    echo "Checking file: $file"
    
    if [ ! -f "$file" ]; then
        echo "Error: File does not exist or is not readable."
        return
    fi
    
    # For p-value files (corrp)
    if [[ $file == *corrp* ]]; then
        echo "Treating as p-value file"
        # Count voxels below or equal to the threshold
        significant_voxels=$(3dclust -1thresh $threshold -dxyz=1 1 0 "$file" | grep -c "^[0-9]")
    # For t-statistic files
    else
        echo "Treating as t-statistic file"
        # For positive t-stats, find voxels above the positive t-value corresponding to p=0.05
        # For negative t-stats, find voxels below the negative t-value corresponding to p=0.05
        # Assuming two-tailed test with df=infinity for simplicity
        t_threshold=$(echo "scale=4; $(echo "sqrt(2)*sqrt(-1*l($threshold*2))" | bc -l)" | bc)
        echo "Calculated t-threshold: $t_threshold"
        significant_voxels=$(3dclust -1thresh $t_threshold -dxyz=1 1 0 "$file" | grep -c "^[0-9]")
        significant_voxels=$((significant_voxels + $(3dclust -1thresh -$t_threshold -dxyz=1 1 0 "$file" | grep -c "^[0-9]")))
    fi
    
    echo "Number of significant voxels: $significant_voxels"
    
    if [ $significant_voxels -gt 0 ]; then
        echo "Significant results found in: $file"
    else
        echo "No significant results found in: $file"
    fi
    echo "--------------------"
}

# Main script
echo "Checking for significant results (p <= $threshold) in $results_dir"
echo "------------------------------------------------------------"

# Check if AFNI is available
check_afni

# Check if the directory exists
if [ ! -d "$results_dir" ]; then
    echo "Error: Directory $results_dir does not exist or is not accessible."
    exit 1
fi

# Count the number of .nii.gz files
file_count=$(find "$results_dir" -name "*.nii.gz" | wc -l)
echo "Found $file_count .nii.gz files in $results_dir"

# Loop through all .nii.gz files in the results directory
for file in "$results_dir"/*.nii.gz; do
    if [[ -f "$file" ]]; then
        check_significance "$file" "$threshold"
    fi
done

echo "------------------------------------------------------------"
echo "Finished checking all files."

   
