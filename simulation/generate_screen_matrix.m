
% Grid parameters

ROWS = 10;
COLS = 10;

% Open the file containing the golden (reference) Life state for reading
fileID = fopen('life_golden_bin.mem', 'r');
generations = 20;

line_str = fgetl(fileID);

fclose(fileID);

% Convert characters to a numeric array of 0s and 1s:
% The character '0' has ASCII code 48, '1' has 49, so subtract '0'
bits = line_str - '0';

% Reconstruct the matrix:
grid = reshape(bits, [COLS, ROWS])';

% Scale each grid cell to a 32x32 block of pixels
screen_matrix = repelem(grid, 32, 32);

% Open the output file for writing the screen matrix
fileID = fopen('screen_matrix_bin.mem', 'w');

for row = 1:(ROWS*32)
    fprintf(fileID, '%d', screen_matrix(row, :));
    fprintf(fileID, '\n');
end

fclose(fileID);