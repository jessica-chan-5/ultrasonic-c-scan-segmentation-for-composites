function [rawTOF,fits,cropCoord] = ...
aScanProcessing(fileName,outFolder,dt,scaleVal,scaleDir,searchArea,cropIncr, ...
baseRow,baseCol,cropThresh,padExtra,saveOutput)
% Take .csv C-scan input file, calculate fits andraw TOF, and saves raw TOF
% and fits data as .mat files if requested
% 
% Inputs:
%   fileName   : Name of .csv C-scan input file
%   outFile    : Folder path to .mat C-scan output file
%   dt         : Sampling period [us]
%   scaleVal   : Scaling factor for TOF plot
%   scaleDir   : Scaling direction for TOF plot, 'row','col', or 'none'
%   startI     : Starting searching for crop edges at this index
%   cropIncr   : Scaling factor for TOF plot
%   baseRow    : Vector of rows to calculate baseline TOF
%   baseCol    : Vector of cols to calculate baseline TOF
%   cropThresh : Crop threshold greater than abs(baseTOF - tof(i))
%   padExtra   : Amount of extra row/col to add to crop boundaries
%   saveMat    : Saves TOF as .mat file
%   saveFits  : Save fits as .mat file

% Concatenate file names/paths
inFile = strcat(outFolder,"\",fileName,'-cScan.mat');
outFileRawTOF = strcat(outFolder,"\",fileName,'-raw-TOF.mat');
outFileFits = strcat(outFolder,'\',fileName,'-fits.mat');

% Load cScan
load(inFile,'cScan');

% Find # of data points per A-scan, rows, and columns
[row, col, dataPtsPerAScan] = size(cScan);

% Create time vector
tEnd = (dataPtsPerAScan-1)*dt;
t = 0:dt:tEnd;

% Calculate scaling ratios
if strcmp('col',scaleDir) == true ...       % resolution along col > row
    || (strcmp('none',scaleDir) == true ... % resolution along col = row
    && col >= row)                          % # of points along col >= row
    vertIncr = floor(row/cropIncr);
    horIncr = vertIncr*scaleVal;
elseif strcmp('row',scaleDir) == true ...   % resolution along col < row
    || (strcmp('none',scaleDir) == true ... % resolution along col = row
    && col < row)                           % # of points along col < row      
    horIncr = floor(col/cropIncr);
    vertIncr = horIncr*scaleVal;
end

searchArea = max(searchArea,[horIncr vertIncr; horIncr vertIncr]);
xStartI = searchArea(1,1);
yStartI = searchArea(1,2);
xEndI = searchArea(2,1);
yEndI = searchArea(2,2);

% Search for rectangular bounding box of damage

% Calculate horizontal and vertical indices
top2bot = yStartI:vertIncr:row-yEndI;
halfVert = floor(length(top2bot)/2);
top2cent = top2bot(1:halfVert);
bot2cent = top2bot(end:-1:halfVert+1);

left2right = xStartI:horIncr:col-xEndI;
halfHor = floor(length(left2right)/2);
left2cent = left2right(1:halfHor);
right2cent = left2right(end:-1:halfHor+1);

% Calculate baseline TOF
tempTOF = calcTOF(cScan,t,baseRow,baseCol);
baseTOF = mode(tempTOF,'all');

% Search for start row moving from top most to center row
startRow = cropEdge(baseTOF,top2cent,left2right,cScan,t,cropThresh,'row');
% Search for end row moving from bottom most to center row
endRow = cropEdge(baseTOF,bot2cent,left2right,cScan,t,cropThresh,'row');

% Set row indices to search
startRowI = find(top2bot==startRow);
endRowI = find(top2bot==endRow);
searchRows = top2bot(startRowI:endRowI);

% Add padding in vertical direction
vertPad = floor((1+padExtra)*vertIncr);
startRow = startRow - vertPad;
endRow = endRow + vertPad;
if startRow <=0
    startRow = 1;
end
if endRow > row
    endRow = row;
end

% From left to center
startCol = cropEdge(baseTOF,left2cent,searchRows,cScan,t,cropThresh,'col');
% From right to center
endCol = cropEdge(baseTOF,right2cent,searchRows,cScan,t,cropThresh,'col');

% Add padding in horizontal direction
horPad = floor((1+padExtra)*horIncr);
startCol = startCol - horPad;
endCol = endCol + horPad;
if startCol <= 0
    startCol = 1;
end
if endCol > col 
    endCol = col;
end

% Step through cropped C-scan to calculate raw TOF
if saveFits == false
    [rawCropTOF, ~] = calcTOF(cScan,t,startRow:endRow,startCol:endCol);
else
    [rawCropTOF, fits] = calcTOF(cScan,t,startRow:endRow,startCol:endCol);
end

% Calculate updated baseline TOF and fill in cropped areas w/ baseline TOF
% baseTOF = mode(rawCropTOF,'all');
% rawTOF = ones(row,col)*baseTOF;
rawTOF = zeros(row,col);
rawTOF(startRow:endRow,startCol:endCol) = rawCropTOF(1:end,1:end);

% Save raw TOF and spline fits
if saveOutput == true
    save(outFileRawTOF,'rawTOF','-mat');
    save(outFileFits,'fits','-mat');
end

cropCoord = [startRow startCol; endRow, endCol];

end





