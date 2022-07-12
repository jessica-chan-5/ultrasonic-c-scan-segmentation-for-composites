%% Countor plot
figure;
testTOF = abs(rawTOF);
contourf(testTOF);

%% Plot A-Scans
plotRow = 160;
plotCol = 673;

spacing = 1;
numPoints = 1;
firstPeakTest = zeros(1,numPoints);
secondPeakTest = firstPeakTest;

figure;

for i = 1:numPoints
    
    titleStr = strcat("Row ", num2str(plotRow), " Col ", num2str(plotCol+(i-1)));
    aScan = squeeze(cScan(plotRow,plotCol+(i-1),:))';
    subplot(sqrt(numPoints),sqrt(numPoints),i);

    plot(t,abs(aScan));
    
    % Find neighboring values that are within 0.01 magnitude and set equal
    for k = 1:length(aScan)-1
        if abs(aScan(1,k+1)-aScan(1,k))<0.01
            aScan(1,k+1) = aScan(1,k);
        end
    end

    % Find and save peaks/locations in signal
    [p, l] = findpeaks(aScan,t);

    % Manually add 0 point to peaks list in case signal is cut off on
    % left side
    p = [0 p];
    l = [0 l];

    % Find neighboring peaks that are within 0.02 magnitude and set equal
    for k = 1:length(p)-1
        if abs(p(k+1)-p(k))< 0.02
            p(k+1) = p(k);
        end
    end
    
    % Square off zero TOF plateaus
    k = find(p>=0.94,1);
    hold on; plot(l(k),p(k),'x','MarkerSize',8);
    if mean(p(k:k+2)) >= 0.97
        p(k:k+2) = 1;
    end

    % Find and save locations of peaks in previously found peaks in
    % descending order
    hold on;
    [peak, loc, width, prom] = findpeaks(p,l,'MinPeakProminence',0.09,...
        'WidthReference','halfheight');
    if length(loc) >= 2
        k = find(l==loc(1));
        if width(1) > 0.7 && mean(p(k:k+4)) >= 0.97 && peak(2) < 0.98
            firstPeakTest(i) = 1;
            secondPeakTest(i) = 1;
        else
            firstPeakTest(i) = loc(1);
            secondPeakTest(i) = loc(2);
        end
    else
        firstPeakTest(i) = 1;
        secondPeakTest(i) = 1;
    end
    findpeaks(p,l,'Annotate','extents','MinPeakProminence',0.09,'WidthReference','halfheight')
    title(titleStr);
    xlabel("Time [us]");
    ylabel("Amplitude");
    xlim([0,tEnd]);

    hl=findobj(gcf,'type','legend');
    delete(hl);
end

TOFtest = (secondPeakTest-firstPeakTest)'


















