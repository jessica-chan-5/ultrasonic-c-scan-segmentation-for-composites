function TOF = calcTOF2(cScan,t,row,col)

% Initialize values
TOF = zeros(length(row),length(col));
loc1 = TOF;
loc2i = TOF;
locs2i = TOF;
peak2 = TOF;
numPeaks = TOF;
widePeakLoc = TOF;
widePeak = false(length(row),length(col));
peakLabels = cell(length(row),length(col));
locs = peakLabels;

inflectionpts = TOF;

% Sensitivity parameters
neighThresh = 0.08; % 8 percent
minpeakheight = 0.11;

for i = 1:length(row)
    
    labelList = 1:20;
    
    for j = 1:length(col)
                
        point = squeeze(cScan(row(i),col(j),:))';

        % Set values greater than 1 equal to 1
        point(point>1) = 1;
    
        % Find and save peaks/locations in signal
        [p, l] = findpeaks(point,t);
    
        % Manually add 0 point to peaks list in case signal is cut off on left
        p = [0 p]; %#ok<AGROW> 
        l = [0 l]; %#ok<AGROW> 
        
        % Flag wide peaks if max diff from max value is less than neighors by 8%
        for k = 1:length(p)-2
            if max(max(p(k:k+2)) - p(k:k+2)) <= neighThresh*max(p(k:k+2))
                widePeak(i,j) = true;
                widePeakLoc(i,j) = l(k);
                break;
            end
        end
    
        % Find neighboring peaks that are within 8%
        % Set peak location and value to be at max of the neighboring peaks
        [p, l] = findCenter(p,l,1,neighThresh,false);
    
        % Find and save locations of peaks in previously found peaks
        [peak,loc] = findpeaks(p,l,...
            'MinPeakHeight',minpeakheight,...
            'WidthReference','halfheight');
        locs{i,j} = loc;
    
        % Count number of peaks
        numPeaks(i,j) = length(peak);
    
        % Assign unique peak IDs
        peakThresh = 0.08;
    
        if j == 1
            peakLabels{i,j} = 1:length(locs{i,j});
            labelList = labelList(length(locs{i,j})+1:end);
        else
            tempCurr = locs{i,j};
            tempPrev = locs{i,j-1};
    
            for k = 1:length(tempPrev)
                minDiff = min(abs(locs{i,j-1}(k)-tempCurr));
                if minDiff > peakThresh
                    labelList = sort([peakLabels{i,j-1}(k), labelList]);
                end
            end
    
            for k = 1:length(tempCurr)
                [minDiff, minI] = min(abs(locs{i,j}(k)-tempPrev));
                if minDiff < peakThresh
                    tempCurr(minI) = NaN;
                    peakLabels{i,j} = [peakLabels{i,j}, peakLabels{i,j-1}(minI)];
                else
                    peakLabels{i,j} = [peakLabels{i,j}, labelList(1)];
                    labelList = labelList(2:end);
                end
            end
        end
    
        if numPeaks(i,j) >= 2
            loc1(i,j) = loc(1);
            [peak2(i,j), loc2i(i,j)] = max(peak(2:end));
            loc2i(i,j) = loc2i(i,j) + 1;
            TOF(i,j) = loc(loc2i(i,j))-loc1(i,j);
            locs2i(i,j) = peakLabels{i,j}(loc2i(i,j));
        end
    end
end

for i = 1:length(row)
    
    minPeakProm = 0.05;
    % Find layer edges using peaks in 2nd peak mag values
    [~,magLoc] = findpeaks(peak2(i,:).^-1-1,'MinPeakProminence',minPeakProm);
    magLoc = col(magLoc);
    
    % Find layer edges using 2nd peak label changes
    peakLoc = [];

    for k = 2:length(col)
        if numPeaks(i,k) >= 2
            if locs2i(i,k) ~= locs2i(i,k-1)
                peakLoc = [peakLoc, col(k)];
            end
        end
    end

    % Merge both methods and remove neighboring values differing by 1
    % When both methods detect a layer change, the peak change is correct and
    % the index is peakLoc = magLoc+1, not sure why
    locLocs = sort([magLoc, peakLoc]);
    locLocs(diff(locLocs)<=1) = [];
%     locLocs = peakLoc;

    startI = 2;
    pastTOF = 0;
    locI = 1;

    for j = startI:length(col)
    
        inflection = false;
        elseFlag = false;
    
        if numPeaks(i,j) >= 2

            if locI <= length(locLocs) && ...
                    col(j) == locLocs(locI)
                inflection = true;
                locI = locI + 1;
%             elseif locs2i(i,j) ~= locs2i(i,j-1)
%                 inflection = true;
            end
            
            if widePeak(i,j) == false || (widePeak(i,j) == true && widePeakLoc(i,j) > loc1(i,j))
                if inflection == true ...
                    || j == 2 || j == length(col) ...
                    || (pastTOF == 0 && TOF(i,j) ~= 0)
    
                    TOF(i,startI:j-1) = mode(round(TOF(i,startI:j-1),2));
                    startI = j;
                    pastTOF = TOF(i,j);

                    inflectionpts(i,j) = 1;
                end
            else
                elseFlag = true;
            end
        else
            elseFlag = true;
        end
    
        if elseFlag == true
            if pastTOF ~= 0
                TOF(i,startI:j-1) = mode(round(TOF(i,startI:j-1),2));
                inflectionpts(i,j) = 1;
            end
            startI = j;
            pastTOF = 0;
            TOF(i,j) = 0;
        end
    end
end

end