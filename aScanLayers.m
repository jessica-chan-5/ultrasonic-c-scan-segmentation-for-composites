function [TOF,inflpt] = aScanLayers(fileName,outFolder,...
    dataPtsPerAScan,saveTOF,saveInflectionPts,modeThresh)

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
minPeakProm1 = 0.03;
minPeakProm2 = 0.015; % Testing ============================================
peakThresh = 0.04;
maxPeakWidth = 0.75;

for i = 1:row    
    for k = 1:col
        fit = fits{i,k};

        if isempty(fit) == false
            % Evaluate smoothing spline for t
            pfit = feval(fit,t);
            % Find and save locations of peaks in spline fit
            [peaks{i,k}, locs{i,k}, width] = findpeaks(pfit,t,'MinPeakProminence',minPeakProm1,'WidthReference','halfheight');
            
            if length(width) >= 1 && width(1) > maxPeakWidth
                widePeak(i,k) = true;
            end
        
            % Count number of peaks
            numPeaks(i,k) = length(peaks{i,k});
        end
    end
end

[peak2,unprocessedTOF,locs2irow] = labelPeaks('row',row,col,locs,peaks,numPeaks,widePeak,peakThresh);
[~,~,locs2icol] = labelPeaks('col',row,col,locs,peaks,numPeaks,widePeak,peakThresh);

inflpt = findInflectionPts(inflpt,'row',row,col,peak2,minPeakProm2,numPeaks,locs2irow);
inflpt = findInflectionPts(inflpt,'col',row,col,peak2,minPeakProm2,numPeaks,locs2icol);

% Set 1 pixel border equal to zero
inflpt(1,:) = 0;
inflpt(:,1) = 0;
inflpt(end,:) = 0;
inflpt(:,end) = 0;

test = true; % Testing ====================================================
dispFig = 'off';
width = size(inflpt,1);
height = size(inflpt,2);

% Set numPeaks < 2 to be inflection points
inflpt(numPeaks < 2) = 1;

if test == true
    figure('visible',dispFig);
    imjet = imshow(inflpt,gray,'XData',[0 height],'YData',[width 0]);
    imjet.CDataMapping = "scaled"; title("Inflection Points"); 
end

if test == true
    figure('visible',dispFig);
    subplot(1,3,1); imjet = imshow(inflpt,gray,'XData',[0 height],'YData',[width 0]);
    imjet.CDataMapping = "scaled"; title("Original"); 
end

% Create concave hull of damage area
concHull = bwmorph(inflpt,'spur',inf); % Remove spurs
if test == true
    subplot(1,3,2); imjet = imshow(concHull,gray,'XData',[0 height],'YData',[width 0]);
    imjet.CDataMapping = "scaled"; title("Spur");
end

