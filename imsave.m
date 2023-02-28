function imsave(fileName,figFolder,fig,name,fullScreen,res)
%IMSAVE Save figure as png and fig.
%   IMSAVE(fileName,figFolder,fig,name,fullScreen,res) Saves figure and
%   sets to fullscreen size if fullScreen is true.
%
%   Inputs:
%
%   FIGFOLDER: Figure subfolder to save files
%   FIG      : Figure handle
%   NAME     : Title and file name for figure
%   FILENAME : Name of .mat file to read
%   RES      : Image resolution setting in dpi for saving image

% Set to full screen
if fullScreen == 1
    screensize = get(groot,'Screensize');
    fig.Position = [1 1 screensize(3) floor(screensize(4)*0.86)];
elseif fullScreen == 0.5
    screensize = get(groot,'Screensize');
    fig.Position = [1 1 floor(screensize(3)*0.5) floor(screensize(4)*0.86)];
end
% Save figure
    path = strcat(figFolder,"\",name,"\",fileName,'-',name);
    fig.CreateFcn = 'set(gcf,''visible'',''on'')';
    savefig(fig,strcat(path,'.fig'));
    exportgraphics(fig,strcat(path,'.png'),'Resolution',res);
end