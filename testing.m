%% Variables
format compact
fileName = "CSAI-CONT-S-20J-2";
% fileName = "CSAI-RPR-S-10J-2";
fileNameFront = strcat("Output\",fileName,"-CH1");
fileNameBack = strcat("Output\",fileName,"-backside-CH1");
vertScale = 238;
row = 385;
col = 1190;
% Plate properties
numLayers    = 25;    % # of layers in plate
plateThick   = 3.3;   % plate thickness [mm]
%% Load TOF - front
load(strcat(fileNameFront,"-TOF-auto"));
TOFfront = TOF; clear TOF;
%% Load spline fits - front
load(strcat(fileNameFront,"-fits-auto"));
%% Load spline fits - back
load(strcat(fileNameBack,"-fits"));
%% Load TOF - back
load(strcat(fileNameBack,"-TOF"));
TOFback = TOF; clear TOF;
%% Plot imshow of TOF w/ jet colormap - front
figure; imjet = imshow(TOFfront,jet,'XData',[0 vertScale],'YData',[row 0]);
imjet.CDataMapping = "scaled";
title(strcat("TOF: ",fileName," - front"));
%% Plot 1 row of TOF - front
figure;
rowI = 191;
plot(TOFfront(rowI,:));
%% Plot imshow of TOF w/ jet colormap - back
figure; imjet = imshow(TOFback,jet,'XData',[0 vertScale],'YData',[row 0]);
imjet.CDataMapping = "scaled";
title(strcat("TOF: ",fileName," - back"));
%% Plot filled contor of TOF - front
figure; contourf(TOFfront);
title(strcat("Contour TOF: ",fileName," - front"));
%% Plot filled contor of TOF - back
figure; contourf(TOFback);
title(strcat("Contour TOF: ",fileName," - back"));
%% Sort TOF into bins using discretize - front (center on layer)
baseTOF = mode(mode(nonzeros(TOFfront))); % baseline TOF [us]
matVel = 2*plateThick/baseTOF; % Calculate material velocity [mm/us]
plyThick = plateThick/numLayers; % Calculate ply thickness
dtTOF = plyThick/matVel; % Calculate TOF for each layer

% Calculate bins centered at interface between layers
layersTOF = 0:dtTOF:baseTOF+dtTOF;
layersTOF(end) = baseTOF+2*dtTOF;
binTOFfront = discretize(TOFfront,layersTOF);

figure;
imjet = imshow(binTOFfront,jet,'XData',[0 vertScale],'YData',[row 0]);
imjet.CDataMapping = "scaled";
title(strcat("TOF ",fileNameFront));
%% Sort TOF into bins using discretize - back (center on layer)
baseTOF = mode(mode(nonzeros(TOFback))); % baseline TOF [us]
matVel = 2*plateThick/baseTOF; % Calculate material velocity [mm/us]
plyThick = plateThick/numLayers; % Calculate ply thickness
dtTOF = plyThick/matVel*2; % Calculate TOF for each layer

% Calculate bins centered at interface between layers
layersTOF = 0:dtTOF:baseTOF;
layersTOF(end) = baseTOF+dtTOF;
binTOFfront = discretize(TOFback,layersTOF);

figure;
imjet = imshow(binTOFfront,jet,'XData',[0 vertScale],'YData',[row 0]);
imjet.CDataMapping = "scaled";
title(strcat("TOF ",fileNameFront));
%% Sort TOF into bins using discretize - front (center on interface)
baseTOF = mode(mode(nonzeros(TOFfront))); % baseline TOF [us]
matVel = 2*plateThick/baseTOF; % Calculate material velocity [mm/us]
plyThick = plateThick/numLayers; % Calculate ply thickness
dtTOF = plyThick/matVel*2; % Calculate TOF for each layer

% Calculate bins centered at interface between layers
layersTOF = -dtTOF/2:dtTOF:baseTOF-dtTOF;
layersTOF(end) = baseTOF+dtTOF;
binTOFfront = discretize(TOFfront,layersTOF);

figure;
imjet = imshow(binTOFfront,jet,'XData',[0 vertScale],'YData',[row 0]);
imjet.CDataMapping = "scaled";
title(strcat("TOF ",fileNameFront));
%% Sort TOF into bins using discretize - front (center on interface)
baseTOF = mode(mode(nonzeros(TOFback))); % baseline TOF [us]
matVel = 2*plateThick/baseTOF; % Calculate material velocity [mm/us]
plyThick = plateThick/numLayers; % Calculate ply thickness
dtTOF = plyThick/matVel*2; % Calculate TOF for each layer

% Calculate bins centered at interface between layers
layersTOF = -dtTOF/2:dtTOF:baseTOF-dtTOF;
layersTOF(end) = baseTOF+dtTOF;
binTOFfront = discretize(TOFback,layersTOF);

figure;
imjet = imshow(binTOFfront,jet,'XData',[0 vertScale],'YData',[row 0]);
imjet.CDataMapping = "scaled";
title(strcat("TOF ",fileNameFront));
%% 3D scatter plot - front
numRow = size(TOFfront,1);
numCol = size(TOFfront,2);
TOFfrontvec = reshape(binTOFfront,numRow*numCol,1);
% TOFfrontvec(TOFfrontvec==0) = NaN;
% TOFfrontvec(TOFfrontvec>2) = NaN;
% TOFfrontvec(1) = 0;
% TOFfrontvec(end) = 2.12;

TOFfrontvec(TOFfrontvec==1) = NaN;
TOFfrontvec(TOFfrontvec>=length(layersTOF)-2) = NaN;
TOFfrontvec(1) = 1;
TOFfrontvec(end) = length(layersTOF);

xvec = repmat((1:numRow)',numCol,1);
yvec = repelem(1:numCol,numRow)';

figure;
scatter3(xvec,yvec,TOFfrontvec,10,TOFfrontvec,'filled');
colormap(gca,'jet');
xlabel('Row #');
ylabel('Col #');
zlabel('TOF (us)');

%% 3D scatter plot - back
numRow = size(TOFfront,1);
numCol = size(TOFfront,2);
binTOFbackflipmirror = -(fliplr(binTOFback)-max(binTOFback));
horzOffset = 33;
binTOFbackflipmirror(:,1:end-horzOffset+1) = binTOFbackflipmirror(:,horzOffset:end);
TOFbackvec = reshape(binTOFbackflipmirror,numRow*numCol,1);
% TOFbackvec(TOFbackvec<0.12) = NaN;
% TOFbackvec(TOFbackvec>2) = NaN;
% TOFbackvec(1) = 0;
% TOFbackvec(end) = 2.12;

TOFbackvec(TOFbackvec<=1) = NaN;
TOFbackvec(TOFbackvec==length(layersTOF)-2) = NaN;
TOFbackvec(1) = 0;
TOFbackvec(end) = length(layersTOF);

xvec = repmat((1:numRow)',numCol,1);
yvec = repelem(1:numCol,numRow)';

figure;
scatter3(xvec,yvec,TOFbackvec,10,TOFbackvec,'filled');
colormap(gca,'jet');
xlabel('Row #');
ylabel('Col #');
zlabel('TOF (us)');
%% 3D scatter plot - front and back
% numRow = size(TOFfront,1);
% numCol = size(TOFfront,2);
% 
% TOFfrontvec = reshape(binTOFfront,numRow*numCol,1);
% TOFfrontvec(TOFfrontvec==0) = NaN;
% TOFfrontvec(TOFfrontvec>2) = NaN;
% TOFfrontvec(1) = 0;
% TOFfrontvec(end) = 2.12;
% 
% horzOffset = 33;
% binTOFbackflipmirror = -(fliplr(binTOFback)-max(binTOFback));
% binTOFbackflipmirror(:,1:end-horzOffset+1) = binTOFbackflipmirror(:,horzOffset:end);
% TOFbackvec = reshape(binTOFbackflipmirror,numRow*numCol,1);
% TOFbackvec(TOFbackvec<0.12) = NaN;
% TOFbackvec(TOFbackvec>2) = NaN;
% TOFbackvec(1) = 0;
% TOFbackvec(end) = 2.12;
% 
% xvec = repmat((1:numRow)',numCol,1);
% yvec = repelem(1:numCol,numRow)';

figure;
scatter3(xvec,yvec,TOFfrontvec,10,TOFfrontvec,'filled');
hold on;
scatter3(xvec,yvec,TOFbackvec,10,TOFbackvec,'filled');

colormap(gca,'jet');
xlabel('Row #');
ylabel('Col #');
zlabel('TOF (us)');

%% Plot by layer

for i = 2:25
    TOFfrontlayer = binTOFfront;
    TOFbacklayer = binTOFbackflipmirror;

    TOFfrontlayer(binTOFfront~=i) = NaN;
    TOFbacklayer(binTOFbackflipmirror~=i) = NaN;
    
    titlestr = strcat("Layer ",num2str(i));
    figure;
    
    subplot(1,2,1);
    imshow(TOFfrontlayer,'XData',[0 vertScale],'YData',[row 0]);
    title(strcat(titlestr," front"));
    
    subplot(1,2,2);
    imshow(TOFbacklayer,'XData',[0 vertScale],'YData',[row 0]);
    title(strcat(titlestr," back"));
end

tabulate(TOFfrontvec)
tabulate(TOFbackvec)
%% Load C-Scan - front
load(strcat(fileNameFront,"-cScan"));
%% Plot A-Scans - testing smoothing spline method

% Points to inspect
plotRow = 191;%floor(size(cScan,1)/2);
plotCol = 1;
spacing = 1;
numPoints = size(cScan,2);
points = 1:spacing:numPoints*spacing;

% Figure properties
plotFig = false;

% Initialize values
TOFtest = zeros(1,numPoints);
smoothParamP = zeros(1,numPoints);
f = cell(1,numPoints);

% Sensitivity parameters
minPeakPromP = 0.03; % For finding peaks of a-scan
minPeakPromPeak = 0.02; % For finding peaks of spline fit
smoothSplineParam = 0.9998; % For smoothparam when using fit with smoothingspline option
noiseThresh = 0.01;

if plotFig == true
    figure;
    fontsizes = 18;
    axislabels = false;
end

% Calculate time vector
dt = 0.02;
tEnd = (size(cScan,3)-1)*dt;
t = 0:dt:tEnd;

cScanSlice = squeeze(cScan(plotRow,:,:));

tic;

for i = 1:length(points)
        titleStr = strcat("Col ", num2str(plotCol+(points(i)-1))," i=",num2str(i));
    
        aScan = cScanSlice(plotCol+(points(i)-1),:);
    if mean(aScan) > noiseThresh

        if plotFig == true
            subplot(sqrt(numPoints),sqrt(numPoints),i); hold on;
            plot(t,abs(aScan));
        end
    
        % Find and save peaks/locations in signal
        [p, l] = findpeaks(aScan,t);
    %     disp('peak prom');
    %     disp(prom);
    
        % Force signal to be zero at beginning and end
        p = [0 p 0]; %#ok<AGROW> 
        l = [0 l t(end)]; %#ok<AGROW> 
        
        % Fit smoothing spline to find peak values
        [f{i}, ~, out] = fit(l',p','smoothingspline','SmoothingParam',smoothSplineParam);
        smoothParamP(i) = out.p;
        
        % Find peak values in smoothing spline
        pfit = feval(f{i},t);
    
        % Find and save locations of peaks in previously found peaks
        [peak,loc,~,~] = findpeaks(pfit,t,'MinPeakProminence',minPeakPromPeak);
    
        if plotFig == true
            hold on;
            findpeaks(pfit,t,'MinPeakProminence',minPeakPromPeak);
    
            % Format plot
            title(titleStr);
            if axislabels == true
                xlabel("Time [us]");
                ylabel("Amplitude");
            end
            xlim([0,tEnd]);
            hl=findobj(gcf,'type','legend');
            delete(hl);
            fontsize(gca,fontsizes,'pixels');
        end
    
        % Count number of peaks
        numPeaks = length(peak);
    
        if numPeaks > 1
            [~, loc2i] = max(peak(2:end));
            TOFtest(i) = loc(loc2i+1)-loc(1);
        end
    end
end

toc;

if plotFig == true
    sgtitle(strcat("Row ", num2str(plotRow)),'FontSize',fontsizes);
end
%% Plot peak values across row
figure; hold on; 
plot(TOFtest);
xlabel("Column Index");
ylabel("TOF");
%% Test aScanLayers
[cropTOF,inflectionpts,peak2] = aScanLayers(fits);
%% Plot peak2 along a col
figure;
minPeakPromPeak2 = 0.1;
invertPeak2 = peak2(:,1077).^-1-1;
invertPeak2(isinf(invertPeak2)) = 0;
findpeaks(invertPeak2,'MinPeakProminence',minPeakPromPeak2,'Annotate','Extents');
%% Plot TOF
TOF = zeros(row,col);
TOF(1:size(cropTOF,1),1:size(cropTOF,2)) = cropTOF;
figure; imjet = imshow(TOF,jet,'XData',[0 vertScale],'YData',[row 0]);
imjet.CDataMapping = "scaled";
title(strcat("TOF: ",fileName," - front"));
%% Plot filled contor of TOF
figure; contourf(TOF);
title(strcat("Contour TOF: ",fileName," - front"));
%% Plot filled contor of inflection points
figure; contourf(inflectionpts);
title(strcat("Contour Inflection Points: ",fileName," - front"));
%% Plot 1 row of TOF - front
figure;
rowI = 167;
plot(TOF(rowI,:));
%% Plot inflection points
inflectionPts = ones(row,col);
inflectionPts(1:size(cropTOF,1),1:size(cropTOF,2)) = uint8(~inflectionpts);
figure; imjet = imshow(inflectionPts,gray,'XData',[0 vertScale],'YData',[row 0]);
imjet.CDataMapping = "scaled";
title(strcat("Inflection points: ",fileName," - front"));