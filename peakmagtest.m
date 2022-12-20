%% Plot A-Scans
tic;
format compact;

% Points to inspect
plotRow = 235-90; %floor(size(fits,1)/2);
plotCol = 1;
spacing = 1;
numPoints = size(fits,2);
plotFig = false;
points = 1:spacing:numPoints*spacing;

% Time vector
dt = 0.02;
tEnd = (205-1)*dt;
t = 0:dt:tEnd;

% Figure properties
if plotFig == true
    figure;
    fontsizes = 18;
    axislabels = false;
end

% Initialize values
TOFtest = zeros(1,numPoints);
loc1 = TOFtest;
loc2i = TOFtest;
locs2i = TOFtest;
peak2 = TOFtest;
numPeaks = TOFtest;
widePeakLoc = TOFtest;
widePeak = false(1,length(points));
peakLabels = cell(1,length(points));
locs = peakLabels;

% Sensitivity parameters
minPeakPromPeak = 0.03;
minPeakPromPeak2 = 0.05;
peakThresh = 0.02;
maxPeakWidth = 0.7;

labelList = 1:20;

for i = 1:length(points)
    
    titleStr = strcat("Col ", num2str(plotCol+(points(i)-1))," i=",num2str(i));
    
    row = plotRow;
    col = plotCol+(points(i)-1);

    % Find and save locations of peaks in previously found peaks
    % Evaluate smoothing spline for t
    pfit = feval(fits{row,col},t);

    % Find and save locations of peaks in previously found peaks
    [peak,loc,width,prom] = findpeaks(pfit,t,'MinPeakProminence',minPeakPromPeak,'WidthReference','halfheight');
    locs{i} = loc;
    
    % Check if first peak is wide
    if width(1) > maxPeakWidth
        widePeak(i) = true;
    end

    if plotFig == true
        s = sqrt(length(points));
        subplot(s,s,i);
        hold on;
        findpeaks(pfit,t,'MinPeakProminence',minPeakPromPeak,'Annotate','extents','WidthReference','halfheight')
        % Format plot
        title(titleStr);
        xlim([0 t(end)]);
        hl=findobj(gcf,'type','legend');
        delete(hl);
        fontsize(gca,fontsizes,'pixels');
    end
    % Count number of peaks
    numPeaks(i) = length(peak);

    % Assign unique peak IDs
    if i == 1
        peakLabels{i} = 1:length(locs{i});
        labelList = labelList(length(locs{i})+1:end);
    else
        tempCurr = locs{i};
        tempPrev = locs{i-1};

        for k = 1:length(tempPrev)
            minDiff = min(abs(locs{i-1}(k)-tempCurr));
            if minDiff > peakThresh
                labelList = sort([peakLabels{i-1}(k), labelList]);
            end
        end
        
        for k = 1:length(tempCurr)
            [minDiff, minI] = min(abs(locs{i}(k)-tempPrev));
            if minDiff < peakThresh
                tempCurr(minI) = NaN;
                peakLabels{i} = [peakLabels{i}, peakLabels{i-1}(minI)];
            else
                peakLabels{i} = [peakLabels{i}, labelList(1)];
                labelList = labelList(2:end);
            end
        end
    end

    if numPeaks(i) >= 2
        loc1(i) = loc(1);
        if widePeak(i) == false
            [peak2(i), loc2i(i)] = max(peak(2:end));
        else
            [~, loc2i(i)] = max(peak(2:end));
        end
        loc2i(i) = loc2i(i) + 1;
        TOFtest(i) = loc(loc2i(i))-loc1(i);
        locs2i(i) = peakLabels{i}(loc2i(i));
    end
end
if plotFig == true
    sgtitle(strcat("Row ", num2str(plotRow)),'FontSize',fontsizes);
end

% Find layer edges using peaks in 2nd peak mag values
invertPeak2 = peak2.^-1-1;
invertPeak2(isinf(invertPeak2)) = 0;
[~, magLoc] = findpeaks(invertPeak2,'MinPeakProminence',minPeakPromPeak2);

% Find layer edges using 2nd peak label changes
peakLoc = [];

for i = 2:length(points)
    if numPeaks(i) >= 2
        if locs2i(i) ~= locs2i(i-1)
            peakLoc = [peakLoc, i];
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

startI = 2;
pastTOF = 0;
locI = 1;

for i = startI:length(points)
    inflection = false;
    elseFlag = false;

    if numPeaks(i) >= 2

        if locI <= length(locLocs) && ...
                points(i) == locLocs(locI)
            inflection = true;
            locI = locI + 1;
            disp('Layer change detected');
        end

        if widePeak(i) == false || widePeak(i) == true
            if inflection == true ...
                || i == 2 || i == length(points) ...
                || (pastTOF == 0 && TOFtest(i) ~= 0)

                disp("1")
                disp(strcat("Current i: ",num2str(i)," Past i: ",num2str(startI)));
                disp(strcat("CurrentTOF: ",num2str(TOFtest(i))," PastTOF: ",num2str(pastTOF)));
                localMode = mode(round(TOFtest(startI:i-1),2));
                for k = startI:i-1
                    if abs(TOFtest(k)-localMode) < 0.08
                        TOFtest(k) = localMode;
                    end
                end
                startI = i;
                pastTOF = TOFtest(i);
            end
        else
            elseFlag = true;
        end
    else
        elseFlag = true;
    end
    if elseFlag == true
        if pastTOF ~= 0
            disp("2")
            disp(strcat("Current i: ",num2str(i)," Past i: ",num2str(startI)));
            disp(strcat("CurrentTOF: ",num2str(TOFtest(i))," PastTOF: ",num2str(pastTOF)));
            localMode = mode(round(TOFtest(startI:i-1),2));
            for k = startI:i-1
                if abs(TOFtest(k)-localMode) < 0.08
                    TOFtest(k) = localMode;
                end
            end
        end
        startI = i;
        pastTOF = 0;
        TOFtest(i) = 0;
    end
end
% dispTOF = [(1:length(TOFtest))', TOFtest']
toc;
%% Plot peak values across row
figure;
invertPeak2 = peak2.^-1-1;
invertPeak2(isinf(invertPeak2)) = 0;
findpeaks(invertPeak2,points+plotCol,'MinPeakProminence',minPeakPromPeak2,'Annotate','Extents');