%% Plot TOF
figure;
contourf(TOF);

vertScale = 238;
numLayers = 25;
plateThick = 3.3;
saveFig = false;
baseTOF = mode(TOF(startRow:endRow,startCol:endCol),"all");
inFile = "testing";
% aScanSegmentation(TOF,inFile,numLayers,plateThick,baseTOF,vertScale,saveFig);

%% Plot imshow w/ jet w/o segmentation
figure('visible','on');
imjet = imshow(TOF,jet,'XData',[0 vertScale],'YData',[385 0]);
imjet.CDataMapping = "scaled";
title(strcat("TOF ",inFile));

%% Plot inflectionPts
inflectPtWhole = zeros(row,col);
inflectPtWhole(startRow:endRow,startCol:endCol) = inflectPt(1:end,1:end-1);

figure('visible','on');
imgray = imshow(inflectPtWhole,gray,'XData',[0 vertScale],'YData',[385 0]);
imgray.CDataMapping = "scaled";
title(strcat("TOF ",inFile));

%% Plot A-Scans

% Points to inspect
plotRow = 206;
plotCol = 1;
spacing = 1;
numPoints = 1000;
points = 1:spacing:numPoints*spacing;

% Figure properties
plotFig = false;

if plotFig == true
    figure;
    fontsizes = 18;
    axislabels = false;

    dt = 0.02;
    tEnd = (size(cScan,3)-1)*dt;
    t = 0:dt:tEnd;
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
neighThresh = 0.08; % 8 percent
minpeakheight = 0.11;

labelList = 1:20;

for i = 1:length(points)
    
    titleStr = strcat("Col ", num2str(plotCol+(points(i)-1))," i=",num2str(i));
    
    aScan = squeeze(cScan(plotRow,plotCol+(points(i)-1),:))';
    % Set values greater than 1 equal to 1
    aScan(aScan>1) = 1;

    if plotFig == true
        subplot(sqrt(numPoints),sqrt(numPoints),i); hold on;
        plot(t,abs(aScan));
    end

    % Find and save peaks/locations in signal
    [p, l] = findpeaks(aScan,t);

    % Manually add 0 point to peaks list in case signal is cut off on left
    p = [0 p]; %#ok<AGROW> 
    l = [0 l]; %#ok<AGROW> 
    
    % Flag wide peaks if max diff from max value is less than neighors by 8%
    for k = 1:length(p)-2
        if max(max(p(k:k+2)) - p(k:k+2)) <= neighThresh*max(p(k:k+2))
            widePeak(i) = true;
            widePeakLoc(i) = l(k);
            break;
        end
    end

    % Find neighboring peaks that are within 8%
    % Set peak location and value to be at max of the neighboring peaks
    [p, l] = findCenter(p,l,1,neighThresh,false);

    % Find and save locations of peaks in previously found peaks
    [peak,loc,width] = findpeaks(p,l,...
        'MinPeakHeight',minpeakheight,...
        'WidthReference','halfheight');
    locs{i} = loc;

    % Count number of peaks
    numPeaks(i) = length(peak);

    % Assign unique peak IDs
    peakThresh = 0.16;

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
        [peak2(i), loc2i(i)] = max(peak(2:end));
        loc2i(i) = loc2i(i) + 1;
        TOFtest(i) = loc(loc2i(i))-loc1(i);
        locs2i(i) = peakLabels{i}(loc2i(i));
    end
    
    if plotFig == true
        % Plot peaks
        findpeaks(p,l,...
            'Annotate','extents',...
            'MinPeakHeight',minpeakheight,...
            'WidthReference','halfheight')
    
        % Format plot
        title(titleStr);
        if axislabels == true
            xlabel("Time [us]");
            ylabel("Amplitude");
        end
        xlim([0,tEnd]);
        hl=findobj(gcf,'type','legend');
        delete(hl);
        fontsize(gca,fontsizes,'pixels');
    end
end

if plotFig == true
    sgtitle(strcat("Row ", num2str(plotRow)),'FontSize',fontsizes);
end

% Find peaks in neg val of 2nd peak mag
[~, magLoc] = findpeaks(-peak2,'MinPeakProminence',0.05);
% [~, magLocPos] = findpeaks(peak2,'MinPeakProminence',0.05);
% magLoc = sort([magLocNeg,magLocPos]);

startI = 2;
pastTOF = 0;
magI = 1;

for i = startI:length(points)

    inflection = false;
    elseFlag = false;

    if numPeaks(i) >= 2

        if numPeaks(i) > 1
            if magI <= length(magLoc) && ...
                    points(i) == magLoc(magI)
                inflection = true;
                magI = magI + 1;
                disp('b')
                disp(magI)
            elseif locs2i(i) ~= locs2i(i-1)
                inflection = true;
                disp('a')
            end
        end
        
        if widePeak(i) == false || (widePeak(i) == true && widePeakLoc(i) > loc1(i))
            if inflection == true ...
                || i == startI || i == length(points) ...
                || (pastTOF == 0 && TOFtest(i) ~= 0)

                disp("1")
                disp(strcat("Current i: ",num2str(i)," Past i: ",num2str(startI)));
                disp(strcat("CurrentTOF: ",num2str(TOFtest(i))," PastTOF: ",num2str(pastTOF)));
                TOFtest(startI:i-1) = mean(round(TOFtest(startI:i-1),2));
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
            TOFtest(startI:i-1) = mean(round(TOFtest(startI:i-1),2));
        end
        startI = i;
        pastTOF = 0;
        TOFtest(i) = 0;
    end
end

dispTOF = [(1:length(TOFtest))', TOFtest']

%% Plot peak values across row
figure;
findpeaks(-peak2,'MinPeakProminence',0.05); % Take negative of magnitude to turn valleys into peaks
hold on;
findpeaks(peak2,'MinPeakProminence',0.05);

