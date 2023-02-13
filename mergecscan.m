function mergecscan(filename,outfolder,figfolder,dx,dy,test,res)

if test == true
    figVis = 'on';
else
    figVis = 'off';
end

% Load segmented TOF and associated info for corresponding front and back

name = "mask";
inFileF = strcat(outfolder,"\",name,"\",filename,'-',name,'.mat');
load(inFileF,name);

name = "damLayers";
segTOFC = cell(1,2);
inFileF = strcat(outfolder,"\",name,"\",filename,'-',name,'.mat');
inFileB = strcat(outfolder,"\",name,"\",filename,'-back-',name,'.mat');
segTOFC{1} = load(inFileF,name); segTOFC{1} = segTOFC{1}.segtof;
segTOFC{2} = load(inFileB,name); segTOFC{2} = fliplr(segTOFC{2}.segtof);

name = "cropCoord";
cropCoordC = cell(1,2);
inFileF = strcat(outfolder,"\",name,"\",filename,'-',name,'.mat');
inFileB = strcat(outfolder,"\",name,"\",filename,'-back-',name,'.mat');
cropCoordC{1} = load(inFileF,name); cropCoordC{1} = cropCoordC{1}.cropcoord;
cropCoordC{2} = load(inFileB,name); cropCoordC{2} = cropCoordC{2}.cropcoord;

name = "bound";
boundC = cell(1,2);
inFileF = strcat(outfolder,"\",name,"\",filename,'-',name,'.mat');
inFileB = strcat(outfolder,"\",name,"\",filename,'-back-',name,'.mat');
boundC{1} = load(inFileF,name); boundC{1} = boundC{1}.bound;
boundC{2} = load(inFileB,name); boundC{2} = fliplr(boundC{2}.bound);

% Save full size of segmented TOF
row = size(segTOFC{1},1);
col = size(segTOFC{1},2);

% Get damage bounding box boundaries
startRow = [cropCoordC{1}(1) cropCoordC{2}(1)];
endRowF = [cropCoordC{1}(2) cropCoordC{2}(2)];
startCol = [cropCoordC{1}(3) cropCoordC{2}(3)];
endCol = [cropCoordC{1}(4) cropCoordC{2}(4)];

% Save boundaries and mask in full size row/col dimensions
tempBoundF= zeros(row,col);
tempBoundF(startRow(1):endRowF(1),startCol(1):endCol(1)) = boundC{1};
boundC{1} = tempBoundF;

tempBoundB= zeros(row,col);
tempBoundB(startRow(2):endRowF(2),startCol(2):endCol(2)) = boundC{2};
boundC{2} = tempBoundB;

tempMask = zeros(row,col);
tempMask(startRow(1):endRowF(1),startCol(1):endCol(1)) = mask; %#ok<NODEF> 
mask = tempMask;

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
    segTOFC{1} = [ones(row,dx) segTOFC{1}(:,1:col-dx)];
elseif dx < 0 % left
    dx = abs(dx);
    boundC{1} = [boundC{1}(:,1+dx:col) zeros(row,dx)];
    segTOFC{1} = [segTOFC{1}(:,1+dx:col) ones(row,dx)];
end 
if dy > 0     % up
    boundC{1} = [boundC{1}(1+dy:row,:); zeros(dy,col)];
    segTOFC{1} = [segTOFC{1}(1+dy:row,:); ones(dy,col)];
elseif dy < 0 % down
    dy = abs(dy);
    boundC{1} = [zeros(dy,col); boundC{1}(1:row-dy,:)];
    segTOFC{1} = [ones(dy,col); segTOFC{1}(1:row-dy,:)];
end

% Replot to check if correct
boundF = boundC{1}+boundC{2}.*2;
boundF = boundF(startRowF:endRowf,startColF:endColF);
subplot(1,2,2); im = imshow(boundF,gray);
im.CDataMapping = "scaled"; axis on; title('Final Check');
imsave(figfolder,fig,"mergeCheck",filename,res);

% Remove points if outside boundary
segTOFC{1}(mask==0) = NaN;
segTOFC{2}(mask==0) = NaN;

% Flip layers top to bottom for back TOF
segTOFC{2} = abs(segTOFC{2}-max(segTOFC{2})-1);

% Use mask to remove exterior points

% Save seg TOF inside of max boundary
segTOFC{1} = segTOFC{1}(startRowF:endRowf,startColF:endColF);
segTOFC{2} = segTOFC{2}(startRowF:endRowf,startColF:endColF);
rowC = size(segTOFC{1},1);
colC = size(segTOFC{1},2);

% 3D plot TOF front
segTOFVec = cell(1,2);
segTOFVec{1} = reshape(segTOFC{1},rowC*colC,1);
segTOFVec{1}(1,1) = max(segTOFVec{1});

segTOFVec{2} = reshape(segTOFC{2},rowC*colC,1);
segTOFVec{2}(1,1) = max(segTOFVec{2});

xVec = repmat((1:rowC)',colC,1);
yVec = repelem(1:colC,rowC)';

fig = figure('Visible','off'); hold on;
scatter3(xVec,yVec,segTOFVec{1},20,segTOFVec{1},'filled'); colormap(gca,'jet');
scatter3(xVec,yVec,segTOFVec{2},20,segTOFVec{2},'filled'); colormap(gca,'jet');
xlabel('Row #'); ylabel('Col #'); zlabel('TOF (us)'); grid on;
savefigure(figfolder,fig,"hybridCscan",filename);

% Save merged TOF

end