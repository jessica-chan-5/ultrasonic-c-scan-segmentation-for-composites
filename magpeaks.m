function inflpt = magpeaks(dir,row,col,peak2,minprom2)

inflpt = zeros(row,col);

if strcmp(dir,'row') == true
    for i = 1:row
        invertPeak2 = -peak2(i,:);
        [~,magloc] = findpeaks(invertPeak2,'MinPeakProminence',minprom2);
        inflpt(i,magloc) = 1;
    end
elseif strcmp(dir,'col') == true
    for j = 1:col
        invertPeak2 = -peak2(:,j);
        [~,magloc] = findpeaks(invertPeak2,'MinPeakProminence',minprom2);
        inflpt(magloc',j) = 1;
    end
end

end