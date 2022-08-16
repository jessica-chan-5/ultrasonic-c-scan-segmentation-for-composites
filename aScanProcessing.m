function [TOF, baseTOF] = aScanProcessing(cScan,inFile,outFile,dt,vertScale, ...
    noiseThresh, cropDam, plotRow,plotCol,plotTOF,plotAScan,saveMat,saveFig)
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
TOF = zeros(row,col);

tEnd = (dataPointsPerAScan-1)*dt;
t = 0:dt:tEnd;

scaleRatio = col/vertScale;

if cropDam == true
    % Search for rectangular bounding box of damage
    cropThresh = 0.2;
    padExtra = 1.25;
    
    % Calculate spacing
    numPts = 10;
    vertSpace = floor(min(row,vertScale)/numPts);
    horSpace = vertSpace*scaleRatio;
    yNoiseSpace = 50;
    xNoiseSpace = 15;

    % Calculate horizontal and vertical indices
    top2bot = yNoiseSpace:vertSpace:row-vertSpace;
    halfVert = floor(length(top2bot)/2);
    top2cent = top2bot(1:halfVert);
    bot2cent = top2bot(end:-1:halfVert+1);

    left2right = xNoiseSpace:horSpace:col-horSpace;
    halfHor = floor(length(left2right)/2);
    left2cent = left2right(1:halfHor);
    right2cent = left2right(end:-1:halfHor+1);
    
    % Calculate baseline TOF
    baseRows = 50:5:60;
    baseCols = 10:2:14;
    tempTOF = zeros(length(baseRows),length(baseCols));

    for i = 1:length(baseRows)
        for j = 1:length(baseCols)
            point = squeeze(cScan(baseRows(i),baseCols(j),:))';
            tempTOF(i,j) = calcTOF(point,noiseThresh,t);
        end
    end

    baseTOF = mode(tempTOF(tempTOF~=0),'all');

    % From top to center
    startRow = cropEdgeDetect(baseTOF,top2cent,left2right,cScan,noiseThresh,t,cropThresh,0);
    % From bottom to center
    endRow = cropEdgeDetect(baseTOF,bot2cent,left2right,cScan,noiseThresh,t,cropThresh,0);
    
    % Set rows to search
    startRowI = find(top2bot==startRow);
    endRowI = find(top2bot==endRow);
    searchRows = top2bot(startRowI:endRowI);
    
    % Add padding
    vertPad = floor(vertSpace*padExtra);
    startRow = startRow - vertPad;
    endRow = endRow + vertPad;

    if startRow <= 0
        startRow = 2;
    end
    if endRow > row
        endRow = row-1;
    end

    % From left to center
    startCol = cropEdgeDetect(baseTOF,left2cent,searchRows,cScan,noiseThresh,t,cropThresh,1);
    % From right to center
    endCol = cropEdgeDetect(baseTOF,right2cent,searchRows,cScan,noiseThresh,t,cropThresh,1);

    % Add padding
    horPad = floor(horSpace*padExtra);
    startCol = startCol - horPad;
    endCol = endCol + horPad;

    if startCol <= 0
        startCol = 2;
    end
    if endCol > col
        endCol = col-1;
    end

else
    startCol = 2;
    endCol   = col-1;
    startRow = 2;
    endRow   = row-1;
end

% Step through each A-scan to calculate time of flight (TOF)
for i = startRow:endRow
    for j = startCol:endCol
        aScan = squeeze(cScan(i,j,:))';
        TOF(i,j) = calcTOF(aScan,noiseThresh,t);
    end
end

if cropDam == true
    % Fill in area outside of crop with TOF = 1 (white)
    TOF = fillArea([1:col, 1:startCol-1, endCol+1:col, 1:col],...
        [1:startRow-1,endRow+1:row],0,TOF);
    TOF = fillArea([1:startCol-1, endCol+1:col],startRow-1:endRow+1,0,TOF);
    
%     % Black vertical and horizontal outlines
%     TOF = fillArea([1:scaleRatio, col-scaleRatio+1:col],1:row,0,TOF);
%     TOF = fillArea(1:col,[1, row],0,TOF);
end

% Save TOF to .mat file
if saveMat == true
    save(outFile,'TOF','-mat');
end

sampleName = inFile{1}(8:end-10);

% Plot TOF
TOFplot = (1/max(TOF,[],'all')) .* TOF;

if plotTOF == true && saveFig == false
    figure('visible','on');
    imshow(TOFplot,'XData',[vertScale 0]);
    title(strcat("TOF ",sampleName));
elseif plotTOF == true && saveFig == true
    figure('visible','off');
    imshow(TOFplot,'XData',[vertScale 0]);
    title(strcat("TOF ",sampleName));
    ax = gca;
    exportgraphics(ax,strcat('Figures\',sampleName,'.png'),'Resolution',300);
end

% Plot A-scan for max value of signal
if plotAScan == true
    titleStr = strcat("A-scan at row ",num2str(plotRow)," column ",num2str(plotCol));

    figure("Name",titleStr);
    plot(t,abs(cScan(plotRow,plotCol,:)));

    title(titleStr);
    xlabel("Time [us]");
    ylabel("Amplitude");
    xlim([0,tEnd]);

    figure('visible','on');
    imshow(TOF,'XData',[vertScale 0]);
    title(strcat("TOF ",sampleName));
end

toc;
disp(sampleName);
disp('test');

end





