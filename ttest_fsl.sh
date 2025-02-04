module load GCC/8.2.0
module load OpenMPI/3.1.4
module load FSL/6.0.1

# Set directories and files
INPUT_DIR="/fs1/neurdylab/projects/jICA/jICA_dual_reg/sub_spec_jICA/16_comp/t-test/"
OUTPUT_DIR="/fs1/neurdylab/projects/jICA/jICA_dual_reg/sub_spec_jICA/16_comp/t-test/results"
DESIGN_MAT="/fs1/neurdylab/projects/jICA/jICA_dual_reg/sub_spec_jICA/design.mat"
DESIGN_CON="/fs1/neurdylab/projects/jICA/jICA_dual_reg/sub_spec_jICA/design.con"
MASK="/fs1/neurdylab/MNI152_T1_2mm_brain_mask_filled.nii.gz"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Function to perform randomise t-test
foo() {
    local comp_num="$1"
    local input_file="${INPUT_DIR}/comp_${comp_num}_4D.nii.gz"
    local output_prefix="${OUTPUT_DIR}/comp_${comp_num}"

    echo "Processing comp_${comp_num}"

    # Create a temporary directory
    tmp_dir=$(mktemp -d -t randomise-XXXXXXXX)
    mkdir -p $tmp_dir/INPUTS $tmp_dir/OUTPUTS

    # Check if input file exists
    if [ ! -f "$input_file" ]; then
        echo "Error: Input file $input_file not found"
        rm -rf $tmp_dir
        return 1
    fi

    # Copy input file to temporary directory
    cp "$input_file" "$tmp_dir/INPUTS/"

    # Run randomise
    randomise -i "$tmp_dir/INPUTS/comp_${comp_num}_4D.nii.gz" \
              -o "$tmp_dir/OUTPUTS/comp_${comp_num}" \
              -d "$DESIGN_MAT" \
              -t "$DESIGN_CON" \
              -m "$MASK" \
              -x -c 2.3 -n 5000 \
              -T

    # Copy results back to output directory
    cp $tmp_dir/OUTPUTS/comp_${comp_num}* "$OUTPUT_DIR/"

    # Clean up temporary directory
    rm -rf $tmp_dir

    echo "Completed t-test for comp_$comp_num"
}

# Export the function so it's available to subshells
export -f foo

# Set the number of parallel processes
N=8

# Run t-tests in parallel
(
for comp_num in {1..80}; do
    ((i=i%N)); ((i++==0)) && wait
    foo "$comp_num" &
done
)

echo "All t-tests completed"
