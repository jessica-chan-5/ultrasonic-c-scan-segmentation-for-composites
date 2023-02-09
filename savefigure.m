function savefigure(figfolder,fig,name,filename)
    path = strcat(figfolder,"\",name,"\",filename,'-',name);
    fig.CreateFcn = 'set(gcf,''visible'',''on'')';
    savefig(fig,strcat(path,'.fig'));
end