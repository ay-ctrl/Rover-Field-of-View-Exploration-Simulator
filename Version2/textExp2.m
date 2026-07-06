clc; clear; close all;

%% MAP SETUP
fig = figure;
ax = axes('Parent', fig);
hold(ax,'on'); axis(ax,'equal');
title('Simple RoverExplorer Test');

mapSize = 300;
viewRadius = 20;

explorer = RoverExplorer(ax, mapSize, mapSize, viewRadius, mapSize/2, mapSize/2);

%% SIMPLE PATH (circle movement)
theta = 0;
r = 100;

dt = 0.1;

for i = 1:2000

    % simple circular motion
    theta = theta + 0.02;
    x = r * cos(theta);
    y = r * sin(theta);

    % shift to positive map space
    mapX = x + mapSize/2;
    mapY = y + mapSize/2;

    % move rover
    explorer.move(mapX, mapY);

    pause(0.01);
end