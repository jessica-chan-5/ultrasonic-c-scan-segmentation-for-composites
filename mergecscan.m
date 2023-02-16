function mergecscan(fileName,outFolder,figFolder,dx,dy,test,res)
%MERGECSCAN Merge hybrid C-scan
%
%   MERGECSCAN(fileName,outFolder,figFolder,dx,dy,test,res) user can adjust
%   dx and dy of front side C-scan relative to back side C-scan using the
%   boundary of damage calculated in segcscan. removes points outside of 
%   the mask calculated in segcsan. Merges front and back side C-scans, 
%   then plots and saves as matrix, png, and fig.
%
%   Inputs:
%
%   FILENAME : Name of sample, same as readcscan
%   OUTFOLDER: Folder path to .mat output files
%   FIGFOLDER: Folder path to .fig and .png files
%   DX       : Amount to adjust front side scan (+) = right, (-) = left
%   DY       : Amount to adjust front side scan (+) = up, (-) = down
%   TEST     : If test is true, shows figures
%   RES      : Image resolution setting in dpi

if test == true
    figVis = 'on';
else
    figVis = 'off';
end

% Load segmented TOF and associated info for corresponding front and back

name = "mask";
maskC = cell(1,2);
inFileF = strcat(outFolder,"\",name,"\",fileName,'-',name,'.mat');
inFileB = strcat(outFolder,"\",name,"\",fileName,'-back-',name,'.mat');
maskC{1} = load(inFileF,name);
maskC{1} = maskC{1}.mask;
maskC{2} = load(inFileB,name);
maskC{2} = maskC{2}.mask;

name = "damLayers";
damLayersC = cell(1,2);
inFileF = strcat(outFolder,"\",name,"\",fileName,'-',name,'.mat');
inFileB = strcat(outFolder,"\",name,"\",fileName,'-back-',name,'.mat');
damLayersC{1} = load(inFileF,name);
damLayersC{1} = damLayersC{1}.damLayers;
damLayersC{2} = load(inFileB,name);
damLayersC{2} = fliplr(damLayersC{2}.damLayers);

name = "cropCoord";
cropCoordC = cell(1,2);
inFileF = strcat(outFolder,"\",name,"\",fileName,'-',name,'.mat');
inFileB = strcat(outFolder,"\",name,"\",fileName,'-back-',name,'.mat');
cropCoordC{1} = load(inFileF,name); 
cropCoordC{1} = cropCoordC{1}.cropCoord;
cropCoordC{2} = load(inFileB,name); 
cropCoordC{2} = cropCoordC{2}.cropCoord;

name = "bound";
boundC = cell(1,2);
inFileF = strcat(outFolder,"\",name,"\",fileName,'-',name,'.mat');
inFileB = strcat(outFolder,"\",name,"\",fileName,'-back-',name,'.mat');
boundC{1} = load(inFileF,name); boundC{1} = boundC{1}.bound;
boundC{2} = load(inFileB,name); boundC{2} = boundC{2}.bound;

% Save full size of segmented TOF
row = size(damLayersC{1},1);
col = size(damLayersC{1},2);

% Get damage bounding box boundaries
startRow = [cropCoordC{1}(1) cropCoordC{2}(1)];
endRow = [cropCoordC{1}(2) cropCoordC{2}(2)];
startCol = [cropCoordC{1}(3) cropCoordC{2}(3)];
endCol = [cropCoordC{1}(4) cropCoordC{2}(4)];

% Save boundaries and mask in full size row/col dimensions
tempBoundF= zeros(row,col);
tempBoundF(startRow(1):endRow(1),startCol(1):endCol(1)) = boundC{1};
boundC{1} = tempBoundF;

tempBoundB= zeros(row,col);
tempBoundB(startRow(2):endRow(2),startCol(2):endCol(2)) = boundC{2};
boundC{2} = fliplr(tempBoundB);

tempMaskF = zeros(row,col);
tempMaskF(startRow(1):endRow(1),startCol(1):endCol(1)) = maskC{1};
maskC{1} = tempMaskF;

tempMaskB = zeros(row,col);
tempMaskB(startRow(2):endRow(2),startCol(2):endCol(2)) = maskC{2};
maskC{2} = fliplr(tempMaskB);

% Max boundary
startRowF = min([cropCoordC{1}(1) cropCoordC{2}(1)]);
endRowF = max([cropCoordC{1}(2) cropCoordC{2}(2)]);
startColF = min([cropCoordC{1}(3) cropCoordC{2}(3)]);
endColF = max([cropCoordC{1}(4) cropCoordC{2}(4)]);

% Save figure to count how many pixels to move
% Grayer is front, whiter is back
fig = figure('Visible',figVis);
boundF = boundC{1}+boundC{2}.*2;
boundF = boundF(startRowF:endRowF,startColF:endColF);
subplot(1,2,1); im = imshow(boundF,gray);
im.CDataMapping = "scaled"; axis on; title('Initial Check');

% Adjust x and y offset for front TOF
if dx > 0     % right
    boundC{1} = [zeros(row,dx) boundC{1}(:,1:col-dx)];
    damLayersC{1} = [nan(row,dx) damLayersC{1}(:,1:col-dx)];
    maskC{1} = [zeros(row,dx) maskC{1}(:,1:col-dx)];
elseif dx < 0 % left
    dx = abs(dx);
    boundC{1} = [boundC{1}(:,1+dx:col) zeros(row,dx)];
    damLayersC{1} = [damLayersC{1}(:,1+dx:col) nan(row,dx)];
    maskC{1} = [maskC{1}(:,1+dx:col) zeros(row,dx)];
end 
if dy > 0     % up
    boundC{1} = [boundC{1}(1+dy:row,:); zeros(dy,col)];
    damLayersC{1} = [damLayersC{1}(1+dy:row,:); nan(dy,col)];
    maskC{1} = [maskC{1}(1+dy:row,:); zeros(dy,col)];
elseif dy < 0 % down
    dy = abs(dy);
    boundC{1} = [zeros(dy,col); boundC{1}(1:row-dy,:)];
    damLayersC{1} = [nan(dy,col); damLayersC{1}(1:row-dy,:)];
    maskC{1} = [zeros(dy,col); maskC{1}(1:row-dy,:)];
end

% Replot to check if correct
boundF = boundC{1}+boundC{2}.*2;
boundF = boundF(startRowF:endRowF,startColF:endColF);
subplot(1,2,2); im = imshow(boundF,gray);
im.CDataMapping = "scaled"; axis on; title('Final Check');
imsave(figFolder,fig,"mergeCheck",fileName,true,res);

% Remove points if outside boundary
damLayersC{1}(maskC{1}==0) = NaN;
damLayersC{2}(maskC{2}==0) = NaN;

% Save seg TOF inside of max boundary
damLayersC{1} = damLayersC{1}(startRowF:endRowF,startColF:endColF);
damLayersC{2} = damLayersC{2}(startRowF:endRowF,startColF:endColF);

rowF = size(damLayersC{1},1);
colF = size(damLayersC{1},2);

% 3D plot TOF front
damLayersVec = cell(1,2);
damLayersVec{1} = reshape(damLayersC{1},rowF*colF,1);
damLayersVec{2} = reshape(damLayersC{2},rowF*colF,1);
xVec = repmat((1:rowF)',colF,1);
yVec = repelem(1:colF,rowF)';

% Flip layers top to bottom for back TOF
damLayersVec{2} = abs(damLayersVec{2}-max(damLayersVec{2})-1);

hybridCscan = sortrows([[xVec; xVec],[yVec; yVec], ...
    [damLayersVec{1};damLayersVec{2}]]);
hybridCscan(isnan(hybridCscan(:,3)),:) = [];

% Plot hybrid C-scan
fig = figure('Visible','off'); hold on;
scatter3(hybridCscan(:,1),hybridCscan(:,2),hybridCscan(:,3), ...
    20,hybridCscan(:,3),'filled'); colormap(gca,'jet');
xlabel('Row #'); ylabel('Col #'); zlabel('Z depth'); grid on;
view(3);
imsave(figFolder,fig,"hybridCscan",fileName,false,res);

% Plot front, back, hybrid C-scan
fig = figure('Visible','off'); hold on;
subplot(1,3,1);
scatter3(xVec,yVec,damLayersVec{1}, ...
    20,damLayersVec{1},'filled'); colormap(gca,'jet');
xlabel('Row #'); ylabel('Col #'); zlabel('Z depth'); grid on;
view(3); title('Front');
subplot(1,3,2);
scatter3(xVec,yVec,damLayersVec{2}, ...
    20,damLayersVec{2},'filled'); colormap(gca,'jet');
xlabel('Row #'); ylabel('Col #'); zlabel('Z depth'); grid on;
view(3); title('Back');
subplot(1,3,3);
scatter3(hybridCscan(:,1),hybridCscan(:,2),hybridCscan(:,3), ...
    20,hybridCscan(:,3),'filled'); colormap(gca,'jet');
xlabel('Row #'); ylabel('Col #'); zlabel('Z depth'); grid on;
view(3); title('Hybrid')
sgtitle(fileName);
imsave(figFolder,fig,"frontBackHybrid",fileName,true,res);

% Save merged damage layers
name = "hybridCscan";
outfile = strcat(outFolder,"\",name,"\",fileName,'-',...
    name,'.mat');
save(outfile,name,'-mat');

end