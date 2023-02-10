function plotcustom(filename,infolder,outfolder,figfolder,utwincrop,dy, ...
    res,test)

% Load raw TOF and associated info
loadvar = ["rawtof";"tof";"cropcoord"];
for i = 1:length(loadvar)
    infile = strcat(outfolder,"\",loadvar(i),"\",filename,'-',...
        loadvar(i),'.mat');
    load(infile,loadvar(i))
end

% Save size of full tof
rowf = size(tof,1); %#ok<NODEF> 
colf = size(tof,2);

% Work with damage bounding box area only
startrow = cropcoord(1);
endrow = cropcoord(2);
startcol = cropcoord(3);
endcol = cropcoord(4);
rawtof = rawtof(startrow:endrow,startcol:endcol); %#ok<NODEF> 
tof = tof(startrow:endrow,startcol:endcol); 
row = size(tof,1);
col = size(tof,2);

infile = strcat(infolder,"\utwin\",filename,'.bmp');
startrowut = utwincrop(1);
endrowut = utwincrop(2);
startcolut = utwincrop(3);
endcolut = utwincrop(4);
rowut = endrowut-startrowut+1; ratiorow = rowut/rowf; 
colut = endcolut-startcolut+1; ratiocol = colut/colf; 
startrow = floor(startrow*ratiorow);
endrow = floor(endrow*ratiorow);
startcol = floor(startcol*ratiocol);
endcol = floor(endcol*ratiocol);
utwin = imread(infile);
utwin = utwin(startrowut:endrowut,startcolut:endcolut,:);
utwin = utwin(startrow+dy:endrow+dy,startcol:endcol,:);

if test == true
    figvis = 'on';
else
    figvis = 'off';
end
% Plot and save raw TOF, TOF, and UTWin images side-by-side
fig = figure('visible',figvis);
subp = subplot(1,3,1); implot(subp,rawtof,jet,row,col,"Raw TOF",true);
subp = subplot(1,3,2); implot(subp,tof,jet,row,col,"TOF",true);
subplot(1,3,3); imshow(utwin); title("UTWin");
if test == true
    axis on;
end
imsave(figfolder,fig,'utwin',filename,res);

end