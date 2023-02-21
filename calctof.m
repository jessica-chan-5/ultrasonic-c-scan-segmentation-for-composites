function [rawTOF,peak,locs,wide,nPeaks] = calctof(cscan,t,row,col, ...
    minProm1,noiseThresh,maxWidth)
%CALCTOF Calculate TOF.
%   rawtof = CALCTOF(cscan,t,row,col,minprom1,noisethresh,maxwidth)
%   calculates TOF using findpeaks and a smoothing spline fit.
%
%   [rawtof,peak,locs,wide,npeaks] = CALCTOF(cscan,t,row,col,minprom,...
%   noisethresh,maxwidth) calculates TOF and returns additional info about 
%   the peaks including the magnitude, location, whether a peak is wider 
%   than the peak width threshold, and number of peaks at each point.
%
%   Inputs:
%   
%   CSCAN:       C-scan data, in 3D matrix form: [row x col x pts]
%   T:           Time, in vector form: [0:dt:tend], in microseconds
%   ROW:         Range of rows to calculate TOF, in vector form
%   COL:         Range of cols to calculate TOF, in vector form
%   MINPROM1:    Min prominence in findpeaks for a peak to be identified
%   NOISETHRESH: If average signal is lower, then point is not processed
%   MAXWIDTH:    If a peak's width is greater, then it is noted as wide

% Initialize variables
rawTOF = zeros(length(row),length(col));
wide   = zeros(length(row),length(col));
nPeaks = zeros(length(row),length(col));
peak   = cell(length(row),length(col));
locs   = cell(length(row),length(col));

% Loop through each row
for i = 1:length(row)
    % Get row-wise slice of C-scan
    cscanSlice = cscan(row(i),:,:);
    % Loop through each point in the row
    parfor j = 1:length(col)
        % Check that signal at point is not just noise
        if mean(cscanSlice(:,col(j),:)) > noiseThresh %#ok<PFBNS> 
            % Get A-scan at point
            point = squeeze(cscanSlice(:,col(j),:))';

            % Find and save peaks/locations in signal
            [p, l] = findpeaks(point,t);
        
            % Force signal to be zero at beginning and end
            p = [0 p 0];
            l = [0 l t(end)];

            % Fit smoothing spline to found peaks
            fits = fit(l',p','smoothingspline');

            % Evaluate smoothing spline for t
            pFit = feval(fits,t);

            % Find and save locations of peaks
            [peak{i,j}, locs{i,j}, width] = findpeaks(pFit,t, ...
                'MinPeakProminence',minProm1,'WidthReference','halfheight');
            
            % Mark wide peaks
            if length(width) >= 1 && width(1) > maxWidth
                wide(i,j) = true;
            end

            % Count number of peaks
            nPeaks(i,j) = length(peak{i,j});
    
            % Calculate raw TOF
            if nPeaks(i,j) > 1
                [~, loc2i] = max(peak{i,j}(2:end));
                rawTOF(i,j) = locs{i,j}(loc2i+1)-locs{i,j}(1);
            end
        end
    end
end

end