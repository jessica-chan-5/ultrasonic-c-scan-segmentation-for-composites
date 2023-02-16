function plottof(outFolder,figFolder,fileName)

loadVar = "rawTOF";
inFile = strcat(outFolder,"\",loadVar,"\",fileName,'-',...
    loadVar,'.mat');
load(inFile,loadVar);

% Plot TOF using imshow
r = size(rawTOF,1);
c = size(rawTOF,2);
fig = figure('visible','on');
modeData = mode(rawTOF(rawTOF~=0),'all');
im = imshow(rawTOF,[0 modeData+0.1]);
im.CDataMapping = "scaled"; axis on;
colormap(jet); hold on;
% Plot TOF as scatter
TOF = reshape(rawTOF,r*c,1);
y = repmat((1:r)',c,1);
x = repelem(1:c,r)';
rawTab = table(x,y,TOF);
scatter(rawTab,'x','y','filled','ColorVariable','TOF');
colormap(gca,'jet');
savefigure(figFolder,fig,'cscan',fileName);

end