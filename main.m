%% Clear workspace
close all; clear; format compact;

%% Function inputs

% .csv file parameters
delimiter = "   ";   % Delimiter in .csv file

% Folder names
inFolder = "Input";   % .csv C-scan file location
outFolder = "Output"; % .mat processed file output location

% Raw c-scan parameters
fs           = 50;    % Sampling frequency [MHz]
vertScale    = 238;   % equal to "Scanning Length" in header

% C-scan processing parameters
noiseThresh  = 0.01;  % Currently only used for cropEdgeDetect
cropDam      = true;  % Crop non-damaged areas?
cropThresh   = 0.2;   % Crop threshold greater than abs(baseTOF - tof(i))
padExtra     = 1.25;  % Extra padding on all 4 crop edges

% Output requests
saveMat      = true;  % Save TOF and fits mat?
saveFig      = true;  % Save segmented figure?

% Plate properties
numLayers    = 25;    % # of layers in plate
plateThick   = 3.3;   % plate thickness [mm]

% Calculated function inputs
dt = 1/fs; % Calculate sampling period [us]

% Input/output file names (user specific)

panelType = ["BL","CONT","RPR"];
impactEnergy = ["10","15","20"];

n = length(impactEnergy);
m = length(panelType);

fileNames = ["CSAI-CONT-S-20J-2-CH1"];
%{ 

fileNames = strings([n*m*2,1]);

% Concat file names
count = 0;
for i = 1:n
    for j = 1:m
        count = count + 1;
        fileNames(count) = strcat("CSAI-",panelType(j),"-S-",impactEnergy(i),"J-2-CH1");
        fileNames(count+n*m) = strcat("CSAI-",panelType(j),"-S-",impactEnergy(i),"J-2-backside-CH1");
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
%{
fprintf("==============================================\n\n")
fprintf("Converted C-scans from .csv to .mat files for:\n\n");

for i = 1:length(fileNames)
    cScanRead(inFolder,outFolder,fileNames(i),delimiter);
    disp(fileNames(i));
end

fprintf("\nFinished converting all C-scan .csv files!\n\n")
%}

%% Process C-Scans and calculate TOF

%{
TOF = cell(length(fileNames),1);
baseTOF = nan(length(fileNames),1);

fprintf("==============================================\n\n")
fprintf("Processed C-scans and converted to TOF for:\n\n");

for i = 1:length(fileNames)
    tic;
    [TOF{i}, baseTOF(i)] = aScanProcessing(outFolder,fileNames(i),dt,vertScale,cropThresh,padExtra,noiseThresh,saveMat);
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
    inFile = strcat(fileNames(i));
    aScanSegmentation(TOF{i},inFile,numLayers,plateThick,baseTOF(i),vertScale,saveFig)

    disp(fileNames(i));
    toc
end

fprintf("\nFinished segmenting all TOF.\n\n")
fprintf("==============================================\n\n")
%}

%% Process and plot

TOF = cell(length(fileNames),1);
baseTOF = nan(length(fileNames),1);
smoothingParamP = cell(length(fileNames),1);

fprintf("==============================================\n\n")
fprintf("Processed and plotted for:\n\n");

for i = 1:length(fileNames)
    tic;
    [TOF{i}, baseTOF(i), smoothingParamP{i}] = aScanProcessing(outFolder,fileNames(i),dt,vertScale,cropThresh,padExtra,noiseThresh,saveMat);
    
%     inFile = strcat(fileNames(i));
%     aScanSegmentation(TOF{i},inFile,numLayers,plateThick,baseTOF(i),vertScale,saveFig)
    
    disp(fileNames(i));
    toc
end

fprintf("\nFinished processing all C-scan .mat files.\n\n")

%% Testing hybrid C-scans




