function [TOF,inflectionpts] = aScanLayers(fits,dataPtsPerAScan)

row = size(fits,1);
col = size(fits,2);

% Time vector
dt = 0.02;
tEnd = (dataPtsPerAScan-1)*dt;
t = 0:dt:tEnd;

% Initialize values
TOF = zeros(row,col);
unprocessedTOF = TOF;
loc1 = TOF;
loc2i = TOF;
locs2i = TOF;
peak2 = TOF;
numPeaks = TOF;
widePeak = false(row,col);
peakLabels = cell(row,col);
locs = peakLabels;
inflectionpts = TOF;

% Sensitivity parameters
minPeakPromPeak = 0.03;
minPeakPromPeak2 = 0.1;
peakThresh = 0.08;
maxPeakWidth = 0.7;

for i = 1:row
    
    labelList = 1:1e3;
    
    for j = 1:col

        fit = fits{i,j};

        if isempty(fit) == false
            % Evaluate smoothing spline for t
            pfit = feval(fit,t);
            % Find and save locations of peaks in splin fit
            [peak, loc, width] = findpeaks(pfit,t,'MinPeakProminence',minPeakPromPeak,'WidthReference','halfheight');
            locs{i,j} = loc;
            
            if length(width) >= 1 && width(1) > maxPeakWidth
                widePeak(i,j) = true;
            end
        
            % Count number of peaks
            numPeaks(i,j) = length(peak);
    
            % Assign unique peak IDs
    
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
                loc1(i,j) = loc(1);
                if widePeak(i,j) == false
                    [peak2(i,j), loc2i(i,j)] = max(peak(2:end));
                else
                    [~, loc2i(i,j)] = max(peak(2:end));                
                end
                loc2i(i,j) = loc2i(i,j) + 1;
                unprocessedTOF(i,j) = loc(loc2i(i,j))-loc1(i,j);
                locs2i(i,j) = peakLabels{i,j}(loc2i(i,j));
            end
        end
    end
end

inflectionpts = findInflectionPts(inflectionpts,'row',row,col,peak2,minPeakPromPeak2,numPeaks,locs2i);
inflectionpts = findInflectionPts(inflectionpts,'col',row,col,peak2,minPeakPromPeak2,numPeaks,locs2i);

TOF = unprocessedTOF;

for i = 1:row

    startI = 2;
    pastTOF = 0;
    locI = 1;

    for j = startI:col

        inflection = false;
        elseFlag = false;

        if numPeaks(i,j) >= 2
            
            locLocs = find(inflectionpts(i,:)==1);
            if locI <= length(locLocs) && j == locLocs(locI)
                inflection = true;
                locI = locI + 1;
            end

            if widePeak(i,j) == false
                if inflection == true ...
                    || j == 2 || j == col
                    
                    modeRow = unprocessedTOF(i,startI:j-1);

                    for k = startI:j-1
                        upLoc = find(inflectionpts(i:-1:1,k)==1,1);
                        downLoc = find(inflectionpts(i:end,k)==1,1)+i-1;
                        modeCol = repmat(unprocessedTOF(upLoc:downLoc,k)',1,5);
                        localMode = mode(round([modeCol,modeRow],2));

                        if abs(unprocessedTOF(i,k)-localMode) < 0.04
                            TOF(i,k) = localMode;
                        end
                    end
                    startI = j;
                    pastTOF = unprocessedTOF(i,j);
                end
            else
                elseFlag = true;
            end
        else
            elseFlag = true;
        end

        if elseFlag == true
            if pastTOF ~= 0

                modeRow = unprocessedTOF(i,startI:j-1);

                for k = startI:j-1
                    upLoc = find(inflectionpts(i:-1:1,k)==1,1);
                    downLoc = find(inflectionpts(i:end,k)==1,1)+i-1;
                    modeCol = repmat(unprocessedTOF(upLoc:downLoc,k)',1,5);
                    localMode = mode(round([modeCol,modeRow],2));

                    if abs(unprocessedTOF(i,k)-localMode) < 0.04
                        TOF(i,k) = localMode;
                    end
                end
            end
            startI = j;
            pastTOF = 0;
            TOF(i,j) = 0;
        end

    end
end

end