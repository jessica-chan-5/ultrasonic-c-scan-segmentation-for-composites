function inflpt = magpeaks(dir,row,col,peak2,minProm2)

inflpt = zeros(row,col);

if strcmp(dir,'row') == true
    for i = 1:row
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