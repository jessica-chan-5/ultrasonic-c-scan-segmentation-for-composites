function inflectionpts = findInflectionPts(inflectionpts,direction,row,col,peak2,minPeakPromPeak2,numPeaks,locs2i)

if strcmp(direction,'row') == true
    for i = 1:row
    
        % Find layer edges using peaks in 2nd peak mag values
        invertPeak2 = peak2(i,:).^-1-1;
        invertPeak2(isinf(invertPeak2)) = 0;
        [~,magLoc] = findpeaks(invertPeak2,'MinPeakProminence',minPeakPromPeak2);
        
        % Find layer edges using 2nd peak label changes
        peakLoc = [];
        
        for k = 2:col
            if numPeaks(i,k) >= 2
                if locs2i(i,k) ~= locs2i(i,k-1)
                    peakLoc = [peakLoc, k]; %#ok<AGROW>
                end
            end
        end
        
        % Merge both methods
        locLocs = sort([magLoc, peakLoc]);
        inflectionpts(i,locLocs) = 1;
    
    end

elseif strcmp(direction,'col') == true
    for j = 1:col
    
        % Find layer edges using peaks in 2nd peak mag values
        invertPeak2 = peak2(:,j).^-1-1;
        invertPeak2(isinf(invertPeak2)) = 0;
        [~,magLoc] = findpeaks(invertPeak2,'MinPeakProminence',minPeakPromPeak2);
        
        % Find layer edges using 2nd peak label changes
        peakLoc = [];
        
        for i = 2:row
            if numPeaks(i,j) >= 2
                if locs2i(i,j) ~= locs2i(i-1,j)
                    peakLoc = [peakLoc, i]; %#ok<AGROW>
                end
            end
        end
        
        % Merge both methods
        locLocs = sort([peakLoc,magLoc']);
        inflectionpts(locLocs,j) = 1;
    
    end
end

end