function mergetof(filename,outfolder,figfolder,dx,dy,test,res)

if test == true
    figvis = 'on';
else
    figvis = 'off';
end

% Load segmented TOF and associated info for corresponding front and back

name = "mask";
infilef = strcat(outfolder,"\",name,"\",filename,'-',name,'.mat');
load(infilef,name);

name = "segtof";
segtofc = cell(1,2);
infilef = strcat(outfolder,"\",name,"\",filename,'-',name,'.mat');
infileb = strcat(outfolder,"\",name,"\",filename,'-back-',name,'.mat');
segtofc{1} = load(infilef,name); segtofc{1} = segtofc{1}.segtof;
segtofc{2} = load(infileb,name); segtofc{2} = fliplr(segtofc{2}.segtof);

name = "cropcoord";
cropcoordc = cell(1,2);
infilef = strcat(outfolder,"\",name,"\",filename,'-',name,'.mat');
infileb = strcat(outfolder,"\",name,"\",filename,'-back-',name,'.mat');
cropcoordc{1} = load(infilef,name); cropcoordc{1} = cropcoordc{1}.cropcoord;
cropcoordc{2} = load(infileb,name); cropcoordc{2} = cropcoordc{2}.cropcoord;

name = "bound";
boundc = cell(1,2);
infilef = strcat(outfolder,"\",name,"\",filename,'-',name,'.mat');
infileb = strcat(outfolder,"\",name,"\",filename,'-back-',name,'.mat');
boundc{1} = load(infilef,name); boundc{1} = boundc{1}.bound;
boundc{2} = load(infileb,name); boundc{2} = fliplr(boundc{2}.bound);

% Save full size of segmented TOF
row = size(segtofc{1},1);
col = size(segtofc{1},2);

% Get damage bounding box boundaries
startrow = [cropcoordc{1}(1) cropcoordc{2}(1)];
endrow = [cropcoordc{1}(2) cropcoordc{2}(2)];
startcol = [cropcoordc{1}(3) cropcoordc{2}(3)];
endcol = [cropcoordc{1}(4) cropcoordc{2}(4)];

% Save boundaries and mask in full size row/col dimensions
tempboundf= zeros(row,col);
tempboundf(startrow(1):endrow(1),startcol(1):endcol(1)) = boundc{1};
boundc{1} = tempboundf;

tempboundb= zeros(row,col);
tempboundb(startrow(2):endrow(2),startcol(2):endcol(2)) = boundc{2};
boundc{2} = tempboundb;

tempmask = zeros(row,col);
tempmask(startrow(1):endrow(1),startcol(1):endcol(1)) = mask;
mask = tempmask;

% Max boundary
startrowf = min([cropcoordc{1}(1) cropcoordc{2}(1)]);
endrowf = max([cropcoordc{1}(2) cropcoordc{2}(2)]);
startcolf = min([cropcoordc{1}(3) cropcoordc{2}(3)]);
endcolf = max([cropcoordc{1}(4) cropcoordc{2}(4)]);

% Save figure to count how many pixels to move
% Grayer is front, whiter is back
fig = figure('Visible',figvis);
boundf = boundc{1}+boundc{2}.*2;
boundf = boundf(startrowf:endrowf,startcolf:endcolf);
subplot(1,2,1); im = imshow(boundf,gray);
im.CDataMapping = "scaled"; axis on; title('Initial Check');

% Adjust x and y offset for front TOF
if dx > 0     % right
    boundc{1} = [zeros(row,dx) boundc{1}(:,1:col-dx)];
    segtofc{1} = [ones(row,dx) segtofc{1}(:,1:col-dx)];
elseif dx < 0 % left
    dx = abs(dx);
    boundc{1} = [boundc{1}(:,1+dx:col) zeros(row,dx)];
    segtofc{1} = [segtofc{1}(:,1+dx:col) ones(row,dx)];
end 
if dy > 0     % up
    boundc{1} = [boundc{1}(1+dy:row,:); zeros(dy,col)];
    segtofc{1} = [segtofc{1}(1+dy:row,:); ones(dy,col)];
elseif dy < 0 % down
    dy = abs(dy);
    boundc{1} = [zeros(dy,col); boundc{1}(1:row-dy,:)];
    segtofc{1} = [ones(dy,col); segtofc{1}(1:row-dy,:)];
end

% Replot to check if correct
boundf = boundc{1}+boundc{2}.*2;
boundf = boundf(startrowf:endrowf,startcolf:endcolf);
subplot(1,2,2); im = imshow(boundf,gray);
im.CDataMapping = "scaled"; axis on; title('Final Check');
imsave(figfolder,fig,"mergecheck",filename,res);

% Remove points if outside boundary
segtofc{1}(mask==0) = NaN;
segtofc{2}(mask==0) = NaN;

% Flip layers top to bottom for back TOF
segtofc{2} = abs(segtofc{2}-max(segtofc{2})-1);

% Use mask to remove exterior points

% Save seg TOF inside of max boundary
segtofc{1} = segtofc{1}(startrowf:endrowf,startcolf:endcolf);
segtofc{2} = segtofc{2}(startrowf:endrowf,startcolf:endcolf);
rowc = size(segtofc{1},1);
colc = size(segtofc{1},2);

% 3D plot TOF front
segtofvec = cell(1,2);
segtofvec{1} = reshape(segtofc{1},rowc*colc,1);
segtofvec{1}(1,1) = max(segtofvec{1});

segtofvec{2} = reshape(segtofc{2},rowc*colc,1);
segtofvec{2}(1,1) = max(segtofvec{2});

xvec = repmat((1:rowc)',colc,1);
yvec = repelem(1:colc,rowc)';

fig = figure('Visible','off'); hold on;
scatter3(xvec,yvec,segtofvec{1},20,segtofvec{1},'filled'); colormap(gca,'jet');
scatter3(xvec,yvec,segtofvec{2},20,segtofvec{2},'filled'); colormap(gca,'jet');
xlabel('Row #'); ylabel('Col #'); zlabel('TOF (us)'); grid on;
savefigure(figfolder,fig,"hybridcscan",filename);

% Save merged TOF

end