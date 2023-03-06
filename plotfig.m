function plotfig(fileName,outFolder,figFolder,plateThick,nLayers,fontSize,res)
%PLOTFIG Plot figures
%   PLOTFIG(fileName,outFolder,figFolder,plateThick,nLayers,res) Groups TOF
%   into twice as many damage layer groups as number of layers. Plots and 
%   saves 2D and 3D layer damage plots. Saves damage layer groups.
%
%   Inputs:
%
%   FILENAME  : Name of .mat file to read
%   OUTFOLDER : Folder path to .mat output files
%   FIGFOLDER : Folder path to .fig and .png files
%   PLATETHICK: Thickness of scanned plate in millimeters
%   NLAYERS   : Number of layers in scanned plate
%   RES       : Image resolution setting in dpi for saving image

% Load raw TOF and associated info
loadVar = ["tof";"cropCoord";"mask"];
for i = 1:length(loadVar)
    inFile = strcat(outFolder,"\",loadVar(i),"\",fileName,'-',...
        loadVar(i),'.mat');
    load(inFile,loadVar(i))
end

% Save full size of raw TOF
rowF = size(tof,1); colF = size(tof,2); %#ok<NODEF>

% Work with damage bounding box area of TOF only
startRow = cropCoord(1); endRow = cropCoord(2);
startCol = cropCoord(3); endCol = cropCoord(4);
tof = tof(startRow:endRow,startCol:endCol); 

% Calculate size of raw TOF
rowC = size(tof,1); colC = size(tof,2);

% Calculate plate properties
baseTOF = mode((nonzeros(tof)),'all'); % Calculate baseline TOF
matVel = 2*plateThick/baseTOF;         % Calculate material velocity
plyt = plateThick/nLayers;             % Calculate ply thickness
dtTOF = plyt/matVel;                   % Calculate TOF for each layer

% Calculate bins centered at interface between layers and group into 
% (nLayers+1) damage layers
layersTOF = 0:dtTOF:baseTOF+dtTOF;
layersTOF(end) = baseTOF+2*dtTOF;
damLayers = discretize(tof,layersTOF);

% Remove points outside of boundary mask
damLayers(mask==0) = NaN;

% Plot and save damage layers
fig = figure('visible','off');
implot(fig,damLayers,jet,rowC,colC,' ',0,fontSize); colorbar;
imsave(fileName,figFolder,fig,"damLayers",true,res);

vecDam = reshape(damLayers,rowC*colC,1);
vecDam(1,1) = max(vecDam);
vecDam(vecDam==max(vecDam)) = NaN;
xVec = repmat((1:rowC)',colC,1);
yVec = repelem(1:colC,rowC)';
vecCscan = [xVec, yVec, vecDam];
vecCscan(isnan(vecCscan(:,3)),:) = [];

fig = figure('Visible','off');
plotlayers(vecCscan,fig,'3Dplot',fileName,figFolder,fontSize,res);

% Save damage layers
savevar = "damLayers";
tempDamLayers = zeros(rowF,colF);
tempDamLayers(startRow:endRow,startCol:endCol) = damLayers;
damLayers = tempDamLayers; %#ok<NASGU> 
outFile = strcat(outFolder,"\",savevar,"\",fileName,'-',...
    savevar,'.mat');
save(outFile,savevar,'-mat');

end