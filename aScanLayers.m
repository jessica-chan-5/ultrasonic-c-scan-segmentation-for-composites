function [TOF,inflectionpts] = aScanLayers(fits)
tic;
row = 1:size(fits,1);
col = 1:size(fits,2);
% Time vector
dt = 0.02;
tEnd = (205-1)*dt;
t = 0:dt:tEnd;

% Initialize values
TOF = zeros(length(row),length(col));
loc1 = TOF;
loc2i = TOF;
locs2i = TOF;
peak2 = TOF;
numPeaks = TOF;
widePeak = false(length(row),length(col));
peakLabels = cell(length(row),length(col));
locs = peakLabels;
inflectionpts = TOF;

% Sensitivity parameters
minPeakPromPeak = 0.03;
minPeakPromPeak2 = 0.05;
peakThresh = 0.08;
maxPeakWidth = 0.7;

for i = 1:length(row)
    
    labelList = 1:20;
    
    for j = 1:length(col)
        % Evaluate smoothing spline for t
        pfit = feval(fits{i,j},t);
        % Find and save locations of peaks in splin fit
        [peak, loc, width] = findpeaks(pfit,t,'MinPeakProminence',minPeakPromPeak,'WidthReference','halfheight');
        locs{i,j} = loc;
        
        if width(1) > maxPeakWidth
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
            TOF(i,j) = loc(loc2i(i,j))-loc1(i,j);
            locs2i(i,j) = peakLabels{i,j}(loc2i(i,j));
        end
    end
end

for i = 1:length(row)

    % Find layer edges using peaks in 2nd peak mag values
    invertPeak2 = peak2(i,:).^-1-1;
    invertPeak2(isinf(invertPeak2)) = 0;
    [~,magLoc] = findpeaks(invertPeak2,'MinPeakProminence',minPeakPromPeak2);
    magLoc = col(magLoc);

    % Find layer edges using 2nd peak label changes
    peakLoc = [];

    for k = 2:length(col)
        if numPeaks(i,k) >= 2
            if locs2i(i,k) ~= locs2i(i,k-1)
                peakLoc = [peakLoc, col(k)]; %#ok<AGROW> 
            end
        end
    end

    % Merge both methods and remove neighboring values differing by 1
    % When both methods detect a layer change, the peak change is correct and
    % the index is peakLoc = magLoc+1, not sure why
    locLocs = magLoc;
    for k = 1:length(peakLoc)
        if min(abs(peakLoc(k)-magLoc))>5
            locLocs = [locLocs, peakLoc(k)]; %#ok<AGROW> 
        end
    end
    locLocs = sort(locLocs);
%     locLocs(diff(locLocs)<=1) = [];

    startI = 2;
    pastTOF = 0;
    locI = 1;

    for j = startI:length(col)

        inflection = false;
        elseFlag = false;

        if numPeaks(i,j) >= 2

            if locI <= length(locLocs) && col(j) == locLocs(locI)
                inflection = true;
                locI = locI + 1;
            end

            if widePeak(i,j) == false || widePeak(i,j) == true
                if inflection == true ...
                    || j == 2 || j == length(col)
    
%                     TOF(i,startI:j-1) = mode(round(TOF(i,startI:j-1),2));
                    localMode = mode(round(TOF(i,startI:j-1),2));
                    for k = startI:j-1
                        if abs(TOF(i,k)-localMode) < 0.08
                            TOF(i,k) = localMode;
                        end
                    end
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
%                 TOF(i,startI:j-1) = mode(round(TOF(i,startI:j-1),2));
                localMode = mode(round(TOF(i,startI:j-1),2));
                for k = startI:j-1
                    if abs(TOF(i,k)-localMode) < 0.08
                        TOF(i,k) = localMode;
                    end
                end
                inflectionpts(i,j) = 1;
            end
            startI = j;
            pastTOF = 0;
            TOF(i,j) = 0;
        end

    end
end
toc;
disp('test');
end