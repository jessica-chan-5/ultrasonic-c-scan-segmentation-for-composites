for i = 1:numFiles
    % Load file
    fileName = fileNames(i);
    % Plot raw TOF
    plottof(outFolder,figFolder,fileName);
    % Plot inflection points
    plotinflpt(outFolder,figFolder,fileName);
end

% Load file
fileName = fileNames(1);

% Plot A-scans
rowRange = 173:175; % y
colRange = 127:129; % x
[row, col] = plotAscans(rowRange,colRange,outFolder,fileName,dt, ...
    minProm1,noiseThresh);
% Plot peak2 magnitude
dir = 'row';
num = 189;
plotPeak2(peak2,dir,num,row,col,outFolder,fileName,minProm2)