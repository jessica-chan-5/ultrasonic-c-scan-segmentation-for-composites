function [TOF,inflectionpts] = aScanLayers(fileName,outFolder,...
    dataPtsPerAScan,saveTOF,saveInflectionPts)

% Concatenate file names/paths
inFile = strcat(outFolder,"\",fileName,'-fits.mat');
outFileTOF = strcat(outFolder,"\",fileName,'-TOF.mat');
outFileInflectionPts = strcat(outFolder,'\',fileName,'-InflectionPts.mat');

% Load cScan
load(inFile,'fits');
colSpacing = 5;
selectCol = [1,colSpacing:colSpacing:size(fits,2)];
fits = fits(:,selectCol);

row = size(fits,1);
col = size(fits,2);

% Time vector
dt = 0.02;
tEnd = (dataPtsPerAScan-1)*dt;
t = 0:dt:tEnd;

% Initialize values
TOF = zeros(row,col);
numPeaks = TOF;
widePeak = false(row,col);
inflectionpts = TOF;
peaks = cell(row,col);
locs = cell(row,col);

% Sensitivity parameters
minPeakPromPeak = 0.03;
minPeakPromPeak2 = 0.1;
peakThresh = 0.04;
maxPeakWidth = 0.75;

for i = 1:row    
    for j = 1:col
        fit = fits{i,j};

        if isempty(fit) == false
            % Evaluate smoothing spline for t
            pfit = feval(fit,t);
            % Find and save locations of peaks in spline fit
            [peaks{i,j}, locs{i,j}, width] = findpeaks(pfit,t,'MinPeakProminence',minPeakPromPeak,'WidthReference','halfheight');
            
            if length(width) >= 1 && width(1) > maxPeakWidth
                widePeak(i,j) = true;
            end
        
            % Count number of peaks
            numPeaks(i,j) = length(peaks{i,j});
        end
    end
end

[peak2,unprocessedTOF,locs2irow] = labelPeaks('row',row,col,locs,peaks,numPeaks,widePeak,peakThresh);
[~,~,locs2icol] = labelPeaks('col',row,col,locs,peaks,numPeaks,widePeak,peakThresh);

inflectionpts = findInflectionPts(inflectionpts,'row',row,col,peak2,minPeakPromPeak2,numPeaks,locs2irow);
inflectionpts = findInflectionPts(inflectionpts,'col',row,col,peak2,minPeakPromPeak2,numPeaks,locs2icol);

% Set edges to be inflection points
% inflectionpts(1,:) = 1;
% inflectionpts(end,:) = 1;
% inflectionpts(:,1) = 1;
% inflectionpts(:,end) = 1;

% Set numPeaks < 2 and widePeak to be inflection points
inflectionpts(numPeaks < 2) = 1;
% inflectionpts(widePeak == true) = 1;

TOF = unprocessedTOF;

% Close gaps in inflection points
SE = strel('line',8,-45); 
J1 = imclose(inflectionpts,SE);

SE = strel('line',8,45); 
J2 = imclose(inflectionpts,SE);

SE = strel('line',6,0); 
J3 = imclose(inflectionpts,SE);

SE = strel('line',6,90); 
J4 = imclose(inflectionpts,SE);

J = J1+J2+J3+J4;

% Label separate layer regions of C-scan
[L,n] = bwlabel(uint8(~J),4);

for i = 1:n
    [areaI, areaJ] = find(L==i);
    areaInd = sub2ind(size(L),areaI,areaJ);
    TOF(areaInd) = mode(round(unprocessedTOF(areaInd),2),'all');
end

% Set numPeaks < 2 and widePeak to be zero TOF
TOF(numPeaks < 2) = 0;
% TOF(widePeak == true) = 0;

% Save TOF and inflection points to .mat file
if saveTOF == true
    save(outFileTOF,'TOF','-mat');
end

if saveInflectionPts == true
    save(outFileInflectionPts,'inflectionpts','-mat');
end

plotTOF = zeros(385,1190);
plotTOF(1:row,1:col) = TOF;

figure('visible','off');
imjet = imshow(plotTOF,jet,'XData',[0 238],'YData',[385 0]);
imjet.CDataMapping = "scaled";
title(strcat("TOF ",inFile));
ax = gca;
exportgraphics(ax,strcat('NewFigures\',fileName,'.png'),'Resolution',300);

end