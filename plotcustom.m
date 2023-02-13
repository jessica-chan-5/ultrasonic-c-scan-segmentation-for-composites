function plotcustom(filename,infolder,outfolder,figfolder,utwincrop,dy, ...
    res,test)

% Load raw TOF and associated info
loadVar = ["rawtof";"tof";"cropcoord"];
for i = 1:length(loadVar)
    inFile = strcat(outfolder,"\",loadVar(i),"\",filename,'-',...
        loadVar(i),'.mat');
    load(inFile,loadVar(i))
end

% Save size of full tof
rowF = size(tof,1); %#ok<NODEF> 
colF = size(tof,2);

% Work with damage bounding box area only
startRow = cropcoord(1);
endRow = cropcoord(2);
startCol = cropcoord(3);
endCol = cropcoord(4);
rawTOF = rawTOF(startRow:endRow,startCol:endCol); %#ok<NODEF> 
tof = tof(startRow:endRow,startCol:endCol); 
row = size(tof,1);
col = size(tof,2);

inFile = strcat(infolder,"\utwin\",filename,'.bmp');
startRowUT = utwincrop(1);
endRowUT = utwincrop(2);
startColUT = utwincrop(3);
endColUT = utwincrop(4);
rowUT = endRowUT-startRowUT+1; ratiorow = rowUT/rowF; 
colUT = endColUT-startColUT+1; ratiocol = colUT/colF; 
startRow = floor(startRow*ratiorow);
endRow = floor(endRow*ratiorow);
startCol = floor(startCol*ratiocol);
endCol = floor(endCol*ratiocol);
utwin = imread(inFile);
utwin = utwin(startRowUT:endRowUT,startColUT:endColUT,:);
utwin = utwin(startRow+dy:endRow+dy,startCol:endCol,:);

if test == true
    figVis = 'on';
else
    figVis = 'off';
end
% Plot and save raw TOF, TOF, and UTWin images side-by-side
fig = figure('visible',figVis);
subp = subplot(1,3,1); implot(subp,rawTOF,jet,row,col,"Raw TOF",true);
subp = subplot(1,3,2); implot(subp,tof,jet,row,col,"TOF",true);
subplot(1,3,3); imshow(utwin); title("UTWin");
if test == true
    axis on;
end
imsave(figfolder,fig,'utwin',filename,res);

end