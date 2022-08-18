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
plotRow = 208;
plotCol = 631;

spacing = 2;
numPoints = 9;
firstPeakTest = zeros(1,numPoints);
secondPeakTest = firstPeakTest;
points = 1:spacing:numPoints*spacing;

figure;

for i = 1:length(points)
    
    widePeak = false;
    widePeakI = t(end);

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
    thresh = 10*0.0039;
    [p, l] = findCenter(p,l,4,thresh);
    [p, l] = findCenter(p,l,3,thresh);
    [p, l] = findCenter(p,l,2,thresh);
    [p, l] = findCenter(p,l,1,thresh);

    % Find and save locations of peaks in previously found peaks in
    % descending order
    minpeakprom = 0.09;
    hold on;
    [peak, loc, width, prom] = findpeaks(p,l,'Annotate','extents',...
        'MinPeakProminence',minpeakprom,'MinPeakHeight',0.16,...
        'SortStr','descend','WidthReference','halfheight');

    if length(loc) >= 2
        loc1 = min([loc(1),loc(2)]);
        loc2 = max([loc(1),loc(2)]);
        
        if widePeak == false
            firstPeakTest(i) = loc1;
            secondPeakTest(i) = loc2;
        elseif widePeak == true && widePeakI > loc1
            firstPeakTest(i) = loc1;
            secondPeakTest(i) = loc2;
        else
            firstPeakTest(i) = 1;
            secondPeakTest(i) = 1;
        end
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

TOFtest = (secondPeakTest-firstPeakTest)'

%% Remove outliers

testingTOF = TOF;

for i = 2:size(testingTOF,1)-1
    for j = 2:size(testingTOF,2)-1
        L = j-1;
        R = j+1;
        T = i+1;
        B = i-1;
        Mi = i;
        Mj = j;
        
        TL = TOF(T,L);
        TMj = TOF(T,Mj);
        TR = TOF(T,R);
        
        MiL = TOF(Mi,L);
        MiR = TOF(Mi,R);

        BL = TOF(B,L);
        BMj = TOF(B,Mj);
        BR = TOF(B,R);

        if range([TL,TMj,TR,MiL,MiR,BL,BMj,BR]) == 0
            testingTOF(i,j) = TL;
        end
    end
end

%% Plot testingTOF
figure('visible','on');
imshow((1/max(testingTOF,[],'all')) .*testingTOF,'XData',[0 vertScale],'YData',[385 0]);
title(strcat("TOF ",sampleName));









