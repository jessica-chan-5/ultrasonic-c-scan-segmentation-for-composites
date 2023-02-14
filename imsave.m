function imsave(figFolder,fig,name,fileName,res,barOn)
%IMSAVE Save figure as png and fig.
%    IMSAVE(figFolder,fig,name,fileName,res) saves figure in designated
%    figure folder, using given title, and with specified resolution as png
%    and fig file types
%
%    Inputs:
%
%    FIGFOLDER: Figure subfolder to save files
%    FIG      : Saved figure handle for plot
%    NAME     : Figure subfolder/name of file to be appended
%    FILENAME : Sample name to be inlcuded in name of file
%    RES      : Resolution in dpi to save file

    path = strcat(figFolder,"\",name,"\",fileName,'-',name);
    fig.CreateFcn = 'set(gcf,''visible'',''on'')';
    savefig(fig,strcat(path,'.fig'));
    exportgraphics(fig,strcat(path,'.png'),'Resolution',res);
end