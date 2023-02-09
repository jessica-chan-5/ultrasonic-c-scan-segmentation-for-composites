function imsave(figfolder,fig,name,filename,res)
    path = strcat(figfolder,"\",name,"\",filename,'-',name);
    fig.CreateFcn = 'set(gcf,''visible'',''on'')';
    savefig(fig,strcat(path,'.fig'));
    exportgraphics(fig,strcat(path,'.png'),'Resolution',res);
end