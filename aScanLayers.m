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
widePeakLoc = TOF;
widePeak = false(length(row),length(col));
peakLabels = cell(length(row),length(col));
locs = peakLabels;
inflectionpts = TOF;

% Sensitivity parameters
minPeakPromPeak = 0.1;
minPeakPromPeak2 = 0.1;
peakThresh = 0.02;
maxPeakWidth = 0.7;

for i = 1:length(row)
    
    labelList = 1:20;
    
    for j = 1:length(col)
        % Evaluate smoothing spline for t
        pfit = feval(fits{i,j},t);
        % Find and save locations of peaks in splin fit
        [peak, loc, width] = findpeaks(pfit,t,'MinPeakProminence',minPeakPromPeak);
        locs{i,j} = loc;
        for k = 1:length(peak)
            if width(k) > maxPeakWidth
                widePeak(i,j) = true;
                widePeakLoc(i,j) = k;
            end
        end
    
        % Count number of peaks
        numPeaks(i,j) = length(peak);

        % Assign unique peak IDs
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
    [~,magLoc] = findpeaks(peak2(i,:).^-1-1,'MinPeakProminence',minPeakPromPeak2);
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
toc;
disp('test');
end