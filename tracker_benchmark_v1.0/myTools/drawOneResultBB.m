function drawOneResultBB(tracker, seq)
    addpath('../util');
    seqs = configSeqs;
    for i = 1:length(seqs),
        seqStruct = seqs{i};
        if strcmp(seqStruct.name, seq),
            break;
        end
    end
     nz	= strcat('%0',num2str(seqStruct.nz),'d');
    
    pathRes = '.\results\results_OPE_CVPR13\';
    matfileName = [pathRes seq '_' tracker '.mat'];
    
    load(matfileName);
    s = results{1};
    
    len = s.len;
    start = s.startFrame;
    for i = start:(len+start-1),
        no = i-start+1;
        id = sprintf(nz,i);
        seqFilePath = strcat(seqStruct.path,id,'.',seqStruct.ext);
        img = imread(seqFilePath);
        imshow(img);
        
        text(10, 15, ['#' num2str(no)], 'Color','y', 'FontWeight','bold', 'FontSize',24);
        rectangle('Position', s.res(no,:), 'EdgeColor', 'r', 'LineWidth', 4);
        
        drawnow
        imwrite(frame2im(getframe(gcf)), ['.\tmp\imgs\' seq  '_' tracker '/'  num2str(no) '.png']);
    end   
end