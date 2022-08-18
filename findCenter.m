function [p, l] = findCenter(p,l,m,thresh)

for k = 1:length(p)-m
    if max(abs(mean(p(k:k+m))-p(k:k+m))) <= thresh
        p(k) = max([p(k:k+m)]);
        l(k) = (l(k)+l(k+m))/2;
        p(k+1:k+m) = NaN;
        l(k+1:k+m) = NaN;
    end
end

p = rmmissing(p);
l = rmmissing(l);

end