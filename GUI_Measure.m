%%% ---------------
% 2024/10/6 lxy
%%% ---------------

function GUI_Measure(distance)
    % 创建图形窗口
    fig = figure('Name', '测距工具', 'NumberTitle', 'off', 'Position', [100, 100, 800, 600]);
    
    % 读取图像并显示
    
    imgfile = fullfile('lxy', '11.bmp');
    img = imread(imgfile);
    axes('Units', 'pixels', 'Position', [50, 50, 600, 500]);
    imshow(img);
    flag = 0;
    % distance = 0.0620;
    
    hold on;

    % 创建按钮
    uicontrol('Style', 'pushbutton', 'String', '开始测距', ...
              'Position', [675, 100, 100, 30], ...
              'Callback', @startMeasurement);
    uicontrol('Style', 'pushbutton', 'String', '结束测距', ...
              'Position', [675, 50, 100, 30], ...
              'Callback', @endMeasurement);
    
    function startMeasurement(~, ~)
        flag = 0;
        while true
            % 获取两个点击的坐标
            [x(1), y(1)] = ginput(1);
            plot(x(1), y(1), 'ro'); % 标记点击的点

            [x(2), y(2)] = ginput(1);
            plot(x(2), y(2), 'ro'); % 标记点击的点

            if(flag == 1)
                break;
            end
            
            % 绘制双向箭头
            quiver(x(1), y(1), x(2) - x(1), y(2) - y(1), 0, 'r', 'LineWidth', 1.5, 'MaxHeadSize', 0.1);
            quiver(x(2), y(2), x(1) - x(2), y(1) - y(2), 0, 'r', 'LineWidth', 1.5, 'MaxHeadSize', 0.1);
            
            % 计算并显示距离
            dis = distance*sqrt((x(2) - x(1))^2 + (y(2) - y(1))^2);
            text(x(2), y(2), ['Distance: ', num2str(dis),'mm'], 'Color', 'red', 'FontSize', 12);
        end
    end

    function endMeasurement(~, ~)
        flag = 1;
    end
end
