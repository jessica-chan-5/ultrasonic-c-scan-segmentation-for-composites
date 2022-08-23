%% Plot TOF
figure;
imshow(TOFplot,'XData',[0 vertScale],'YData',[385 0]);

figure;
contourf(TOF);

vertScale = 238;
numLayers = 25;
plateThick = 3.3;
baseTOF = mode(TOF(startRow:endRow,startCol:endCol),"all");
aScanSegmentation(TOF,numLayers,plateThick,baseTOF,vertScale);

%% Plot A-Scans
plotRow = 223;
plotCol = 688;

spacing = 7;
numPoints = 25;
TOFtest = zeros(1,numPoints);
points = 1:spacing:numPoints*spacing;

% Sensitivity parameters
neighThresh = 0.04; % 10 x 0.0039 (1/2^8)
layerThresh = 0.16; % 0.10 + 0.02*3
minpeakprom = 0.09;
minpeakheight = 0.16;

figure;
fontsizes = 12;
axislabels = false;

startI = 1;
l2i = zeros(1,length(points));
pastTOF = 0;

for i = 1:length(points)
    
    widePeak = false;
    widePeakI = t(end);

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
    
    % Flag wide peaks if mean is close to 1 and max diff from 1 is less
    % than neighoring threshold value
    for k = 1:length(p)-2
        if mean(p(k:k+2)) >= 0.98 && max(1 - p(k:k+2)) <= neighThresh
            widePeak = true;
            widePeakI = l(k);
            break;
        end
    end

    % Find neighboring peaks that are within ~10 x 0.0039
    % Set peak location and value to be at leftmost of the neighboring peaks
    [p, l] = findCenter(p,l,1,neighThresh,false);
%     p = rmmissing(p);
%     l = rmmissing(l);

    % Find and save locations of peaks in previously found peaks
    [peak, loc] = findpeaks(p,l,...
        'MinPeakProminence',minpeakprom,...
        'MinPeakHeight',minpeakheight,...
        'WidthReference','halfheight');

    if length(loc) >= 2

        loc1 = loc(1);
        [~, loc2i] = max(peak(2:end));
        loc2i = loc2i + 1;
        l2i(i) = find(l==loc(loc2i));
        tof = loc(loc2i)-loc(1);

        currentTOF = tof;

        if widePeak == false || (widePeak == true && widePeakI > loc(1))
            if (range(l2i(startI:i)) > 2 && abs(pastTOF-currentTOF) > layerThresh) ...
                    || i == 1 || i == length(points) ...
                    || (pastTOF == 0 && currentTOF ~= 0)
                disp("1")
                disp(strcat("Current i: ",num2str(i)," Past i: ",num2str(startI)));
                disp(strcat("CurrentTOF: ",num2str(currentTOF)," PastTOF: ",num2str(pastTOF)));
                round(TOFtest(startI:i-1),2)
                mode(round(TOFtest(startI:i-1),2))
                TOFtest(startI:i-1) = mode(round(TOFtest(startI:i-1),2));
                TOFtest(i) = currentTOF;
                startI = i;
                pastTOF = currentTOF;
            else
                TOFtest(i) = tof;
            end
        else
            currentTOF = 0;
            if pastTOF ~= 0
                disp("2")
                disp(strcat("Current i: ",num2str(i)," Past i: ",num2str(startI)));
                disp(strcat("CurrentTOF: ",num2str(currentTOF)," PastTOF: ",num2str(pastTOF)));
                TOFtest(startI:i-1) = mode(round(TOFtest(startI:i-1),2));
                TOFtest(i) = currentTOF;
            end
            TOFtest(i) = 0;
            startI = i;
            pastTOF = 0;
        end
    else
        currentTOF = 0;
        if pastTOF ~= 0
            disp("3")
            disp(strcat("Current i: ",num2str(i)," Past i: ",num2str(startI)));
            disp(strcat("CurrentTOF: ",num2str(currentTOF)," PastTOF: ",num2str(pastTOF)));
            TOFtest(startI:i-1) = mode(round(TOFtest(startI:i-1),2));
            TOFtest(i) = currentTOF;
        end
        TOFtest(i) = 0;
        startI = i;
        pastTOF = 0;
    end

    % Plot peaks
    findpeaks(p,l,...
        'Annotate','extents',...
        'MinPeakProminence',minpeakprom,...
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

l2i
TOFtest = [(1:length(TOFtest))', TOFtest']
