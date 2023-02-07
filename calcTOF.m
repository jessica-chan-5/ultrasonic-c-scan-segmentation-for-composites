function [rawTOF,peaks,locs,wide,npeaks] = calcTOF(cScan,t,row,col,minprom,noisethresh,maxwidth)

% Initialize values
rawTOF = zeros(length(row),length(col));
peaks = cell(length(row),length(col));
locs = cell(length(row),length(col));
wide = zeros(length(row),length(col));
npeaks = zeros(length(row),length(col));

for i = 1:length(row)
    
    cScanSlice = cScan(row(i),:,:);

    parfor j = 1:length(col)
        if mean(cScanSlice(:,col(j),:)) > noisethresh %#ok<PFBNS> 

            point = squeeze(cScanSlice(:,col(j),:))';
    
            % Find and save peaks/locations in signal
            [p, l] = findpeaks(point,t);
        
            % Force signal to be zero at beginning and end
            p = [0 p 0];
            l = [0 l t(end)];

            
            % Fit smoothing spline to find peak values
%             fit = makima(l',p');
            fits = fit(l',p','smoothingspline');

            % Evaluate smoothing spline for t
%             pfit = ppval(fits,t);
            pfit = feval(fits,t);

            % Find and save locations of peaks in previously found peaks
            [peaks{i,j}, locs{i,j}, width] = findpeaks(pfit,t,'MinPeakProminence',minprom);
            
            if length(width) >= 1 && width(1) > maxwidth
                wide(i,j) = true;
            end

            % Count number of peaks
            npeaks(i,j) = length(peaks{i,j});
    
            if npeaks(i,j) > 1
                [~, loc2i] = max(peaks{i,j}(2:end));
                rawTOF(i,j) = locs{i,j}(loc2i+1)-locs{i,j}(1);
            end
        end
    end
end

end