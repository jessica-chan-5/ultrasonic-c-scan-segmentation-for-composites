function implot(fig,data,map,row,col,figTitle,norm,fontSize)
%IMPLOT Plot figure using imshow.
%   IMPLOT(fig,data,map,row,col,figTitle,norm) Plots figure using imshow.
%   Scales x and y direction using provided row and col coordinates. Flips
%   image along x-axis. Normalizes plot with mode of data as highest
%   plotted value if norm is true.
%
%   Inputs:
%
%   FIG     : Figure handle - can be subfigure handle
%   DATA    : Data to be plotted as 2D matrix in [row x col] form
%   MAP     : Colormap to use for figure
%   ROW     : Plots from coordinates [row to 0] for YData
%   COL     : Plots from coordinates [0 to col] for XData
%   FIGTITLE: Title to be used for plot
%   NORM    : If true, sets mode of data as highest value of colormap

if norm == true
    modeData = mode(data(data~=0),'all');
    im = imshow(data,[0 modeData+0.1],'XData',[0 col],'YData',[row 0]);
    colormap(fig,map);
    im.CDataMapping = "scaled";
else
    im = imshow(data,[min(data,[],'all') max(data,[],'all')], ...
        'XData',[0 col],'YData',[row 0]);
    colormap(fig,map);
    im.CDataMapping = "scaled";
end

if strcmp(figTitle,' ') == false
    title(figTitle);
end

ax = gca;
ax.FontSize = fontSize;

end

