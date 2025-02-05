#!/bin/bash

# Set default values
input_dir="/fs1/neurdylab/projects/jICA/jICA_dual_reg/sub_spec_jICA/16_comp/t-test/results/sig_res"
brain_mask="/fs1/neurdylab/projects/jICA/jICA_dual_reg/sub_spec_jICA/16_comp/t-test/results/sig_res/MNI152_T1_2mm_brain.nii.gz"

# Function to display usage
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -i, --input_dir DIR    Input directory containing NIfTI files (default: $input_dir)"
    echo "  -m, --mask FILE        Brain mask file (default: $brain_mask)"
    echo "  -h, --help             Display this help message"
    exit 1
}

# Parse command-line options
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--input_dir)
            input_dir="$2"
            shift 2
            ;;
        -m|--mask)
            brain_mask="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Check if the input directory exists
if [ ! -d "$input_dir" ]; then
    echo "Error: Input directory does not exist: $input_dir"
    exit 1
fi

# Check if the brain mask file exists
if [ ! -f "$brain_mask" ]; then
    echo "Error: Brain mask file does not exist: $brain_mask"
    exit 1
fi

# Create output directory
output_dir="${input_dir}/montages"
mkdir -p "$output_dir"

# Create a temporary directory for aligned files
temp_dir="${output_dir}/temp_aligned"
mkdir -p "$temp_dir"

# Loop through NIfTI files in the input directory
for nifti_file in "$input_dir"/*.nii*; do
    if [ -f "$nifti_file" ]; then
        # Extract filename without extension
        filename=$(basename -- "$nifti_file")
        filename_noext="${filename%.*}"
        filename_noext="${filename_noext%.*}"  # Remove second extension if .nii.gz

        # Align the file to original space
        aligned_file="${temp_dir}/${filename_noext}_aligned.nii"
        3drefit -view orig -space ORIG "$nifti_file" "$aligned_file"

        # Create axial montage
        @chauffeur_afni \
            -ulay "$brain_mask" \
            -olay "$aligned_file" \
            -set_dicom_xyz 0 0 0 \
            -montx 5 -monty 3 \
            -set_xhairs OFF \
            -label_mode 1 -label_size 3 \
            -thr_olay 0.95 \
            -prefix "${output_dir}/${filename_noext}_axial" \
            -save_ftype JPEG \
            -do_clean

        # Create sagittal montage
        @chauffeur_afni \
            -ulay "$brain_mask" \
            -olay "$aligned_file" \
            -set_dicom_xyz 0 0 0 \
            -montx 5 -monty 3 \
            -set_xhairs OFF \
            -label_mode 1 -label_size 3 \
            -thr_olay 0.95 \
            -prefix "${output_dir}/${filename_noext}_sagittal" \
            -save_ftype JPEG \
            -do_clean \
            -set_subbricks 0 0 0 \
            -sagittal_slice

        echo "Created montages for $filename"
    fi
done

# Clean up temporary directory
rm -rf "$temp_dir"

echo "All montages have been created in $output_dir"
