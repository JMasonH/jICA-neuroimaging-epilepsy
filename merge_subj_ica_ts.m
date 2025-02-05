dataDir = '/fs1/neurdylab/projects/jICA/jtica_full_16/ica_ts';
new_dir = '/fs1/neurdylab/projects/jICA/jtica_full_16/single_subject/';


List = dir(fullfile(dataDir, '*.mat'));

if isempty(List)
    error('No .mat files found in the specified directory: %s', dataDir);
else
    disp(['Found ', num2str(length(List)), ' files.']);
end

disp(List);


for d = 1:length(List)

    dat = load(fullfile(dataDir, List(d).name)); 
    timeSeries = dat.OUT.icasig;
    sub_ts = zeros(16, 575, 82); 

    for s = 1:82
        sub_ts(:, :, s) = timeSeries(:, (575*(s-1)+1):575*s);
    end

    save(fullfile(new_dir, ['sub_spec_', List(d).name, '.mat']), 'sub_ts', '-mat');

end
