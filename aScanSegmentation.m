function aScanSegmentation(TOF,numLayers,plateThick,baseTOF,vertScale)
    
    % Calculate material velocity
    matVel = 2*plateThick/baseTOF; % mm/us

    % Calculate ply thickness
    plyThick = plateThick/numLayers;

    % Calculate TOF for each layer
    dtTOF = plyThick/matVel*2;

    % Calculate bins centered at TOF for each layer
    layersTOF = baseTOF-numLayers*dtTOF-dtTOF/2:dtTOF:baseTOF+dtTOF/2;
%     layersTOF = [layersTOF(1:end-2),2,3];
    binTOF = discretize(TOF,layersTOF);
    
    % Create custom colormap that shows baseline TOF as white = [1, 1, 1]
    customColorMap = jet(numLayers);
    customColorMap = [customColorMap; [1 1 1]];
    
    % Plot
    figure;
    imshow(binTOF,customColorMap,'XData',[0 vertScale],'YData',[385 0]);
    
    testBins = [1:2:numLayers+1,26,27];
    figure;
    contourf(size(TOF,2):-1:1,size(TOF,1):-1:1,binTOF,testBins);
    colormap(customColorMap);
end