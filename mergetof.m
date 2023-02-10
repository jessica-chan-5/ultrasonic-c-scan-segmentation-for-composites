function mergetof(filename,outfolder,figfolder,dx,dy,test,res)

if test == true
    figvis = 'on';
else
    figvis = 'off';
end

% Load segmented TOF and associated info for corresponding front and back

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
rowf = [size(segtofc{1},1) size(segtofc{2},1)];
colf = [size(segtofc{1},2) size(segtofc{2},2)];

% Get damage bounding box boundaries
startrow = [cropcoordc{1}(1) cropcoordc{2}(1)];
endrow = [cropcoordc{1}(2) cropcoordc{2}(2)];
startcol = [cropcoordc{1}(3) cropcoordc{2}(3)];
endcol = [cropcoordc{1}(4) cropcoordc{2}(4)];

% Save boundaries in full size row/col dimensions
tempboundf= zeros(rowf(1),colf(1));
tempboundf(startrow(1):endrow(1),startcol(1):endcol(1)) = boundc{1};
boundc{1} = tempboundf;

tempboundb= zeros(rowf(2),colf(2));
tempboundb(startrow(2):endrow(2),startcol(2):endcol(2)) = boundc{2};
boundc{2} = tempboundb;

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
    boundc{1} = [zeros(rowf(1),dx) boundc{1}(:,1:colf(1)-dx)];
    segtofc{1} = [zeros(rowf(1),dx) segtofc{1}(:,1:colf(1)-dx)];
elseif dx < 0 % left
    dx = abs(dx);
    segtofc{1} = [segtofc{1}(:,1+dx:colf(1)) zeros(rowf(1),dx)];
end 
if dy > 0     % up
    boundc{1} = [boundc{1}(1+dy:rowf(1),:); zeros(dy,colf(1))];
    segtofc{1} = [segtofc{1}(1+dy:rowf(1),:); zeros(dy,colf(1))];
elseif dy < 0 % down
    dy = abs(dy);
    boundc{1} = [zeros(dy,colf(1)); boundc{1}(1:rowf(1)-dy,:)];
    segtofc{1} = [zeros(dy,colf(1)); segtofc{1}(1:rowf(1)-dy,:)];
end

% Replot to check if correct
boundf = boundc{1}+boundc{2}.*2;
boundf = boundf(startrowf:endrowf,startcolf:endcolf);
subplot(1,2,2); im = imshow(boundf,gray);
im.CDataMapping = "scaled"; axis on; title('Final Check');
imsave(figfolder,fig,"mergecheck",filename,res);

% Flip layers top to bottom for back TOF
segtofc{2} = abs(segtofc{2}-max(segtofc{2})-1);

% Merge TOF
% Write code that checks if one or the other is equal to zero, otherwise
% don't add, just pick one
mergetof = mergetof(startrowf:endrowf,startcolf:endcolf);
row = size(mergetof,1);
col = size(mergetof,2);

% 3D plot merged TOF
mergetofvec = reshape(mergetof,row*col,1);
mergetofvec(1,1) = max(mergetofvec);
mergetofvec(mergetofvec==max(mergetofvec)) = NaN;

xvec = repmat((1:row)',col,1);
yvec = repelem(1:col,row)';

fig = figure('Visible','off');
scatter3(xvec,yvec,mergetofvec,20,mergetofvec,'filled'); colormap(gca,'jet');
xlabel('Row #'); ylabel('Col #'); zlabel('TOF (us)');
savefigure(figfolder,fig,"3Dplot",filename);

% Save merged TOF

end