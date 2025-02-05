function check_fsl_results()
    % Directory containing the result files
    results_dir = '/fs1/neurdylab/projects/jICA/jICA_dual_reg/sub_spec_jICA/16_comp/t-test/results';  % Change this to your results directory
    
    % Significance threshold (1-p)
    threshold = 0.95;  % Corresponds to p <= 0.05
    
    % Print header
    fprintf('Checking for significant results (1-p >= %.2f) in %s\n', threshold, results_dir);
    fprintf('------------------------------------------------------------\n');
    
    % Check if the directory exists
    if ~exist(results_dir, 'dir')
        error('Directory %s does not exist or is not accessible.', results_dir);
    end
    
    % Get all .nii.gz files in the directory
    files = dir(fullfile(results_dir, '*.nii.gz'));
    
    fprintf('Found %d .nii.gz files in %s\n', length(files), results_dir);
    
    % Loop through all files
    for i = 1:length(files)
        file_path = fullfile(results_dir, files(i).name);
        check_significance(file_path, threshold);
    end
    
    fprintf('------------------------------------------------------------\n');
    fprintf('Finished checking all files.\n');
end

function check_significance(file_path, threshold)
    try
        % Load the NIfTI file
        nii = niftiread(file_path);
        
        % Get file info
        info = niftiinfo(file_path);
        
        % Check if it's a p-value file or t-statistic file
        if contains(file_path, 'corrp')
            % For corrected p-value files, count voxels above or equal to the threshold
            significant_voxels = sum(nii(:) >= threshold);
        elseif contains(file_path, 'tstat')
            % For t-statistic files, we need the degrees of freedom
            % This is typically N - k - 1, where N is number of subjects and k is number of regressors
            % For this example, let's assume df = 20 (adjust this based on your study)
            df = 20;
            p_threshold = 1 - threshold;  % Convert back to p-value for t-distribution
            t_threshold = tinv(1 - p_threshold/2, df);
            significant_voxels = sum(abs(nii(:)) > t_threshold);
        else
            % For other types of files, we'll just report we can't determine significance
            significant_voxels = NaN;
        end
        
        % Count non-zero voxels (brain mask)
        non_zero_voxels = sum(nii(:) ~= 0);
        
        % Print results
        [~, file_name, ~] = fileparts(file_path);
        fprintf('File: %s\n', file_name);
        fprintf('Total non-zero voxels: %d\n', non_zero_voxels);
        
        if isnan(significant_voxels)
            fprintf('Unable to determine significant voxels for this file type\n');
        else
            fprintf('Number of significant voxels: %d\n', significant_voxels);
            if significant_voxels > 0
                fprintf('Significant results found\n');
            else
                fprintf('No significant results found\n');
            end
        end
        fprintf('--------------------\n');
    catch ME
        fprintf('Error processing %s: %s\n', file_path, ME.message);
    end
end
   
