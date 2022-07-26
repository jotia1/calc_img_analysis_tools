function [Suite2p_traces, ROI_centroids, fish_ncells, fish_numbers, stim_trains] = load_all_fish_standard_format(pipeline_output_path, sep_idxs, load_s2p, load_ants, reload_all, analysis_dir_name)
%% LOAD_ALL_FISH_STANDARD_FORMAT - Load all fish s2p and/or ANTs roi results into matlab
%   Load all processed fish within the supplied folder in the standard
%   format. That is apply DF/F with windows 101, 7 (lab standard). Also
%   filter ROIs such that only those within a Zbrain region are included.
%
%   Raw traces are split up into stimulus trains (stim_trains) based on the
%   seperation index's supplied (sep_idxs). The raw Suite2p traces are left
%   in the Suite2p matrix unseperated (but filtered according to zbrains).
%
%   Example usage:
%       [ROI_centroids, fish_ncells, fish_numbers, stim_trains, Suite2p_traces] = 
%           load_all_fish_standard_format('I:\SCN1LABSYN-Q3714\SPIM\pipeline',
%           [1200], true, true, false, 'loaded_data');


% set up default values (true) for load_s2p/rois, raise error if both false
if ~exist('load_s2p', 'var')
    load_s2p = true;
end
if ~exist('load_ants', 'var')
    load_rois = true;
end
if ~exist('reload_all', 'var')
    reload_all = true;
end
if ~exist('analysis_dir_name', 'var')
    analysis_dir_name = 'matlab_data';
end
if ~load_s2p && ~load_ants
    throw(MException('LOAD_ALL_FISH:NothingToLoad', 'load_s2p and load_rois cannot both be false.'))
end


analysis_folder = fullfile(pipeline_output_path, analysis_dir_name);
final_output = fullfile(analysis_folder, 'all_fish_std_fmt.mat');
if ~exist(analysis_folder, "dir")  % if folder doesn't exist, create it
    mkdir(analysis_folder);
elseif exist(final_output, 'file') && ~reload_all % if it does exist and we dont need to reload_all
    load(final_output); % just load everything and give it back
    return; 
end


fish_folders = dir(fullfile(pipeline_output_path, 'suite2p_*'));

% TODO : testing hack
%fish_folders = fish_folders(1:2);
%fprintf('NOTE: left in a hack for testing !!!!!!!!!!!!!!! only using 2 fish')
%fish_folders(22) = [];  % Remove fish 41 which is missing data


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
stim_trains = cell(numel(sep_idxs) + 1, 1);
fish_ncells = zeros(num_fish, 1); % number of cells per fish

for fish_idx = 1:num_fish
    folder = fish_folders(fish_idx).name;
    
    fish_number = fish_numbers{fish_idx};
    matfile_name = fullfile(analysis_folder, sprintf('raw_fish_std_fmt_%s.mat', fish_number));
    if exist(matfile_name, 'file') && ~reload_all
        fprintf('Found existing matlab file, loading that (fish%s)\n', fish_number)
        data = load(matfile_name, 'Suite2p_traces', 'fish_stim_trains', 'fish_ROI_centroids');
        fish_stim_trains = data.fish_stim_trains;
        fish_ROI_centroids = data.fish_ROI_centroids;
        fish_Suite2p_traces = data.Suite2p_traces;
    else
        [fish_Suite2p_traces, fish_stim_trains, fish_ROI_centroids, ~] = load_fish_standard_format(pipeline_output_path, fish_number, sep_idxs);
        save(matfile_name, 'fish_Suite2p_traces', 'fish_stim_trains', 'fish_ROI_centroids', '-v7.3');
    end
    
    % Join individual fish with the collective fish
    %Suite2p_traces = vertcat(Suite2p_traces, fish_Suite2p_traces);
    ROI_centroids = vertcat(ROI_centroids, fish_ROI_centroids);
    ROI_centroids(isnan(ROI_centroids)) = 0; % Avoid that nan ROI at end of file from ANTs
    Suite2p_traces = vertcat(Suite2p_traces, fish_Suite2p_traces);
    for st = 1 : numel(stim_trains)
        stim_trains{st} = vertcat(stim_trains{st}, fish_stim_trains{st});
    end
    
    % Count cells as #traces if loading traces, else use #ROIs
    ncells = size(fish_stim_trains{1}, 1);
    if ~load_s2p
        ncells = size(fish_ROI_centroids, 1);
    end
    fish_ncells(fish_idx) = ncells;
    
end

save(final_output, 'Suite2p_traces', 'ROI_centroids', 'fish_ncells', 'fish_numbers', 'stim_trains', '-v7.3');

end