function [Suite2p_traces, ROI_centroids, fish_ncells, fish_numbers] = load_all_fish(pipeline_output_path, load_s2p, load_rois)
%% LOAD_ALL_FISH - Load all fish s2p and/or ANTs roi results into matlab
%   Look through all folders in the given path opening any prepended with
%   'suite2p_'/'ants_' and loading relevant suite2p/ants data. Assumes
%   pipeline_output_path contains individual fish folders which in turn
%   contain multiple planeX folders with corresponding suite2p output or
%   or ANTs warped ROI files (ROIs_zbrainspace_XX.csv) 
%
%   Optionally can specify to load just s2p or just ROI data by setting
%   load_s2p or load_ants to false. Default to true for both. 
%
%   Warning:
%   Loading many fish (>10) can take a long time and may use more RAM than
%   standard computers have (~1GB per fish). 
%   
%   Args:
%       pipeline_output_path - A full path to a folder containing s2p
%           processed fish.
%       load_s2p - true (default) or false if suite2p data should be loaded
%       load_ants - true (default) or false if ROIs data should be loaded
%   
%
%   Example usage:
%       [Suite2p_traces, ROI_centroids, fish_ncells, fish_numbers] = load_all_fish('I:\MECP2GEN-Q4070\SPIM\PipelineOutputs');
%   Load just rois:
%       [Suite2p_traces, ROI_centroids, fish_ncells, fish_numbers] = load_all_fish('I:\MECP2GEN-Q4070\SPIM\PipelineOutputs', false, true);
%

% set up default values (true) for load_s2p/rois, raise error if both false
if ~exist('load_s2p', 'var')
    load_s2p = true;
end
if ~exist('load_ants', 'var')
    load_rois = true;
end
if ~load_s2p && ~load_ants
    throw(MException('LOAD_ALL_FISH:NothingToLoad', 'load_s2p and load_rois cannot both be false.'))
end

fish_folders = dir(fullfile(pipeline_output_path, 'suite2p_*'));
num_fish = numel(fish_folders);

%% Get all fish numbers, padded with leading zeros (e.g. 05 rather than 5)
fish_folder_names = {fish_folders.name};
fin = cellfun(@(x)regexp(x,'fish(\d+)','tokens'), fish_folder_names, 'UniformOutput', false);
fish_numbers = cell(numel(fin), 1);
for i = 1:numel(fin)
    fish_numbers{i} = fin{i}{1}{1};
end


%% Loop through folders to get traces and xy locations of all ROIs Suite2p defines as cells
Suite2p_traces = []; 
ROI_centroids = [];
fish_ncells = zeros(num_fish, 1); % number of cells per fish

for fish_idx = 1:num_fish
    folder = fish_folders(fish_idx).name;
    
    fish_number = fish_numbers{fish_idx};
    [fish_Suite2p_traces, fish_ROI_centroids] = load_single_fish(pipeline_output_path, fish_number, load_s2p, load_rois);
    
    Suite2p_traces = vertcat(Suite2p_traces, fish_Suite2p_traces);
    ROI_centroids = vertcat(ROI_centroids, fish_ROI_centroids);
    ROI_centroids(isnan(ROI_centroids)) = 0; % Avoid that nan ROI at end of file from ANTs
    
    % Count cells as #traces if loading traces, else use #ROIs
    ncells = size(fish_Suite2p_traces, 1);
    if ~load_s2p
        ncells = size(ROI_centroids, 1);
    end
    fish_ncells(fish_idx) = ncells;
    
end



end