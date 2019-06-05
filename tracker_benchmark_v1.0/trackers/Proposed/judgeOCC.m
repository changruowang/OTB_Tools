function [occflag, updateMask] = judgeOCC(patch, bg_hist, fg_hist, target_sz, occflag)
    global History; 
    global n_frame;
    global APEC_H;
    
    window_sz = size(patch);

    tmp = floor((window_sz(1:2) - target_sz)/2);

    [likelihood_map] = getColourMap(patch, bg_hist, fg_hist, 2^5, false);
    updateMask = true(size(likelihood_map));
    obj_likehood = likelihood_map((tmp(1)+1):(tmp(1)+target_sz(1)), (tmp(2)+1):(tmp(2)+target_sz(2)));
    obj_likehood = floor(obj_likehood*255);
    obj_binary = im2bw(obj_likehood,graythresh(obj_likehood));
    SE=strel('square',2);
    obj_binary = imdilate(obj_binary,SE);
    obj_binary = imerode(obj_binary,SE);
    Lable = bwlabel(~obj_binary,8);
    mounts = length(unique(Lable))-1;

    for i = 1:mounts,
        [rows, cols] = find(Lable == i);
        areaS = length(rows);
        if areaS < 20,
            obj_binary(Lable == i) = 1;
            continue;     
        end
        edge_flag = [min(rows),max(rows)-target_sz(1)+1,min(cols),max(cols)-target_sz(2)+1];

        if ~any(edge_flag == 1),
            obj_binary(Lable == i) = 1;
        end
    end 
    updateMask((tmp(1)+1):(tmp(1)+target_sz(1)), (tmp(2)+1):(tmp(2)+target_sz(2))) = obj_binary;  
    areaS = length(find(obj_binary == 0));
  
    if n_frame>10 && occflag <= 1,   
        nz_s = History(1:n_frame-1,4);
        nz_s(nz_s==0) = [];
        thr = mean(nz_s);
        thr(isnan(thr)) = 0;
        if ((areaS > thr*3) && (History(n_frame,2)+15 < History(n_frame, 6))),
            occflag = 2;
            APEC_H = mean(History(n_frame-2:n_frame-1,2));
            History(n_frame,4) = thr;
        elseif areaS > thr*2,
            occflag = 1;
        else 
            occflag = 0;
        end 
    end
    
    if occflag == 2 && History(n_frame,2) > APEC_H,
         occflag = 0;
    end

     History(n_frame,5) = occflag;
     str_show = sprintf('obj.binary: %d',occflag);     

     mySubplot(2,1,3,1,likelihood_map,'background.likelihood','parula');
     mySubplot(2,1,3,2,obj_likehood,'obj.likelihood','parula');
     mySubplot(2,1,3,3,obj_binary,str_show,'gray');
     drawnow
     
%      if n_frame > 105 && n_frame < 119,
%          occflag = 2;
%      end
end

