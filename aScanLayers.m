function [TOF,inflpt] = aScanLayers(fileName,outFolder,...
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
inflpt = TOF;
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

inflpt = findInflectionPts(inflpt,'row',row,col,peak2,minPeakPromPeak2,numPeaks,locs2irow);
inflpt = findInflectionPts(inflpt,'col',row,col,peak2,minPeakPromPeak2,numPeaks,locs2icol);

% Set 1 pixel border equal to zero
inflpt(1,:) = 0;
inflpt(:,1) = 0;
inflpt(end,:) = 0;
inflpt(:,end) = 0;

test = false; % temp

% Set numPeaks < 2 and widePeak to be inflection points
inflpt(numPeaks < 2) = 1;
if test == true
    figure('visible','on');
    subplot(1,3,1); imjet = imshow(inflpt,gray,'XData',[0 size(inflpt,2)],'YData',[size(inflpt,1) 0]);
    imjet.CDataMapping = "scaled"; title("Original"); 
end

% Create concave hull of damage area
concHull = bwmorph(inflpt,'spur',inf); % Remove spurs
if test == true
    subplot(1,3,2); imjet = imshow(concHull,gray,'XData',[0 size(inflpt,2)],'YData',[size(inflpt,1) 0]);
    imjet.CDataMapping = "scaled"; title("Spur");
end

concHull = bwmorph(concHull,'clean',inf); % Remove isolated pixels
if test == true
    subplot(1,3,3); imjet = imshow(concHull,gray,'XData',[0 size(inflpt,2)],'YData',[size(inflpt,1) 0]);
    imjet.CDataMapping = "scaled"; title("Clean");
    exportgraphics(gcf,strcat('ConcaveHulls\',fileName,'.png'),'Resolution',300);
end

% Trace exterior boundary, ignore interior holes
[concBoundC,~] = bwboundaries(concHull,'noholes');
% Convert boundaries from cell to binary image
concBound = zeros(size(concHull));
for i = 1:length(concBoundC)
    for j = 1:size(concBoundC{i},1)
        concBound(concBoundC{i}(j,1),concBoundC{i}(j,2)) = 1;
    end
end
% Flood-fill boundary
concFill = imfill(concBound,4);
if test == true
    figure('visible','off');
    subplot(1,2,1); imjet = imshow(concFill,gray,'XData',[0 size(inflpt,2)],'YData',[size(inflpt,1) 0]);
    imjet.CDataMapping = "scaled"; title("Mask");
end
% Find perimeter using 8 pixel connectivity
concPerim = bwperim(concFill,8);
if test == true
    subplot(1,2,2); imjet = imshow(concPerim,gray,'XData',[0 size(inflpt,2)],'YData',[size(inflpt,1) 0]);
    imjet.CDataMapping = "scaled"; title("Boundary");
    exportgraphics(gcf,strcat('Masks\',fileName,'.png'),'Resolution',300);
end

% Apply mask to inflection points map before morphological operations
J = inflpt & concFill;

% Close gaps in inflection points using morphological operations
J = bwmorph(J,'clean',inf); % Remove isolated pixels

% Close w/ 2 independent operations
seNeg45 = strel('line',3,-45); 
neg45 = imclose(J,seNeg45); % Close w/ -45 degree line
sePos45 = strel('line',3,45); 
pos45 = imclose(J,sePos45); % Close w/ +45 degree line
J = neg45|pos45;

% Remove excess pixels outside concave hull and add outline where missing
J = J & concFill;
J = J | concPerim;

% Clean up w/ a few operations
J = bwmorph(J,'spur',inf); % Remove spurs
J = bwmorph(J,'clean',inf); % Remove isolated pixels

% Add any missing zero TOF values
J(numPeaks < 2) = 1;

figure('visible','off');
subplot(1,4,1); imjet = imshow(inflpt,gray,'XData',[0 size(inflpt,2)],'YData',[size(inflpt,1) 0]);
imjet.CDataMapping = "scaled"; title("Original");
subplot(1,4,2); imjet = imshow(J,gray,'XData',[0 size(inflpt,2)],'YData',[size(inflpt,1) 0]);
imjet.CDataMapping = "scaled"; title("Processed");

% Label separate layer regions of C-scan
[L,n] = bwlabel(uint8(~J),4);

subplot(1,4,3); imjet = imshow(L,colorcube,'XData',[0 size(inflpt,2)],'YData',[size(inflpt,1) 0]);
imjet.CDataMapping = "scaled"; title("Labeled");

TOF = unprocessedTOF;

for i = 1:n
    [areaI, areaJ] = find(L==i);
    areaInd = sub2ind(size(L),areaI,areaJ);
    TOF(areaInd) = mode(round(unprocessedTOF(areaInd),2),'all');
end

% Set numPeaks < 2 and widePeak to be zero TOF
TOF(numPeaks < 2) = 0;

subplot(1,4,4); imjet = imshow(TOF,jet,'XData',[0 size(inflpt,2)],'YData',[size(inflpt,1) 0]);
imjet.CDataMapping = "scaled"; title("Labeled");
exportgraphics(gcf,strcat('Processed\',fileName,'.png'),'Resolution',300);
end
%{
% Save TOF and inflection points to .mat file
if saveTOF == true
    save(outFileTOF,'TOF','-mat');
end

if saveInflectionPts == true
    save(outFileInflectionPts,'inflpt','-mat');
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
%}