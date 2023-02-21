function mergecscan(fileName,outFolder,figFolder,dx,dy,test,res)
%MERGECSCAN Merge C-scans.
%   MERGECSCAN(fileName,outFolder,figFolder,dx,dy,test,res) user can adjust
%   dx and dy of front side C-scan relative to back side C-scan using the
%   outline of damage. Removes points outside of the outline. Merges front 
%   and back side C-scans, then plots and saves as matrix, png, and fig.
%
%   Inputs:
%
%   FILENAME : Name of .mat file to read
%   OUTFOLDER: Folder path to .mat output files
%   FIGFOLDER: Folder path to .fig and .png files
%   DX       : Amount to move front side scan relative to back horizontally
%              (+) = right, (-) = left
%   DY       : Amount to move front side scan relative to back vertically
%              (+) = up, (-) = down
%   TEST     : If test is true, shows figures
%   RES      : Image resolution setting in dpi for saving image

%#ok<*NASGU>
%#ok<*NODEF> 

% If testing, set testing figures to be visible
if test == true
    figVis = 'on';
else
    figVis = 'off';
end

% Load segmented TOF and associated info for corresponding front and back
loadVar = ["mask","damLayers","cropCoord","bound"];
for i = 1:length(loadVar)
    name = loadVar(i);
    eval(strcat(name,"C = cell(1,2);"));
    inFileF = strcat(outFolder,"\",name,"\",fileName,'-',name,'.mat'); 
    inFileB = strcat(outFolder,"\",name,"\",fileName,'-back-',name,'.mat');
    eval(strcat(name,"C{1} = load(inFileF,name);"));
    eval(strcat(name,"C{1} = ",name,"C{1}.",name,";"));
    eval(strcat(name,"C{2} = load(inFileB,name);"));
    eval(strcat(name,"C{2} = ",name,"C{2}.",name,";"));
end

% Save full size of segmented TOF
rowF = size(damLayersC{1},1); colF = size(damLayersC{1},2);

% Get damage bounding box boundaries
startRowC = [cropCoordC{1}(1) cropCoordC{2}(1)]; %#ok<USENS> 
endRowC = [cropCoordC{1}(2) cropCoordC{2}(2)];
startColC = [cropCoordC{1}(3) cropCoordC{2}(3)];
endColC = [cropCoordC{1}(4) cropCoordC{2}(4)];

% Save boundaries and mask in full size row/col dimensions
tempBoundF(startRowC(1):endRowC(1),startColC(1):endColC(1)) = boundC{1};
boundC{1} = tempBoundF;

tempBoundB= zeros(rowF,colF);
tempBoundB(startRowC(2):endRowC(2),startColC(2):endColC(2)) = boundC{2};
boundC{2} = fliplr(tempBoundB);

tempMaskF = zeros(rowF,colF);
tempMaskF(startRowC(1):endRowC(1),startColC(1):endColC(1)) = maskC{1};
maskC{1} = tempMaskF;

tempMaskB = zeros(rowF,colF);
tempMaskB(startRowC(2):endRowC(2),startColC(2):endColC(2)) = maskC{2};
maskC{2} = fliplr(tempMaskB);

% Max boundary
startRowF = min([cropCoordC{1}(1) cropCoordC{2}(1)]);
endRowF = max([cropCoordC{1}(2) cropCoordC{2}(2)]);
startColF = min([cropCoordC{1}(3) cropCoordC{2}(3)]);
endColF = max([cropCoordC{1}(4) cropCoordC{2}(4)]);

% Use figure to count how many pixels to move, gray is front, white is back
fig = figure('Visible',figVis);
boundF = boundC{1}+boundC{2}.*2;
boundF = boundF(startRowF:endRowF,startColF:endColF);
subplot(1,2,1); im = imshow(boundF,gray);
im.CDataMapping = "scaled"; axis on; title('Initial Check');

% Adjust x and y offset for front TOF
if dx > 0     % right
    boundC{1} = [zeros(rowF,dx) boundC{1}(:,1:colF-dx)];
    damLayersC{1} = [nan(rowF,dx) damLayersC{1}(:,1:colF-dx)];
    maskC{1} = [zeros(rowF,dx) maskC{1}(:,1:colF-dx)];
elseif dx < 0 % left
    dx = abs(dx);
    boundC{1} = [boundC{1}(:,1+dx:colF) zeros(rowF,dx)];
    damLayersC{1} = [damLayersC{1}(:,1+dx:colF) nan(rowF,dx)];
    maskC{1} = [maskC{1}(:,1+dx:colF) zeros(rowF,dx)];
end 
if dy > 0     % up
    boundC{1} = [boundC{1}(1+dy:rowF,:); zeros(dy,colF)];
    damLayersC{1} = [damLayersC{1}(1+dy:rowF,:); nan(dy,colF)];
    maskC{1} = [maskC{1}(1+dy:rowF,:); zeros(dy,colF)];
elseif dy < 0 % down
    dy = abs(dy);
    boundC{1} = [zeros(dy,colF); boundC{1}(1:rowF-dy,:)];
    damLayersC{1} = [nan(dy,colF); damLayersC{1}(1:rowF-dy,:)];
    maskC{1} = [zeros(dy,colF); maskC{1}(1:rowF-dy,:)];
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