%% Clear workspace
close all; clear; format compact;

%% Function inputs

% .csv file parameters
delimiter = "   ";   % Delimiter in .csv file

% Folder names
inFolder  = "Input";  % .csv C-scan file location
outFolder = "Output"; % .mat processed file output location

% Raw c-scan parameters
% dt           = 1/50;  % Sampling period [us]
dt           = 1/100;  % Sampling period [us]
% scaleVal     = 5;     % equal to #col/"Scanning Length" in header
scaleVal = 1;
scaleDir     = 'col'; % Direction to scale along
% dataPtsPerAScan = 205;
dataPtsPerAScan = 535;

% C-scan processing parameters
% xStartI      = 125;
% yStartI      = 30;
% xEndI        = 385;
% yEndI        = 1190;
xStartI    = 81;
xEndI      = 336;
yStartI    = 11;
yEndI      = 552;
searchArea   = [xStartI xEndI yStartI yEndI];
cropIncr     = 20;
% baseRow      = 50:5:60;
% baseCol      = 10:2:14;
baseRow      = 470:5:480;
baseCol      = 160:5:170;
cropThresh   = 0.2;   % Crop threshold greater than abs(baseTOF - tof(i))
padExtra     = 0.5;  % Extra padding on all 4 crop edges

% Output requests
saveMat      = true;  % Save TOF mat?
saveFits     = true;  % Save fits mat?
saveFig      = true;  % Save segmented figure?
saveTOF      = true;
saveInflectionPts = true; % temp testing
saveOutput   = true;

% Plate properties
numLayers    = 25;    % # of layers in plate
plateThick   = 3.3;   % plate thickness [mm]

fileNames = ["LV-162-WhiteSide-CH1"];
numFiles = length(fileNames);

%% Input/output file names (user specific)

panelType = ["BL","CONT","RPR"];
impactEnergy = ["10","15","20"];

n = length(impactEnergy);
m = length(panelType);

%{ 

fileNames = strings([n*m*2,1]);

% Concat file names
count = 0;
for i = 1:n
    for j = 1:m
        count = count + 1;
        fileNames(count) = ...
            strcat("CSAI-",panelType(j),"-S-",impactEnergy(i),"J-2-CH1");
        fileNames(count+n*m) = ...
            strcat("CSAI-",panelType(j),"-S-",impactEnergy(i),"J-2-backside-CH1");
    end
end

%}

% "Hard" panel samples can be included as extra test cases
%{
miscFileNames = ["CSAI-BL-H-15J-1-waveform-CH1";
                 "CSAI-CONT-H-10J-2-waveform-CH1";
                 "CSAI-CONT-H-10J-3-waveform-CH1";
                 "CSAI-CONT-H-20J-1-waveform-CH1";
                 "CSAI-CONT-H-20J-2-waveform-CH1";
                 "CSAI-CONT-H-20J-3-waveform-CH1";
                 "CSAI-RPR-H-20J-2-waveform-CH1";
                 "CSAI-RPR-H-20J-3-waveform-CH1"];

fileNames = [miscFileNames; fileNames];
%}
%% Read in C-Scans

% Uncomment when need to convert additional .csv files
%%{
fprintf("==============================================\n\n")
fprintf("Converted C-scans from .csv to .mat files for:\n\n");

for i = 1:numFiles
    cScanRead(fileNames(i),delimiter,inFolder,outFolder);
    disp(fileNames(i));
end

fprintf("\nFinished converting all C-scan .csv files!\n\n")
%}

%% Process C-Scans and calculate raw TOF

%%{
fprintf("==============================================\n\n")
fprintf("Processed C-scans and converted to raw TOF for:\n\n");


cropCoord = cell(1,numFiles);
rawTOF = cell(1,numFiles);
fits = cell(1,numFiles);

for i = 1:numFiles
    tic;
    [~,~,cropCoord{i}] = ...
    aScanProcessing(fileNames{i},outFolder,dt,scaleVal,scaleDir,searchArea,cropIncr, ...
    baseRow,baseCol,cropThresh,padExtra,saveOutput);
    disp(fileNames(i));
    toc
end

fprintf("\nFinished processing all C-scan .mat files.\n\n")
%}

%% Process TOF

%{
fprintf("==============================================\n\n")
fprintf("Processed TOF for:\n\n");

% TOF = cell(numFiles,1);
% inflectionpts = cell(numFiles,1);

for i = 25:numFiles
    tic;
    aScanLayers(fileNames(i),outFolder,205,saveTOF,saveInflectionPts);
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