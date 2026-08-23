clc; clear; close all;

%% 1. Figure and Axes Setup
fig = figure('Name', 'Rover Simulation', 'NumberTitle', 'off');
ax = axes('Parent', fig);

%% 2. Map Parameters and Class Initialization
% Map Boundaries: X -> [-150, 150], Y -> [-150, 150]
xLimits = [-150, 150];
yLimits = [-150, 150];
viewRadius = 15;        % Sensor view radius
startX = 0;             % Initial X coordinate (Center)
startY = 0;             % Initial Y coordinate (Center)

% Instantiate the RoverExplorer object
explorer = RoverExplorer(ax, xLimits, yLimits, viewRadius, startX, startY);

%% 3. Add Obstacles (Optional)
% Define obstacle center locations [X, Y] and their corresponding radii
obstacleCenters = [ 40,  40; 
                   -50, -30];
obstacleRadii   = [15; 20];

% Render obstacles on the map
explorer.drawObstacles(obstacleCenters, obstacleRadii);

%% 4. Add Frontier Region (Optional)
% Add a frontier region centered at (0,0) with a radius of 25
explorer.drawFrontier(0, 0, 25);

%% 5. Simulation Loop (Circular Motion)
theta = 0;
radius = 60; % Motion radius

for i = 1:300
    theta = theta + 0.03;
    
    % Compute circular trajectory centered at (0,0)
    currentX = radius * cos(theta);
    currentY = radius * sin(theta);
    
    % Move the rover to the new position and update map scores
    explorer.move(currentX, currentY);
    
    % Pause brief moment to visualize animation
    pause(0.01);
end