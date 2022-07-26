function [Suite2p_traces, stim_trains, ROI_centroids, fish_number] = load_fish_standard_format(pipeline_output_path, fish_number, sep_idxs)
%% LOAD_FISH_STANDARD_FORMAT - Load a fish in the standard format
%   Load fish from raw variables (e.g. suite2p/ants outputs) or from a
%   previously created matlab file of these variables. Convert the raw
%   suite2p traces to df/f and remove all ROIs (and their corresponding
%   traces) that fall outside of the zbrain mask.
%
%   Args:
%       pipeline_output_path - A full path to a folder containing s2p
%           processed fish.
%       fish_number - zero-padded fish number of the fish to load (e.g. 05)
%       sep_idx - list of indices at which stimuli are separated (e.g.
%           spontaneous, auditory, visual trains)
%
%   Example usage:
%       [Suite2p_traces, stim_trains, ROI_centroids, fish_number] = load_fish_standard_format('I:\SCN1LABSYN-Q3714\SPIM\pipeline', '04', [1200]);
%

[Suite2p_traces, ROI_centroids] = load_single_fish(pipeline_output_path, fish_number);

% Seperate stimuli trains and calculate dF/f
sep_idxs = [sep_idxs, size(Suite2p_traces, 2)];
stim_trains = cell(numel(sep_idxs), 1);
last_idx = 1;
for st = 1 : numel(stim_trains)
    sep_idx = sep_idxs(st);
    stim_df = DeltaF2(Suite2p_traces(:, last_idx:sep_idx),101,7);
    stim_df(isnan(stim_df))=0;
    stim_trains{st} = stim_df;
    last_idx = sep_idx + 1;
end

% reorganise ANTs ROIs
ROIs_shuffled = zeros(size(ROI_centroids));
ROIs_shuffled(:,1) = ROI_centroids(:,2);
ROIs_shuffled(:,2) = ROI_centroids(:,1);
ROIs_shuffled(:,3) = ROI_centroids(:,3) / 2;

% Create full brain mask
if ismac
    load('/Volumes/UQ-Inst-Gateway1/PIPEDATA-Q4414/Zbrain_Masks.mat');
elseif isunix  % if unix but not mac (Jess) -> should be linux (hpc) or Sarah
    load('/QRISdata/Q4414/Zbrain_Masks.mat')
else  % everyone else - Windows
    load('I:\PIPEDATA-Q4414\Zbrain_Masks.mat');
end
Zbrain_AllMask=vertcat(Zbrain_Masks{[1:1:77 79:1:294],3}); %Makes a massive matrix of all the Zbrain regions except the eyes
Zbrain_AllMask=unique(Zbrain_AllMask,'rows');
IsInBrainRegion=ismember(round(ROIs_shuffled), Zbrain_AllMask,'rows'); 

% Update all variables to exclude rois not in the brain
Suite2p_traces = Suite2p_traces(IsInBrainRegion, :);
ROI_centroids = ROIs_shuffled(IsInBrainRegion, :);
for st = 1 : numel(stim_trains)
    stim_train = stim_trains{st};
    stim_trains{st} = stim_train(IsInBrainRegion, :);
end

end
