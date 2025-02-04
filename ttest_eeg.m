% Define directories
patients_dir = '/fs1/neurdylab/projects/jICA/jICA_dual_reg/16_comp/patients';
controls_dir = '/fs1/neurdylab/projects/jICA/jICA_dual_reg/16_comp/controls';
output_dir = '/fs1/neurdylab/projects/jICA/jICA_dual_reg/sub_spec_jICA/16_comp/t-test/results';
%addpath('/fs1/neurdylab/projects/jICA/fdr_bh.m');

% List of patient and control .mat files
patient_files = dir(fullfile(patients_dir, '*_jICA.mat'));
control_files = dir(fullfile(controls_dir, '*_jICA.mat'));

% Ensure output directory exists
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% Initialize struct to store t-test results
t_test_results = {};

% Loop over 8 ICA components and 5 frequency bands (x = 1:8, z = 1:5)
for x = 1:16
    for z = 1:5
        % Initialize vectors for patient and control data
        patient_data = [];
        control_data = [];

        % Extract data from patient files
        for i = 1:length(patient_files)
            load(fullfile(patient_files(i).folder, patient_files(i).name), 'OUT');
            eeg_data = OUT.spatial(x, 1:26, z);  % Extract EEG data (columns 1:26)
            patient_data = [patient_data; eeg_data];
        end

        % Extract data from control files
        for i = 1:length(control_files)
            load(fullfile(control_files(i).folder, control_files(i).name), 'OUT');
            eeg_data = OUT.spatial(x, 1:26, z);  % Extract EEG data (columns 1:26)
            control_data = [control_data; eeg_data];
        end

        % Perform two-sample t-test across 26 EEG signals (columns 1:26)
        [h, pvals, ~, stats] = ttest2(patient_data, control_data);

        % Adjust p-values using Benjamini-Hochberg correction
        [h_adj, crit_p, adj_p] = fdr_bh(pvals, 0.05, 'pdep');

        % Store t-stats, p-values, adjusted p-values, and hypothesis test results
        tstats = stats.tstat;  % t-statistic values
        t_test_results{x, z} = struct('tstats', tstats, 'pvals', pvals, 'adj_p', adj_p, 'h', h_adj);

        % Calculate # as (8*(z-1)) + x
        comp_num = (16*(z-1)) + x;

        % Save results to .mat file
        comp_filename = fullfile(output_dir, ['comp_', num2str(comp_num), '_eeg.mat']);
        save(comp_filename, 'tstats', 'pvals', 'adj_p', 'h_adj');
    end
end

% Optionally save the entire t_test_results structure for later reference
save(fullfile(output_dir, 't_test_results.mat'), 't_test_results');
