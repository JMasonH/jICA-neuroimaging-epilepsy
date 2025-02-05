%% Define directories and settings
data_dir = '/fs1/neurdylab/projects/jICA/jtica_full_16/single_subject/';
output_dir = '/fs1/neurdylab/projects/jICA/jtica_full_16/amp_spec_02';

% Create output directory if it doesn't exist
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% Paired scan matrix
D = [5,6; 8,9; 10,11; 12,13; 14,15; 17,18; 19,20; 21,22; 23,24; 25,26; 27,28; 29,30; ...
     31,32; 33,34; 37,38; 40,41; 42,43; 45,46; 48,49; 53,54; 55,56; 59,60; 61,62; 63,64;...
     65,66; 67,68; 69,70; 71,72; 77,78; 80,81];

% Parameters
fs = 1/2.1;  % Sampling frequency
num_bins = 5;  % Number of frequency bins
num_components = 16;  % Number of components
slice_names = {'delta', 'theta', 'alpha', 'beta', 'gamma'};

% Calculate number of unique subjects after pairing
num_paired = size(D, 1);
num_unpaired = 82 - (2 * num_paired);  % Total subjects minus paired subjects
total_unique_subjects = num_paired + num_unpaired;

% Get indices of unpaired subjects
all_subjects = 1:82;
paired_subjects = D(:)';  % Flatten D into a single row
unpaired_subjects = setdiff(all_subjects, paired_subjects);

% Determine control and patient counts after pairing
control_indices = 1:56;
patient_indices = 57:82;

% Initialize arrays to store power spectra
control_spectra = cell(length(slice_names), 1);
patient_spectra = cell(length(slice_names), 1);

% Process each frequency band
for slice = 1:length(slice_names)
    % Load the data for this frequency band
    data = load(fullfile(data_dir, sprintf('sub_spec_%s.mat', slice_names{slice})));
    time_series = data.sub_ts;
    
    % Initialize temporary storage for this slice
    temp_spectra = zeros(total_unique_subjects, num_components, num_bins);
    current_subject = 1;
    
    % Process paired subjects
    for pair = 1:size(D, 1)
        scan1_idx = D(pair, 1);
        scan2_idx = D(pair, 2);
        
        % Calculate spectra for both scans and average them
        for component = 1:num_components
            % Process first scan
            [pxx1, f] = pwelch(squeeze(time_series(component, :, scan1_idx)), 36, [], [], fs, 'power');
            amp1 = sqrt(pxx1);
            
            % Process second scan
            [pxx2, f] = pwelch(squeeze(time_series(component, :, scan2_idx)), 36, [], [], fs, 'power');
            amp2 = sqrt(pxx2);
            
            % Average the amplitudes
            avg_amp = (amp1 + amp2) / 2;
            
            % Bin the averaged amplitude
            bin_edges = linspace(min(f), max(f), num_bins + 1);
                

            labels = zeros(num_bins);
            for bin = 1:num_bins
                bin_indices = f >= bin_edges(bin) & f < bin_edges(bin+1);
                temp_spectra(current_subject, component, bin) = mean(avg_amp(bin_indices));
                label = mean(f(bin_indices)); 
                labels(bin) = label; 
            end
        end
        current_subject = current_subject + 1;
    end
   
     

    % Process unpaired subjects
    for i = 1:length(unpaired_subjects)
        subj_idx = unpaired_subjects(i);
        
        for component = 1:num_components
            [pxx, f] = pwelch(squeeze(time_series(component, :, subj_idx)), 36, [], [], fs, 'power');
            amplitude = sqrt(pxx);
            
            bin_edges = linspace(min(f), max(f), num_bins + 1);
            

            for bin = 1:num_bins
                bin_indices = f >= bin_edges(bin) & f < bin_edges(bin+1);
                temp_spectra(current_subject, component, bin) = mean(amplitude(bin_indices)); 
            end
        end
        current_subject = current_subject + 1;
    end
    
    % Separate controls and patients
    % Create mapping from original to new indices
    index_map = zeros(1, 82);
    curr_idx = 1;
    
    % Map paired subjects
    for pair = 1:size(D, 1)
        index_map(D(pair, 1)) = curr_idx;
        index_map(D(pair, 2)) = curr_idx;
        curr_idx = curr_idx + 1;
    end
    
    % Map unpaired subjects
    for i = 1:length(unpaired_subjects)
        index_map(unpaired_subjects(i)) = curr_idx;
        curr_idx = curr_idx + 1;
    end
    
    % Determine which subjects are controls and patients in the new indexing
    control_spectra{slice} = [];
    patient_spectra{slice} = [];
    
    for i = 1:total_unique_subjects
        % Find original indices that map to this new index
        orig_indices = find(index_map == i);
        if any(orig_indices <= 56)  % If any original index was a control
            control_spectra{slice} = [control_spectra{slice}; temp_spectra(i, :, :)];
        else
            patient_spectra{slice} = [patient_spectra{slice}; temp_spectra(i, :, :)];
        end
    end
