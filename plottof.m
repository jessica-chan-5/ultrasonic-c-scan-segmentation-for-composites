function plottof(filename,outfolder,figfolder,platet,nlayers,res)

% Load raw TOF and associated info
loadvar = ["tof";"cropcoord"];
for i = 1:length(loadvar)
    infile = strcat(outfolder,"\",loadvar(i),"\",filename,'-',...
        loadvar(i),'.mat');
    load(infile,loadvar(i))
end

% Save full size of raw TOF
rowf = size(tof,1); %#ok<NODEF> 
colf = size(tof,2);

% Work with damage bounding box area of raw TOF only
startrow = cropcoord(1);
endrow = cropcoord(2);
startcol = cropcoord(3);
endcol = cropcoord(4);
tof = tof(startrow:endrow,startcol:endcol); 

% Calculate size of raw TOF
row = size(tof,1);
col = size(tof,2);

% Calculate plate properties
basetof = mode((nonzeros(tof)),'all'); % Calculate baseline TOF
matvel = 2*platet/basetof;             % Calculate material velocity
plyt = platet/nlayers;                 % Calculate ply thickness
dttof = plyt/matvel*2;                   % Calculate TOF for each layer

% Calculate bins centered at interface between layers and segment TOF
layerstof = 0:dttof:basetof+dttof;
layerstof(end) = basetof+2*dttof;
segtof = discretize(tof,layerstof);

% Plot and save segmented TOF
fig = figure('visible','off');
implot(fig,segtof,jet,row,col,filename,false);
imsave(figfolder,fig,"segtof",filename,res);

tofvec = reshape(segtof,row*col,1);
tofvec(1,1) = max(tofvec);
tofvec(tofvec==max(tofvec)) = NaN;

xvec = repmat((1:row)',col,1);
yvec = repelem(1:col,row)';

fig = figure('Visible','off');
scatter3(xvec,yvec,tofvec,20,tofvec,'filled'); colormap(gca,'jet');
xlabel('Row #'); ylabel('Col #'); zlabel('TOF (us)');
savefigure(figfolder,fig,"3Dplot",filename);

% Save segmented TOF
savevar = "segtof";
tempsegtof = zeros(rowf,colf);
tempsegtof(startrow:endrow,startcol:endcol) = segtof;
segtof = tempsegtof; %#ok<NASGU> 
outfile = strcat(outfolder,"\",savevar,"\",filename,'-',...
    savevar,'.mat');
save(outfile,savevar,'-mat');

end