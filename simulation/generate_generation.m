fileID = fopen('life_golden_bin.mem', 'w');

% Grid size
N = 10;

% Initial random state (bit / logical array)
% 1 = alive cell, 0 = dead cell
grid = rand(N, N) > 0.7;

grid_row_major = grid';
fprintf(fileID, '%d', grid_row_major(:));
fprintf(fileID, '\n');
disp(uint8(grid));

% Kernel for counting neighbors (excluding the central cell itself)
kernel = [1 1 1; ...
          1 0 1; ...
          1 1 1];

% Number of generations
generations = 20;

for t = 1:generations
    % Toroidal boundaries (wrap grid edges into a torus)
    extended = grid([end 1:end 1], [end 1:end 1]);

    % Count live neighbors via 2D convolution
    neighbors = conv2(double(extended), kernel, 'valid');

    % Apply Conway's rules:
    % 1. Birth: a dead cell with exactly 3 neighbors
    % 2. Survival: a live cell with 2 or 3 neighbors
    grid = (neighbors == 3) | (grid & (neighbors == 2));

    % Print current step to command window (as a matrix of zeros and ones)
    fprintf('Generation %d (total alive: %d):\n', t, sum(grid(:)));
    disp(uint8(grid));

    grid_row_major = grid';                     % Transpose for row-major order
    fprintf(fileID, '%d', grid_row_major(:));   
    fprintf(fileID, '\n');                      
end