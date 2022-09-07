%% Plot TOF
% figure;
% imshow(TOFplot,'XData',[0 vertScale],'YData',[385 0]);

figure;
contourf(TOF);

vertScale = 238;
numLayers = 25;
plateThick = 3.3;
baseTOF = mode(TOF(startRow:endRow,startCol:endCol),"all");
aScanSegmentation(TOF,numLayers,plateThick,baseTOF,vertScale);

%% Plot A-Scans
plotRow = 142;
plotCol = 599;

spacing = 1;
numPoints = 25;
TOFtest = zeros(1,numPoints);
points = 1:spacing:numPoints*spacing;

% Sensitivity parameters
neighThresh = 0.08; % 8 percent
minpeakheight = 0.16;

figure;
fontsizes = 18;
axislabels = false;

loc2i = TOFtest;
peak2 = TOFtest;
widePeak = false(1,length(points));
widePeakLoc = TOFtest;
numPeaks = TOFtest;
loc1 = TOFtest;

for i = 1:length(points)
    
    titleStr = strcat("Col ", num2str(plotCol+(points(i)-1))," i=",num2str(i));
    aScan = squeeze(cScan(plotRow,plotCol+(points(i)-1),:))';
    aScan(aScan>1) = 1;

    subplot(sqrt(numPoints),sqrt(numPoints),i); hold on;
    plot(t,abs(aScan));

    % Find and save peaks/locations in signal
    [p, l] = findpeaks(aScan,t);

    % Manually add 0 point to peaks list in case signal is cut off on left
    p = [0 p]; %#ok<AGROW> 
    l = [0 l]; %#ok<AGROW> 
    
    % Flag wide peaks if max diff from 1 is less than neighoring threshold value
    for k = 1:length(p)-2 
        if max(1 - p(k:k+2)) <= neighThresh
            widePeak(i) = true;
            widePeakLoc(i) = l(k);
            break;
        end
    end

    % Find neighboring peaks that are within 8%
    % Set peak location and value to be at max of the neighboring peaks
    [p, l] = findCenter(p,l,1,neighThresh,false);

    % Find and save locations of peaks in previously found peaks
    [peak,loc,width] = findpeaks(p,l,...
        'MinPeakHeight',minpeakheight,...
        'WidthReference','halfheight');

    % Count number of peaks
    numPeaks(i) = length(peak)-1;
    
    if numPeaks(i)+1 >= 2
        loc1(i) = loc(1);
        [peak2(i), loc2i(i)] = max(peak(2:end));
        loc2i(i) = loc2i(i) + 1;
        TOFtest(i) = loc(loc2i(i))-loc1(i);
    end

    % Plot peaks
    findpeaks(p,l,...
        'Annotate','extents',...
        'MinPeakHeight',minpeakheight,...
        'WidthReference','halfheight')

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

sgtitle(strcat("Row ", num2str(plotRow)),'FontSize',fontsizes);

%%

startI = 4;
pastTOF = 0;

for i = 4:length(points)-3

    inflection = false;
    elseFlag = false;

    if numPeaks(i)+1 >= 2

        if numPeaks(i) > 0
            if numPeaks(i) == numPeaks(i-1) && loc2i(i) ~= loc2i(i-1)
                inflection = true;
                disp('a')
            elseif issorted(peak2(i-2:i),'descend') && issorted(peak2(i+1:i+2))
                inflection = true;
                disp('b')
            end
        end
        
        if widePeak(i) == false || (widePeak(i) == true && widePeakLoc(i) > loc1(i))
            if inflection == true ...
                || i == 1 || i == length(points)-5 ...
                || (pastTOF == 0 && TOFtest(i) ~= 0)

                disp("1")
                disp(strcat("Current i: ",num2str(i)," Past i: ",num2str(startI)));
                disp(strcat("CurrentTOF: ",num2str(TOFtest(i))," PastTOF: ",num2str(pastTOF)));
                TOFtest(startI:i-1) = mode(round(TOFtest(startI:i-1),2));
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
            TOFtest(startI:i-1) = mode(round(TOFtest(startI:i-1),2));
        end
        startI = i;
        pastTOF = 0;
        TOFtest(i) = 0;
    end
end

dispTOF = [(1:length(TOFtest))', TOFtest']
