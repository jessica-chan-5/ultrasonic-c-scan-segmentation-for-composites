%% Plot TOF
figure;
contourf(TOF);

vertScale = 238;
numLayers = 25;
plateThick = 3.3;
baseTOF = mode(TOF(startRow:endRow,startCol:endCol),"all");
aScanSegmentation(TOF,numLayers,plateThick,baseTOF,vertScale);

%% Plot A-Scans

% Points to inspect
plotRow = 190;
plotCol = 332;
spacing = 1;
numPoints = 516;
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

startI = 3;
pastTOF = 0;

for i = 3:length(points)-2

    inflection = false;
    elseFlag = false;

    if numPeaks(i) >= 2

        if numPeaks(i) > 1
            if locs2i(i) ~= locs2i(i-1)
                inflection = true;
                disp('a')
            elseif all(peak2(i-2:i+2) ~= 1) && ...
                    issorted(peak2(i-2:i),'descend') && ...
                    issorted(peak2(i:i+2))% ascend
                inflection = true;
                disp('b')
            end
        end
        
        if widePeak(i) == false || (widePeak(i) == true && widePeakLoc(i) > loc1(i))
            if inflection == true ...
                || i == 3 || i == length(points)-2 ...
                || (pastTOF == 0 && TOFtest(i) ~= 0)

                disp("1")
                disp(strcat("Current i: ",num2str(i)," Past i: ",num2str(startI)));
                disp(strcat("CurrentTOF: ",num2str(TOFtest(i))," PastTOF: ",num2str(pastTOF)));
                TOFtest(startI:i-1) = mode(round(TOFtest(startI:i-1),2));
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
            TOFtest(startI:i-1) = mode(round(TOFtest(startI:i-1),2));
        end
        startI = i;
        pastTOF = 0;
        TOFtest(i) = 0;
    end
end

dispTOF = [(1:length(TOFtest))', TOFtest']
