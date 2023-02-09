function implot(fig,data,map,row,col,figtitle,norm)
    if norm == true
        modedata = mode(data(data~=0),'all');
        im = imshow(data,[0 modedata+0.1],'XData',[0 col],'YData',[row 0]);
        im.CDataMapping = "scaled";
        colormap(fig,map);
        title(figtitle);
    else
        im = imshow(data,map,'XData',[0 col],'YData',[row 0]);
        im.CDataMapping = "scaled";
        colormap(fig,map);
        title(figtitle);
    end
end

