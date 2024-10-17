function [distance,cameraParams] = cameraCheck()
    % 1. 读取图片文件路径，图片格式为bmp
    imageFileNames = cell(1, 7); % 创建一个单元数组来存储图片文件路径
    % index = [1 4 5 6 8 9 10];
    for i = 1:10
        imageFileNames{i} = fullfile('lxy', [num2str(i), '.bmp']);
    end

    % 2. 检测角点
    [imagePoints, boardSize] = detectCheckerboardPoints(imageFileNames);

    % 3. 生成标定板的三维坐标
    % 标定板尺寸为12*9，每个格子边长为6mm
    squareSize = 6;
    worldPoints = generateCheckerboardPoints(boardSize, squareSize);

    % 4. 执行相机标定
    % 假设图像的尺寸为 [height, width]
    imageSize = [size(imread(imageFileNames{1}), 1), size(imread(imageFileNames{1}), 2)];
    cameraParams = estimateCameraParameters(imagePoints, worldPoints, 'ImageSize', imageSize);

    point1 = imagePoints(1,:,1);
    point2 = imagePoints(2,:,1);

    % 将图像坐标转换为世界坐标
    worldPoint1 = pointsToWorld(cameraParams, cameraParams.RotationMatrices(:, :, 1), cameraParams.TranslationVectors(1, :), point1);
    worldPoint2 = pointsToWorld(cameraParams, cameraParams.RotationMatrices(:, :, 1), cameraParams.TranslationVectors(1, :), point2);

    % 8. 计算像素点之间的实际长度
    distance = norm(worldPoint1 - worldPoint2)/norm(point1 - point2);
    save('cameraParams.mat', 'cameraParams');
end
