%spatial maps
%dataDir = '/fs1/neurdylab/projects/jICA/jtica_full_2/'; 
ICA_components= niftiread('C:\Users\hardijm1\Projects\jICA\data\full_melodic_IC.nii.gz'); %control ic maps
maskfile = "C:\Users\hardijm1\Projects\jICA\scripts\MNI152_T1_2mm_brain_mask_filled.nii.gz"; %control ic maps
%maskfile = "C:\Users\hardijm1\Documents\MATLAB\TLE\MNI152_T1_2mm_brain_mask_filled.nii.gz"; 




%brain_mask_dir = 'C:\Users\hardijm1\Projects\jICA\scripts\MNI152_T1_2mm_brain_mask_filled.nii.gz'; % folder for brain mask
brain_mask = niftiread(maskfile);
dims = size(brain_mask);
mask_inds = find(brain_mask ~= 0);
 




%%
addpath('C:\Users\hardijm1\Projects\jICA\jtica_full_16')
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

% vox = reshape(ICA_components, [], 40);
MRI_1d = zeros(229694, 40); 

for n = 1:40
    ic = ICA_components(:,:,:,n);
    MRI_1d(:, n) = ic(mask_inds);
end

% ic_map = zeros(229694, 10);
MRI_recover_3D = zeros([dims(:)',10]);

%loop through each component: 8, 16 * 5
for i = 1:80 

       %separate the fMRI signals from the EEG, multiply
       fmri_mix = tica_mat(27:66, i); 
       ic_map = MRI_1d*fmri_mix;

       temp = zeros(dims);
       temp(mask_inds) = ic_map; 

       MRI_recover_3D(:,:,:,i) = temp;
end

%%
% i changes for # joint comps

output_dir = 'C:\Users\hardijm1\Projects\jICA\full_maps\16_comp'; 
hdr = niftiinfo(maskfile);
hdr.Datatype='double';
for i = 1:80
    vol = MRI_recover_3D(:,:,:,i);
    nifti_filename = fullfile(output_dir, ['full_fmri_', num2str(i), '.nii']);
    niftiwrite(vol, nifti_filename, hdr);
end

%%

addpath('C:\Users\hardijm1\Projects\jICA\scripts\');
EEG = load("vpat15-scan02_eeg_pp.mat");
addpath('C:\Users\hardijm1\Downloads\eeglab_current\eeglab2024.0');

eeglab;


%%
% addpath('C:\Users\hardijm1\Projects\jICA\scripts\');
EEG = load("vpat15-scan02_eeg_pp.mat");
% addpath('C:\Users\hardijm1\Downloads\eeglab_current\eeglab2024.0');

brain_ch = 1:26;
chanlocs_use = EEG.EEG.chanlocs(brain_ch);

% eeg_vector = tica_mat(1:26, 4);
% 
% % [~, map_value]= 
% topoplot(eeg_vector, chanlocs_use, 'style', 'map', 'hcolor', 'none', 'electrodes', 'off');

% i changes for # joint comps

save_dir = 'C:\Users\hardijm1\Projects\jICA\full_maps\16_comp\';

for i = 1:80
    eeg_vector = tica_mat(1:26, i); % Extract the vector for the ith band
    figure;
    
    topoplot(eeg_vector, chanlocs_use, 'maplimits', 'maxmin', 'electrodes', 'on');
    
    title(sprintf('Scalp Map for Component %d', i));
    colorbar; 

    savefig(fullfile(save_dir, sprintf('full_eeg_%d.fig', i)));
    close(gcf);
end
%%
