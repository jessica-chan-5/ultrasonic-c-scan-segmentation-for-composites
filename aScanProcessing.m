function TOF = aScanProcessing(cScan,inFile,outFile,dt,vertScale,noiseThresh,startRow,startCol,endRow,endCol,plotRow,plotCol,plotTOF,plotAScan,saveMat,saveFig)
% Take .csv C-scan input file, calculate time of flight (TOF), and save
% normalized TOF data as .mat file
% 
% Inputs:
%   inFile     : Name of .mat C-scan input file
%   outFile    : Name of .mat TOF output file
%   dt         : Sampling period [us]
%   vertScale  : Vertical scaling factor for TOF plot
%   noiseThresh: If mean signal value is below value of noise threshold, 
%                TOF is set to zero
%   plotRow    : Row of A-scan plot
%   plotCol    : Column of A-scan plot
%   plotTOF    : Plots TOF image
%   plotAScan  : Plots A-scan for specified row, column location on plate
%   saveMat    : Saves TOF as .mat file
%   saveFig    : Saves plotted figures

tic;

% Find row, column, and data points info from C-scan
[row, col, dataPointsPerAScan] = size(cScan);

% Use basic gating procedure similar to UTWin
firstPeak = zeros(row,col);
secondPeak = firstPeak;

tEnd = (dataPointsPerAScan-1)*dt;
t = 0:dt:tEnd;

% Search for rectangular bounding box of damage

% Search through horizontal centerline
horCent = floor(row/2);
vertCent = floor(col/2);
horCentTOF = zeros(1,vertCent);

% From center of left edge
for i = 1:vertCent
    rowSlice = squeeze(cScan(horCent,i,:))';
    % Find and save peaks/locations in signal
    [p, l] = findpeaks(rowSlice,t);
    % Manually add 0 point to peaks list in case signal is cut off on
    % left side
    p = [0 p];
    l = [0 l];

    % Find and save locations of peaks in previously found peaks
    [~, loc,~] = findpeaks(p,l,'MinPeakProminence',0.09,...
        'WidthReference','halfheight');
    horCentTOF(i) = loc(2) - loc(1);
    if (mode(horCentTOF(1:i)) - horCentTOF(i)) >= 0.3
        startCol = i-10;
        break
    end
end

% From center of right edge
horCentTOF = zeros(1,vertCent);

for i = col:-1:vertCent+1
    rowSlice = squeeze(cScan(horCent,i,:))';

    % Check if mean signal value is above noise threshold
        if mean(rowSlice) > noiseThresh        
            % Find neighboring values that are within 0.01 magnitude and set equal
            for k = 1:length(rowSlice)-1
                if abs(rowSlice(1,k+1)-rowSlice(1,k))<0.01
                    rowSlice(1,k+1) = rowSlice(1,k);
                end
            end
            
            % Find and save peaks/locations in signal
            [p, l] = findpeaks(rowSlice,t);
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
            if mean(p(k:k+2)) >= 0.97
                p(k:k+4) = 1;
            end

            % Find and save locations of peaks in previously found peaks
            [peak, loc,width] = findpeaks(p,l,'MinPeakProminence',0.09,...
                'WidthReference','halfheight');
            if length(loc) >= 2
                k = find(l==loc(1));
                if width(1) > 0.7 && mean(p(k:k+4)) >= 0.97 && peak(2) < 0.98
                    tempFirstPeak = 1;
                    tempsecondPeak = 1;
                else
                    tempFirstPeak = loc(1);
                    tempsecondPeak = loc(2);
                end
            else
                tempFirstPeak = 1;
                tempsecondPeak = 1;
            end
        else
            tempFirstPeak = 1;
            tempsecondPeak = 1;
        end

    horCentTOF(i) = tempsecondPeak - tempFirstPeak;
    if (mode(horCentTOF(col:-1:i)) - horCentTOF(i)) >= 0.3
        endCol = i+10;
        break
    end
end

% Step through each A-scan to calculate time of flight (TOF)
for i = startRow:endRow
    for j = startCol:endCol
        aScan = squeeze(cScan(i,j,:))';

        % Check if mean signal value is above noise threshold
        if mean(aScan) > noiseThresh        
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
            if mean(p(k:k+2)) >= 0.97
                p(k:k+4) = 1;
            end

            % Find and save locations of peaks in previously found peaks
            [peak, loc,width] = findpeaks(p,l,'MinPeakProminence',0.09,...
                'WidthReference','halfheight');
            if length(loc) >= 2
                k = find(l==loc(1));
                if width(1) > 0.7 && mean(p(k:k+4)) >= 0.97 && peak(2) < 0.98
                    firstPeak(i,j) = 1;
                    secondPeak(i,j) = 1;
                else
                    firstPeak(i,j) = loc(1);
                    secondPeak(i,j) = loc(2);
                end
            else

                firstPeak(i,j) = 1;
                secondPeak(i,j) = 1;
            end
        else
            firstPeak(i,j) = 1;
            secondPeak(i,j) = 1;
        end
    end
end

% Calculate raw TOF
rawTOF = secondPeak - firstPeak;

% Find baseline TOF for undamaged plate
baseTOF = mode(rawTOF,'all');
rawTOF(abs(rawTOF-baseTOF)<2*dt) = baseTOF;

% Reshape and normalize raw TOF by max TOF
TOF = (1/max(rawTOF,[],'all')) .* rawTOF;

% Save TOF to .mat file
if saveMat == true
    save(outFile,'TOF','-mat');
end

sampleName = inFile{1}(8:end-10);

% Plot TOF
if plotTOF == true && saveFig == false
    figure('visible','on');
    imshow(TOF,'XData',[vertScale 0]);
    title(strcat("TOF ",sampleName));
elseif plotTOF == true && saveFig == true
    figure('visible','off');
    imshow(TOF,'XData',[vertScale 0]);
    title(strcat("TOF ",sampleName));
    ax = gca;
    exportgraphics(ax,strcat('Figures\',sampleName,'.png'),'Resolution',300);
end

toc;

% Plot A-scan for max value of signal
if plotAScan == true
    titleStr = strcat("A-scan at row ",num2str(plotRow)," column ",num2str(plotCol));

    figure("Name",titleStr);
    plot(t,abs(cScan(plotRow,plotCol,:)));

    title(titleStr);
    xlabel("Time [us]");
    ylabel("Amplitude");
    xlim([0,tEnd]);
end

end





