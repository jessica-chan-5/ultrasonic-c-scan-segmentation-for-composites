%% Plot imshow of TOF w/ jet colormap
figure; imjet = imshow(TOF,jet,'XData',[0 vertScale],'YData',[row 0]);
imjet.CDataMapping = "scaled";
title(strcat("TOF: ",fileName));
%% Plot filled contor of TOF
figure; contourf(TOF);
title(strcat("Contour TOF: ",fileName));
%% Plot A-Scans - testing smoothing spline method

% Points to inspect
plotRow = 215;
plotCol = 1;
spacing = 1;
numPoints = endCol;
points = 1:spacing:numPoints*spacing;

% Figure properties
plotFig = false;

% Initialize values
TOFtest = zeros(1,numPoints);
% loc1 = TOFtest;
% loc2i = TOFtest;
% locs2i = TOFtest;
% peak2 = TOFtest;
% numPeaks = TOFtest;
% widePeakLoc = TOFtest;
% widePeak = false(1,length(points));
% peakLabels = cell(1,length(points));
% locs = peakLabels;

% Sensitivity parameters
% minpeakheight = 0.1; % For finding peaks of peaks
% peakThresh = 0.14; % For setting peak IDs
minPeakProm = 0.012; % For finding peaks in 2nd peak magnitude

% labelList = 1:20;

if plotFig == true
    figure;
    fontsizes = 18;
    axislabels = false;
end


% Calculate time vector
dt = 0.02;
tEnd = (size(cScan,3)-1)*dt;
t = 0:dt:tEnd;

cScanSlice = squeeze(cScan(plotRow,:,:));

tic;

parfor i = 1:length(points)

    titleStr = strcat("Col ", num2str(plotCol+(points(i)-1))," i=",num2str(i));

    aScan = cScanSlice(plotCol+(points(i)-1),:);

    if plotFig == true
        subplot(sqrt(numPoints),sqrt(numPoints),i); hold on;
        plot(t,abs(aScan));
    end

    % Find and save peaks/locations in signal
    [p, l] = findpeaks(aScan,t);

    % Manually add 0 point to peaks list in case signal is cut off on left
    p = [0 p];
    l = [0 l];
    
    % Fit smoothing spline to find peak values
    f = fit(l',p','smoothingspline');
    % Find peak values in smoothing spline
    pfit = feval(f,t);

    % Find and save locations of peaks in previously found peaks
    [peak,loc] = findpeaks(pfit,t,'MinPeakProminence',minPeakProm);
%     locs{i} = loc;

    if plotFig == true
        plot(t,pfit);
        hold on;
        findpeaks(pfit,t,'MinPeakProminence',minPeakProm);

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

    % Count number of peaks
    numPeaks = length(peak);
%{
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
%}
    if numPeaks > 1
%         loc1(i) = loc(1);
        [~, loc2i] = max(peak(2:end));
%         loc2i(i) = loc2i(i) + 1;
        TOFtest(i) = loc(loc2i+1)-loc(1);
%         locs2i(i) = peakLabels{i}(loc2i(i));
    end
%}
end

toc;

% TOFfilter = TOFtest;

if plotFig == true
    sgtitle(strcat("Row ", num2str(plotRow)),'FontSize',fontsizes);
end

%{
% Find layer edges using peaks in 2nd peak mag values
[~, magLoc] = findpeaks(-peak2,'MinPeakProminence',minPeakProm);

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
locLocs = sort([magLoc, peakLoc]);
locLocs(diff(locLocs)<=1) = [];
locLocs = unique(locLocs);


startI = 2;
pastTOF = 0;

for i = startI:length(points)

    inflection = false;
    elseFlag = false;

    if numPeaks(i) >= 2

%         if sum(points(i) == locLocs)==1
%             inflection = true;
%             disp('Layer change detected');
%         end
        
        if widePeak(i) == false || (widePeak(i) == true && widePeakLoc(i) > loc1(i))
            if inflection == true ...
                || i == 2 || i == length(points) ...
                || (pastTOF == 0 && TOFtest(i) ~= 0)

                disp("1")
                disp(strcat("Current i: ",num2str(i)," Past i: ",num2str(startI)));
                disp(strcat("CurrentTOF: ",num2str(TOFtest(i))," PastTOF: ",num2str(pastTOF)));
%                 TOFtest(startI:i-1) = median(TOFtest(startI:i-1));
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
%             TOFtest(startI:i-1) = median(TOFtest(startI:i-1));
        end
        startI = i;
        pastTOF = 0;
        TOFtest(i) = 0;
    end
end
%}

%% Plot peak values across row
figure; hold on; 
plot(TOFtest);
xlim([startCol endCol]);
xlabel("Column Index");
ylabel("TOF");