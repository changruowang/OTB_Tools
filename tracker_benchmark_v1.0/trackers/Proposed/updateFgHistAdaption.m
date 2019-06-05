function fg_hist_new = updateFgHistAdaption(patch, bg_area, target_sz, fg_hist, updateMask, occflag)
%UPDATEHISTMODEL create new models for foreground and background or update the current ones
    global n_frame;   
    
%     learningRate = (3-occflag)*0.01;
    learningRate = 0.04;
    
    pad_offset2 = floor((bg_area-target_sz)/2); % we constrained the difference to be mod2, so we do not have to round here
    fg_mask = false(bg_area); % init fg_mask
    pad_offset2(pad_offset2<=0)=1;
    fg_mask(pad_offset2(1)+1:end-pad_offset2(1), pad_offset2(2)+1:end-pad_offset2(2)) = true;
    fg_mask = fg_mask.*updateMask;
    
    fg_hist_now = computeHistogram(patch, fg_mask , 2^5, false);
    
%     if occflag == 1,
%         learningRate = 0.02;
%     elseif occflag == 2,
%         learningRate = 0.0;
%     end
    if mod(n_frame, 5) == 0,    
        fg_hist_new = fg_hist_now;
    else
        fg_hist_new = (1 - learningRate)*fg_hist + learningRate*fg_hist_now;     
    end
end