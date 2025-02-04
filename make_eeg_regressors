function OUT = make_eeg_regressors_vu(EEG,chans_use,nframes, ...
                                       TR, save_fname, ...
                                       MOTPAR, frames_bufferOv);
global
[figure_save_dir,plotting_name,~] = fileparts(save_fname);
tmp = strsplit(plotting_name,"_");
save_prefix = tmp{1};

if ~exist(figure_save_dir, 'dir')
    mkdir(figure_save_dir)
end

% extract params
% ----------------------------------
fs = EEG.srate;
chan_labels_all = {EEG.chanlocs.labels};
event_types = {EEG.event.type};
mrtrig_samps = [EEG.event(find(strcmp(event_types,'R149'))).latency];


% channels to use
% ----------------------------------
if ~isempty(chans_use)
    ii_use = find(ismember(chan_labels_all,chans_use));
    % note, this re-sorts them (select channs are not the order we specified)
    chan_labels = chan_labels_all(ii_use);
else
    ii_use = size(EEG.data,1); % by default, use all channels 
    chan_labels = chan_labels_all;
end

bands = [0.50 3
         3 7;  
         8 12;
         13 29;
         30 50]; 
band_labels = {'delta','theta','alpha','beta','gamma'};

% reject artifactual TRs (later make this a separate script, where
% here we just pass in rejected frames)
% ---------------------------------- % 
disp('********************************')
disp('determining outlier timeframes');
disp('********************************')
dat = EEG.data(ii_use,:); 
% filtering (1-13 Hz) for rejection purposes
% (due to gradient artifact peak at ~14.29 Hz)
% and fix transients
dat_hpf = eegfilt(dat,EEG.srate,1,0);
dat_bpf = eegfilt(dat_hpf,EEG.srate,0,13);
dat_bpf(1:6*EEG.srate)=0;
dat_bpf(end-6*EEG.srate:end)=0;
% rms across channels (at EEG sampling)
rms_ts = sqrt(mean(dat_bpf,1).^2);
% rms across channels (mean within TR)
% rms_TRs = [];
rms_TRs = zeros(1, nframes);

% frames with incomplete data due to buffer overflow error are '0'
mask = ones(nframes,1);
mask(frames_bufferOv)=0;

TR_samples_vec = zeros(nframes, length(mrtrig_samps(1):mrtrig_samps(2)-1));
% (expected nframes) x (nsamps per trigger)

% adjust mrtrig_samps, inserting 'nan' for frames impacted by
% buffer overflow errors

if ~isempty(frames_bufferOv)
    start_samps = [mrtrig_samps(1:frames_bufferOv(1)-1), ...
                   nan(1,length(frames_bufferOv)), ...
                   mrtrig_samps(frames_bufferOv(1)+1:end)];
else
    start_samps = mrtrig_samps; 
end
rms_TRs = []; % vector of rms 
for jj=1:nframes
    % volume triggers
    % EEG datapoints within this interval
    if mask(jj)==1 
        pp = [start_samps(jj):start_samps(jj)+(TR*EEG.srate)-1];
        rms_TRs(jj) = mean(rms_ts(pp));
    else % buffer ov frame
        pp = nan(1,TR*EEG.srate);
        rms_TRs(jj) = nan;
    end
    TR_samples_vec(jj,:) = pp;
end
rms_TRs(1) = rms_TRs(2); 


% plot
dt_eeg = 1./(EEG.srate);
tax_tr = [0:TR:TR*(nframes-1)];
tax_eeg = [0:dt_eeg:dt_eeg*(size(dat,2)-1)];

outlier_thresh_TR = nanmedian(rms_TRs) + 4*iqr(rms_TRs(~isnan(rms_TRs)))
display(['rms *TR* outlier thresh=',num2str(outlier_thresh_TR)]);

% indicate "bad" time points
bad_TR = find(rms_TRs>=outlier_thresh_TR);

% include missing buffer ov frames as "bad" time points
bad_TR = sort([bad_TR, frames_bufferOv]);

% manual double-check!
disp("Potential bad frames: [" + num2str(bad_TR) + "]");
if CHECK_BAD_CHANNELS
    outliers = input('input bad frames, or Enter to accept all: ');
else
    outliers = [];
end

if ~isempty(outliers)
    bad_TR = outliers;
end

% fill binary array for later use in fMRI frame exclusion
binary_rejTR = zeros(nframes,1);
binary_rejTR(bad_TR)=1;

% REGRESSORS: based on RMS energy in a given band, within each TR
% ------------------------------- %
dat = EEG.data(ii_use,:); 

