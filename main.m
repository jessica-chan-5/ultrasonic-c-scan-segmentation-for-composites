%% i. Clear workspace
close all; clearvars; format compact;
%% ii. File names
panel = ["BL","CONT","RPR"];    m = length(panel);
impact = ["10","15","20"];      n = length(impact);
fileNames = strings([n*m*2,1]); count = 0;
for i = 1:n
    for j = 1:m
        count = count + 1;
        fileNames(count) = strcat(panel(j),"-S-",impact(i),"J-2");
        fileNames(count+n*m) = strcat(panel(j),"-S-",impact(i),"J-2-back");
    end
end
fileNames = ["BL-H-15J-1";"CONT-H-10J-2";"CONT-H-10J-3";"CONT-H-20J-1";
"CONT-H-20J-2";"CONT-H-20J-3";"RPR-H-20J-2";"RPR-H-20J-3"; fileNames];
numFiles = length(fileNames);
%% iii. Function options
%   Run function?   |  Indices of files to read?   |  Shows figures if true
% readcscan
runRead    = false;    filesRead    = 1:numFiles;
% processcscan
runProcess = false;    filesProcess = 1:numFiles;     testProcess = false;
% segcscan
runSeg     = false;    filesSeg     = 1:numFiles;     testSeg     = true;
% plottest
runTest    = false;    filesTest    = 1;
% plotfig
runFig     = false;    filesFig     = 1:numFiles;
% mergecscan
runMerge   = false;    filesMerge   = 9:17;           testMerge   = false;
% plotcustom
runCustom  = true;    filesCustom  = 1:numFiles;     testCustom  = false;
%% A. readcscan inputs
inFolder   = "Input";  % Folder location for input files
outFolder  = "Output"; % Folder location for output files
delim      = "   ";    % Field delimiter character
dRow       = 1;        % # rows to down sample
dCol       = 5;        % # col  to down sample
%% B. processcscan inputs -------------------------------------------------
figFolder  = "Figures";% Folder path to .fig and .png files
dt         = 1/50;     % Sampling period in microseconds
bounds     = [30 217 30 350]; % Indices of search area for bounding box
                              % in format: [startX endX startY endY]
incr       = 10;       % Increment for bounding box search in indices
baseRow    = 50:5:60;  % Row indices across which to calculate baseline TOF
baseCol    = 10:5:20;  % Col indices across which to calculate baseline TOF
cropThresh = 0.2;      % If diff between baseline TOF and TOF at a point is 
                       % greater than cropThresh, then the point is damaged
pad        = 1;        % (1+pad)*incr added to all sides of bounding box
minProm1   = 0.03;     % Min prominence for a peak to be identified
noiseThresh= 0.01;     % If the average signal at a point is lower than 
                       % noiseThresh, then the point is ignored
maxWidth   = 0.75;     % If a peak's width is greater, then noted as wide
calcT1     = false;    % If true, calculates and plots time of first peak 
res        = 300;      % Image resolution setting in dpi for saving image
%% C. segcscan inputs -----------------------------------------------------
fontSize   = 16;
minProm2   = 0.013;%Min prominence in findpeaks for a peak to be identified
peakThresh = 0.04; % If the difference between the time a peak appears in 
                   % the first point and the time the same peak appears in 
                   % the next point is greater than peakThresh, label as
                   % new peak
% MODETHRESH:        If difference between TOF at current point and mode 
                   % TOF of the area the current point belongs to is less 
                   % than modeThresh, set TOF at current point to mode TOF
hig = 0.25; med = 0.14; low = 0.06;
modeThresh = [hig; hig; hig; med; hig;       %  1- 5 
              low; hig; hig; med; hig;       %  6-10
              hig; med; med; low; low;       % 11-15
              med; med; hig; hig; hig;       % 16-20
              hig; hig; hig; med; med; low]; % 21-26
% SEEL:              Vector in the form: 
                   % [length45 lengthNeg45 length90 length0]
                   % indicating length of structuring element for 
                   % morphological closing of gaps if needed
seEl       = [0 0 0 0; 0 0 0 0; 0 0 0 0; 0 0 0 0; 0 0 0 0; % 1-5
              0 0 0 0; 0 0 0 0; 0 0 0 0; 0 0 0 0; 0 0 0 0; % 6-10
              0 0 0 0; 0 0 0 0; 0 0 0 0; 0 0 0 0; 0 0 0 0; % 11-15
              0 3 0 0; 0 0 0 4; 0 6 0 0; 0 0 0 0; 0 0 0 0; % 16-20
              0 0 0 0; 0 0 0 0; 6 0 0 0; 0 0 0 0; 0 0 0 0; 0 3 0 0];% 21-26
