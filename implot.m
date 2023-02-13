function implot(fig,data,map,row,col,figTitle,norm)
    if norm == true
        modeData = mode(data(data~=0),'all');
        im = imshow(data,[0 modeData+0.1],'XData',[0 col],'YData',[row 0]);
        im.CDataMapping = "scaled";
        colormap(fig,map);
        title(figTitle);
    else
        im = imshow(data,map,'XData',[0 col],'YData',[row 0]);
        im.CDataMapping = "scaled";
        colormap(fig,map);
        title(figTitle);
    end
end

