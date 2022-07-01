%% Plot A-Scans
plotRow = 201;
numCol = 1190;
plotCol = 770;

spacing = 1;
numPoints = 16;
plotIndex = zeros(1,numPoints);

figure;

for i = 1:numPoints
    rowNum = (i*spacing-1)+plotRow;
    titleStr = strcat(num2str(rowNum),", ",num2str(plotCol));
    
    subplot(sqrt(numPoints),sqrt(numPoints),i);
    plotIndices = plotCol+numCol*(rowNum-1);

    plot(t,abs(cScan(plotIndices,:)));
    
    % Find neighboring values that are within 0.01 magnitude and set equal
    for j = 1:length(cScan(i,:))-1
        if abs(cScan(i,j+1)-cScan(i,j))<0.01
            cScan(i,j+1) = cScan(i,j);
        end
    end

    % Find and save peaks/locations in signal
    [p, l] = findpeaks(cScan(plotIndices,:),t);

    % Manually add 0 point to peaks list in case signal is cut off on
    % left side
    p = [0 p];
    l = [0 l];

    % Test manual flat peaks
    for j = 1:length(p)-1
        if abs(p(j+1)-p(j))<0.05
            p(j+1) = p(j);
        end
    end

    % Find and save locations of peaks in previously found peaks in
    % descending order
    % [~, loc] = findpeaks(p,'SortStr','descend');
    hold on;
    [peak loc] = findpeaks(p,l,'Annotate','extents');
    findpeaks(p,l,'Annotate','extents');

    title(titleStr);
    xlabel("Time [us]");
    ylabel("Amplitude");
    xlim([0,tEnd]);

    hl=findobj(gcf,'type','legend');
    delete(hl);
end

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


















