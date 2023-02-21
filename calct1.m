function calct1(fileName,outFolder,figFolder,cscan,t,minProm1, ...
    noiseThresh,maxWidth,map,res)
%CALCT1 Calculate time of first peak.
%   CALCT1(figFolder,outFolder,fileName,cscan,t,minProm1,noiseThresh,...
%   maxWidth,map,res) Calculates time of first peak and TOF of full plate,
%   then saves time of first peak and plots time of first peak as well as
%   TOF of full plate.
%
%   Inputs:
%
%   FILENAME:    Name of .mat file to read
%   FIGFOLDER:   Folder path to .fig and .png files
%   OUTFOLDER:   Folder path to .mat output files
%   CSCAN:       C-scan data, in 3D matrix form: [row x col x pts]
%   T:           Time, in vector form: [0:dt:tend], in microseconds
%   MINPROM1:    Min prominence in findpeaks for a peak to be identified
%   NOISETHRESH: If average signal is lower, then point is not processed
%   MAXWIDTH:    If a peak's width is greater, then it is noted as wide
%   MAP:         Colormap to use for figure
%   RES:         Image resolution setting in dpi for saving image

% Calculate size of C-scan
row = size(cscan,1);
col = size(cscan,2);

% Calculate TOF for full plate
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

% Plot TOF
sub2 = subplot(1,2,2);
implot(sub2,fullTOF,map,row,col,'Raw TOF (microseconds)',true);
colorbar;

sgtitle(fileName);
imsave(figFolder,fig,'t1',fileName,true,res);

% Save time of first peak
savevar = 't1';
outfile = strcat(outFolder,"\",savevar,"\",fileName,'-',...
    savevar,'.mat');
save(outfile,savevar,'-mat');

end