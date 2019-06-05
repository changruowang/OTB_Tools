%��Propose tracker�����ڷ��� color��Ӧ��CF��Ӧ����ĸ���λ��
%�÷����ڷ���ϵ����øýű� �ű��в��ֱ���ֱ��ʹ�ù������еı���
%      ����Ŀ¼����path
[row, col] = find(response_pwp == max(response_pwp(:)), 1);
posCOLOR = pos + ([row, col] - center) / area_resize_factor;
[row, col] = find(response_cf == max(response_cf(:)), 1);
posCF = pos + ([row, col] - center) / area_resize_factor;

%��ͼ�п����Ӧλ�õ����겢��ʾ
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
    dip('֡������');
end 




