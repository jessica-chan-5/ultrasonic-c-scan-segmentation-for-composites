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
plotRow = 165;
plotCol = 381;

spacing = 1;
numPoints = 36;
TOFtest = zeros(1,numPoints);
points = 1:spacing:numPoints*spacing;

% Sensitivity parameters
neighThresh = 0.08; % 8 percent
minpeakheight = 0.16;

figure;
fontsizes = 18;
axislabels = false;

startI = 1;
l2i = zeros(1,length(points));
loc2i = l2i;
peak2 = l2i;
pastTOF = 0;
pastNumPeaks = 0;

for i = 1:length(points)
    
    inflection = false;
    widePeak = false;
    widePeakLoc = t(end);

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
            widePeak = true;
            widePeakLoc = l(k);
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

    for k = 1:length(width)
        if width(k) >= 0.80
            widePeak = true;
            widePeakLoc = loc(k);
            break;
        end
    end

    % Count number of peaks
    currentNumPeaks = length(peak)-1;

    if length(loc) >= 2

        [peak2(i), loc2i(i)] = max(peak(2:end));
        loc2i(i) = loc2i(i) + 1;
        currentTOF = loc(loc2i(i))-loc(1);

        if i > 3
            if currentNumPeaks > 0
                if currentNumPeaks == pastNumPeaks && loc2i(i) ~= loc2i(i-1)
                    inflection = true;
                elseif peak2(i-2) > peak2(i-1) && peak2(i) > peak2(i-1)
                    inflection = true;
                elseif (peak2(i-3)-peak2(i)) == 0 && (peak2(i-2)-peak2(i-1)) == 0
                    inflection = true;
                end
            end
        end
        
        pastNumPeaks = currentNumPeaks;

        if widePeak == false || (widePeak == true && widePeakLoc > loc(1))
            if inflection == true ...
                || i == 1 || i == length(points) ...
                || (pastTOF == 0 && currentTOF ~= 0)

                disp("1")
                disp(strcat("Current i: ",num2str(i)," Past i: ",num2str(startI)));
                disp(strcat("CurrentTOF: ",num2str(currentTOF)," PastTOF: ",num2str(pastTOF)));
                TOFtest(startI:i-1) = mode(round(TOFtest(startI:i-1),2));
                TOFtest(i) = currentTOF;
                startI = i;
                pastTOF = currentTOF;
            else
                TOFtest(i) = currentTOF;
            end
        else
            if pastTOF ~= 0
                disp("2")
                disp(strcat("Current i: ",num2str(i)," Past i: ",num2str(startI)));
                disp(strcat("CurrentTOF: ",num2str(currentTOF)," PastTOF: ",num2str(pastTOF)));
                TOFtest(startI:i-1) = mode(round(TOFtest(startI:i-1),2));
            end
            startI = i;
            pastTOF = 0;
            TOFtest(i) = 0;
        end
    else
        if pastTOF ~= 0
            disp("3")
            disp(strcat("Current i: ",num2str(i)," Past i: ",num2str(startI)));
            disp(strcat("CurrentTOF: ",num2str(currentTOF)," PastTOF: ",num2str(pastTOF)));
            TOFtest(startI:i-1) = mode(round(TOFtest(startI:i-1),2));
        end
        startI = i;
        pastTOF = 0;
        TOFtest(i) = 0;
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

TOFtest = [(1:length(TOFtest))', TOFtest']
