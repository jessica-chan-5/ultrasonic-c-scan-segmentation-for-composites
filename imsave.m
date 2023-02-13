function imsave(figFolder,fig,name,fileName,res)
    path = strcat(figFolder,"\",name,"\",fileName,'-',name);
    fig.CreateFcn = 'set(gcf,''visible'',''on'')';
    savefig(fig,strcat(path,'.fig'));
    exportgraphics(fig,strcat(path,'.png'),'Resolution',res);
end