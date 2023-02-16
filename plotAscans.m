function plotAscans(rowRange,colRange,cscan,t,fileName,minProm1,noiseThresh)

nCol = length(colRange);
nRow = length(rowRange);

figure('WindowState','maximized');
n = 0;
for j = 1:nCol
    for i = 1:nRow
        n = n + 1;
        subplot(nRow,nCol,n);
        point = squeeze(cscan(rowRange(i),colRange(j),:))';
        [p, l] = findpeaks(point,t);
        % Force signal to be zero at beginning and end
        p = [0 p 0]; %#ok<AGROW> 
        l = [0 l t(end)]; %#ok<AGROW> 
        % Fit smoothing spline to found peaks
        fits = fit(l',p','smoothingspline');
        % Evaluate smoothing spline for t
        pFit = feval(fits,t);
        hold on;
        plot(t,point,'Color',[0.5,0.5,0.5]);
        findpeaks(pFit,t,'MinPeakProminence',minProm1,'WidthReference', ...
            'halfheight','Annotate','extents');
        [peak,loc,width,prom] = findpeaks(pFit,t','MinPeakProminence', ...
            minProm1,'WidthReference','halfheight','Annotate','extents');
        peakInfo = table(peak,loc,width,prom);
        figTitle = strcat("Row ",num2str(rowRange(j)), ...
            ", Col ",num2str(colRange(i)),", #",num2str(n));
        disp(figTitle)
        disp(peakInfo)
        plot(t,pFit,'-k','LineWidth',2);
        plot([0,t(end)],[noiseThresh noiseThresh],'--r');
        grid minor
        title(figTitle);
        xlabel('Time (microseconds)');
        ylabel('Magnitude');
        s = findobj('type','legend');
        delete(s)
    end
end

sgtitle(fileName);

end