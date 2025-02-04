addpath('C:\Users\hardijm1\Projects\jICA\jtica_full_16');
addpath('C:\Users\hardijm1\Projects\jICA\hrf_conv\');

path_dir = 'C:\Users\hardijm1\Projects\jICA\hrf_conv\';
files = dir(fullfile(path_dir, '*.mat'));

c_delta = load('delta-tica_full.mat');
d = c_delta.OUT.A;
c_theta = load('theta-tica_full.mat');
t = c_theta.OUT.A;
c_alpha = load('alpha-tica_full.mat');
a = c_alpha.OUT.A;
c_beta = load('beta-tica_full.mat');
b = c_beta.OUT.A;
c_gamma = load('gamma-tica_full.mat');
g = c_gamma.OUT.A; 

tica_mat = cat(2, d,t,a,b,g);


num_components = size(tica_mat,2);
n = num_components/5;

    % Load all temporal ICA components
   % ICA_components = tica_mat(1:26, 1:80);

 
%loop through 5 power bands


    %match mixing matrix components to proper power band
    % ICA_components = tica_mat(1:26, ((n*(b-1))+1):n*b);

    % Loop through each entry in single subject, hrf convolved data
for i = 1:length(files)

       % Y = load(files{i});

    file_name = fullfile(path_dir, files(i).name);
    Yraw = load(file_name);
    Ymat = Yraw.OUT.BLP_conv;

    spatial = zeros(num_components, 26);
    time = zeros(num_components, size(Ymat, 2)); 

    %loop through 5 power bands
    for b = 1:5

        %match mixing matrix components to proper power band
        ICA_components = tica_mat(1:26, ((n*(b-1))+1):n*b);

    
        % Load the proper frequency band matrix
        % Yraw = load(file_name);
        % Ymat = Yraw.OUT.BLP_conv;

        Ybox = Ymat(b, :, :);
        Y = (squeeze(Ybox(1, :, :)))';
        
        % Initialize matrix to store ICA components (electrodes x components)
        ICA_spatial_maps_voxels = zeros(26, n);
        
        % Loop through each of the n components for a given band
        for j = 1:n
            component = ICA_components(:, j);  % Access the j-th component
            ICA_spatial_maps_voxels(:, j) = component;
        end
        

        % Derive subject-specific time course (temporal regression)
        X = [ones(size(ICA_spatial_maps_voxels, 1), 1), zscore(ICA_spatial_maps_voxels)];
        beta_1 = pinv(X) * Y;
        beta_1_z = zscore(beta_1);
        
        % Derive subject-specific spatial maps (spatial regression)
        x_ts = beta_1(2:end, :);  % Use components' time series (exclude intercept)
        x_ts = [ones(size(x_ts, 2), 1), zscore(x_ts')];  % Regress over time
        beta_2 = pinv(x_ts) * Y';  % Get spatial maps

        % Save results

        spatial(( ((b-1)*n) + 1 : b*n) , :) = beta_2(2:(n+1), :);
        time(( ((b-1)*n) + 1 : b*n) , :) = beta_1(2:(n+1), :);
        
    end

    [~, fileName, ~] = fileparts(files(i).name);
    newFilePath = fullfile('C:\Users\hardijm1\Projects\jICA\jICA_single_subject\16_comp_eeg\', [fileName, '_eeg.mat']);
    OUT.spatial = spatial;
    OUT.time_series = time;
    save(newFilePath, 'OUT'); 
    fprintf('Processed subject: %s\n', fileName);
end
