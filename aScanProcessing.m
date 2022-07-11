function TOF = aScanProcessing(cScan,inFile,outFile,dt,vertScale, ...
    noiseThresh,plotRow,plotCol,plotTOF,plotAScan,saveMat,saveFig)
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
    [tempFirstPeak, tempSecondPeak] = calcTOF(rowSlice,noiseThresh,t);
    horCentTOF(i) = tempSecondPeak - tempFirstPeak;

    if (mode(horCentTOF(1:i)) - horCentTOF(i)) >= 0.3
        startCol = i-10;
        break
    end
end

% From center of right edge
horCentTOF = zeros(1,vertCent);

for i = col:-1:vertCent+1
    rowSlice = squeeze(cScan(horCent,i,:))';
    [tempFirstPeak, tempSecondPeak] = calcTOF(rowSlice,noiseThresh,t);
    horCentTOF(i) = tempSecondPeak - tempFirstPeak;

    if (mode(horCentTOF(col:-1:i)) - horCentTOF(i)) >= 0.3
        endCol = i+10;
        break
    end
end

% Search through vertical centerline
vertCentTOF = zeros(1,horCent);

% From center of top edge
for i = 1:horCent
    rowSlice = squeeze(cScan(i,vertCent,:))';
    [tempFirstPeak, tempSecondPeak] = calcTOF(rowSlice,noiseThresh,t);
    vertCentTOF(i) = tempSecondPeak - tempFirstPeak;

    if (mode(vertCentTOF(1:i)) - vertCentTOF(i)) >= 0.3
        startRow = i-10;
        break
    end
end

% From center of bottom edge
vertCentTOF = zeros(1,horCent);

for i = row:-1:horCent+1
    rowSlice = squeeze(cScan(i,vertCent,:))';
    [tempFirstPeak, tempSecondPeak] = calcTOF(rowSlice,noiseThresh,t);
    vertCentTOF(i) = tempSecondPeak - tempFirstPeak;

    if (mode(vertCentTOF(row:-1:i)) - vertCentTOF(i)) >= 0.3
        endRow = i+10;
        break
    end
end

% Step through each A-scan to calculate time of flight (TOF)
for i = startRow:endRow
    for j = startCol:endCol
        aScan = squeeze(cScan(i,j,:))';
        [firstPeak(i,j), secondPeak(i,j)] = calcTOF(aScan,noiseThresh,t);
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