concHull = bwmorph(concHull,'clean',inf); % Remove isolated pixels
if test == true
    subplot(1,3,3); imjet = imshow(concHull,gray,'XData',[0 height],'YData',[width 0]);
    imjet.CDataMapping = "scaled"; title("Clean");
    exportgraphics(gcf,strcat('ConcaveHulls\',fileName,'.png'),'Resolution',300);
end

% Trace exterior boundary, ignore interior holes
[concBoundC,~] = bwboundaries(concHull,'noholes');
% Convert boundaries from cell to binary image
concBound = zeros(size(concHull));
for i = 1:length(concBoundC)
    for k = 1:size(concBoundC{i},1)
        concBound(concBoundC{i}(k,1),concBoundC{i}(k,2)) = 1;
    end
end
% Flood-fill boundary
concFill = imfill(concBound,4);
if test == true
    figure('visible',dispFig);
    subplot(1,2,1); imjet = imshow(concFill,gray,'XData',[0 height],'YData',[width 0]);
    imjet.CDataMapping = "scaled"; title("Mask");
end
% Find perimeter using 8 pixel connectivity
concPerim = bwperim(concFill,8);
if test == true
    subplot(1,2,2); imjet = imshow(concPerim,gray,'XData',[0 height],'YData',[width 0]);
    imjet.CDataMapping = "scaled"; title("Boundary");
    exportgraphics(gcf,strcat('Masks\',fileName,'.png'),'Resolution',300);
end

% Apply mask to inflection points map before morphological operations
J = inflpt & concFill;

% Close gaps in inflection points using morphological operations
J = bwmorph(J,'clean',inf);
J = bwmorph(J,'bridge',inf); % Remove isolated pixels

% Close w/ 2 independent operations
% se0 = strel('line',2,45); 
% close0 = imclose(J,se0); % Close w/ 0 degree line
% se90 = strel('line',2,-45); 
% close90 = imclose(J,se90); % Close w/ 90 degree line
% J = close0|close90;

% Remove excess pixels outside concave hull and add outline where missing
% J = J & concFill;
J = J | concPerim;

% Clean up w/ a few operations
J = bwmorph(J,'fill'); % Fill in isolated pixels
J = bwmorph(J,'spur',2); % Remove spurs
J = bwmorph(J,'clean',inf); % Remove isolated pixels

% Add any missing zero TOF values
J(numPeaks < 2) = 1;
if test == true
    figure('visible',dispFig);
    subplot(1,4,1); imjet = imshow(inflpt,gray,'XData',[0 height],'YData',[width 0]);
    imjet.CDataMapping = "scaled"; title("Original");
    subplot(1,4,2); imjet = imshow(J,gray,'XData',[0 height],'YData',[width 0]);
    imjet.CDataMapping = "scaled"; title("Processed");
end

% Label separate layer regions of C-scan
[L,n] = bwlabel(uint8(~J),4);

if test == true
    subplot(1,4,3); imjet = imshow(L,colorcube,'XData',[0 height],'YData',[width 0]);
    imjet.CDataMapping = "scaled"; title("Labeled");
end

TOF = unprocessedTOF;

for i = 1:n
    [areaI, areaJ] = find(L==i);
    areaInd = sub2ind(size(L),areaI,areaJ);
    areaMode = mode(round(unprocessedTOF(areaInd),2),'all');
    for k = 1:length(areaI)
        if abs(TOF(areaI(k),areaJ(k)) - areaMode) < modeThresh
            TOF(areaI(k),areaJ(k)) = areaMode;
        end
    end
end

% Set numPeaks < 2 and widePeak to be zero TOF
TOF(numPeaks < 2) = 0;

if test == true
    subplot(1,4,4); imjet = imshow(TOF,jet,'XData',[0 height],'YData',[width 0]);
    imjet.CDataMapping = "scaled"; title("Mode");
    exportgraphics(gcf,strcat('Processed\',fileName,'.png'),'Resolution',300);
end

% Save TOF and inflection points to .mat file
if saveTOF == true
    save(outFileTOF,'TOF','-mat');
end

if saveInflectionPts == true
    save(outFileInflectionPts,'inflpt','-mat');
end

if test == true
    figure('Visible',dispFig);
    subplot(1,2,1); imjet = imshow(unprocessedTOF,jet,'XData',[0 height],'YData',[width 0]);
    imjet.CDataMapping = "scaled"; title("Unprocessed");
    exportgraphics(gcf,strcat('Processed\',fileName,'.png'),'Resolution',300);
    subplot(1,2,2); imjet = imshow(TOF,jet,'XData',[0 height],'YData',[width 0]);
    imjet.CDataMapping = "scaled"; title("Processed");
    sgtitle(fileName);
    exportgraphics(gcf,strcat('Comparison\',fileName,'.png'),'Resolution',300);
end

figure('visible',dispFig);
imjet = imshow(TOF,jet,'XData',[0 height],'YData',[width 0]);
imjet.CDataMapping = "scaled";
ax = gca;
exportgraphics(ax,strcat('NewFigures\',fileName,'.png'),'Resolution',300);

end