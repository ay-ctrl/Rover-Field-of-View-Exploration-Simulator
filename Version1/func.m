function score = rover_score(d, alpha, base_w, view_radius)
    % d: distance between rover and that point
    % alpha: slope of the logistic curve
    % base_w: base weight
    % view_radius: view radius of rover

    % Logistic distribution
    score_new = 1 ./ (1 + exp(alpha*(d - view_radius/2)));

    % Base according to distance
    w = base_w * (1 + 0.5*(1 - d/view_radius));

    % Total score
    score = w .* score_new;
end

view_radius = 5;
alpha = 0.6;
base_w = 0.4;

d = linspace(0, view_radius, 100);   % distances
s = rover_score(d, alpha, base_w, view_radius);

figure;
plot(d, s, 'LineWidth', 2);
xlabel('Distance from rover');
ylabel('Score contribution');
title('Rover score as a function of distance');
grid on;