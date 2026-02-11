clc; clear; close all;

%% --- PARAMETERS AND BEGINNING ---
mapW = 60; mapH = 60;
mapScore = zeros(mapH, mapW);
% Create a path in Nx2 format from x and y
path = rover_path(); % [row,col] , can take parameters for choosing a path 


viewR = 5;                % view radius
alphaSharp = 0.6;         % sigmoid sharpness
weightBase = 0.4;         % base weight

colorList = [0 0 0;      % unknown black
             0 0.5 1;      % blue
             0 1 0;        % green
             1 1 0;        % yellow
             1 1 1];       % white

%% --- FIGURE AND AXES ---
fig = figure('Color',[0.1 0.1 0],'Units','normalized','Position',[0.05 0.1 0.75 0.75]);
mainAx = axes('Position',[0.05 0.05 0.78 0.9]);
hold(mainAx,'on'); axis(mainAx,'equal','xy');
xlim(mainAx,[0 mapW+1]); ylim(mainAx,[0 mapH+1]);
set(mainAx,'Color',colorList(1,:));
title(mainAx,'Rover Keşif Simülasyonu');

%% --- ROVER AND MAP POINTS ---
[X, Y] = meshgrid(1:mapW,1:mapH);
nPts = numel(X);

hRover = plot(mainAx,path(1,2),path(1,1),'ro','MarkerFaceColor','r','MarkerSize',6);
hPts = scatter(mainAx,X(:),Y(:), 10*ones(nPts,1), mapScore(:),'filled');

cmap = interp1(linspace(0,1,size(colorList,1)),colorList,linspace(0,1,256));
colormap(mainAx,cmap); clim(mainAx,[0 1]);

%% --- COLORBAR AXES ---
cbAx = axes('Position',[0.86 0.1 0.08 0.8]);
axis(cbAx,'off');

%% --- VIEW MASK ---
[dX, dY] = meshgrid(-viewR:viewR, -viewR:viewR);
dist = sqrt(dX.^2 + dY.^2);
mask = dist <= viewR;
dRow = dX(mask); dCol = dY(mask); dDist = dist(mask);

%% --- MARKER SIZE PARAMETERS ---
sizeBase = 10; sizeScale = 50;
ranges = [0 0; 0 0.3; 0.3 0.6; 0.6 1; 1 1];

%% --- MAIN LOOP ---
for i = 1:size(path,1)
    r = path(i,1); c = path(i,2);
    set(hRover,'XData',c,'YData',r);

    rr = r + dRow; cc = c + dCol;
    valid = rr>=1 & rr<=mapH & cc>=1 & cc<=mapW;

    rr = rr(valid); cc = cc(valid); dV = dDist(valid);
    score = 1 ./ (1 + exp(alphaSharp*(dV - viewR/2)));
    w = weightBase*(1 + 0.5*(1 - dV/viewR));

    idx = sub2ind([mapH,mapW],rr,cc);
    mapScore(idx) = min(mapScore(idx) + w.*score, 1);

    %% --- RATE CALCULATION ---
    bins = [...
        nnz(mapScore(:)==0), ...
        nnz(mapScore(:)>0 & mapScore(:)<=0.3), ...
        nnz(mapScore(:)>0.3 & mapScore(:)<=0.6), ...
        nnz(mapScore(:)>0.6 & mapScore(:)<1), ...
        nnz(mapScore(:)==1)];
    pct = bins / sum(bins);

    %% --- COLORBAR DRAWING ---
    cla(cbAx); hold(cbAx,'on'); axis(cbAx,'off');
    H = [0; cumsum(pct(:))];
    
    for s = 1:length(pct)
        rectangle(cbAx, ...
            'Position',[0 H(s) 1 H(s+1)-H(s)], ...
            'FaceColor',colorList(s,:), ...
            'EdgeColor','none');
        text(cbAx,1.05,(H(s)+H(s+1))/2, ...
            sprintf('%d%%',round(pct(s)*100)), ...
            'Color','w','FontSize',9);
    end
    
    set(cbAx,'YDir','normal','YLim',[0 1],'XLim',[0 1.6]);
    %% --- MARKER SIZE ---
    sz = sizeBase*ones(nPts,1);
    for ri=2:size(ranges,1)
        maskR = mapScore(:)>ranges(ri,1) & mapScore(:)<=ranges(ri,2);
        if any(maskR)
            avg = mean(mapScore(maskR));
            sz(maskR) = sizeBase + sizeScale*abs(mapScore(maskR) - avg);
        end
    end

    set(hPts,'CData',mapScore(:),'SizeData',sz);

    drawnow limitrate;
    pause(0.06);
end

title(mainAx,'Rover keşfi tamamlandı');
