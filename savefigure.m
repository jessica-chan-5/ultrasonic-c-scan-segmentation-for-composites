function savefigure(figFolder,fig,name,fileName)
%SAVEFIGURE Save figure as png and fig.
%    SAVEFIGURE(figFolder,fig,name,fileName) saves figure in designated
%    figure folder, using given title, and with specified resolution.
%
%    Inputs:
%
%    FIGFOLDER: Figure subfolder to save files
%    FIG      : Saved figure handle for plot
%    NAME     : Figure subfolder/name of file to be appended
%    FILENAME : Sample name to be inlcuded in name of file

path = strcat(figFolder,"\",name,"\",fileName,'-',name);
    fig.CreateFcn = 'set(gcf,''visible'',''on'')';
    savefig(fig,strcat(path,'.fig'));
end