function calct1(figFolder,outFolder,fileName,cscan,t,minProm1, ...
    noiseThresh,maxWidth,map,res)

row = size(cscan,1);
col = size(cscan,2);

[fullTOF,~,fullLocs,~,~] = calctof(cscan,t,1:row,1:col,minProm1, ...
    noiseThresh,maxWidth);

% Plot time of first peak
fig = figure('visible','off');

t1 = zeros(row,col);
for i = 1:row
    for j = 1:col
        if ~isempty(fullLocs{i,j})
            t1(i,j) = fullLocs{i,j}(1);
        end
    end
end

sub1 = subplot(1,2,1);
implot(sub1,t1,map,row,col,'t1 (microseconds)',false);
colorbar;

sub2 = subplot(1,2,2);
implot(sub2,fullTOF,map,row,col,'Raw TOF (microseconds)',true);
colorbar;

sgtitle(fileName);
imsave(figFolder,fig,'t1',fileName,true,res);

savevar = 't1';
outfile = strcat(outFolder,"\",savevar,"\",fileName,'-',...
    savevar,'.mat');
save(outfile,savevar,'-mat');

end