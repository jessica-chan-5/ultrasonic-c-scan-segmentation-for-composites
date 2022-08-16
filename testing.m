%% Imshow normalized TOF
figure('visible','on');
imshow(TOFplot,'XData',[0 vertScale],'YData',[385 0]);
title(strcat("TOF ",sampleName));

%% Countor plot TOF
figure;
contourf(TOF);

%% Save figure
ax = gca;
exportgraphics(ax,strcat('Figures\',sampleName,'.png'),'Resolution',300);

%% Plot A-Scans
plotRow = 175;
plotCol = 635;

spacing = 1;
numPoints = 1;
firstPeakTest = zeros(1,numPoints);
secondPeakTest = firstPeakTest;
points = 1:spacing:numPoints*spacing;

figure;

for i = 1:length(points)
    
    widePeak = false;

    titleStr = strcat("Row ", num2str(plotRow), " Col ", num2str(plotCol+(points(i)-1)));
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

    for k = 1:length(p)-3
        if mean(p(k:k+2)) >= 0.98 && max(1 - p(k:k+2)) <= (10*0.0039)
            widePeak = true;
            break;
        end
    end

    % Find neighboring peaks that are within 10 x 0.0039
    % Set peak location to be at center of the neighboring peaks
    % Set peak value as max of neighboring peaks
    [p, l] = findCenter(p,l,4);
    [p, l] = findCenter(p,l,3);
    [p, l] = findCenter(p,l,2);
    [p, l] = findCenter(p,l,1);

    % Find and save locations of peaks in previously found peaks in
    % descending order
    minpeakprom = 0.09;
    hold on;
    [peak, loc, width, prom] = findpeaks(p,l,'Annotate','extents',...
        'MinPeakProminence',minpeakprom,'MinPeakHeight',0.16,...
        'SortStr','descend','WidthReference','halfheight');
    
    if length(loc) >= 2 && widePeak == false
        firstPeakTest(i) = loc(1);
        secondPeakTest(i) = loc(2);
    else
        firstPeakTest(i) = 1;
        secondPeakTest(i) = 1;
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

TOFtest = abs(secondPeakTest-firstPeakTest)'













