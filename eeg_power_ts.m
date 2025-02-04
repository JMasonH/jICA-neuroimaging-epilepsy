function OUT = load_eeg_txt(input_txt_file)
    % Open the file
    fid = fopen(input_txt_file, 'r');
    
    % Read the file paths into a cell array
    filePaths = textscan(fid, '%s', 'Delimiter', '\n');
    
    % Close the file
    fclose(fid);
    
    % Convert filePaths to a simple cell array of strings
    filePaths = filePaths{1};
    
    % Loop through each entry in the file paths array
    for i = 1:length(filePaths)
        fprintf('Loading file: %s\n', filePaths{i});
        
        % Load the data from the file specified in the array
        data = load(filePaths{i});  % Ensure filePaths contains file names as strings

        buff = data.frames_bufferOv;

        % Check if the data contains the 'EEG' struct
        if isfield(data, 'EEG')
            EEG = data.EEG;
            fprintf('Loaded EEG struct from file: %s\n', filePaths{i});
            
            % Check if 'srate' field exists in the EEG struct
            if isfield(EEG, 'srate')
                fprintf('EEG.srate found: %f\n', EEG.srate);
                
                % Get the 'times' field from the 'EEG' struct
                frames = [EEG.event(strcmp({EEG.event.type}, 'R149')).latency];

                chans_use = {EEG.chanlocs(1:26).labels};
                
                % Call the make_eeg_regressors_vu function with the appropriate parameters
                make_eeg_regressors_vu(EEG, chans_use, length(frames), 2.1, ['vpat', num2str(i+1), 'power.mat'], [], buff);
            else
                error('EEG.srate field is missing in file: %s\n', filePaths{i});
            end
        else
            error('EEG struct is missing in file: %s\n', filePaths{i});
        end
    end
end
