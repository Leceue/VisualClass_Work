%%% ---------------
% 2024/10/6 lxy
%%% ---------------

[distance,cameraParams] = cameraCheck();

square_image = fullfile('lxy', '11.bmp');
gear_image = fullfile('lxy', '12.bmp');

square_image = imread(square_image);
gear_image = imread(gear_image);

square_image = undistortImage(square_image, cameraParams);
gear_image = undistortImage(gear_image, cameraParams);

disp('齿轮测量开始');
Gear_Measure(gear_image, distance);
disp('齿轮测量结束');
disp('冲压件测量开始');
Square_Measure(square_image, distance);
disp('冲压件测量结束');

% 显示结果
fprintf('两个像素点之间的实际长度为 %.2f mm\n', distance);
