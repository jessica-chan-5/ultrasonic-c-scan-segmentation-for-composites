function imscatter(fileName,figFolder,fig,name,data,map)
%IMSCATTER Plot queryable figure.
%   IMSCATTER(fileName,figFolder,fig,name,data,map) Plot and save a 
%   queryable figure using the combination of imshow and scatter.
%
%   Inputs:
%
%   FIG:       Figure handle
%   FIGFOLDER: Folder path to .fig and .png files
%   FILENAME:  Name of .mat file to read
%   NAME:      Title and file name for figure - if equal to ' ', don't save
%   DATA:      Data to be plotted in 2D matrix form
%   MAP:       Colormap to use for figure

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
axis on;

% Save figure
if strcmp(name,' ') == false
    path = strcat(figFolder,"\",name,"\",fileName,'-',name);
    fig.CreateFcn = 'set(gcf,''visible'',''on'')';
    savefig(fig,strcat(path,'.fig'));
end

end