end

% Plot results
subplot_rows = ceil(sqrt(num_components));
subplot_cols = ceil(num_components / subplot_rows);



% Perform t-tests and FDR correction
for slice = 1:length(slice_names)
    % Create a new figure
    figure('Position', [100, 100, 300*subplot_cols, 250*subplot_rows]);

    
    for component = 1:num_components
        subplot(subplot_rows, subplot_cols, component);
        
        p_values = zeros(1, num_bins);
        stats = struct('tstat', zeros(1, num_bins));

        for bin = 1:num_bins
            [~, p, ~, stats_temp] = ttest2(squeeze(patient_spectra{slice}(:, component, bin)), ...
                                         squeeze(control_spectra{slice}(:, component, bin)));
            p_values(bin) = p;
            stats.tstat(bin) = stats_temp.tstat;
        end
        
        % Apply FDR correction
        [~, ~, adj_p] = fdr_bh(p_values, 0.05, 'pdep');
        
        % Debug information
        fprintf('Slice: %d, Component: %d\n', slice, component);
        fprintf('p-values: %s\n', mat2str(p_values, 3));
        fprintf('adj_p: %s\n', mat2str(adj_p, 3));
        fprintf('t-stats: %s\n', mat2str(stats.tstat, 3));
        
        

        % Plot results
        if all(isnan(adj_p)) || all(adj_p == 1)
            warning('All p-values are NaN or 1 for Slice %d, Component %d', slice, component);
            text(0.5, 0.5, 'No significant differences', 'HorizontalAlignment', 'center');
            set(gca, 'XTick', [], 'YTick', []);
        else
            % Multiply -log10(adj_p) by sign of t-statistic
            
            % Then multiply -log10 of adjusted p-values by sign of t-statistic
            signed_log_p = (-log10(adj_p(:))) .* sign(stats.tstat(:));
            
            % Create bar plot with default color
            b = bar(1:num_bins, signed_log_p);
            
            % Set colors based on direction
            for bin = 1:num_bins
                if signed_log_p(bin) > 0
                    set(b(1), 'FaceColor', [0.2 0.2 0.8]);  % Red for positive
                else
                    set(b(1), 'FaceColor', [0.2 0.2 0.8]);  % Blue for negative
                end
            end
            
            title(sprintf('Comp %d', component));
            xlabel('Freq Bin');
            ylabel('Signed -log10(Adj p)');
            
            % Set y-axis limits to be symmetric
            max_abs_val = max(abs(signed_log_p(~isinf(signed_log_p))));
            if isempty(max_abs_val) || max_abs_val == 0
                ylim([-1 1]);
            else
                ylim([-max_abs_val*1.1 max_abs_val*1.1]);
            end
            
            labels = round(labels, 2);
        
            xticklabels({labels(1,1), labels(2,1), labels(3,1), labels(4,1), labels(5,1)});

            % Add zero line
            hold on;
            plot([0.5 num_bins+0.5], [0 0], 'k-', 'LineWidth', 0.5);
            
            % Add significance stars
            for bin = 1:num_bins
                if adj_p(bin) < 0.05
                    if signed_log_p(bin) > 0
                        text(bin, signed_log_p(bin), '*', ...
                             'HorizontalAlignment', 'center', ...
                             'VerticalAlignment', 'bottom');
                    else
                        text(bin, signed_log_p(bin), '*', ...
                             'HorizontalAlignment', 'center', ...
                             'VerticalAlignment', 'top');
                    end
                end
            end
            hold off;
        end


    end
    
    % Set overall title and save
    sgtitle(sprintf('%s Component Amplitude Spectra', slice_names{slice}), 'Interpreter', 'none');
    
    % Add legend
    h = axes('Position', [0.95 0.1 0.1 0.1], 'Visible', 'off');
    plot(h, [0 1], [0 1], 'r-', 'Visible', 'off');
    hold on;
    plot(h, [0 1], [0 1], 'b-', 'Visible', 'off');
    legend(h, {'Patients > Controls', 'Patients < Controls'}, 'Location', 'southoutside');
    
    % Save figure
    saveas(gcf, fullfile(output_dir, sprintf('%s_amplitude_spectra.png', slice_names{slice})));
end



% Display data dimensions
disp('Patient spectra dimensions after pairing:');
cellfun(@(x) disp(size(x)), patient_spectra);
disp('Control spectra dimensions after pairing:');
cellfun(@(x) disp(size(x)), control_spectra);
