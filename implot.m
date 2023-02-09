function implot(data,colormap,row,col,figtitle)
    im = imshow(data,colormap,'XData',[0 col],'YData',[row 0]);
    im.CDataMapping = "scaled"; title(figtitle); 
end