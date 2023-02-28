load("Output\cscan\BL-H-15J-1-cscan.mat");
load("Output\cropCoord\BL-H-15J-1-cropCoord.mat");
load("Output\t.mat");

cscan = cscan(cropCoord(1):cropCoord(2),cropCoord(3):cropCoord(4),:);
row = 96; rowf = 215;
col = 36:41; colf = 95:100;

figure;
fontsize = 10;
linewidth = 1;

nplots = 1;
for i = 1:length(col)
    ascan = squeeze(cscan(row,col(i),:));

    [p, l] = findpeaks(ascan,t);
    p = [0; p; 0]; %#ok<AGROW> 
    l = [0; l; t(end)]; %#ok<AGROW> 
    
    fits = fit(l,p,'smoothingspline');
    pFit = feval(fits,t);
    
    subplot(6,1,nplots); hold on;
    set(gca,'DefaultLineLineWidth',linewidth);

    plot(t,pFit,'color','#0072BD');

    plot(locs{row,col(i)},peak{row,col(i)}+0.05,'v', ...
        'MarkerEdgeColor',[0.39,0.83,0.07], ...
        'MarkerFaceColor',[0.39,0.83,0.07],'LineWidth',0.5);
    text(locs{row,col(i)}+0.1,peak{row,col(i)}+0.05, ...
        num2str(peakLab{row,col(i)}'));

    grid minor; xlim([min(t),max(t)]);
    ylabel("Magnitude");
    ax = gca; ax.FontSize = fontsize;
    ax.XAxis.Visible = 'off';
%     legend("A-scan","Peaks","Location","best");
%     title(strcat("Row ",num2str(rowf)," Column ",num2str(colf(i))));
    nplots = nplots + 1;
end

ax.XAxis.Visible = 'on';
xlabel("Time (microseconds)"); 
