function aScanProcessing(cScan,inFile,outFile,dt,vertScale,noiseThresh,plotRow,plotCol,plotTOF,plotAScan,saveMat,saveFig)
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

% Use basic gating procedure similar to UTWin
firstPeak = zeros(numAScans,1);
secondPeak = firstPeak;

tEnd = (dataPointsPerAScan-1)*dt;
t = 0:dt:tEnd;

% Step through each A-scan to calculate time of flight (TOF)
for i = 1:numAScans

    % Check if mean signal value is above noise threshold
    if mean(cScan(i,:)) > noiseThresh
        % Find neighboring values that are within 0.01 magnitude and set equal
        for j = 1:length(cScan(i,:))-1
            if abs(cScan(i,j+1)-cScan(i,j))<0.01
                cScan(i,j+1) = cScan(i,j);
            end
        end

        % Find and save peaks/locations in signal
        [p, l] = findpeaks(cScan(i,:),t);
        % Manually add 0 point to peaks list in case signal is cut off on
        % left side
        p = [0 p];
        l = [0 l];

        % Find neighboring peaks that are within 0.05 magnitude and set equal
        for j = 1:length(p)-1
            if abs(p(j+1)-p(j))<0.05
                p(j+1) = p(j);
            end
        end

        % Find and save locations of peaks in previously found peaks in
        % descending order
        [~, loc] = findpeaks(p,l,'SortStr','descend');
        if length(loc) >= 2
            firstPeak(i) = loc(1);
            secondPeak(i) = loc(2);
        else
            firstPeak(i) = 1;
            secondPeak(i) = 1;
        end
    % Set TOF = 0 if mean signal value is below noise threshold
    else
        firstPeak(i) = 1;
        secondPeak(i) = 1;
    end
end

% Calculate raw TOF
rawTOF = secondPeak - firstPeak;

% Find baseline TOF for undamaged plate
baseTOF = mode(rawTOF,'all');
rawTOF(abs(rawTOF-baseTOF)<7*dt) = baseTOF;

% Reshape and normalize raw TOF by max TOF
TOF = abs((1/max(rawTOF)) .* reshape(rawTOF',col,row)');

% Merge adjacent transition sections
for i = 1:row
    for j = 1:col-1
        if abs(TOF(i,j+1)-TOF(i,j))<0.1 
            TOF(i,j+1) = TOF(i,j);
        end
    end
end

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

% Plot A-scan for max value of signal
if plotAScan == true
    titleStr = strcat("A-scan at row ",num2str(plotRow)," column ",num2str(plotCol));

    figure("Name",titleStr);
    plot(t,abs(cScan(plotRow*plotCol,3:end)));

    title(titleStr);
    xlabel("Time [us]");
    ylabel("Amplitude");
    xlim([0,tEnd]);
end

end





