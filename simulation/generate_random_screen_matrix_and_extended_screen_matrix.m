fileID_1 = fopen('screen_matrix_random_bin.mem', 'w');
fileID_2 = fopen('screen_matrix_random_extended_bin.mem', 'w');

N = 320;

Screen_wight = 640;
Screen_heidht = 480;

Front_Porch_hor = 16;
Sync_Pulse_hor = 96;
Back_Porch_hor = 48;

Front_Porch_ver = 10;
Sync_Pulse_ver = 2;
Back_Porch_ver = 33;

Hor_game_zone_left_bound = (Screen_wight - N) / 2;
Ver_game_zone_up_bound = (Screen_heidht - N) / 2;

screen_matrix = rand(N, N) > 0.7;
extended_screen_matrix = zeros(Screen_heidht+Front_Porch_ver+Sync_Pulse_ver+Back_Porch_ver,Screen_wight+Front_Porch_hor+Sync_Pulse_hor+Back_Porch_hor);

for row = 1:N
    % Write row as a sequence of '0'/'1' characters
    fprintf(fileID_1, '%d', screen_matrix(row, :));
    fprintf(fileID_1, '\n');
end

for row = 1:(Screen_heidht+Front_Porch_ver+Sync_Pulse_ver+Back_Porch_ver)
    for col = 1:(Screen_wight+Front_Porch_hor+Sync_Pulse_hor+Back_Porch_hor)
        % Copy the random matrix into the corresponding game zone of the extended frame
        if col >= Hor_game_zone_left_bound  && col < Hor_game_zone_left_bound+N && row >= Ver_game_zone_up_bound && row < Ver_game_zone_up_bound + N
            extended_screen_matrix(row,col) = screen_matrix(row - Ver_game_zone_up_bound + 1,col-Hor_game_zone_left_bound + 1);
        end
    end
    fprintf(fileID_2, '%d', extended_screen_matrix(row, :));
    fprintf(fileID_2, '\n');
end