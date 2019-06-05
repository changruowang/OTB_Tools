%在Propose tracker中用于分析 color响应和CF响应输出的各自位置
%用法：在仿真断点后调用该脚本 脚本中部分变量直接使用工作区中的变量
%      将根目录加入path
[row, col] = find(response_pwp == max(response_pwp(:)), 1);
posCOLOR = pos + ([row, col] - center) / area_resize_factor;
[row, col] = find(response_cf == max(response_cf(:)), 1);
posCF = pos + ([row, col] - center) / area_resize_factor;

%在图中框出对应位置的坐标并显示
seq = 'skating1';
addpath('D:\MyProject\Matlab\OTB\tracker_benchmark_v1.0\util');
seqs = configSeqs;
for i = 1:length(seqs),
    seqStruct = seqs{i};
    if strcmp(seqStruct.name, seq),
        break;
    end
end

groundtrth_path = seqStruct.path(1:end-4);
f = fopen([groundtrth_path, 'groundtruth_rect.txt']);
ground_truth = textscan(f, '%f,%f,%f,%f');  %[x, y, width, height]
ground_truth = cat(2, ground_truth{:});
fclose(f);

if size(ground_truth,1) >= frame,
    realPos = ground_truth(frame, :);
    imshow(im);
    hold on;
    rectangle('Position', realPos, 'EdgeColor', 'g', 'LineWidth', 1);
    plot(posCF(2),posCF(1),'y+','MarkerSize',8,'LineWidth', 2);
    plot(posCOLOR(2),posCOLOR(1),'rX','MarkerSize',8,'LineWidth', 2);%x y
%         plot(10, 20,'y+','MarkerSize',10,'LineWidth', 3);
%         plot(30,40,'rX','MarkerSize',10,'LineWidth', 3);%x y
    legend('CF response','COLOR response');
else
    dip('帧数错误');
end 




