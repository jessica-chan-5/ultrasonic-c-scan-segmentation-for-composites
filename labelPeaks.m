function [peak2,unprocessedTOF,locs2i] = labelPeaks(row,col,locs,peaks,numPeaks,widePeak,peakThresh)

peakLabels = cell(row,col);
peak2 = zeros(row,col);
loc2i = zeros(row,col);
unprocessedTOF = zeros(row,col);
locs2i = zeros(row,col);

for i = 1:row    
    labelList = 1:1e3;
    for j = 1:col
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

end