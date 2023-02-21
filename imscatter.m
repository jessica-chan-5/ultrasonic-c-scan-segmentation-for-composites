function imscatter(fig,figFolder,fileName,name,data,map)
%IMSCATTER Plot rawTOF as scatter + imshow

% Use imshow
modeData = mode(data(data~=0),'all');
im = imshow(data,[0 modeData+0.1]);
im.CDataMapping = "scaled";
colormap(map); hold on;

% Use scatter
row = size(data,1);
col = size(data,2);
dataVec = reshape(data,row*col,1);
y = repmat((1:row)',col,1);
x = repelem(1:col,row)';
dataTab = table(x,y,dataVec);
scatter(dataTab,'x','y','filled','ColorVariable','dataVec');
colormap(gca,map);
title(fileName);

% Save figure
if strcmp(name,' ') == false
    savefigure(figFolder,fig,name,fileName)
end

end