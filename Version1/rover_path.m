function path = rover_path(type)
% ROVER_PATH - generates different paths
% protects bounds for 60x60 map
%
% path = rover_path(type)
% type: 'default', 'horizontal', 'circle', 'diagonal', 'repeat',
%       'spiral', 'zigzag', 'figure8', 'random_walk', 'looping'

    if nargin < 1
        type = 'default';
    end

    map_size = 60;  % Map size
    path = [];   

    switch type
        case 'default'
            path = [ % Infinity sign
                5 5;
             8 8;
             12 11;
             15 15;
             18 20;
             22 24;
             27 27;
             30 30;
             34 32;
             38 33;
             42 34;
             45 36;
             48 38;
             50 41;
             52 45;
             53 49;
             52 53;
             50 56;
             47 58;
             43 59;
             39 58;
             35 56;
             32 53;
             29 49;
             27 45;
             25 40;
             23 35;
             22 31;
             21 27;
             20 23;
             19 19;
             18 16;
             17 14;
             15 12;
             13 10;
             11 9;
             9 8;
             7 9;
             5 11;
             4 14;
             3 18;
             4 22;
             6 26;
             9 30;
             13 34;
             17 37;
             22 40;
             27 42;
             33 44;
             38 45;
             43 46;
             47 47;
             50 49;
             52 52;
             53 55;
             53 58;
             51 60;
             47 59;
             43 57;
             39 54;
             34 50;
             30 46;
             27 42;
             25 38;
             23 33;
             22 28;
             21 24;
             20 20;
             19 17;
             18 15;
             16 13;
             14 12;
             12 11;
             10 11;
             8 12;
             6 14;
             5 17;
             6 21;
             8 25;
             11 29;
             15 33;
             20 37;
             26 40;
             31 43;
             36 45;
             41 47;
             46 48;
             50 49;
             53 51;
             55 54;
             56 57;
             55 59;
             52 60;
             48 59;
             44 57;
             39 54;
             35 50;
             31 45;
             27 40;
             24 35;
             21 30;
             19 25;
             18 21;
             17 17;
             16 14;
             14 12;
             12 11;
            ];
        case 'mert'
            path = [
0.939316260452838,0.724759682136109;
0.963389452605096,0.762779169502465;
0.985349690187359,0.802056999958468;
1.00505082837394,0.842515190157157;
0.966704793721319,0.81896563333712;
0.928385693127182,0.795372275592696;
0.890117414103467,0.771696574535217;
0.851921069238717,0.747904995374239;
0.813815957470419,0.723967567418723;
0.794900683272854,0.760350513731891;
0.76718019838609,0.788311196929411;
0.738476819292744,0.815261913355011;
0.708827320123691,0.841168134350242;
0.678269687157804,0.865996669440971;
0.646843070154777,0.889715708860275;
0.614587732197326,0.912294864302408;
0.581544998107018,0.933705207855621;
0.547757201499835,0.953919309063963;
0.513267630549284,0.972911270070567;
0.522996091225906,1.01684709887649;
0.530485857557463,1.0612194258416;
0.535629435616403,1.10592449943232;
0.538322937652473,1.15084381651063;
0.538468646182758,1.19584358061028;
0.514186733791026,1.15795705621703;
0.489947946399875,1.12004292711182;
0.465790585840463,1.08207686422926;
0.441748270773964,1.04403784365508
];
        case 'horizontal'
            % horizontal line
            row = 30;
            col = 10:10:60;
            path = [row*ones(length(col),1), col'];

        case 'circle'
            % circular path
            t = linspace(0,2*pi,20);
            r_center = 30; c_center = 30; radius = 5;
            path = round([r_center + radius*sin(t(:)), c_center + radius*cos(t(:))]);

        case 'diagonal'
            % cross from left to right
            path = [(1:map_size)', (1:map_size)'];

        case 'repeat'
            % same row again
            path = [10*ones(5,1), (1:5)'];

        case 'spiral'
            % spiral from center to out
            t = linspace(0,4*pi,80);
            r_center = 30; c_center = 30;
            a = 0.5;  % spiral frequnecy
            path = round([r_center + a*t.*cos(t(:)), c_center + a*t.*sin(t(:))]);
            % bounds
            path(:,1) = max(1,min(map_size,path(:,1)));
            path(:,2) = max(1,min(map_size,path(:,2)));

        case 'random_walk'
            % random walk
            n = 100;
            path = zeros(n,2);
            path(1,:) = [30 30];
            for k = 2:n
                step = randi([-1 1],1,2);
                path(k,:) = path(k-1,:) + step;
                % bound control
                path(k,1) = max(1,min(map_size,path(k,1)));
                path(k,2) = max(1,min(map_size,path(k,2)));
            end

        case 'looping'
            % nested loops
            t = linspace(0,2*pi,20);
            r_center = 30; c_center = 30;
            radii = [3 6 9];
            path = [];
            for r = radii
                new_loop = round([r_center + r*sin(t(:)), c_center + r*cos(t(:))]);
                new_loop(:,1) = max(1,min(map_size,new_loop(:,1)));
                new_loop(:,2) = max(1,min(map_size,new_loop(:,2)));
                path = [path; new_loop];
            end

        otherwise
            % Fallback
            path = [1 1];
    end
end
