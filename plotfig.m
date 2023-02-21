function plotfig(fileName,outFolder,figFolder,plateThick,nLayers,res)
%PLOTFIG Plot figures
%    PLOTFIG(fileName,outFolder,figFolder,plateThick,nLayers,res) Plots 
%    and saves 2D/3D layer damage plots as png and fig files at designated
%    resolution res and in given folder figFolder
% 
%    Inputs:
% 
%    FILENAME  : Name of sample, same as readcscan
%    OUTFOLDER : Folder path to .mat output files
%    FIGFOLDER : Folder path to .fig and .png files
%    PLATETHICK: Thickness of scanned plate in millimeters
%    NLAYERS   : Number of layers in scanned plate
%    RES       : Image resolution setting in dpi

% Load raw TOF and associated info
loadVar = ["tof";"cropCoord";"mask"];
for i = 1:length(loadVar)
    inFile = strcat(outFolder,"\",loadVar(i),"\",fileName,'-',...
        loadVar(i),'.mat');
    load(inFile,loadVar(i))
end

% Save full size of raw TOF
rowF = size(tof,1); %#ok<NODEF> 
colF = size(tof,2);

% Work with damage bounding box area of raw TOF only
startRow = cropCoord(1);
endRow = cropCoord(2);
startCol = cropCoord(3);
endCol = cropCoord(4);
tof = tof(startRow:endRow,startCol:endCol); 

% Calculate size of raw TOF
row = size(tof,1);
col = size(tof,2);

% Calculate plate properties
baseTOF = mode((nonzeros(tof)),'all'); % Calculate baseline TOF
matVel = 2*plateThick/baseTOF;         % Calculate material velocity
plyt = plateThick/nLayers;             % Calculate ply thickness
dtTOF = plyt/matVel;                 % Calculate TOF for each layer

% Calculate bins centered at interface between layers and group into 
% (nLayers+1) damage layers
layersTOF = 0:dtTOF:baseTOF+dtTOF;
layersTOF(end) = baseTOF+2*dtTOF;
damLayers = discretize(tof,layersTOF);
damLayers(mask==0) = NaN;

% Plot and save damage layers
fig = figure('visible','off');
implot(fig,damLayers,jet,row,col,fileName,false);
imsave(figFolder,fig,"damLayers",fileName,true,res);

vecDam = reshape(damLayers,row*col,1);
vecDam(1,1) = max(vecDam);
vecDam(vecDam==max(vecDam)) = NaN;

xVec = repmat((1:row)',col,1);
yVec = repelem(1:col,row)';

fig = figure('Visible','off');
scatter3(xVec,yVec,vecDam,20,vecDam,'filled'); colormap(gca,'jet');
xlabel('Row #'); ylabel('Col #'); zlabel('Layer #');
imsave(figFolder,fig,"3Dplot",fileName,false,res);

% Save damage layers
savevar = "damLayers";
tempDamLayers = zeros(rowF,colF);
tempDamLayers(startRow:endRow,startCol:endCol) = damLayers;
damLayers = tempDamLayers; %#ok<NASGU> 
outFile = strcat(outFolder,"\",savevar,"\",fileName,'-',...
    savevar,'.mat');
save(outFile,savevar,'-mat');

end