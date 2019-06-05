function contrastSim(seq)
    global History;
    
    addpath('../util');
    addpath('../trackers/Proposed');
    seqs = configSeqs;

    for i = 1:length(seqs),
        seqStruct = seqs{i};
        if strcmp(seqStruct.name, seq),
            break;
        end
    end
    groundtrth_path = seqStruct.path(1:end-4);
    f = fopen([groundtrth_path, 'groundtruth_rect.txt']);
    ground_truth1 = textscan(f, '%f,%f,%f,%f');  %[x, y, width, height]
    ground_truth1 = cat(2, ground_truth1{:});
    ground_truth = ground_truth1;
    ground_truth(:,1:2) = ground_truth1(:,1:2) +  floor(ground_truth1(:,3:4)/2); 
 
    fclose(f);
    
    nz	= strcat('%0',num2str(seqStruct.nz),'d');
    
    History = zeros(seqStruct.endFrame-seqStruct.startFrame+1,1);
    
    for i = seqStruct.startFrame:seqStruct.endFrame,
       id = sprintf(nz,i);
       imgPath = strcat(seqStruct.path,id,'.',seqStruct.ext); 
       img = imread(imgPath);
       imshow(img);

       pos = ground_truth(i,1:2);
       target_sz = ground_truth(i,3:4);
       window_sz = floor(target_sz*2);
       windoe_rect = [floor(pos - window_sz/2) window_sz];
       rectangle('Position', ground_truth1(i,:), 'EdgeColor', 'r', 'LineWidth', 4);  
       rectangle('Position', windoe_rect, 'EdgeColor', 'g', 'LineWidth', 4);  
       drawnow
       
       patch = get_subwindow(img, pos, window_sz, 1);
       
       [bg_hist, fg_hist] = updateHistModel(true, patch, window_sz, target_sz,0 ,0 ,0);
       bg = bg_hist(:);
       fg = fg_hist(:);
       
       tmp = bg .* fg;
       bh = sum(tmp.^0.5);
       History(i) = 1 - (1 - bh)^0.5;
    end
    
end