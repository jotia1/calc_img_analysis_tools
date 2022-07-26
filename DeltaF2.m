function [DF, F0_trace] = DeltaF2(RawFluo, window_baseline, window_smooth)
%% DELTAF2 - Calculate DF/F for raw SPIM data
% Original script written by Gilles, minor edits by Josh - removed calls to
% progressbar, and added excessive comments because I was trying to figure
% out how it worked. Current method is very slow because it recalculates a
% the sliding window many many times. If I understand correct it could be
% significantly sped up but I hesitate to alter something some
% foundational to our processing and this is done on HPC so not overly time
% sensitive. 
%
%  In general, there are two sliding windows, a smoothing window
%  (window_smooth) which just smooths the calcium trace to reduce the
%  impact of outlier values (typically 7). The second, larger, window is the area over
%  which to calculate a baseline for the fluoresence from (typically 101).
%
% Parameters:
%   RawFluro - the raw Suite2p_traces extracted by suite2p, should be
%       (#cells x #frames) matrix.
%   window_baseline - distance over which to find a baseline (minimum
%       value), typically set to 101 in our data.
%   window_smooth - the smaller window over which to take and average to
%       help avoid outliers causing large deviations of the baseline (typically 7) 

%RawFluo is Neurons x Time
%window_baseline is the window for the moving minimum (number of frames to look for the minimum)
%window_smooth is the window for the "high pass filtering" which is a rolling average (avoid spiky minima from artefacts)

if nargin<1
	error('no baseline or smoothing window size specified')
else if nargin<2    
    error('no smoothing window size specified')
end

%rounds even window sizes down to next lowest odd number
if mod(window_baseline,2)==0
    window_baseline=window_baseline-1;
end
if mod(window_smooth,2)==0
    window_smooth=window_smooth-1;
end

%calculates the size of the input data set
n=size(RawFluo);

%Calculates the number of elements in before and after the central element
%to incorporate in the moving mean.  Round command is just present to deal
%with the potential problem of division leaving a very small decimal, ie.
%2.000000000001.
halfspace_baseline=round((window_baseline-1)/2);
halfspace_smooth=round((window_smooth-1)/2);

DF=zeros(size(RawFluo));
F0_trace = zeros(size(RawFluo));
%progressbar();
parfor i=1:n(2) %should be fastish, it runs on all neurons in parallel, not sure how to speed it up further
    start=max(1,i-halfspace_baseline);  % From either the start OR half window size
    stop=min(i+halfspace_baseline,n(2));% To either the end OR half window size
    FX=zeros(size(RawFluo,1),stop-start);   % variable for the fluoresence
    counter=1;
    for j=start:stop  % Compute the mean of the 7 neighbour points
        start_smooth=nanmax(1,j-halfspace_smooth);  % smaller window also bounded by 1, and end
        stop_smooth=nanmin(j+halfspace_smooth,n(2));% goes up to 7/2 away from j.
        FX(:,counter)=sum(RawFluo(:,start_smooth:stop_smooth),2)/(stop_smooth-start_smooth+1); % average of small window at this time point
        counter=counter+1;
    end
    F0=nanmin(FX,[],2);  % FX is the min of the small(7) window averages in this 101 area.
    F0_trace(:, i) = F0;
    DF(:,i)=(RawFluo(:,i)-F0)./F0;    
    %progressbar(i / n(2));
end
end