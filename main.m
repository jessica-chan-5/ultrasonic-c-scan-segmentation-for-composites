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
cscanfiles = 1:numFiles; % Indices of files to read
% READCSCAN inputs --------------------------------------------------------
delim      = "   ";      % Field delimiter characters (i.e. "," or " ")
infolder   = "Input";    % Folder location of .csv C-scan input file
outfolder  = "Output";   % Folder to write .mat C-scan output file
drow       = 1;          % # rows to down sample
dcol       = 5;          % # col to down sample
% END READCSCAN____________________________________________________________

% PROCESSASCAN options ====================================================
runascan   = false;       % Run processascan?
ascanfiles = 1:numFiles; % Indices of files to read
% PROCESSASCAN inputs -----------------------------------------------------
figfolder  = "Figures";% Folder path to .fig and .png files
dt          = 1/50;    % Sampling period in microseconds
bounds      = [30 217 30 350];   % Indices of search area for bounding box
                                 % in format: [startX endX startY endY]
incr        = 10;      % Increment for bounding box search in indices
baserow     = 50:5:60; % Vector of row indices to calculate baseline TOF
basecol     = 10:5:20; % Vector of cols indices to calculate baseline TOF
cropthresh  = 0.2;     % If abs(basetof-tof(i)) > cropthresh, pt is damaged
pad         = 1;     % (1+pad)*incr added to calculated bounding box
minprom1    = 0.03;    % Min prominence for a peak to be identified
noisethresh = 0.01;    % If average signal lower, then pt is not processed
maxwidth    = 0.75;    % Max width for a peak to be marked as wide
% END PROCESSASCAN ________________________________________________________

% PROCESSTOF options ======================================================
runtof   = true;       % Run processtof?
toffiles = 1:numFiles; % Indices of files to read
% PROCESSTOF inputs -------------------------------------------------------
minprom2   = 0.013;
peakthresh = 0.04;
hi = 0.25;
md = 0.14;
lo = 0.06;
modethresh = [hi; hi; hi; hi; hi;      %  1- 5
              md; hi; hi; md; hi;      %  6-10
              hi; md; lo; lo; lo;      % 11-15
              md; md; hi; hi; hi;      % 16-20
              hi; hi; hi; md; md; hi]; % 21-26
% END PROCESSTOF __________________________________________________________

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
sec = toc;
fprintf('\nElapsed time is:')
disp(duration(0,0,sec))
fprintf("Finished converting all C-scan .csv files!\n\n")
end
%% Spline fit A-scans & calculate raw TOF

if runascan == true
tic
fprintf("PROCESSASCAN====================================\n\n")
fprintf("Processing A-scans and converted to raw TOF for:\n\n");
for i = ascanfiles
    disp(strcat(num2str(i),'.',filenames(i)));
    processascan(filenames(i),outfolder,figfolder,dt,bounds,incr, ...
        baserow,basecol,cropthresh,pad,minprom1,noisethresh,maxwidth)
end
sec = toc;
fprintf('\nElapsed time is:')
disp(duration(0,0,sec))
fprintf("Finished processing all C-scan .mat files!\n\n")
end

%% Process raw TOF
% Note: parfor results in file processing to complete out of order

if runtof == true
tic
fprintf("PROCESSTOF======================================\n\n")
fprintf("Processed raw TOF for:\n\n");
parfor i = 1:numFiles
    disp(strcat(num2str(i),'.',filenames(i)));
    processtof(filenames(i),outfolder,figfolder,minprom2,peakthresh, ...
        modethresh(i));
end
sec = toc;
fprintf('\nElapsed time is:')
disp(duration(0,0,sec))
fprintf("Finished processing all raw TOF.mat files!\n\n")
end

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
