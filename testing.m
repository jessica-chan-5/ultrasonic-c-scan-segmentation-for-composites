%% Variables
format compact
sampleName = "CSAI-BL-H-15J-1-waveform";
fileName = strcat("Output\",sampleName,"-CH1");
vertScale = 238;
row = 385;
col = 1190;
% Plate properties
numLayers    = 25;    % # of layers in plate
plateThick   = 3.3;   % plate thickness [mm]
%% Load TOF
load(strcat(fileName,"-TOF"));
%% Load spline fits
load(strcat(fileName,"-fits"));
%% Plot imshow of TOF w/ jet colormap
figure; imjet = imshow(TOF,jet,'XData',[0 vertScale],'YData',[row 0]);
imjet.CDataMapping = "scaled";
title(strcat("TOF: ",sampleName));
%% Plot filled contor of TOF
figure; contourf(TOF);
title(strcat("Contour TOF: ",sampleName));
%% Sort TOF into bins using discretize (center on layer)
baseTOF = mode(mode(nonzeros(TOF))); % baseline TOF [us]
matVel = 2*plateThick/baseTOF; % Calculate material velocity [mm/us]
plyThick = plateThick/numLayers; % Calculate ply thickness
dtTOF = plyThick/matVel; % Calculate TOF for each layer

% Calculate bins centered at interface between layers
layersTOF = 0:dtTOF:baseTOF+dtTOF;
layersTOF(end) = baseTOF+2*dtTOF;
binTOF = discretize(TOF,layersTOF);

figure;
imjet = imshow(binTOF,jet,'XData',[0 vertScale],'YData',[row 0]);
imjet.CDataMapping = "scaled";
title(strcat("TOF ",fileName));
%% 3D scatter plot - front
numRow = size(TOF,1);
numCol = size(TOF,2);
TOFvec = reshape(binTOF,numRow*numCol,1);
% TOFvec(TOFvec==0) = NaN;
% TOFvec(TOFvec>2) = NaN;
% TOFvec(1) = 0;
% TOFvec(end) = 2.12;

TOFvec(TOFvec==1) = NaN;
TOFvec(TOFvec>=length(layersTOF)-2) = NaN;
TOFvec(1) = 1;
TOFvec(end) = length(layersTOF);

xvec = repmat((1:numRow)',numCol,1);
yvec = repelem(1:numCol,numRow)';

figure;
scatter3(xvec,yvec,TOFvec,10,TOFvec,'filled');
colormap(gca,'jet');
xlabel('Row #');
ylabel('Col #');
zlabel('TOF (us)');
%% 3D scatter plot - front and back
figure;
scatter3(xvec,yvec,TOFvec,10,TOFvec,'filled');
hold on;
scatter3(xvec,yvec,TOFbackvec,10,TOFbackvec,'filled');

colormap(gca,'jet');
xlabel('Row #');
ylabel('Col #');
zlabel('TOF (us)');

%% Plot by layer

for i = 2:25
    TOFfrontlayer = binTOF;
    TOFbacklayer = binTOFbackflipmirror;

    TOFfrontlayer(binTOF~=i) = NaN;
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

tabulate(TOFvec)
tabulate(TOFbackvec)
%% Test aScanLayers
[cropTOF,inflectionpts] = aScanLayers(fits,205);
%% Plot TOF
TOF = zeros(row,col);
TOF(1:size(cropTOF,1),1:size(cropTOF,2)) = cropTOF;
figure; imjet = imshow(TOF,jet,'XData',[0 vertScale],'YData',[row 0]);
imjet.CDataMapping = "scaled";
title(strcat("TOF: ",sampleName));
%% Plot filled contor of TOF
figure; contourf(TOF);
title(strcat("Contour TOF: ",sampleName));
%% Plot inflection points
inflectionPts = ones(row,col);
inflectionPts(1:size(cropTOF,1),1:size(cropTOF,2)) = uint8(~inflectionpts);
figure; imjet = imshow(inflectionPts,gray,'XData',[0 vertScale],'YData',[row 0]);
imjet.CDataMapping = "scaled";
title(strcat("Inflection points: ",sampleName));
%% Plot filled contor of inflection points
figure; contourf(inflectionpts);
title(strcat("Contour Inflection Points: ",sampleName));