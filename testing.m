%% Plot A-Scans
plotRow = 186;
plotCol = 390;

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

    % Find neighboring peaks that are within 0.15 magnitude and set equal
    for k = 1:length(p)-1
        if abs(p(k+1)-p(k))<0.15
            p(k+1) = p(k);
        end
    end

    % Find and save locations of peaks in previously found peaks in
    % descending order
    % Find and save locations of peaks in previously found peaks in
    % descending order
    hold on;
    [~, loc] = findpeaks(p,l,'SortStr','descend');
    if length(loc) >= 2
        firstPeakTest(i) = loc(1);
        secondPeakTest(i) = loc(2);
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

%% Show image slice

numCol = 1190+100;
height = 32/2;
plotRow = 384/2;
width = 2/2;

figure('visible','on');
% plotRow:plotRow+height
imshow(TOF(:,numCol/2-width:numCol/2+width),'XData',[vertScale*((width*2+1)/numCol) 0]);
title(strcat("TOF ",sampleName));

%% Bins
testTOF = round(abs(rawTOF),4);
[C,~,ic] = unique(testTOF);
a_counts = accumarray(ic,1);
[~,loc] = findpeaks(a_counts(2:end-2),C(2:end-2));

for i=1:numAScans
    for j=1:length(loc)-1
        if testTOF(i)>loc(j) && testTOF(i)<=loc(j+1)
            testTOF(i) = loc(j+1);
        end
    end
end

% Reshape and normalize raw TOF by max TOF
TOFtest = abs((1/max(testTOF)) .* reshape(testTOF',col,row)');


















