function [peak2, inflpt] = labelpeaks(dir,row,col,locs,peak,npeaks, ...
    wide,peakthresh)

if strcmp(dir,'row')
    dir1 = row;
    dir2 = col;
elseif strcmp(dir,'col')
    dir1 = col;
    dir2 = row;
    locs = locs';
    peak = peak';
    npeaks = npeaks';
    wide = wide';
end

peakLabels = cell(dir1,dir2);
peak2 = zeros(dir1,dir2);
loc2i = zeros(dir1,dir2);
locs2i = zeros(dir1,dir2);

for i = 1:dir1    
    labelList = 1:1e3;
    for j = 1:dir2
        % Assign unique peak IDs
        
        if isempty(peak{i,j}) == false
            % Initialize first entry of a row
            if j == 1
                peakLabels{i,j} = 1:length(locs{i,j});
                labelList = labelList(length(locs{i,j})+1:end);
            % Check for peak changes
            else
                currLocs = locs{i,j};
                prevLocs = locs{i,j-1};
            
                for k = 1:length(prevLocs)
                    minDiff = min(abs(prevLocs(k)-currLocs));
                    % Old peak disappeared
                    if minDiff > peakthresh
                        labelList = sort([peakLabels{i,j-1}(k), labelList]);
                    end
                end
            
                for k = 1:length(currLocs)
                    [minDiff, minI] = min(abs(currLocs(k)-prevLocs));
                    % Current peak didn't change
                    if minDiff < peakthresh
                        currLocs(minI) = NaN;
                        peakLabels{i,j} = [peakLabels{i,j}, peakLabels{i,j-1}(minI)];
                    % New peak appeared
                    else
                        peakLabels{i,j} = [peakLabels{i,j}, labelList(1)];
                        labelList = labelList(2:end);
                    end
                end
            end
            
            if npeaks(i,j) >= 2
                if wide(i,j) == false
                    [peak2(i,j), loc2i(i,j)] = max(peak{i,j}(2:end));
                else
                    [~, loc2i(i,j)] = max(peak{i,j}(2:end));                
                end
                loc2i(i,j) = loc2i(i,j) + 1;
                locs2i(i,j) = peakLabels{i,j}(loc2i(i,j));
            end
        end
    end
end

inflpt = zeros(row,col);

if strcmp(dir,'row') == true
    for i = 1:row
        labellocs = [];
        for j = 2:col
            if npeaks(i,j) >= 2
                if locs2i(i,j) ~= locs2i(i,j-1)
                    labellocs = [labellocs, j]; %#ok<AGROW>
                end
            end
        end
        inflpt(i,labellocs) = 1;
    end
elseif strcmp(dir,'col') == true
    npeaks = npeaks';
    locs2i = locs2i';
    for j = 1:col
        labellocs = [];
        for i = 2:row
            if npeaks(i,j) >= 2
                if locs2i(i,j) ~= locs2i(i-1,j)
                    labellocs = [labellocs, i]; %#ok<AGROW>
                end
            end
        end
        inflpt(labellocs',j) = 1;
    end
end

end