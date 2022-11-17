function [TOF, baseTOF] = aScanProcessing(outFolder,fileName,dt,vertScale, ...
    cropThresh, padExtra, noiseThresh, saveMat)
% Take .csv C-scan input file, calculate time of flight (TOF), and save
% normalized TOF data as .mat file
% 
% Inputs:
%   outFile:   Folder path to .mat C-scan output file
%   fileName:  Name of .csv C-scan input file
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

% Concatenate file names/paths
inFile = strcat(outFolder,"\",fileName,'-cScan.mat');
outFile = strcat(outFolder,"\",fileName,'-TOF.mat');

% Load cScan
load(inFile);

% Find row, column, and data points info from C-scan
[row, col, dataPointsPerAScan] = size(cScan);

% Create time vector
tEnd = (dataPointsPerAScan-1)*dt;
t = 0:dt:tEnd;

% Calculate vertical scale ratio
scaleRatio = col/vertScale;

% Search for rectangular bounding box of damage
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

[tempTOF, ~] = calcTOF(cScan,t,baseRows,baseCols);
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

% Step through each A-scan to calculate time of flight (TOF)
[cropTOF, inflectPt] = calcTOF(cScan,t,startRow:endRow,startCol:endCol+1);
baseTOF = mode(cropTOF,"all");

TOF = zeros(row,col);
TOF(startRow:endRow,startCol:endCol) = cropTOF(1:end,1:end-1);

% Fill in area outside of crop with TOF = 0 (black)
TOF = fillArea([1:col, 1:startCol-1, endCol+1:col, 1:col],...
    [1:startRow-1,endRow+1:row],0,TOF);
TOF = fillArea([1:startCol-1, endCol+1:col],startRow-1:endRow+1,0,TOF);

%     % Black vertical and horizontal outlines
%     TOF = fillArea([1:scaleRatio, col-scaleRatio+1:col],1:row,0,TOF);
%     TOF = fillArea(1:col,[1, row],0,TOF);

% Save TOF to .mat file
if saveMat == true
    save(outFile,'TOF','-mat');
end

% Remove outliers
for i = 2:size(TOF,1)-1
    for j = 2:size(TOF,2)-1
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
        
        freqTab = tabulate([TL,TMj,TR,MiL,MiR,BL,BMj,BR]);

        if freqTab(1,2) >= 8
            TOF(i,j) = freqTab(1,1);
        end
    end
end

end





