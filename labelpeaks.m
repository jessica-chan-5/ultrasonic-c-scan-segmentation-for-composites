function [peak2, inflpt] = labelpeaks(dir,row,col,locs,peak,nPeaks, ...
    wide,peakThresh)
%LABELPEAKS Use unique peak labels to find inflection points
%    [peak2, inflpt] = LABELPEAKS(dir,row,col,locs,peak,nPeaks,wide,...
%    peakThresh) searches along row or col depending on given dir to search
%    for inflection points using unique peak labels. Returns inflection 
%    points and magnitude of 2nd peak.
%
%    Inputs:
%
%    DIR:        'row' or 'col' - searches along given direction
%    ROW:        Number of points along row
%    COL:        Number of points along col
%    LOCS:       Locations of all peaks at each A-scan point
%    PEAK:       Magnitude of all peaks at each A-scan point
%    NPEAKS:     Number of peaks at each A-scan point
%    WIDE:       Is true if 1st peak is labeled as 'wide' at A-scan point
%    PEAKTHRESH: If the difference between the time a peak appears in the
%                first point and the time the same peak appears in the
%                next point is greater than peakThresh, label as new peak

% Initialize variables depending on if searching along row or col
if strcmp(dir,'row')
    dir1 = row;
    dir2 = col;
elseif strcmp(dir,'col')
    dir1 = col;
    dir2 = row;
    locs = locs';
    peak = peak';
    wide = wide';
    nPeaks = nPeaks';
end

peakLab = cell(dir1,dir2);
peak2   = zeros(dir1,dir2);
loc2i   = zeros(dir1,dir2);
locs2i  = zeros(dir1,dir2);

for i = 1:dir1    
    labList = 1:1e3; % Initialize list of labels
    for j = 1:dir2
        % Assign unique peak IDs to each peak at each A-scan point
        if isempty(peak{i,j}) == false
            % Initialize first entry of a row or col
            if j == 1
                peakLab{i,j} = 1:length(locs{i,j});
                labList = labList(length(locs{i,j})+1:end);
            % Check for peak changes
            else
                currLocs = locs{i,j};
                prevLocs = locs{i,j-1};
                % Loop through previous point peaks
                for k = 1:length(prevLocs)
                    minDiff = min(abs(prevLocs(k)-currLocs));
                    % Old peak disappeared
                    if minDiff > peakThresh
                        labList = sort([peakLab{i,j-1}(k), labList]);
                    end
                end
                % Loop through current point peaks
                for k = 1:length(currLocs)
                    [minDiff, minI] = min(abs(currLocs(k)-prevLocs));
                    % Current peak didn't change
                    if minDiff < peakThresh
                        currLocs(minI) = NaN;
                        peakLab{i,j} = [peakLab{i,j}, ...
                            peakLab{i,j-1}(minI)];
                    % New peak appeared
                    else
                        peakLab{i,j} = [peakLab{i,j}, labList(1)];
                        labList = labList(2:end);
                    end
                end
            end
            % Identify and save peak label of 2nd peak 
            if nPeaks(i,j) >= 2
                if wide(i,j) == false
                    [peak2(i,j), loc2i(i,j)] = max(peak{i,j}(2:end));
                else
                    [~, loc2i(i,j)] = max(peak{i,j}(2:end));                
                end
                loc2i(i,j) = loc2i(i,j) + 1;
                locs2i(i,j) = peakLab{i,j}(loc2i(i,j));
            end
        end
    end
end

% Mark inflection points by checking for changes in 2nd peak labels along a
% row or col depending on given dir
inflpt = zeros(row,col);
if strcmp(dir,'row') == true
    for i = 1:row
        labelLocs = [];
        for j = 2:col
            if nPeaks(i,j) >= 2
                if locs2i(i,j) ~= locs2i(i,j-1)
                    labelLocs = [labelLocs, j]; %#ok<AGROW>
                end
            end
        end
        inflpt(i,labelLocs) = 1;
    end
elseif strcmp(dir,'col') == true
    nPeaks = nPeaks';
    locs2i = locs2i';
    for j = 1:col
        labelLocs = [];
        for i = 2:row
            if nPeaks(i,j) >= 2
                if locs2i(i,j) ~= locs2i(i-1,j)
                    labelLocs = [labelLocs, i]; %#ok<AGROW>
                end
            end
        end
        inflpt(labelLocs',j) = 1;
    end
end

end