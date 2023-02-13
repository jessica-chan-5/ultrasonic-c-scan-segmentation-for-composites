function [rawTOF,peak,locs,wide,nPeaks] = calctof(cscan,t,row,col, ...
    minProm,noiseThresh,maxWidth)
%CALCTOF Calculate time-of-flight.
%    rawtof = CALCTOF(cscan,t,row,col,minprom,noisethresh,maxwidth)
%    calculates time-of-flight without any post-processing using findpeaks
%    and a smoothing spline fit.
%
%    [rawtof,peak,locs,wide,npeaks] = CALCTOF(cscan,t,row,col,minprom,...
%    noisethresh,maxwidth) calculates time-of-flight and returns additional
%    info about the found peaks including the height, location, width, and
%    number of peaks at each point.
%
%    Inputs:
%    
%    CSCAN:       C-scan data, in 3D matrix form: [row x col x pts]
%    T:           Time, in vector form: [0:dt:tend], in microseconds
%    ROW:         Range of rows to calculate TOF, in vector form
%    COL:         Range of cols to calculate TOF, in vector form
%    MINPROM:     Min prominence in findpeaks for a peak to be identified
%    NOISETHRESH: If average signal is lower, then point is not processed
%    MAXWIDTH:    Max width in findpeaks for a peak to be marked as wide

% Initialize variables
rawTOF = zeros(length(row),length(col));
peak = cell(length(row),length(col));
locs = cell(length(row),length(col));
wide = zeros(length(row),length(col));
nPeaks = zeros(length(row),length(col));

for i = 1:length(row) % Loop through each row
    
    cscanSlice = cscan(row(i),:,:); % Get row-wise slice of C-scan

    parfor j = 1:length(col) % Loop through each point in the row
        % Check that signal at point is not just noise
        if mean(cscanSlice(:,col(j),:)) > noiseThresh %#ok<PFBNS> 
            point = squeeze(cscanSlice(:,col(j),:))'; % Get A-scan at point
    
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
                'MinPeakProminence',minProm,'WidthReference','halfheight');
            
            if length(width) >= 1 && width(1) > maxWidth
                wide(i,j) = true; % Mark wide peaks
            end

            % Count number of peaks
            nPeaks(i,j) = length(peak{i,j});
    
            % Calculate raw time-of-flight
            if nPeaks(i,j) > 1
                [~, loc2i] = max(peak{i,j}(2:end));
                rawTOF(i,j) = locs{i,j}(loc2i+1)-locs{i,j}(1);
            end
        end
    end
end

end