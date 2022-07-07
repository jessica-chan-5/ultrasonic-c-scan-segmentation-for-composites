%% Countor plot
figure;
contourf(TOF);

%% Plot A-Scans
plotRow = 165;
plotCol = 680;

spacing = 1;
numPoints = 16;
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
%     findpeaks(aScan,t);
    % Manually add 0 point to peaks list in case signal is cut off on
    % left side
    p = [0 p];
    l = [0 l];

    % Find neighboring peaks that are within 0.05 magnitude and set equal
    for k = 1:length(p)-1
%         if abs(p(k+1)-p(k))< (5*(2^8)^-1)
        if abs(p(k+1)-p(k))< 0.05
            p(k+1) = p(k);
        end
    end

    % Find and save locations of peaks in previously found peaks in
    % descending order
    hold on;
    [peak, loc, width] = findpeaks(p,l,'SortStr','descend','WidthReference','halfheight');
    if length(loc) >= 2
        k = find(l==loc(1));
        if width(1) > 0.7 && mean(p(k):p(k)+4) <= 0.9
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
    findpeaks(p,l,'MinPeakProminence',0.1,'Annotate','extents');

    title(titleStr);
    xlabel("Time [us]");
    ylabel("Amplitude");
    xlim([0,tEnd]);

    hl=findobj(gcf,'type','legend');
    delete(hl);
end

TOFtest = (secondPeakTest-firstPeakTest)'


















