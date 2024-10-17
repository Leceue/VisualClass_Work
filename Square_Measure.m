%%% ---------------
% 2024/10/6 lxy
%%% ---------------
function Square_Measure(square_image,distance)

    undistortedrectangleImage = square_image;

    %% 对图像进行裁剪，只保留冲压件部分
    % 获取图像的大小
    [height2, width2, ~] = size(undistortedrectangleImage);
    % 定义裁剪区域 (保留中间部分)
    cropWidth2 = round(width2 * 0.5); % 裁剪区域宽度为图像宽度的 50%
    cropHeight2 = round(height2 * 0.5); % 裁剪区域高度为图像高度的 50%
    centerX2 = round(width2 / 2);
    centerY2 = round(height2 / 2);
    % 偏移量：使裁剪区域偏上
    verticalOffset2 = round(cropHeight2 * 0.25); % 向上偏移 25%
    % 计算裁剪区域的起始坐标
    xStart2 = centerX2 - round(cropWidth2 / 2);
    yStart2 = centerY2 - round(cropHeight2 / 2) - verticalOffset2; % 上移裁剪框
    % 裁剪图像
    croppedImage2 = imcrop(undistortedrectangleImage, [xStart2, yStart2, cropWidth2, cropHeight2]);

    square_image = croppedImage2;

    square_image = medfilt2(square_image);

    % imshow(square_image);

    % 二值化齿轮图像
    bw = imbinarize(square_image);

    boundaries = bwboundaries(bw);

    % 第二大的轮廓为冲压方片
    square_eg = boundaries{6};
    % 第3到第6大的轮廓为冲压方片的孔
    square_hole = boundaries(2:5);
    figure(2);
    imshow(square_image);
    hold on;
    % 绘制冲压方片
    plot(square_eg(:,2), square_eg(:,1), 'r', 'LineWidth', 2);

    % 拟合四个孔的圆，计算其尺寸
    for i = 1:4
        hole1 = square_hole{i};
        hole_center{i} = [mean(hole1(:,1)), mean(hole1(:,2))];
        hole1_cir = hole1 - hole_center{i};
        min_cir = min(sqrt(hole1_cir(:,1).^2 + hole1_cir(:,2).^2));
        max_cir = max(sqrt(hole1_cir(:,1).^2 + hole1_cir(:,2).^2));
        delta = max_cir - min_cir;
        circle_min = hole1_cir(sqrt(hole1_cir(:,1).^2 + hole1_cir(:,2).^2) > max_cir - 0.5*delta, :);
        circle_rd{i} = mean(sqrt(circle_min(:,1).^2 + circle_min(:,2).^2));
        fprintf('孔 %d 直径：%.2f mm\n', i, 2*circle_rd{i}*distance);
        
        % 绘制孔的圆
        theta = linspace(0, 2*pi, 100);
        x = circle_rd{i}*cos(theta) + hole_center{i}(2);
        y = circle_rd{i}*sin(theta) + hole_center{i}(1);
        plot(x, y, 'b', 'LineWidth', 2);
        
        quiver(hole_center{i}(2), hole_center{i}(1), circle_rd{i}*cos(-pi/4), circle_rd{i}*sin(-pi/4), 'b', 'LineWidth', 3, "MaxHeadSize", 0.5);
        
        text(hole_center{i}(2)+circle_rd{i}*cos(-pi/4), hole_center{i}(1)+circle_rd{i}*sin(-pi/4), num2str(circle_rd{i}*distance, '%.2f')+"mm", 'FontSize', 12, 'Color', 'r');
    end

    grayImg = im2gray(square_image);

    % 边缘检测
    edges = edge(grayImg, 'Canny');

    % 形态学操作：膨胀和腐蚀去掉圆角
    se = strel('line', 5, 0);
    dilatedEdges = imdilate(edges, se);
    cleanedEdges = imerode(dilatedEdges, se);

    % 霍夫变换提取直线
    [H, T, R] = hough(cleanedEdges);
    % plot(H);
    peaks = houghpeaks(H, 4, 'threshold',ceil(0.15*max(H(:)))); % 获取前4个峰值
    lines = houghlines(cleanedEdges, T, R, peaks);

    % 提取直线参数
    lineParams = zeros(length(lines), 4);
    for k = 1:length(lines)
        % 计算直线方程参数
        x1 = lines(k).point1(1);
        y1 = lines(k).point1(2);
        x2 = lines(k).point2(1);
        y2 = lines(k).point2(2);
        
        % 线的斜率和截距
        if x1 ~= x2
            slope = (y2 - y1) / (x2 - x1);
            intercept = y1 - slope * x1;
            lineParams(k, :) = [slope, intercept, 1, k]; % 线的参数 (斜率, 截距, 类型, 索引)
        else
            % 垂直线
            lineParams(k, :) = [Inf, x1, 0, k]; % x = const
        end
    end

    deleteIndex = [];

    % 判断是否有斜率截距相近的直线，将其合并
    for i = 1:length(lines)
        for j = i+1:length(lines)
            % 计算两条直线的斜率和截距之差
            diff = abs(lineParams(i, 1) - lineParams(j, 1)) + abs(lineParams(i, 2) - lineParams(j, 2));
            if diff < 10
                % 合并两条直线，取平均值
                lineParams(i, 1) = (lineParams(i, 1) + lineParams(j, 1)) / 2;
                lineParams(i, 2) = (lineParams(i, 2) + lineParams(j, 2)) / 2;
                deleteIndex = [deleteIndex, j];
            end
        end
    end

    % 删除合并的直线
    lineParams(deleteIndex, :) = [];
    lines(deleteIndex) = [];

    for i = 1:length(lineParams)
        lineParams(i, 4) = i;
    end

    % 计算平行边的距离
    distances = zeros(length(lineParams)/2, 1);

    % 将直线按斜率排序
    lineParams = sortrows(lineParams, 1);

    % 计算两两直线之间的距离
    for i = 1:2
        slope1 = lineParams(i*2-1, 1);
        % intercept1 = lineParams(i, 2);
        
        slope2 = lineParams(i*2, 1);
        % intercept2 = lineParams(i*2, 2);
        
        % 根据线的类型计算距离
        if slope1 ~= Inf && slope2 ~= Inf
            % 两条非垂直直线
            % d = abs(intercept2 - intercept1) / sqrt(1 + slope1^2);
            x1 = (lines(lineParams(i*2-1,4)).point1(1)+lines(lineParams(i*2-1,4)).point2(1))/2;
            y1 = (lines(lineParams(i*2-1,4)).point1(2)+lines(lineParams(i*2-1,4)).point2(2))/2;
            x2 = (lines(lineParams(i*2,4)).point1(1)+lines(lineParams(i*2,4)).point2(1))/2;
            y2 = (lines(lineParams(i*2,4)).point1(2)+lines(lineParams(i*2,4)).point2(2))/2;
            k = (slope1+slope2)/2;
            A1 = (slope1+slope2)/2;
            B1 = -1;
            C1 = -k*x1+y1;
            % A2 = A1;
            % B2 = -1;
            C2 = -k*x2+y2;
            d=abs(C2-C1)/sqrt(A1^2+B1^2);
            % 绘制出这两条直线
            % plot([x1, x2], [y1, y2], 'LineWidth', 2, 'Color', 'green');
            t = -1000:0.1:1000;
            x1_p = x1 + t;
            y1_p = y1 + k*t;
            x2_p = x2 + t;
            y2_p = y2 + k*t;
            plot(x1_p, y1_p, 'LineWidth', 2, 'Color', 'green');
            plot(x2_p, y2_p, 'LineWidth', 2, 'Color', 'green');

        else
            % 垂直线之间的距离
            d = abs(lineParams(i, 2) - lineParams(i+2, 2));
        end
        
        distances(i) = d;
    end

    % 输出距离
    disp('平行边的距离:');
    for i = 1:length(distances)
        fprintf('边 %d 和 边 %d 之间的距离: %.2f mm\n', i, i + 2, distances(i)*distance);
    end

    % 计算相邻边的4个交点
    crosspoints = zeros(4, 2);
    point_lin = [[1,3];[1,4];[2,4];[2,3]];
    for i = 1:4
        index1 = point_lin(i,1);
        index2 = point_lin(i,2);
        slope1 = lineParams(index1, 1);
        intercept1 = lineParams(index1, 2);
        
        slope2 = lineParams(index2, 1);
        intercept2 = lineParams(index2, 2);
        
        % 计算交点
        if slope1 ~= Inf && slope2 ~= Inf
            % 两条非垂直直线
            x = (intercept2 - intercept1) / (slope1 - slope2);
            y = slope1 * x + intercept1;
        else
            % 一条垂直线
            x = intercept1;
            y = slope2 * x + intercept2;
        end
        crosspoints(i, :) = [x, y];
    end

    % 绘图
    % figure;
    % imshow(croppedImage2);
    % hold on;

    indexm = [3,2];
    if sqrt((crosspoints(1,1)-crosspoints(3,1))^2+(crosspoints(1,2)-crosspoints(3,2))^2)>sqrt((crosspoints(1,1)-crosspoints(4,1))^2+(crosspoints(1,2)-crosspoints(4,2))^2)
        indexm = [4,2];
    end

    % 计算标注方向
    vectors = [];
    vectors=[vectors;crosspoints(1,:) - crosspoints(indexm(2),:)];
    vectors=[vectors;crosspoints(1,:) - crosspoints(indexm(1),:)];

    % 绘制标注线
    for i = 1:2
        point1 = crosspoints(1, :);
        point2 = crosspoints(indexm(i), :);
        point12 = point1 + vectors(i,:)*0.1;
        point22 = point2 + vectors(i,:)*0.1;
        point1mid = (point1 + point12)/2;
        point2mid = (point2 + point22)/2;
        point12mid = (point1mid + point2mid)/2;
        plot([point1(1), point12(1)], [point1(2), point12(2)], 'LineWidth', 2, 'Color', 'blue');
        plot([point2(1), point22(1)], [point2(2), point22(2)], 'LineWidth', 2, 'Color', 'blue');
        quiver(point1mid(1), point1mid(2), point2mid(1)-point1mid(1), point2mid(2)-point1mid(2), 0, 'b', 'LineWidth', 1.5, 'MaxHeadSize', 0.1);
        quiver(point2mid(1), point2mid(2), point1mid(1)-point2mid(1), point1mid(2)-point2mid(2), 0, 'b', 'LineWidth', 1.5, 'MaxHeadSize', 0.1);
        % quiver(hole_center{i}(2), hole_center{i}(1), -circle_rd{i}*cos(pi/4), -circle_rd{i}*sin(pi/4), 'b', 'LineWidth', 2);
        % plot([point1mid(1), point2mid(1)], [point1mid(2), point2mid(2)], 'LineWidth', 2, 'Color', 'blue');
        angle = 0;
        % 字体方向沿直线方向
        
        text(point12mid(1), point12mid(2)-0.01*distances(i), num2str(distances(i)*distance, '%.2f')+"mm", 'Color', 'red', 'FontSize', 12,'Rotation',angle);
    end

    % 测量一个圆的圆心到直线的距离
    cir_center = hole_center{1};
    % cir_rd = circle_rd{1};
    % 计算圆心到直线的距离
    cir_dis = zeros(2, 2);
    for i = 1:2
        slope1 = lineParams(i*2-1, 1);
        intercept1 = lineParams(i, 2);
        
        slope2 = lineParams(i*2, 1);
        intercept2 = lineParams(i*2, 2);
        
        % 计算圆心到直线的距离
        if slope1 ~= Inf && slope2 ~= Inf
            % 分别计算两条直线到圆心的距离
            x1 = (lines(lineParams(i*2-1,4)).point1(1)+lines(lineParams(i*2-1,4)).point2(1))/2;
            y1 = (lines(lineParams(i*2-1,4)).point1(2)+lines(lineParams(i*2-1,4)).point2(2))/2;
            x2 = (lines(lineParams(i*2,4)).point1(1)+lines(lineParams(i*2,4)).point2(1))/2;
            y2 = (lines(lineParams(i*2,4)).point1(2)+lines(lineParams(i*2,4)).point2(2))/2;
            % plot([x1, x2], [y1, y2], 'LineWidth', 2, 'Color', 'green');
            k = (slope1+slope2)/2;
            A1 = (slope1+slope2)/2;
            B1 = -1;
            C1 = -k*x1+y1;
            A2 = A1;
            B2 = -1;
            C2 = -k*x2+y2;
            d1 = abs(A1*cir_center(2)+B1*cir_center(1)+C1)/sqrt(A1^2+B1^2);
            d2 = abs(A2*cir_center(2)+B2*cir_center(1)+C2)/sqrt(A2^2+B2^2);
            if(d1>d2)
                cir_dis(i,:) = [d2, i*2];
            else
                cir_dis(i,:) = [d1, i*2-1];
            end
        else
            % 一条垂直线
            if slope1 == Inf
                d = abs(cir_center(1) - intercept1);
            else
                d = abs(cir_center(1) - intercept2);
            end
            cir_dis(i) = [d, i];
        end
    end

    % 输出圆心到直线的距离
    disp('圆心到直线的距离:');
    for i = 1:2
        fprintf('圆心到边 %d 的距离: %.2f mm\n', cir_dis(i, 2), cir_dis(i, 1)*distance);
    end

    % 绘制圆心到直线的距离
    for i = 1:2
        slope1 = lineParams(cir_dis(i, 2), 1);
        % intercept1 = lineParams(cir_dis(i, 2), 2);
        point1 = cir_center;
        point2 = cir_center + 1/slope1*[1, -slope1]*cir_dis(i, 1)/sqrt(1+1/slope1^2);
        % 计算标注方向
        vector = point2 - point1;
        % 从圆心出发画一个箭头，标注圆心到直线的距禋
        quiver(point1(2), point1(1), vector(2), vector(1), 0, 'g', 'LineWidth', 2, 'MaxHeadSize', 0.5);
        quiver(point2(2), point2(1), -vector(2), -vector(1), 0, 'g', 'LineWidth', 2, 'MaxHeadSize', 0.5);
        % 计算标注位置
        point12 = point1 + vector*0.5;
        angle = 0;
        % 字体方向沿直线方向
        text(point12(2)-cir_dis(i, 1)*0.1, point12(1)-cir_dis(i, 1)*0.1, num2str(cir_dis(i, 1)*distance, '%.2f')+"mm", 'Color', 'red', 'FontSize', 12,'Rotation',angle);
        
    end

    % title('提取的矩形直边');
    hold off;

end