function [peak2,unprocessedTOF,locs2i] = labelPeaks(direction,row,col,locs,peaks,numPeaks,widePeak,peakThresh)

if strcmp(direction,'row')
    dir1 = row;
    dir2 = col;
elseif strcmp(direction,'col')
    dir1 = col;
    dir2 = row;
    locs = locs';
    peaks = peaks';
    numPeaks = numPeaks';
    widePeak = widePeak';
end

peakLabels = cell(dir1,dir2);
peak2 = zeros(dir1,dir2);
loc2i = zeros(dir1,dir2);
unprocessedTOF = zeros(dir1,dir2);
locs2i = zeros(dir1,dir2);

for i = 1:dir1    
    labelList = 1:1e3;
    for j = 1:dir2
        % Assign unique peak IDs
        
        if isempty(peaks{i,j}) == false
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
                    if minDiff > peakThresh
                        labelList = sort([peakLabels{i,j-1}(k), labelList]);
                    end
                end
            
                for k = 1:length(currLocs)
                    [minDiff, minI] = min(abs(currLocs(k)-prevLocs));
                    % Current peak didn't change
                    if minDiff < peakThresh
                        currLocs(minI) = NaN;
                        peakLabels{i,j} = [peakLabels{i,j}, peakLabels{i,j-1}(minI)];
                    % New peak appeared
                    else
                        peakLabels{i,j} = [peakLabels{i,j}, labelList(1)];
                        labelList = labelList(2:end);
                    end
                end
            end
            
            if numPeaks(i,j) >= 2
                if widePeak(i,j) == false
                    [peak2(i,j), loc2i(i,j)] = max(peaks{i,j}(2:end));
                else
                    [~, loc2i(i,j)] = max(peaks{i,j}(2:end));                
                end
                loc2i(i,j) = loc2i(i,j) + 1;
                unprocessedTOF(i,j) = locs{i,j}(loc2i(i,j))-locs{i,j}(1);
                locs2i(i,j) = peakLabels{i,j}(loc2i(i,j));
            end
        end
    end
end

if strcmp(direction,'col')
    peak2 = peak2';
    unprocessedTOF = unprocessedTOF';
    locs2i = locs2i';
end

end