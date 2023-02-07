%% Variables
format compact
sampleName = "CSAI-BL-H-15J-1-waveform";
fileName = strcat("Output\",sampleName,"-CH1");
vertScale = 238;
row = 385;
col = 1190;
% Plate properties
% numLayers    = 25;    % # of layers in plate
numLayers = 24;
plateThick   = 3.3;   % plate thickness [mm]
%% Load TOF
load(strcat(fileName,"-TOF"));
%% Load spline fits
load(strcat(fileName,"-fits"));
%% Plot imshow of TOF w/ jet colormap
figure; imjet = imshow(rawtof,jet,'XData',[0 239],'YData',[385 0]);
imjet.CDataMapping = "scaled";
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
imjet = imshow(binTOF,jet,'XData',[0 size(TOF,2)],'YData',[size(TOF,1) 0]);
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

% TOFvec(TOFvec==1) = NaN;
% TOFvec(TOFvec>=length(layersTOF)-2) = NaN;
% TOFvec(1) = 1;
% TOFvec(end) = length(layersTOF);

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
figure; imjet = imshow(TOF,jet,'XData',[0 size(TOF,2)],'YData',[size(TOF,1) 0]);
imjet.CDataMapping = "scaled";
%% Plot filled contor of TOF
figure; contourf(rawTOF);
%% Plot inflection points
figure; imjet = imshow(int8(~inflectionpts),gray,'XData',[0 size(inflectionpts,2)],'YData',[size(inflectionpts,1) 0]);
imjet.CDataMapping = "scaled";
%% Plot filled contor of inflection points
figure; contourf(inflectionpts,1);
title(strcat("Contour Inflection Points: ",sampleName));
%% Create Mask

% Clean up inflection points
J = bwmorph(inflectionpts,'spur',inf);
J = bwmorph(J,'clean',inf);
J = bwmorph(J,'remove',inf);
J = bwmorph(J,'thin',inf);
% figure; imshow(J,'XData',[0 size(inflectionpts,2)],'YData',[size(inflectionpts,1) 0]);
[B,~] = bwboundaries(J,'noholes');
BW = zeros(size(J));
for i = 1:length(B)
    for j = 1:size(B{i},1)
        BW(B{i}(j,1),B{i}(j,2)) = 1;
    end
end
% figure; imshow(BW,'XData',[0 size(inflectionpts,2)],'YData',[size(inflectionpts,1) 0]);
BW2 = imfill(BW);
% figure; imshow(BW2,'XData',[0 size(inflectionpts,2)],'YData',[size(inflectionpts,1) 0]);
outline = bwperim(BW2,8);
% figure; imshow(outline,'XData',[0 size(inflectionpts,2)],'YData',[size(inflectionpts,1) 0]);

%% Apply mask before
J = inflectionpts;
J = ~J + ~BW2;
% figure; imshow(J,'XData',[0 size(inflectionpts,2)],'YData',[size(inflectionpts,1) 0]);

%% Morphologically operate on image

J = ~J;
J = bwmorph(J,'bridge',inf); % Bridge gaps

% imclose in 2 independent operations using +/- 45 line elements
SEneg45 = strel('line',6,-45);
J1 = imclose(J,SEneg45);
SEpos45 = strel('line',6,45); 
J2 = imclose(J,SEpos45);
J = J1+J2;

J = bwmorph(J,"thin",2); % Remove triangles where 3 lines meet
J = bwmorph(J,"spur",inf); % Remove inf spurs
J = bwmorph(J,"clean",inf); % Remove random pixels

J(numPeaks < 2) = 1;

%% Apply mask after
J = ~J + ~BW2;
J(J>1) = 1;

J = ~J + outline;
J(J>1) = 1;

figure; imjet = imshow(int8(~J),gray,'XData',[0 size(inflectionpts,2)],'YData',[size(inflectionpts,1) 0]);
imjet.CDataMapping = "scaled";

[L,n] = bwlabel(int8(~J),4);

figure; imjet = imshow(L,colorcube,'XData',[0 size(inflectionpts,2)],'YData',[size(inflectionpts,1) 0]);
imjet.CDataMapping = "scaled";

%%
finalTOF = TOF;

for i = 1:n
    [areaI, areaJ] = find(L==i);
    areaInd = sub2ind(size(L),areaI,areaJ);
    finalTOF(areaInd) = mode(round(TOF(areaInd),2),'all');
end

figure; imjet = imshow(finalTOF,jet,'XData',[0 size(finalTOF,2)],'YData',[size(finalTOF,1) 0]);
imjet.CDataMapping = "scaled";