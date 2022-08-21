%% Imshow normalized TOF
figure('visible','on');
imshow(TOFplot,'XData',[0 vertScale],'YData',[385 0]);
title(strcat("TOF ",sampleName));

%% Countor plot TOF
figure;
contourf(TOF);

%% Plot color

dt           = 0.02;  % us
vertScale    = 238;   % equal to "Scanning Length" in header
noiseThresh  = 0.01;
cropDam      = true;
plotTOF      = true;
plotAScan    = false;
saveMat      = false;
saveFig      = true;

numLayers = 25;
plateThick = 3.3; % mm

aScanSegmentation(TOF,numLayers,plateThick,baseTOF,vertScale)

%% Save figure
ax = gca;
exportgraphics(ax,strcat('Figures\',sampleName,'.png'),'Resolution',300);

%% Plot A-Scans
plotRow = 185;
plotCol = 392;

spacing = 7;
numPoints = 16;
TOFtest = zeros(1,numPoints);
points = 1:spacing:numPoints*spacing;

figure;

startI = 1;

for i = 1:length(points)
    
    widePeak = false;
    widePeakI = t(end);

    titleStr = strcat("Row ", num2str(plotRow), " Col ", num2str(plotCol+(points(i)-1))," i=",num2str(i));
    aScan = squeeze(cScan(plotRow,plotCol+(points(i)-1),:))';
    aScan(aScan>1) = 1;

    subplot(sqrt(numPoints),sqrt(numPoints),i);

    plot(t,abs(aScan));

    % Find and save peaks/locations in signal
    [p, l] = findpeaks(aScan,t);

    % Manually add 0 point to peaks list in case signal is cut off on
    % left side
    p = [0 p];
    l = [0 l];
    
    for k = 1:length(p)-2
        if mean(p(k:k+2)) >= 0.98 && max(1 - p(k:k+2)) <= (10*0.0039)
            widePeak = true;
            widePeakI = l(k);
            break;
        end
    end

    % Find neighboring peaks that are within 10 x 0.0039
    % Set peak location to be at center of the neighboring peaks
    % Set peak value as max of neighboring peaks
    thresh = 0.04;
%     [p, l] = findCenter(p,l,4,thresh,false);
%     [p, l] = findCenter(p,l,3,thresh,false);
%     [p, l] = findCenter(p,l,2,thresh,false);
    [p, l] = findCenter(p,l,1,thresh,false);

    p = rmmissing(p);
    l = rmmissing(l);

    % Find and save locations of peaks in previously found peaks in
    % descending order
    minpeakprom = 0.09;
    hold on;
    [peak, loc, width, prom] = findpeaks(p,l,'Annotate','extents',...
        'MinPeakProminence',minpeakprom,'MinPeakHeight',0.16,...
        'WidthReference','halfheight');

    if length(loc) >= 2

        for k = 1:length(loc)-1
            if (loc(k+1)-loc(k)) <= 0.28
                disp(strcat("Removed loc(k+1=",num2str(k+1),"), j=",num2str(i)));
                peak(k+1) = NaN;
                loc(k+1) = NaN;
            end
        end

        peak = rmmissing(peak);
        loc = rmmissing(loc);

        loc1 = loc(1);
        [~, loc2i] = max(peak(2:end));
        tof = loc(loc2i+1)-loc(1);

        if i == 1
            pastTOF = tof+0.16;
        end
        currentTOF = tof;

        if widePeak == false || (widePeak == true && widePeakI > loc(1))
            if abs(pastTOF-currentTOF) > 0.16
                disp(strcat("Current i: ",num2str(i)," Past i: ",num2str(startI)));
                disp(strcat("CurrentTOF: ",num2str(currentTOF)," PastTOF: ",num2str(pastTOF)));
                TOFtest(startI:i) = pastTOF;
                startI = i;
                pastTOF = currentTOF;
            else
                TOFtest(i) = tof;
            end
        else
            TOFtest(i) = 0;
            startI = i;
            pastTOF = 0;
        end
    else
        TOFtest(i) = 0;
        startI = i;
        pastTOF = 0;
    end

    findpeaks(p,l,'Annotate','extents','MinPeakProminence',minpeakprom,...
        'MinPeakHeight',0.16,'SortStr','descend','WidthReference','halfheight')
    title(titleStr);
    xlabel("Time [us]");
    ylabel("Amplitude");
    xlim([0,tEnd]);

    hl=findobj(gcf,'type','legend');
    delete(hl);
end

TOFtest = [(1:length(TOFtest))', TOFtest']

%% Try to draw outlines

testingTOF = TOFtest;

% Left to right
for i = 1:size(TOFtest,1)
    for j = 2:size(TOFtest,2)
        if abs(TOFtest(i,j-1) - TOFtest(i,j)) >= 0.1
            testingTOF(i,j) = 0;
        end
    end
end

% Top to bottom
for j = 1:size(TOFtest,2)
    for i = 2:size(TOFtest,1)
        if abs(TOFtest(i-1,j) - TOFtest(i,j)) >= 0.1
            testingTOF(i,j) = 0;
        end
    end
end

%% Plot outlines
figure('visible','on');
imshow((1/max(testingTOF,[],'all')) .* testingTOF,'XData',[0 vertScale],'YData',[385 0]);
title(strcat("TOF ",sampleName));




