function plotPeak2(peak2,dir,num,row,col,outFolder,fileName,minProm2)

loadVar = "peak2";
inFile = strcat(outFolder,"\",loadVar,"\",fileName,'-',...
    loadVar,'.mat');
load(inFile,loadVar);

loadVar = "cropCoord";
inFile = strcat(outFolder,"\",loadVar,"\",fileName,'-',...
    loadVar,'.mat');
load(inFile,loadVar);

tempPeak2 = zeros(row,col);
tempPeak2(cropCoord(1):cropCoord(2),cropCoord(3):cropCoord(4)) = peak2;
peak2 = tempPeak2;

if strcmp(dir,'row') == true
    endx = size(peak2,2);
elseif strcmp(dir,'col') == true
    endx = size(peak2,1);
end

titleStr = strings(length(num),1);
figure('WindowState','maximized');
hold on

for i = 1:length(num)
    if strcmp(dir,'row') == true
        slice = -peak2(num(i),:);
    elseif strcmp(dir,'col') == true
        slice = -peak2(:,num(i));
    end
    x = linspace(1,endx,length(slice));
    findpeaks(slice,x,'MinPeakProminence',minProm2,'Annotate','extents');
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
legend(titleStr);

end