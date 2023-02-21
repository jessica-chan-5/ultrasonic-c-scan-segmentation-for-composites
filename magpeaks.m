function inflpt = magpeaks(dir,row,col,peak2,minProm2)
%MAGPEAKS Use 2nd peak magnitude to find inflection points
%   inflpt = MAGPEAKS(dir,row,col,peak2,minProm2) searches along row or
%   col depending on given dir for inflection points using negative values
%   of 2nd peak magnitude. Returns inflection points.
%
%   Inputs:
%
%   DIR:      'row' or 'col' - searches along given direction
%   ROW:      Number of points along row
%   COL:      Number of points along col
%   PEAK2:    2nd peak magnitude values
%   MINPROM2: Min prominence in findpeaks for a peak to be identified

% Initialize variable
inflpt = zeros(row,col);

% Search along row or col for peaks to identify inflection points
if strcmp(dir,'row') == true
    for i = 1:row
        % Take negative value to find peaks instead of valleys
        invertPeak2 = -peak2(i,:);
        [~,magLoc] = findpeaks(invertPeak2,'MinPeakProminence',minProm2);
        inflpt(i,magLoc) = 1;
    end
elseif strcmp(dir,'col') == true
    for j = 1:col
        invertPeak2 = -peak2(:,j);
        [~,magLoc] = findpeaks(invertPeak2,'MinPeakProminence',minProm2);
        inflpt(magLoc',j) = 1;
    end
end

end