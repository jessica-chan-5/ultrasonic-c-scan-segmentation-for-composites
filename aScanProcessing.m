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
%

% Calculate # of A-scans and # of data points per A-scan
[numAScans, dataPointsPerAScan] = size(cScan);

% Calculate number of scans along x (row) and y (col) scan directions
% Add 1 for x and 2 for y because the last line begins with (row,col)
col = cScan(end,2) + 1;
row = cScan(end,1) + 1;

% Take absolute value of signal
cScan = abs(cScan);

% Use basic gating procedure similar to UTWin
firstPeak = zeros(numAScans,1);
secondPeak = firstPeak;

tEnd = (dataPointsPerAScan-3)*dt;
t = 0:dt:tEnd;

% Step through each A-scan to calculate time of flight (TOF)
for i = 1%:numAScans
    % Check if mean signal value is above noise threshold
    if mean(cScan(i,3:end)) > noiseThresh
        % Find and save peaks/locations in signal
        [p, l] = findpeaks(cScan(i,3:end),t);
        % Manually add 0 point to peaks list in case signal is cut off on
        % left side
        p = [0 p];
        % Find and save locations of peaks in previously found peaks in
        % descending order
        [~, loc] = findpeaks(p,'SortStr','descend','MinPeakProminence',0.1);
        if length(loc) >= 2
            % Find locations of peaks
            firstPeak(i) = l(loc(1));
            secondPeak(i) = l(loc(2));
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

% Reshape and normalize raw TOF by max TOF
TOF = abs((1/max(rawTOF)) .* reshape(rawTOF',col,row)');

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

disp(strcat("Finished processing A-scans for ",sampleName));

end