disp('********************************')
disp('band-pass filtering');
disp('********************************')
% band-pass filter in each band (operates along each row of 'dat')
% BPF = []; % nch x ntimepts x nbands matrix of band-pass filtered EEG
BPF = zeros(length(chans_use), length(rms_ts), length(band_labels));
for kk=1:size(bands,1)
    b1 = bands(kk,1); b2 = bands(kk,2);
 
    % 2-stage
    % can set endpnts to 0 b/c data affter correction is (usually) 0-mean.
    % hpf
    [tmp_hpf,filtwts] = eegfilt(dat,fs,b1,0);
    ntap = length(filtwts);
    tmp_hpf_kk = tmp_hpf;
    tmp_hpf_kk(:,1:ntap) = 0;
    tmp_hpf_kk(:,end-ntap:end) = 0;
    % lpf
    [tmp_bpf,filtwts] = eegfilt(tmp_hpf_kk,fs,0,b2);
    ntap = length(filtwts);
    tmp_bpf_kk = tmp_bpf;
    tmp_bpf_kk(:,1:ntap) = 0;
    tmp_bpf_kk(:,end-ntap:end)=0;
    BPF(:,:,kk) = tmp_bpf_kk;
end

% regressors: RMS
disp('********************************')
disp('calculating band power (rms) per TR');
disp('********************************')
% BLP_rms = []; % nbands x time x channels
% BLP_rms_raw = []; % (before interp of bad TRs)

BLP_rms = zeros(length(band_labels), nframes, length(chans_use));
BLP_rms_raw = BLP_rms;
BLP_rms_ch = zeros(length(band_labels), nframes);

for cc=1:size(BPF,1) % for each chann
    % BLP_rms_cc = [];
    for jj=1:nframes
        if mask(jj)==1
            SEG = squeeze(BPF(cc,TR_samples_vec(jj,:),:))'; % nbands x {samples in TR}
            MU = repmat(mean(SEG,2),1,size(SEG,2)); % rep time-wise mean
            BLP_rms_ch(:,jj) = sqrt(mean((SEG-MU).^2,2)); %time-wise rms (nchx1)
        else % buffer ov
            BLP_rms_ch(:,jj) = nan(length(band_labels),1);
        end
    end
    % store; but first, fix ends and interpolate (store both)
    BLP_rms_raw(:,:,cc) = fixends(BLP_rms_ch,7); 
    BLP_rms(:,:,cc) = interp_pts(BLP_rms_raw(:,:,cc),bad_TR,0);
end

BLP_rms_ave = mean(BLP_rms,3); % nbands x nframes


% form some ratios of interest
% -------------------------------------- % 
disp('********************************')
disp('calculating band ratios');
disp('********************************')
ratio_bands = [4 2; % beta/theta
            5 2; % gamma/theta
            4 3; % beta/alpha
            5 3]; % gamma/alpha
ratio_labels = {'beta/theta','gamma/theta','beta/alpha','gamma/alpha'};

% BLP_rms_RATS = {};
zero_array = zeros(1, nframes);
BLP_rms_RATS = {zero_array, zero_array, zero_array, zero_array};
for kk=1:size(ratio_bands,1)
    num = ratio_bands(kk,1); den = ratio_bands(kk,2);
    BLP_rms_RATS{kk} = BLP_rms_ave(num,:) ./ BLP_rms_ave(den,:);
end

% form relative power for each band
% (i.e., normalized to "full" band
% (defined by range specified in final row of 'bands')
% -------------------------------------- % 
TotalPower = repmat(BLP_rms_ave(end,:),size(bands,1)-1,1);
BLP_rms_rel = BLP_rms_ave(1:end-1,:) ./ TotalPower;

% save useful things
% ----------------------------- % 
OUT.dat = dat;
OUT.binary_rejTR = binary_rejTR;
OUT.bad_TR = bad_TR;
OUT.chans_use = chans_use;
OUT.chan_labels = chan_labels;
OUT.bands = bands;
OUT.band_labels = band_labels;

OUT.BLP = BLP_rms; % after interpolating 'bad' frames
OUT.BLP_raw = BLP_rms_raw; % before interpolation
OUT.BLP_ave= BLP_rms_ave; % channel-average
OUT.BLP_rel = BLP_rms_rel;%relative to total pow

OUT.BL_RATS = BLP_rms_RATS; % ratios set here
OUT.ratio_bands = ratio_bands;
OUT.ratio_labels = ratio_labels;

if ~isempty(save_fname)
    disp('********************************')
    disp('saving');
    disp('********************************')
    
%    disp('saving as: ' + save_fname);
    save(save_fname, 'OUT'); 
end
