addpath("C:\Users\hardijm1\Projects\jICA\full_maps\16_comp\figs")
dataDir = "C:\Users\hardijm1\Projects\jICA\full_maps\16_comp\figs";
saveDir = "C:\Users\hardijm1\Projects\jICA\full_maps\16_comp";



eegFiles = dir(fullfile(dataDir, '*.fig'));



for eegIdx = 1:length(eegFiles)
   
   FigH = openfig(eegFiles(eegIdx).name);
 
   drawnow;
   F = getframe(FigH);

   outputFileName = fullfile(saveDir, ['full_eeg_', num2str(eegIdx), '.png']);
   
   imwrite(F.cdata, outputFileName)

end
