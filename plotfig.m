function plotfig(fileName,outFolder,figFolder,plateThick,nLayers,res)

% Load raw TOF and associated info
loadVar = ["tof";"cropcoord"];
for i = 1:length(loadVar)
    inFile = strcat(outFolder,"\",loadVar(i),"\",fileName,'-',...
        loadVar(i),'.mat');
    load(inFile,loadVar(i))
end

% Save full size of raw TOF
rowF = size(tof,1); %#ok<NODEF> 
colF = size(tof,2);

% Work with damage bounding box area of raw TOF only
startRow = cropcoord(1);
endRow = cropcoord(2);
startCol = cropcoord(3);
endCol = cropcoord(4);
tof = tof(startRow:endRow,startCol:endCol); 

% Calculate size of raw TOF
row = size(tof,1);
col = size(tof,2);

% Calculate plate properties
baseTOF = mode((nonzeros(tof)),'all'); % Calculate baseline TOF
matVel = 2*plateThick/baseTOF;             % Calculate material velocity
plyt = plateThick/nLayers;                 % Calculate ply thickness
dtTOF = plyt/matVel*2;                   % Calculate TOF for each layer

% Calculate bins centered at interface between layers and segment TOF
layersTOF = 0:dtTOF:baseTOF+dtTOF;
layersTOF(end) = baseTOF+2*dtTOF;
segTOF = discretize(tof,layersTOF);

% Plot and save segmented TOF
fig = figure('visible','off');
implot(fig,segTOF,jet,row,col,fileName,false);
imsave(figFolder,fig,"segtof",fileName,res);

vecTOF = reshape(segTOF,row*col,1);
vecTOF(1,1) = max(vecTOF);
vecTOF(vecTOF==max(vecTOF)) = NaN;

xVec = repmat((1:row)',col,1);
yVec = repelem(1:col,row)';

fig = figure('Visible','off');
scatter3(xVec,yVec,vecTOF,20,vecTOF,'filled'); colormap(gca,'jet');
xlabel('Row #'); ylabel('Col #'); zlabel('TOF (us)');
savefigure(figFolder,fig,"3Dplot",fileName);

% Save segmented TOF
savevar = "segtof";
tempSegTOF = zeros(rowF,colF);
tempSegTOF(startRow:endRow,startCol:endCol) = segTOF;
segTOF = tempSegTOF; %#ok<NASGU> 
outFile = strcat(outFolder,"\",savevar,"\",fileName,'-',...
    savevar,'.mat');
save(outFile,savevar,'-mat');

end