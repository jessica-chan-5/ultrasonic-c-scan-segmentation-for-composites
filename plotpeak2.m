function plotpeak2(fileName,outFolder,dir,num,row,col,minProm2)
%PLOTPEAK2 Plot 2nd peak magnitude.
%   PLOTPEAK2(fileName,outFolder,dir,num,row,col,minProm2) Plots 2nd peak
%   magnitude along row(s) or column(s). Plots and displays peak
%   information of the negative value of 2nd peak magnitude along row/col.
%
%   Inputs:
%
%   FILENAME:  Name of .mat file to read
%   OUTFOLDER: Folder path to .mat output files
%   DIR:       'row' or 'col' - plots along given direction
%   NUM:       Vector of rows or columns to plot along
%   ROW:       Number of rows in C-scan
%   COL:       Number of columns in C-scan
%   MINPROM2:  Min prominence in findpeaks for a peak to be identified

%#ok<*NODEF>

% Load variables
loadVar = ["peak2","cropCoord"];
for i = 1:length(loadVar)
    inFile = strcat(outFolder,"\",loadVar(i),"\",fileName,'-',...
        loadVar(i),'.mat');
    load(inFile,loadVar(i));
end

% Save peak2 in full plate
tempPeak2 = zeros(row,col);
tempPeak2(cropCoord(1):cropCoord(2),cropCoord(3):cropCoord(4)) = peak2; 
peak2 = tempPeak2;

% Set endx to row or col depending on dir
if strcmp(dir,'row') == true
    endx = col;
elseif strcmp(dir,'col') == true
    endx = row;
end

titleStr = strings(length(num),1); % Initialize legend string array
figure('WindowState','maximized'); hold on; % Full screen figure

% Plot all 2nd peak magnitude across row(s) or col(s) requested
for i = 1:length(num)
    % Slice along row or col depending on dir
    if strcmp(dir,'row') == true
        slice = -peak2(num(i),:);
    elseif strcmp(dir,'col') == true
        slice = -peak2(:,num(i));
    end
    
    % Find peaks in negative of 2nd peak magnitude values
    x = linspace(1,endx,length(slice));
    findpeaks(slice,x,'MinPeakProminence',minProm2,'Annotate','extents');

    % Display peak information
    [peak,loc,~,prom] = findpeaks(slice',x','MinPeakProminence',minProm2, ...
        'Annotate','extents');
    peakInfo = table(peak,loc,prom);
    figTitle = strcat(dir," ",num2str(num(i)));
    disp(figTitle)
    disp(peakInfo)
    titleStr(i) = figTitle;
end

grid minor;
title(strcat(dir," ",num2str(num)));
xlim([1 endx]);
xlabel(dir);
ylabel('2nd Peak Magnitude')
legend(titleStr);

end