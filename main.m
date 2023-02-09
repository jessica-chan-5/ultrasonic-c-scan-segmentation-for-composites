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
% #########################################################################

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
res         = 300;     % Image resolution setting in dpi
% END PROCESSASCAN ________________________________________________________
% #########################################################################

% PROCESSTOF options ======================================================
runtof   = false;       % Run processtof?
toffiles = 1:numFiles; % Indices of files to read
% PROCESSTOF inputs -------------------------------------------------------
minprom2   = 0.013;%Min prominence in findpeaks for a peak to be identified
peakthresh = 0.04; %Threshold of dt for peak to be labeled as unique
% MODETHRESH:       Threshold for TOF to be set to mode TOF
hi = 0.25;
md = 0.14;
lo = 0.06;
modethresh = [hi; hi; hi; hi; hi;      %  1- 5 
              md; hi; hi; md; hi;      %  6-10
              hi; md; lo; lo; lo;      % 11-15
              md; md; hi; hi; hi;      % 16-20
              hi; hi; hi; md; md; hi]; % 21-26
% END PROCESSTOF __________________________________________________________
% #########################################################################

% PLOTTOF options =========================================================
runplot   = false;         % Run plottof?
plotfiles = 1:numFiles; % Indices of files to read
% PLOTTOF inputs ----------------------------------------------------------
platet  = 3.3;% Plate thickness in millimeters
nlayers = 25; % Number of layers in plate
% END PLOTTOF _____________________________________________________________
% #########################################################################

% MERGETOF options ========================================================
runmerge   = true; % Run mergetof?
mergefiles = 9:17; % Indices of files to read
% MERGETOF inputs ---------------------------------------------------------
di = 8;            % File index offset if necessary
dx = [ 8;-2;            % 9-10
      -4; 7; 4;-27;-45; % 11-15
       6; 9];           % 16-17
dy = [ 2; 0;            % 9-10
       2;-1;-5; -2;  0; % 11-15
       1; 0];           % 16-17
test = false;
% END MERGETOF ____________________________________________________________
% #########################################################################

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
        baserow,basecol,cropthresh,pad,minprom1,noisethresh,maxwidth,res)
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
parfor i = toffiles
    disp(strcat(num2str(i),'.',filenames(i)));
    processtof(filenames(i),outfolder,figfolder,minprom2,peakthresh, ...
        modethresh(i),res);
end
sec = toc;
fprintf('\nElapsed time is:')
disp(duration(0,0,sec))
fprintf("Finished processing all raw TOF.mat files!\n\n")
end

%% Plot relevant figures
% Note: parfor results in file processing to complete out of order

if runplot == true
tic
fprintf("PROCESSTOF======================================\n\n")
fprintf("Plotting for:\n\n");
parfor i = plotfiles
    disp(strcat(num2str(i),'.',filenames(i)));
    plottof(filenames(i),outfolder,figfolder,platet,nlayers,res);
end
sec = toc;
fprintf('\nElapsed time is:')
disp(duration(0,0,sec))
fprintf("Finished plotting!\n\n")
end

%% Merge for hybrid C-scan

if runmerge == true
tic
fprintf("MERGETOF======================================\n\n")
fprintf("Merging TOF for:\n\n");
parfor i = mergefiles
    disp(strcat(num2str(i),'.',filenames(i)));
    mergetof(filenames(i),outfolder,figfolder,dx(i-di),dy(i-di),test,res);
end
sec = toc;
fprintf('\nElapsed time is:')
disp(duration(0,0,sec))
fprintf("Finished merging!\n\n")
end
