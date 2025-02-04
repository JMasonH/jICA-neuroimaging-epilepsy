#!/bin/bash

# Directory containing the NIfTI files
input_dir="/mnt/c/Users/hardijm1/Projects/jICA/full_maps/8_comp/niftis"
# Directory to save the generated JPG files
output_dir="/mnt/c/Users/hardijm1/Projects/jICA/full_maps/8_comp"
# AFNI's MNI template
mni_template="/mnt/c/Users/hardijm1/Projects/jICA/scripts/MNI152_T1_2mm_brain.nii.gz"

# Create output directory if it doesn't exist
mkdir -p "$output_dir"

# Loop through all NIfTI files in the input directory
for nifti_file in "$input_dir"/full_fmri_*.nii; do
    # Extract the base filename without the extension
    base_filename=$(basename "$nifti_file" .nii)

    # Extract the number from the filename
    file_number=$(echo "$base_filename" | grep -oP '(?<=full_fmri_)\d+')

    # Verify if a number was extracted
    if [ -z "$file_number" ]; then
        echo "Warning: No number found in filename $nifti_file. Skipping file."
        continue
    fi

    echo "Processing file: $nifti_file"
    echo "Extracted file number: $file_number"

    3drefit -view orig -space ORIG "$mni_template"

    # Create an axial montage (4x4 grid, spacing 3, no border, no xhairs)
    @chauffeur_afni                                                       \
        -ulay "$mni_template"                                             \
        -olay "$nifti_file"                                               \
        -prefix "${output_dir}/full_${file_number}"                       \
        -montx 4 -monty 4                                                 \
        -delta_slices 3 3 3                                               \
        -set_xhairs OFF                                                   \
        -no_cor                                                           \
        -do_clean                                                         \
        -box_focus_slices AMASK_FOCUS_ULAY                                \
        -cbar GoogleTurbo
   done

echo "Processing complete. All images saved to $output_dir"