%% D. plottest inputs -----------------------------------------------------
rowRange = 171:172; % y
colRange = 115:116; % x
dir = 'row';
num = 171;
%% E. plotfig inputs ------------------------------------------------------
plateThick  = 3.3;% Thickness of scanned plate in millimeters
nLayers = 25;     % Number of layers in scanned plate
%% F. mergecscan inputs ---------------------------------------------------
di = 8;% File index offset
% DX: Amount to move front side scan relative to back horizontally
%     (+) = right, (-) = left
dx = [-3; 8;            % 9-10
      -4; 7;14; 4; 5;   % 11-15
       6; 9];           % 16-17
% DY: Amount to move front side scan relative to back vertically
%     (+) = up, (-) = down
dyMergeCscan = [2; 0;  % 9-10
                2;-1;-5; -2;  0; % 11-15
                1; 1];           % 16-17
%% G. plotcustom inputs ---------------------------------------------------
% UTWINCROP: Indices to crop UTWin screenshot in format:
%               [startRow endRow startCol endCol]
startRowUT = 22;
endRowUT = 617;
startColUT = 98;
endColUT = 477;
utwinCrop = [startRowUT endRowUT startColUT endColUT];
% DY       : Amount to adjust UTWin screenshots (+) = up, (-) = down
dyPlotCustom = [26; 12; -5; 70; 73;      %  1- 5 
                25; 25; 72;-18; -5;      %  6-10
                10; -5; 28; 58; 40;      % 11-15
                -2; -2; -5; -2; 10;      % 16-20
                -7; -5; 55; 43; -5; 10]; % 21-26
%% 1. Convert C-scan from .csv to .mat file
if runRead == true
tic; fprintf("READCSCAN Convert C-scan from .csv to .mat file for:\n");
parfor i = filesRead
    disp(strcat(num2str(i),'.',fileNames(i)));
    readcscan(fileNames(i),inFolder,outFolder,delim,dRow,dCol);
end
fprintf("\nFinished! Elapsed time is:"); sec = toc; disp(duration(0,0,sec))
end
%% 2. Process C-scans to calculate TOF
if runProcess == true
tic; fprintf("\nPROCESSCSCAN Process C-scans to calculate TOF for:\n");
parfor i = filesProcess
    disp(strcat(num2str(i),'.',fileNames(i)));
    processcscan(fileNames(i),outFolder,figFolder,dt,bounds,incr, ...
        baseRow,baseCol,cropThresh,pad,minProm1,noiseThresh,maxWidth, ...
        calcT1,testProcess,res);
end
fprintf("\nFinished! Elapsed time is:"); sec = toc; disp(duration(0,0,sec))
end
%% 3. Segment C-Scan
if runSeg == true
tic; fprintf("\nSEGCSCAN Segment C-scan for:\n");
parfor i = filesSeg
    disp(strcat(num2str(i),'.',fileNames(i)));
    segcscan(fileNames(i),outFolder,figFolder,minProm2,peakThresh, ...
        modeThresh(i),seEl(i,:),testSeg,fontSize,res);
end
fprintf("\nFinished! Elapsed time is:"); sec = toc; disp(duration(0,0,sec))
end
%% 4. Plot test figures
if runTest == true
tic; fprintf("\nPLOTTEST Plot test figures for:\n")
for i = filesTest
    disp(strcat(num2str(i),'.',fileNames(i)));
    [row, col] = plotascans(fileNames(i),outFolder,rowRange,colRange,dt,...
        minProm1,noiseThresh);
    plotpeak2(fileNames(i),outFolder,dir,num,row,col,minProm2);
end
fprintf("\nFinished! Elapsed time is:"); sec = toc; disp(duration(0,0,sec))
end
%% 5. Plot figures
if runFig == true
tic; fprintf("\nPLOTFIG Plot figures for:\n");
parfor i = filesFig
    disp(strcat(num2str(i),'.',fileNames(i)));
    plotfig(fileNames(i),outFolder,figFolder,plateThick,fontSize,res);
end
fprintf("\nFinished! Elapsed time is:"); sec = toc; disp(duration(0,0,sec))
end
%% 6. Merge C-scans
if runMerge == true
tic; fprintf("\nMERGECSCAN Merge C-scans for:\n");
parfor i = filesMerge
    disp(strcat(num2str(i),'.',fileNames(i)));
    mergecscan(fileNames(i),outFolder,figFolder,dx(i-di),...
        dyMergeCscan(i-di),testMerge,fontSize,res);
end
fprintf("\nFinished! Elapsed time is:"); sec = toc; disp(duration(0,0,sec))
end
%% 7. Make custom plots
if runCustom == true
tic; fprintf("\nPLOTCUSTOM Plot custom figures for:\n");
parfor i = filesCustom
    disp(strcat(num2str(i),'.',fileNames(i)));
    plotcustom(fileNames(i),inFolder,outFolder,figFolder,utwinCrop, ...
        dyPlotCustom(i),plateThick ...
        ,testCustom,fontSize,res);
end
fprintf("\nFinished! Elapsed time is:"); sec = toc; disp(duration(0,0,sec))
end