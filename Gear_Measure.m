%%% ---------------
% 2024/9/4 lxy
%%% ---------------
function Gear_Measure(gear_image, distance)
    % 加载齿轮图像
    % 读取齿轮图像

    % gear_image = medfilt2(gear_image);
    % 二值化齿轮图像
    bw = imbinarize(gear_image);

    boundaries = bwboundaries(bw);
    
    gear_eg = boundaries{3};
    size(gear_eg);
    gear_cir = boundaries{2};
    size(gear_cir);
    % 提取出齿轮圆心
    gear_center = [mean(gear_eg(:,1)), mean(gear_eg(:,2))];
    % gear_center2 = [mean(gear_eg(:,1)), mean(gear_eg(:,2))]

    % 计算孔径半径
    circle_eg = gear_cir - gear_center;
    min_cir = min(sqrt(circle_eg(:,1).^2 + circle_eg(:,2).^2));
    max_cir = max(sqrt(circle_eg(:,1).^2 + circle_eg(:,2).^2));
    delta = max_cir - min_cir;
    circle_min = circle_eg(sqrt(circle_eg(:,1).^2 + circle_eg(:,2).^2) < min_cir + 0.1*delta, :);
    circle_rd = mean(sqrt(circle_min(:,1).^2 + circle_min(:,2).^2));

    % 计算孔径方差

    % 计算齿顶圆
    % 提取出齿顶圆的点
    gear_cir = gear_eg - gear_center;
    max_r = max(sqrt(gear_cir(:,1).^2 + gear_cir(:,2).^2));
    min_r = min(sqrt(gear_cir(:,1).^2 + gear_cir(:,2).^2));
    delta = max_r - min_r;
    gear_top = gear_cir(sqrt(gear_cir(:,1).^2 + gear_cir(:,2).^2) > max_r - 0.03*delta, :);
    gear_min = gear_cir(sqrt(gear_cir(:,1).^2 + gear_cir(:,2).^2) < min_r + 0.03*delta, :);
    % 计算齿顶圆半径
    top_rd = mean(sqrt(gear_top(:,1).^2 + gear_top(:,2).^2));
    min_rd = mean(sqrt(gear_min(:,1).^2 + gear_min(:,2).^2));
    

    % 输出结果
    fprintf('齿轮孔径：%.2f mm\n', 2*circle_rd*distance);
    fprintf('齿顶圆直径：%.2f mm\n', 2*top_rd*distance);
    fprintf('齿根圆直径：%.2f mm\n', 2*min_rd*distance);

    %绘制齿轮图像标注
    figure(1);
    imshow(bw);
    hold on;

    % 绘制圆心
    plot(gear_center(2), gear_center(1), 'r+', 'MarkerSize', 10, 'LineWidth', 2);

    % 绘制齿顶圆尺寸
    theta = linspace(0, 2*pi, 100);
    x = top_rd*cos(theta) + gear_center(2);
    y = top_rd*sin(theta) + gear_center(1);
    plot(x, y, 'r', 'LineWidth', 2);
    % 从圆心出发画一个箭头，标注齿顶圆半径
    quiver(gear_center(2), gear_center(1), top_rd, 0, 'r', 'LineWidth', 2);
    text(gear_center(2) + top_rd, gear_center(1), "齿顶圆半径:"+num2str(top_rd*distance)+"mm", 'FontSize', 12, 'Color', 'r');

    % 绘制齿根圆尺寸
    theta = linspace(0, 2*pi, 100);
    x = min_rd*cos(theta) + gear_center(2);
    y = min_rd*sin(theta) + gear_center(1);
    plot(x, y, 'b', 'LineWidth', 2);
    quiver(gear_center(2), gear_center(1), 0, min_rd, 'b', 'LineWidth', 2);
    text(gear_center(2) , gear_center(1)+ min_rd, "齿根圆半径:"+num2str(min_rd*distance)+"mm", 'FontSize', 12, 'Color', 'b');

    % 绘制孔径尺寸
    theta = linspace(0, 2*pi, 100);
    x = circle_rd*cos(theta) + gear_center(2);
    y = circle_rd*sin(theta) + gear_center(1);
    plot(x, y, 'g', 'LineWidth', 2);
    quiver(gear_center(2), gear_center(1), -circle_rd*cos(pi/4), -circle_rd*sin(pi/4), 'g', 'LineWidth', 2);
    text(gear_center(2) -circle_rd*cos(pi/4), gear_center(1) - circle_rd*sin(pi/4), "孔径半径:"+num2str(circle_rd*distance)+"mm", 'FontSize', 12, 'Color', 'g');

    hold off;
end
