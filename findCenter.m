function [p, l] = findCenter(p,l,m,thresh,center)

for k = 1:length(p)-m
    maxVal = max(p(k:k+m));
    if sum(isnan(p(k:k+m))) == 0 && max(maxVal-p(k:k+m))/maxVal <= thresh
        p(k) = max([p(k:k+m)]);
        if center == true
            l(k) = (l(k)+l(k+m))/2;
        end
        p(k+1:k+m) = NaN;
        l(k+1:k+m) = NaN;
    end
end

end