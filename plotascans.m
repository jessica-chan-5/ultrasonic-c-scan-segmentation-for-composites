function [row, col] = plotascans(fileName,outFolder,rowRange,colRange, ...
    dt,minProm1,noiseThresh)
%PLOTASCANS Plot A-scans.
%   [row, col] = PLOTASCANS(fileName,outFolder,rowRange,colRange,dt,...
%   minProm1,noiseThresh) Plots A-scans over requested row and column range
%   and finds peaks. Uses found peaks to fit smoothing spline and plots
%   spline. Plots and displays peak of peaks information.
%
%   Inputs:
%
%   FILENAME:    Name of .mat file to read
%   OUTFOLDER:   Folder path to .mat output files
%   ROWRANGE:    Range of rows to plot A-scans
%   COLRANGE:    Range of columns to plot A-scans
%   DT:          Sampling period in microseconds
%   MINPROM1:    Min prominence in findpeaks for a peak to be identified
%   NOISETHRESH: If the average signal at a point is lower than 
%                noiseThresh, then the point is ignored

% Load variable
loadVar = "cscan";
inFile = strcat(outFolder,"\",loadVar,"\",fileName,'-',...
    loadVar,'.mat');
load(inFile,loadVar);

% Find # data points/A-scan
[row, col, pts] = size(cscan); %#ok<USENS> 

% Create time vector
tend = (pts-1)*dt;
t = 0:dt:tend;

% Find number of rows and columns requested
nCol = length(colRange); nRow = length(rowRange);

% Full screen figure
figure('WindowState','maximized');
n = 0; % subplot counter

for j = 1:nCol
    for i = 1:nRow
        n = n + 1;
        subplot(nRow,nCol,n); hold on;
        point = squeeze(cscan(rowRange(i),colRange(j),:))';
        [p, l] = findpeaks(point,t);

        % Force signal to be zero at beginning and end
        p = [0 p 0]; %#ok<AGROW> 
        l = [0 l t(end)]; %#ok<AGROW> 
        
        % Fit smoothing spline to found peaks
        fits = fit(l',p','smoothingspline');
        
        % Evaluate smoothing spline for t
        pFit = feval(fits,t);
        
        % Plot A-scan
        plot(t,point,'Color',[0.5,0.5,0.5]);
        findpeaks(pFit,t,'MinPeakProminence',minProm1,'WidthReference', ...
            'halfheight','Annotate','extents');
        
        % Find peaks
        [peak,loc,width,prom] = findpeaks(pFit,t','MinPeakProminence', ...
            minProm1,'WidthReference','halfheight','Annotate','extents');

        % Display peak info
        peakInfo = table(peak,loc,width,prom);
        figTitle = strcat("Row ",num2str(rowRange(i)), ...
            ", Col ",num2str(colRange(j)),", #",num2str(n));
        disp(figTitle)
        disp(peakInfo)

        % Plot smoothing spline fit
        plot(t,pFit,'-k','LineWidth',2);
        plot([0,t(end)],[noiseThresh noiseThresh],'--r');

        % Format figure
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