# Rover-Field-of-View-Exploration-Simulator

## Project Structure

This project simulates a rover exploring a 2D grid environment by updating a map based on its field of view. The system consists of two implementations. The first version is a procedural prototype developed without object-oriented programming, focusing on validating the mathematical model and visualization logic. As the rover follows a predefined path, it updates surrounding cells within a circular view radius using a distance-based logistic scoring function. The accumulated scores represent exploration intensity and are visualized dynamically on the grid.

The second version restructures the same simulation using object-oriented design principles. Rover behavior, grid management, and simulation flow are separated into modular components, making the system more maintainable, extensible, and scalable. While Version 1 serves as a functional and mathematical proof of concept, the OOP-based version improves software architecture and enables further feature expansion.

## Version 1

Rover Field-of-View Exploration Simulator is a 2D grid-based simulation that models how a rover explores an environment using a circular sensing region. As the rover moves along a predefined trajectory, it updates and accumulates coverage scores for the surrounding cells based on distance-dependent weighting.

This version focuses on visualizing exploration dynamics and cumulative sensing impact over time.

---

## Core Idea

At each simulation step:

1. The rover moves to the next position on a predefined path.
2. A circular sensing radius is applied around the rover.
3. Each visible grid cell receives a distance-based score contribution.
4. The global coverage map is updated cumulatively.
5. The visualization refreshes to reflect exploration progress.

The scoring model combines:

* A logistic distance response function
* Distance-based weighting
* Cumulative saturation (values capped at 1)

This ensures that closer regions receive stronger influence, while distant regions receive smoothly decreasing contributions.

---

## Features

* 60x60 2D grid environment
* Circular sensing field visualization
* Real-time rover movement
* Distance-based coverage accumulation
* Dynamic color bar showing coverage intensity
* Multiple trajectory types

---

## Supported Path Types

The rover trajectory is generated through a modular path function. Current implementations include:

* Diagonal motion
* Circular trajectory
* Spiral pattern
* Random walk
* Looping path
* Custom trajectories

This modular structure allows experimentation with different exploration strategies.

---

## Purpose of Version 1

Version 1 establishes the mathematical foundation and visualization pipeline of the system. It is primarily focused on:

* Modeling sensing influence
* Testing exploration behaviors
* Visualizing cumulative field coverage

The current implementation works functionally but requires further structural improvement.

---

## Version 2

Version 2 redesigns the simulator using a fully object-oriented architecture through the `RoverExplorer` class. The objective of this version is to transform the initial procedural prototype into a modular and extensible exploration framework while preserving the same mathematical sensing model.

All core responsibilities are encapsulated inside the class, including:

* Rover state management
* Score accumulation logic
* Rendering and visualization
* Obstacle handling
* Frontier construction

This eliminates script-level dependencies and provides a cleaner separation between simulation logic and visualization.

The sensing mechanism still relies on a distance-based logistic scoring model. However, in this version:

* The observation mask is precomputed for efficiency.
* Score updates are handled through structured internal methods.
* Rendering updates are centralized and automatically triggered after movement.

Each rover movement follows a consistent update pipeline:

1. Update rover position
2. Accumulate scores within the sensing radius
3. Apply obstacle masking
4. Refresh visualization
5. Recalculate coverage distribution

### Obstacle Modeling

Version 2 introduces circular obstacle support. Obstacles:

* Block rendering and score updates inside their regions
* Are visualized directly on the map
* Are considered during interpolated rover movement

The `interpolativeMove` method allows smooth transitions between points while performing collision checks in real time.

### Frontier Representation

Another major enhancement is dynamic frontier construction. The system:

* Generates circular frontier regions
* Merges multiple regions using polygon union operations
* Subtracts obstacle areas from frontier shapes
* Computes and renders the resulting boundary

Obstacle intersections with the frontier are detected and highlighted, enabling geometric analysis of reachable exploration zones.

### Visualization Improvements

* Dynamic colorbar alignment with automatic resizing
* Real-time coverage percentage breakdown
* Configurable marker sizes
* Continuous colormap interpolation
* Improved rendering structure

---

## Future Improvements

* Multi-rover support
* Performance improvements
* Additional Features

This version shifts the project from a procedural proof of concept to a structured exploration simulation framework suitable for further development, such as multi-rover coordination, path planning integration, adaptive sensing models, and autonomous navigation experimentation.

