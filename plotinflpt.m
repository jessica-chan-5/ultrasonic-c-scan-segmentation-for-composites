function plotinflpt(outFolder,figFolder,fileName)

loadVar = "inflpt";
inFile = strcat(outFolder,"\",loadVar,"\",fileName,'-',...
    loadVar,'.mat');
load(inFile,loadVar);

% Plot inflpt using imshow
r = size(inflpt,1);
c = size(inflpt,2);
fig = figure('visible','on');
modeData = mode(inflpt(inflpt~=0),'all');
im = imshow(inflpt,[0 modeData+0.1]);
im.CDataMapping = "scaled"; axis on;
colormap(gray); hold on;
% Plot inflpt as scatter
infl = reshape(int8(inflpt),r*c,1);
y = repmat((1:r)',c,1);
x = repelem(1:c,r)';
rawTab = table(x,y,infl);
scatter(rawTab,'x','y','filled','ColorVariable','infl');
colormap(gca,'gray');
savefigure(figFolder,fig,'inflpt',fileName);

end