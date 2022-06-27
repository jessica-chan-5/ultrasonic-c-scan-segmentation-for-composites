
plotRow = 221;
% plotRow = 1;
numCol = 1190;
plotCol = numCol/2;

% spacing = 5;
spacing = 1;
% numPoints = 9;
numPoints = 16;

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
    [~, loc] = findpeaks(p,'SortStr','descend');
    hold on;
    findpeaks(p,l,'Annotate','extents');

    title(titleStr);
    xlabel("Time [us]");
    ylabel("Amplitude");
    xlim([0,tEnd]);

    hl=findobj(gcf,'type','legend');
    delete(hl);
end