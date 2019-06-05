function [bg_hist_new, fg_hist_new] = updateHistModel(new_model, patch, bg_area, target_sz, bg_hist, fg_hist, learning_rate_pwp)
%UPDATEHISTMODEL create new models for foreground and background or update the current ones

	% Get BG (frame around target_sz) and FG masks (inner portion of target_sz)
	pad_offset1 = floor((bg_area-target_sz*0.8)/2); % we constrained the difference to be mod2, so we do not have to round here
	bg_mask = true(bg_area); % init bg_mask
	pad_offset1(pad_offset1<=0)=1;
	bg_mask(pad_offset1(1)+1:end-pad_offset1(1), pad_offset1(2)+1:end-pad_offset1(2)) = false;

	pad_offset2 = floor((bg_area-target_sz)/2); % we constrained the difference to be mod2, so we do not have to round here
	fg_mask = false(bg_area); % init fg_mask
	pad_offset2(pad_offset2<=0)=1;
	fg_mask(pad_offset2(1)+1:end-pad_offset2(1), pad_offset2(2)+1:end-pad_offset2(2)) = true;


	%% (TRAIN) BUILD THE MODEL
	if new_model
		% from scratch (frame=1)
		bg_hist_new = computeHistogram(patch, bg_mask, 2^5, false);
		fg_hist_new = computeHistogram(patch, fg_mask, 2^5, false);
	else
		% update the model
		bg_hist_new = (1 - learning_rate_pwp)*bg_hist + learning_rate_pwp*computeHistogram(patch, bg_mask, 2^5, false);
		fg_hist_new = (1 - learning_rate_pwp)*fg_hist + learning_rate_pwp*computeHistogram(patch, fg_mask, 2^5, false);
	end

end