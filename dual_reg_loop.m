%DUAL REGRESSION CODE
function OUT = dual_reg_loop(input_txt_file)
    % Open the file
    fid = fopen(input_txt_file, 'r');
    
    % Read the file paths into a cell array
    filePaths = textscan(fid, '%s', 'Delimiter', '\n');
    
    % Close the file
    fclose(fid);
    
    % Convert filePaths to a simple cell array of strings
    filePaths = filePaths{1};
    
    ICA_components= niftiread('/fs1/neurdylab/projects/jICA/spatial_ICA_out_full/melodic_IC.nii.gz');
    mask = niftiread('/fs1/neurdylab/projects/jICA/MNI152_T1_2mm_brain_mask_filled.nii.gz');

    % Loop through each entry in the file paths array
    
   for i = 1:length(filePaths)

       Y=niftiread(filePaths{i});

        dims = size(Y);

        newY = reshape(Y,prod(dims(1:3)),size(Y,4));

        vox = find(mask>0);

        maskedY = newY(vox,:);
        
        component1 = ICA_components(:,:,:,1);
        
        maskedComponent1 = component1(vox);
        
        ICA_spatial_maps_voxels = zeros(size(maskedComponent1,1),size(ICA_components,4));
        
        for j = 1:size(ICA_components,4)
            component = ICA_components(:,:,:,j);
            maskedComponent = component(vox);
            ICA_spatial_maps_voxels(:,j) = [maskedComponent];
        end
        
        X=[ones(size(ICA_spatial_maps_voxels,1),1), zscore(ICA_spatial_maps_voxels)];
        
        %derive subject specific time course
        beta_1= pinv(X)*maskedY;
        beta_1_z = zscore(beta_1);
        
        %label subject specific ts as the next X to derive spatial map
        x_ts=beta_1(2:41,:);
        
        x_ts=[ones(size(x_ts,2),1),zscore(x_ts')];
        
        %derive subject specific spatial maps
        beta_2= pinv(x_ts)*maskedY';

        [~, fileName] = fileparts(filePaths{i});
        newFilePath = fullfile('/fs1/neurdylab/projects/jICA/ss_IC_full', [fileName, '_IC_reg', '.mat']);
        OUT.spatial = beta_2;
        OUT.time_series = beta_1;
        save(newFilePath, 'OUT'); 
        fprintf('Anotha One');
   end
end   

%%

% for i = 1:size(beta_2,1)
%     comp = beta_2(i,:);
%     spatial_map = zeros(dims(1:3));
%     spatial_map(vox) = comp';
%     subComp(:,:,:,i) = [spatial_map];
% end
% 
% dmn = subComp(:,:,:,9);
% 
% figure;
% montage(dmn),colormap parula;
% hold on
% camroll(90);
% hold off
%%
% subj_39074_fsl_ts = readmatrix('/Users/jacquelinefrist/Downloads/dr_stage1_subject00000.txt'); %what is this
% 
% %normalize the data output
% 
% zscore_ts=zscore(subj_39074_fsl_ts);
% 
% beta_1 = beta_1';
% comp_1=beta_1(:,1);
% zscore_beta=zscore(beta_1);
% 
% zscore_comp_1=zscore(comp_1);
%% 

% Plot dual regression comparisons -- WARNING: will pop up 40 graphs
% for i = 1:40
%     figure
%     plot(zscore_beta(:,i+1),"LineStyle","--","LineWidth",2)
%     hold on
%     plot(zscore_ts(:,i),"LineStyle","--","LineWidth",2)
%     legend("MatLab","FSL")
%     title("Comparing Dual Regression Methods")
%     xlabel("Time")
%     hold off
% end
%% 

% fsl_dmn = niftiread('/Users/roggeokk/Desktop/Projects/BrainHack2024/sub_39074_FSL_DualRegressionResults/dr_stage2_ic0007.nii.gz');
% fsl_dmn_sub_1 = fsl_dmn(:,:,:,1);
% newdmn = reshape(fsl_dmn_sub_1,prod(dims(1:3)),1);
% masked_dmn = newdmn(vox,:);
% 
% dmn_spatial_map = zeros(dims(1:3));
% dmn_spatial_map(vox) = masked_dmn';
% 
% figure;
% montage(dmn_spatial_map),colormap parula;
% hold on
% camroll(90);
% hold off