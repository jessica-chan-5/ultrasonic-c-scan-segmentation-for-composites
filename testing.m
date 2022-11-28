%% Plot imshow of TOF w/ jet colormap
figure; imjet = imshow(TOF,jet,'XData',[0 vertScale],'YData',[row 0]);
imjet.CDataMapping = "scaled";
title(strcat("TOF: ",fileName));
%% Plot filled contor of TOF
figure; contourf(TOF);
title(strcat("Contour TOF: ",fileName));
%% Plot A-Scans - testing smoothing spline method

% Points to inspect
plotRow = 199;
plotCol = 467;
spacing = 1;
numPoints = 36;
points = 1:spacing:numPoints*spacing;

% Figure properties
plotFig = true;

% Initialize values
TOFtest = zeros(1,numPoints);

% Sensitivity parameters
minPeakPromP = 0.03; % For finding peaks of a-scan
minPeakPromPeak = 0.1; % For finding peaks of spline fit
smoothSplineParam = 1; % For smoothparam when using fit with smoothingspline option

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

for i = 1:length(points)

    titleStr = strcat("Col ", num2str(plotCol+(points(i)-1))," i=",num2str(i));

    aScan = cScanSlice(plotCol+(points(i)-1),:);

    if plotFig == true
        subplot(sqrt(numPoints),sqrt(numPoints),i); hold on;
        plot(t,abs(aScan));
    end

    % Find and save peaks/locations in signal
    [p, l, ~, prom] = findpeaks(aScan,t,'MinPeakProminence',minPeakPromP);
%     disp('peak prom');
%     disp(prom);

    % Force signal to be zero at beginning and end
    p = [0 p 0];
    l = [0 l t(end)];
    
    % Fit smoothing spline to find peak values
    f = fit(l',p','smoothingspline','SmoothingParam',smoothSplineParam);
    % Find peak values in smoothing spline
    pfit = feval(f,t);

    % Find and save locations of peaks in previously found peaks
    [peak,loc,~,prom] = findpeaks(pfit,t,'MinPeakProminence',minPeakPromPeak);
%     disp('peak prom');
%     disp(prom);

    if plotFig == true
        plot(t,pfit);
        hold on;
        findpeaks(pfit,t,'MinPeakProminence',minPeakPromPeak);

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

    if numPeaks > 1
        [~, loc2i] = max(peak(2:end));
        TOFtest(i) = loc(loc2i+1)-loc(1);
    end
end

toc;

if plotFig == true
    sgtitle(strcat("Row ", num2str(plotRow)),'FontSize',fontsizes);
end
%% Plot peak values across row
figure; hold on; 
plot(TOFtest);
xlim([startCol endCol]);
xlabel("Column Index");
ylabel("TOF");