%% Clear workspace
close all; clearvars; format compact;

%% C-scan .csv file names

panelType = ["BL","CONT","RPR"];
impactEnergy = ["10","15","20"];
n = length(impactEnergy);
m = length(panelType);
filenames = strings([n*m*2,1]);
count = 0;
for i = 1:n
    for j = 1:m
        count = count + 1;
        filenames(count) = strcat(panelType(j),"-S-",...
            impactEnergy(i),"J-2");
        filenames(count+n*m) = strcat(panelType(j),"-S-",...
            impactEnergy(i),"J-2-back");
    end
end
miscFileNames = ["BL-H-15J-1";
                 "CONT-H-10J-2";"CONT-H-10J-3";
                 "CONT-H-20J-1";"CONT-H-20J-2";"CONT-H-20J-3";
                  "RPR-H-20J-2";"RPR-H-20J-3"];
filenames = [miscFileNames; filenames];
numFiles = length(filenames);

%% Function inputs

% READCSCAN options =======================================================
runcscan   = false;      % Run readcscan?
cscanfiles = 1;%:numFiles; % Indices of files to read
% READCSCAN inputs --------------------------------------------------------
delim      = "   ";      % Field delimiter characters (i.e. "," or " ")
infolder   = "Input";    % Folder location of .csv C-scan input file
outfolder  = "Output";   % Folder to write .mat C-scan output file
drow       = 1;          % # rows to down sample
dcol       = 5;          % # col to down sample
% END READCSCAN____________________________________________________________

% PROCESSASCAN options ====================================================
runascan   = true;       % Run processascan?
ascanfiles = 5;%1:numFiles; % Indices of files to read
% PROCESSASCAN inputs -----------------------------------------------------
figfolder  = "Figures";% Folder path to .fig and .png files
dt          = 1/50;    % Sampling period in microseconds
bounds      = [30 239 30 385];   % Indices of search area for bounding box
                                 % in format: [startX endX startY endY]
incr        = 10;      % Increment for bounding box search in indices
baserow     = 50:5:60; % Vector of row indices to calculate baseline TOF
basecol     = 10:5:20; % Vector of cols indices to calculate baseline TOF
cropthresh  = 0.2;     % If abs(basetof-tof(i)) > cropthresh, pt is damaged
pad         = 0.5;     % (1+pad)*incr added to calculated bounding box
minprom     = 0.03;    % Min prominence for a peak to be identified
noisethresh = 0.01;    % If average signal lower, then pt is not processed
maxwidth    = 0.75;    % Max width for a peak to be marked as wide
% END PROCESSASCAN ________________________________________________________

% Plate properties
numLayers    = 25;    % # of layers in plate
plateThick   = 3.3;   % plate thickness [mm]

%% Read C-scans from .csv file(s)
% Note: parfor results in file processing to complete out of order

if runcscan == true
tic
fprintf("READCSCAN======================================\n\n")
fprintf("Converting C-scans from .csv to .mat files for:\n\n");
parfor i = cscanfiles
    disp(strcat(num2str(i),'.',filenames(i)));
    readcscan(filenames(i),delim,infolder,outfolder,drow,dcol);
end
fprintf("\nFinished converting all C-scan .csv files!\n\n")
sec = toc;
disp('Elapsed time is:')
disp(duration(0,0,sec))
end
%% Spline fit A-scans & calculate raw TOF

if runascan == true
tic
fprintf("================================================\n\n")
fprintf("Processing A-scans and converted to raw TOF for:\n\n");
for i = ascanfiles
    disp(strcat(num2str(i),'.',filenames(i)));
    processascan(filenames(i),outfolder,figfolder,dt,bounds,incr,baserow, ...
    basecol,cropthresh,pad,minprom,noisethresh,maxwidth)
end
fprintf("\nFinished processing all C-scan .mat files.\n\n")
fprintf("\nFinished converting all C-scan .csv files!\n\n")
sec = toc;
disp('Elapsed time is:')
disp(duration(0,0,sec))
end

%{
%% Process TOF

%{
fprintf("==============================================\n\n")
fprintf("Processed TOF for:\n\n");

% TOF = cell(numFiles,1);
inflectionpts = cell(numFiles,1);
hi = 0.25;
md = 0.14;
lo = 0.06;
modeThresh = [hi % 1
              hi % 2
              hi % 3
              hi % 4 
              hi % 5
              md % 6
              hi % 7
              hi % 8
              md % 9
              hi % 10
              hi % 11
              md % 12
              lo % 13
              lo % 14
              lo % 15
              md % 16
              md % 17
              hi % 18
              hi % 19
              hi % 20
              hi % 21
              hi % 22
              hi % 23
              md % 24
              md % 25
              hi]; % 26
% for i = 1:numFiles
for i = [4, 8]
    tic;
    [~,inflectionpts{i}] = aScanLayers(fileNames(i),outfolder,dataPtsPerAScan,saveTOF,saveInflectionPts,modeThresh(i));
    disp(fileNames(i));
    toc
end

fprintf("\nFinished processing all C-scan .mat files.\n\n")
%}

%% Segment TOF

%{
fprintf("==============================================\n\n")
fprintf("Segmented TOF for:\n\n")

for i = 1:length(fileNames)
    tic;
    aScanSegmentation();

    disp(fileNames(i));
    toc
end

fprintf("\nFinished segmenting all TOF.\n\n")
fprintf("==============================================\n\n")
%}

%% Combine front and back to create hybrid C-scans

%% Plot 3D and layer by layer
%}