addpath('/fs1/neurdylab/projects/jICA/spm12');

% Define the directory containing the .mat files
dataDir = '/fs1/neurdylab/projects/jICA/vpat_power';

% Get a list of all .mat files in the directory
fileList = dir(fullfile(dataDir, '*.mat'));

% Loop through each file in the directory
for fileIdx = 1:length(fileList)
    % Load the current .mat file
    filePath = fullfile(fileList(fileIdx).folder, fileList(fileIdx).name);
    data = load(filePath);
    
    % Check if the loaded data contains the expected structure
    if isfield(data, 'OUT') && isfield(data.OUT, 'BLP')
        % Extract the BLP matrix
        BLP = data.OUT.BLP;
        
        % Initialize the BLP_conv matrix
        BLP_conv = zeros(size(BLP));
        
        % Loop through each frequency band (1 to 5)
        for bandIdx = 1:size(BLP, 1)
            % Loop through each electrode (1 to 26)
            for electrodeIdx = 1:size(BLP, 3)
                % Extract the time series for the current band and electrode
                timeSeries = squeeze(BLP(bandIdx, :, electrodeIdx));
                
                % Convolve the time series with the HRF function
                convolvedTimeSeries = conv_hrf(timeSeries);  % Using your HRF function
                
                % Store the convolved time series in the BLP_conv matrix
                BLP_conv(bandIdx, :, electrodeIdx) = convolvedTimeSeries;
            end
        end
        
        % Save the convolved results into a new .mat file with '_conv' appended to the name
        [~, fileName, fileExt] = fileparts(filePath);
        newFilePath = fullfile(dataDir, [fileName, '_conv', fileExt]);
        OUT.BLP_conv = BLP_conv; % Save the convolved data in a new field BLP_conv
        save(newFilePath, 'OUT');
    else
        % Display a warning if the file does not have the expected structure
        warning('File %s does not have the expected structure. Skipping file.', filePath);
    end
end
