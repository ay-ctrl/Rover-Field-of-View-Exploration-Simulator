classdef RoverExplorer < handle
    properties
        viewRadius
        sigmoidSharpness = 0.05
        baseWeight = 0.05
        baseMarkerSize = 2
        markerScale = 50
        colorMap = [0.6 0.2 0.2; 0 0 0; 0 0.5 1; 0 1 0; 1 1 0; 1 1 1]
        mapScore
        mapWidth
        mapHeight
        xBounds
        yBounds
        dRow
        dCol
        dDist
        axMain
        axCB
        hRover
        hPoints
        Xgrid
        Ygrid
        startX
        startY
        hFrontierShapes
        hFrontierPlot
        obstacles = []
        radii = []
    end
    
    properties (Access = private)
        hRectangles
        hTexts
        validGridMask 
    end
    
    methods
        function obj = RoverExplorer(axHandle, xLimits, yLimits, viewRadius, startX, startY)
            if nargin < 1, error('RoverExplorer requires an axes handle.'); end
            obj.axMain = axHandle;
            
            if nargin < 2 || isempty(xLimits), xLimits = [0 200]; end
            if nargin < 3 || isempty(yLimits), yLimits = [0 200]; end
            
            if isscalar(xLimits), xLimits = [-xLimits/2, xLimits/2]; end
            if isscalar(yLimits), yLimits = [-yLimits/2, yLimits/2]; end
            
            obj.xBounds = xLimits;
            obj.yBounds = yLimits;
            obj.mapWidth = diff(xLimits);
            obj.mapHeight = diff(yLimits);
            
            obj.viewRadius = obj.getArgOrDefault(viewRadius, 3);
            obj.startX = obj.getArgOrDefault(startX, mean(xLimits));
            obj.startY = obj.getArgOrDefault(startY, mean(yLimits));
            
            gridW = round(obj.mapWidth);
            gridH = round(obj.mapHeight);
            obj.mapScore = zeros(gridH, gridW);
            obj.validGridMask = true(gridH * gridW, 1);
            
            obj.initAxes();
            obj.alignColorbar();
            obj.computeObservationMask();
            
            fig = ancestor(obj.axMain, 'figure');
            if ~isempty(fig)
                fig.SizeChangedFcn = @(~,~) obj.alignColorbar();
            end
        end
        
        function move(obj, x, y)
            set(obj.hRover, 'XData', x, 'YData', y);
            obj.updateScores(y, x);
            obj.updateRendering();
            drawnow limitrate;
        end
        
        function setMarkerSize(obj, baseSize, scale)
            if nargin >= 2, obj.baseMarkerSize = baseSize; end
            if nargin >= 3, obj.markerScale = scale; end
        end
        
        function drawObstacles(obj, obstacles, radii)
            obj.obstacles = [obj.obstacles; obstacles];
            obj.radii = [obj.radii; radii];
            
            hold(obj.axMain, 'on');
            uistack(obj.hPoints, 'bottom');
            theta = linspace(0, 2*pi, 80);
            for i = 1:size(obstacles, 1)
                x = obstacles(i,1) + radii(i) * cos(theta);
                y = obstacles(i,2) + radii(i) * sin(theta);
                fill(obj.axMain, x, y, [0.6 0.2 0.2], 'FaceAlpha', 0.5, 'EdgeColor', 'none');
            end
            
            obj.validGridMask = obj.computeObstacleMask();
            
            set(obj.hPoints, 'XData', obj.Xgrid(obj.validGridMask), ...
                             'YData', obj.Ygrid(obj.validGridMask));
                         
            obj.updateRendering();
        end
        
        function drawFrontier(obj, centerX, centerY, funnelRadius)
            theta = linspace(0, 2*pi, 100);
            xCircle = centerX + funnelRadius * cos(theta);
            yCircle = centerY + funnelRadius * sin(theta);
            newCircle = polyshape(xCircle, yCircle);
            if isempty(obj.hFrontierShapes)
                obj.hFrontierShapes = newCircle;
            else
                obj.hFrontierShapes = [obj.hFrontierShapes, newCircle];
            end
            obj.updateFrontierPlot();
        end
        
        function interpolativeMove(obj, from, to)
            steps = ceil(norm(to - from) / 0.5);
            if steps < 1, steps = 1; end
            
            for alpha = linspace(0, 1, steps)
                pos = (1-alpha)*from + alpha*to;
                set(obj.hRover, 'XData', pos(1), 'YData', pos(2));
                obj.updateScores(pos(2), pos(1));
                obj.updateRendering();
                drawnow limitrate; 
            end
        end
    end
    
    methods (Access = private)
        function val = getArgOrDefault(~, arg, def)
            if nargin < 2 || isempty(arg)
                val = def;
            else
                val = arg;
            end
        end
        
        function initAxes(obj)
            hold(obj.axMain, 'on'); axis(obj.axMain, 'equal');
            xlim(obj.axMain, obj.xBounds); 
            ylim(obj.axMain, obj.yBounds);
            set(obj.axMain, 'Color', obj.colorMap(2,:));
            
            gridW = round(obj.mapWidth);
            gridH = round(obj.mapHeight);
            
            [obj.Xgrid, obj.Ygrid] = meshgrid(...
                linspace(obj.xBounds(1), obj.xBounds(2), gridW), ...
                linspace(obj.yBounds(1), obj.yBounds(2), gridH));
                
            obj.hPoints = scatter(obj.axMain, obj.Xgrid(:), obj.Ygrid(:), ...
                obj.baseMarkerSize * ones(numel(obj.Xgrid),1), obj.mapScore(:), 'filled');
            
            colormap(obj.axMain, interp1(linspace(0,1,size(obj.colorMap(2:end,:),1)), ...
                obj.colorMap(2:end,:), linspace(0,1,256)));
                
            obj.hRover = plot(obj.axMain, obj.startX, obj.startY, 'ro', ...
                'MarkerFaceColor', 'r', 'MarkerSize', 6);
            
            parentFig = ancestor(obj.axMain, 'figure');
            if ~isempty(parentFig)
                obj.axCB = axes('Parent', parentFig); axis(obj.axCB, 'off');
                hold(obj.axCB, 'on');
                obj.hRectangles = gobjects(6, 1);
                obj.hTexts = gobjects(6, 1);
                for s = 1:6
                    obj.hRectangles(s) = rectangle(obj.axCB, 'Position', [0 0 1 0], ...
                        'FaceColor', obj.colorMap(s,:), 'EdgeColor', 'none');
                    obj.hTexts(s) = text(obj.axCB, 1.05, 0, '', ...
                        'HorizontalAlignment','left', 'VerticalAlignment','middle');
                end
                set(obj.axCB, 'YLim', [0 1], 'XLim', [0 1]);
            end
        end
        
        function alignColorbar(obj)
            if isempty(obj.axCB) || ~isvalid(obj.axCB), return; end
            mainPos = get(obj.axMain, 'Position');
            set(obj.axCB, 'Position', [mainPos(1)+mainPos(3)+0.01, mainPos(2), 0.05, mainPos(4)]);
        end
        
        function computeObservationMask(obj)
            [dX, dY] = meshgrid(-obj.viewRadius:obj.viewRadius);
            dist = sqrt(dX.^2 + dY.^2);
            mask = dist <= obj.viewRadius;
            obj.dRow = dY(mask);
            obj.dCol = dX(mask);
            obj.dDist = dist(mask);
        end
        
        function updateScores(obj, yWorld, xWorld)
            gridW = round(obj.mapWidth);
            gridH = round(obj.mapHeight);
            
            c = round((xWorld - obj.xBounds(1)) / obj.mapWidth * (gridW - 1)) + 1;
            r = round((yWorld - obj.yBounds(1)) / obj.mapHeight * (gridH - 1)) + 1;
            c = min(max(c, 1), gridW);
            r = min(max(r, 1), gridH);
            
            rr = min(max(r + obj.dRow, 1), gridH);
            cc = min(max(c + obj.dCol, 1), gridW);
            
            idx = sub2ind([gridH, gridW], round(rr), round(cc));
            score = 1 ./ (1 + exp(obj.sigmoidSharpness * (obj.dDist - obj.viewRadius/2)));
            w = obj.baseWeight * (1 + 0.5 * (1 - obj.dDist / obj.viewRadius));
            obj.mapScore(idx) = min(obj.mapScore(idx) + w .* score, 1);
        end
        
        function updateRendering(obj)
            set(obj.hPoints, 'CData', obj.mapScore(obj.validGridMask), ...
                             'SizeData', obj.baseMarkerSize * ones(sum(obj.validGridMask), 1));
            obj.updateColorbar();
        end
        
        function updateColorbar(obj)
            if isempty(obj.axCB) || ~isvalid(obj.axCB), return; end
            
            obstacleCount = nnz(~obj.validGridMask);
            validScores = obj.mapScore(obj.validGridMask);
            
            bins = [
                obstacleCount;
                nnz(validScores <= 0);
                nnz(validScores > 0 & validScores <= 0.25);
                nnz(validScores > 0.25 & validScores <= 0.50);
                nnz(validScores > 0.50 & validScores <= 0.75);
                nnz(validScores > 0.75)
            ];
            
            pct = bins / sum(bins);
            H = [0; cumsum(pct(:))];
            
            for s = 1:6
                hLen = H(s+1) - H(s);
                if hLen > 0
                    set(obj.hRectangles(s), 'Position', [0 H(s) 1 hLen], 'Visible', 'on');
                    
                    if round(pct(s)*100) > 0
                        set(obj.hTexts(s), 'Position', [1.05, (H(s)+H(s+1))/2, 0], ...
                            'String', sprintf('%d%%', round(pct(s)*100)), 'Visible', 'on');
                    else
                        set(obj.hTexts(s), 'Visible', 'off');
                    end
                else
                    set(obj.hRectangles(s), 'Visible', 'off');
                    set(obj.hTexts(s), 'Visible', 'off');
                end
            end
        end
        function mask = computeObstacleMask(obj)
            mask = true(size(obj.Xgrid(:)));
            if isempty(obj.obstacles), return; end
            for i = 1:size(obj.obstacles,1)
                dx = obj.Xgrid(:) - obj.obstacles(i,1);
                dy = obj.Ygrid(:) - obj.obstacles(i,2);
                mask((dx.^2 + dy.^2) <= obj.radii(i)^2) = false;
            end
        end
        
        function updateFrontierPlot(obj)
            if ~isempty(obj.hFrontierPlot) && all(isvalid(obj.hFrontierPlot))
                delete(obj.hFrontierPlot);
            end
            if isempty(obj.hFrontierShapes), return; end
            
            combinedFrontier = obj.hFrontierShapes(1);
            for k = 2:length(obj.hFrontierShapes)
                combinedFrontier = union(combinedFrontier, obj.hFrontierShapes(k));
            end
            
            if ~isempty(obj.obstacles)
                for i = 1:size(obj.obstacles,1)
                    theta = linspace(0,2*pi,100);
                    obsX = obj.obstacles(i,1) + obj.radii(i)*cos(theta);
                    obsY = obj.obstacles(i,2) + obj.radii(i)*sin(theta);
                    combinedFrontier = subtract(combinedFrontier, polyshape(obsX, obsY));
                end
            end
            
            [xF, yF] = boundary(combinedFrontier);
            hold(obj.axMain, 'on');
            obj.hFrontierPlot = plot(obj.axMain, xF, yF, 'LineWidth', 2, 'Color', [1 0.4 0.8]);
            
            for i = 1:size(obj.obstacles,1)
                theta = linspace(0,2*pi,200);
                obsX = obj.obstacles(i,1) + obj.radii(i)*cos(theta);
                obsY = obj.obstacles(i,2) + obj.radii(i)*sin(theta);
                insideFrontier = isinterior(combinedFrontier, obsX', obsY');
                idx = find(insideFrontier);
                for k = 1:length(idx)-1
                    if idx(k+1) == idx(k)+1
                        plot(obj.axMain, [obsX(idx(k)), obsX(idx(k+1))], ...
                                         [obsY(idx(k)), obsY(idx(k+1))], 'r', 'LineWidth',2);
                    end
                end
                if insideFrontier(1) && insideFrontier(end)
                    plot(obj.axMain, [obsX(end), obsX(1)], [obsY(end), obsY(1)], 'r', 'LineWidth',2);
                end
            end
        end
    end
end