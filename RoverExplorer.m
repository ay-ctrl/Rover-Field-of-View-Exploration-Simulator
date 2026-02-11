classdef RoverExplorer < handle
    properties
        viewRadius
        sigmoidSharpness = 0.1
        baseWeight = 0.1
        baseMarkerSize = 6
        markerScale = 50
        colorMap = [0 0 0; 0 0.5 1; 0 1 0; 1 1 0; 1 1 1]

        mapScore
        mapWidth
        mapHeight

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

        scoreRanges = [0 0.3; 0.3 0.6; 0.6 0.9; 0.9 1];
    end

    methods
        function obj = RoverExplorer(axHandle, mapWidth, mapHeight, viewRadius, startX, startY)
            if nargin < 1, error('RoverExplorer requires an axes handle.'); end
            obj.axMain = axHandle;
            obj.mapWidth = obj.getArgOrDefault(mapWidth, 200);
            obj.mapHeight = obj.getArgOrDefault(mapHeight, 200);
            obj.viewRadius = obj.getArgOrDefault(viewRadius, 3);
            obj.startX = obj.getArgOrDefault(startX, 1);
            obj.startY = obj.getArgOrDefault(startY, 1);

            obj.mapScore = zeros(obj.mapHeight, obj.mapWidth);

            obj.initAxes();
            obj.alignColorbar();
            obj.computeObservationMask();

            fig = ancestor(obj.axMain, 'figure');
            fig.SizeChangedFcn = @(~,~) obj.alignColorbar();
        end

        function move(obj, x, y)
            set(obj.hRover, 'XData', x, 'YData', y);
            obj.updateScores(round(y), round(x));
            obj.updateRendering();
            drawnow limitrate;
        end

        function setMarkerSize(obj, baseSize, scale)
            if nargin >= 2, obj.baseMarkerSize = baseSize; end
            if nargin >= 3, obj.markerScale = scale; end
        end

        function drawObstacles(obj, obstacles, radii)
            obj.obstacles = obstacles;
            obj.radii = radii;
            hold(obj.axMain, 'on');
            uistack(obj.hPoints, 'bottom');

            theta = linspace(0, 2*pi, 80);
            for i = 1:size(obstacles, 1)
                x = obstacles(i,1) + radii(i) * cos(theta);
                y = obstacles(i,2) + radii(i) * sin(theta);
                fill(obj.axMain, x, y, [0.6 0.2 0.2], 'FaceAlpha', 0.5, 'EdgeColor', 'none');
            end
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

        function success = interpolativeMove(obj, from, to)
            steps = ceil(norm(to - from) / 0.5);
            success = true;
            for alpha = linspace(0,1,steps)
                pos = (1-alpha)*from + alpha*to;
                if any(vecnorm(obj.obstacles - pos, 2, 2) < obj.radii)
                    success = false;
                    return;
                end
                set(obj.hRover, 'XData', pos(1), 'YData', pos(2));
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
            xlim(obj.axMain, [0 obj.mapWidth]); ylim(obj.axMain, [0 obj.mapHeight]);
            set(obj.axMain, 'Color', obj.colorMap(1,:));

            [obj.Xgrid, obj.Ygrid] = meshgrid(1:obj.mapWidth, 1:obj.mapHeight);
            obj.hPoints = scatter(obj.axMain, obj.Xgrid(:), obj.Ygrid(:), ...
                obj.baseMarkerSize * ones(numel(obj.Xgrid),1), obj.mapScore(:), 'filled');

            colormap(obj.axMain, interp1(linspace(0,1,size(obj.colorMap,1)), ...
                obj.colorMap, linspace(0,1,256)));

            obj.hRover = plot(obj.axMain, obj.startX, obj.startY, 'ro', ...
                'MarkerFaceColor', 'r', 'MarkerSize', 6);

            parentFig = ancestor(obj.axMain, 'figure');
            obj.axCB = axes('Parent', parentFig); axis(obj.axCB, 'off');
        end

        function alignColorbar(obj)
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

        function updateScores(obj, r, c)
            rr = min(max(r + obj.dRow, 1), obj.mapHeight);
            cc = min(max(c + obj.dCol, 1), obj.mapWidth);
            idx = sub2ind([obj.mapHeight, obj.mapWidth], round(rr), round(cc));

            score = 1 ./ (1 + exp(obj.sigmoidSharpness * (obj.dDist - obj.viewRadius/2)));
            w = obj.baseWeight * (1 + 0.5 * (1 - obj.dDist / obj.viewRadius));

            obj.mapScore(idx) = min(obj.mapScore(idx) + w .* score, 1);
        end

        function updateRendering(obj)
            mask = obj.computeObstacleMask();
            set(obj.hPoints, 'XData', obj.Xgrid(mask), 'YData', obj.Ygrid(mask), ...
                'CData', obj.mapScore(mask), 'SizeData', obj.baseMarkerSize*ones(sum(mask),1));
            obj.updateColorbar();
        end

        function updateColorbar(obj)
            bins = [
                nnz(obj.mapScore(:) <= 0)
                nnz(obj.mapScore(:) > 0 & obj.mapScore(:) <= 0.3)
                nnz(obj.mapScore(:) > 0.3 & obj.mapScore(:) <= 0.6)
                nnz(obj.mapScore(:) > 0.6 & obj.mapScore(:) < 0.9)
                nnz(obj.mapScore(:) >= 0.9)
            ];
            pct = bins / sum(bins);
            H = [0; cumsum(pct(:))];

            cla(obj.axCB); hold(obj.axCB,'on'); axis(obj.axCB,'off');
            for s = 1:5
                rectangle(obj.axCB, 'Position', [0 H(s) 1 (H(s+1)-H(s))], ...
                    'FaceColor', obj.colorMap(s,:), 'EdgeColor', 'none');
                text(obj.axCB, 1.05, (H(s)+H(s+1))/2, sprintf('%d%%', round(pct(s)*100)), ...
                    'HorizontalAlignment','left', 'VerticalAlignment','middle');
            end
            set(obj.axCB, 'YLim', [0 1], 'XLim', [0 1]);
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
            % Remove old frontier plot
            if ~isempty(obj.hFrontierPlot) && all(isvalid(obj.hFrontierPlot))
                delete(obj.hFrontierPlot);
            end
            if isempty(obj.hFrontierShapes), return; end

            % Combine all frontier shapes
            combinedFrontier = obj.hFrontierShapes(1);
            for k = 2:length(obj.hFrontierShapes)
                combinedFrontier = union(combinedFrontier, obj.hFrontierShapes(k));
            end

            % Subtract obstacles to prevent drawing inside them
            if ~isempty(obj.obstacles)
                for i = 1:size(obj.obstacles,1)
                    theta = linspace(0,2*pi,100);
                    obsX = obj.obstacles(i,1) + obj.radii(i)*cos(theta);
                    obsY = obj.obstacles(i,2) + obj.radii(i)*sin(theta);
                    combinedFrontier = subtract(combinedFrontier, polyshape(obsX, obsY));
                end
            end

            % Draw main frontier
            [xF, yF] = boundary(combinedFrontier);
            hold(obj.axMain, 'on');
            obj.hFrontierPlot = plot(obj.axMain, xF, yF, 'LineWidth', 2, 'Color', [1 0.4 0.8]);

            % Draw red arcs on obstacle edges that intersect the frontier
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
