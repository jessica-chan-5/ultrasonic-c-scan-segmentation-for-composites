function plotlayers(hybridCscan,fig,name,fileName,figFolder,fontSize,res)
    xval = hybridCscan(:,1);
    yval = hybridCscan(:,2);
    cscanval = hybridCscan(:,3);
    
    endx = max(hybridCscan(:,1));
    endy = max(hybridCscan(:,2));    
    
    numlayers = max(cscanval);
    
    cscan3d = ones(endy,endx,numlayers)*0.02;
    cscancell = cell(1,numlayers);
    
    for i = 1:length(cscanval)
        cscan3d(yval(i),xval(i),cscanval(i)) = 1;
    end
    
    c = colormap(jet(numlayers));
    
    for i = 1:numlayers
        cscancell{i} = ones(endy,endx,3);
        for j = 1:endy
            for k = 1:endx
                cscancell{i}(j,k,:) = c(i,:);
            end
        end
    end
    
    xIm = [1 endx; 1 endx];
    yIm = [1 1; endy endy];
    
    hold on;

    for i = 1:max(cscanval)
        zIm = [i i; i i];
        surf(xIm,yIm,zIm,'CData',cscancell{i}, ...
            'FaceColor','texturemap', ...
            'EdgeColor','none', ...
            'FaceAlpha','texturemap', ...
            'AlphaData',cscan3d(:,:,i), ...
            'AlphaDataMapping','none');
    end
    view(3);
    ax = gca; ax.FontSize = fontSize;
    set(ax,'Ydir','reverse','Zdir','reverse')
    xlabel('Row'); ylabel('Col'); zlabel('Damage group');

    if strcmp(name,' ') == false
        title(fileName); ax = gca; ax.FontSize = fontSize;
        imsave(fileName,figFolder,fig,name,0.5,res);
    end
end