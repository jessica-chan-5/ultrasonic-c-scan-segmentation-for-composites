%% Header

close all; clear; format compact;

%% Function inputs

tic;
dt           = 0.02;  % us
vertScale    = 238;   % equal to "Scanning Length" in header
noiseThresh  = 0.01;
plotRow      = 1190/2; % Center of plate
plotCol      = 384/2;  % Center of plate
plotTOF      = false;
plotAScan    = false;
saveMat      = false;
saveFig      = false;

%% Input/output file names

panelType = ["BL","CONT","RPR"];
impactEnergy = ["10","15","20"];

n = length(impactEnergy);
m = length(panelType);

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

% "Hard" panel samples can be included as extra test cases
% %{
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

%% Testing cScanRead function call

disp("Saved C-scans as .mat files for:");

for i = 1:length(fileNames)
    inFile = strcat("Input\",fileNames(i),".csv");
    outFile = strcat("Output\",fileNames(i));
    cScanRead(inFile,outFile); % Convert .csv to .mat file
end

toc;
disp("Done! Finished processing all C-scan .csv files.")

%% Testing aScanProcessing function call

tic;
disp("Processed C-scans and converted to TOF for:")
for i = 1%:length(fileNames)
    inFile = strcat("Output\",fileNames(i),'-cScan.mat');
    outFile = strcat("Output\",fileNames(i),'-TOF.mat');
    load(inFile);
    aScanProcessing(cScan,inFile,outFile,dt,vertScale,noiseThresh, ...
        plotRow,plotCol,plotTOF,plotAScan,saveMat,saveFig)
end

toc;
disp("Done! Finished processing all C-scan .mat files.")






