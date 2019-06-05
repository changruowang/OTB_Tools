function model = updateColorModel(new_model, patch, bg_area, fg_area, target_sz, norm_area, n_bins, model)
%UPDATEHISTMODEL create new models for foreground and background or update the current ones

	% Get BG (frame around target_sz) and FG masks (inner portion of target_sz)
	pad_offset1 = (bg_area-target_sz)/2; % we constrained the difference to be mod2, so we do not have to round here
	assert(sum(pad_offset1==round(pad_offset1))==2, 'difference between bg_area and target_sz has to be even.');

	bg_mask = true(bg_area); % init bg_mask
	pad_offset1(pad_offset1<=0)=1;
	bg_mask(pad_offset1(1)+1:end-pad_offset1(1), pad_offset1(2)+1:end-pad_offset1(2)) = false;

	pad_offset2 = (bg_area-fg_area)/2; % we constrained the difference to be mod2, so we do not have to round here
	assert(sum(pad_offset2==round(pad_offset2))==2, 'difference between bg_area and fg_area has to be even.');
	fg_mask = false(bg_area); % init fg_mask
	pad_offset2(pad_offset2<=0)=1;
	fg_mask(pad_offset2(1)+1:end-pad_offset2(1), pad_offset2(2)+1:end-pad_offset2(2)) = true;

	fg_mask = logical(mexResize(fg_mask, norm_area, 'auto'));
	bg_mask = logical(mexResize(bg_mask, norm_area, 'auto'));
    

    
	%% (TRAIN) BUILD THE MODEL
    if new_model
        sample = getBinaryFeature(patch, n_bins);
        label_pos = reshape(fg_mask, norm_area(1)*norm_area(2),1);
        label_neg = reshape(bg_mask, norm_area(1)*norm_area(2),1);
        model = LogisticRegressionTrain(sample(label_pos,:), sample(label_neg,:));
%         xx = LogisticRegressionTest(sample, model);
%         xx = reshape(xx, norm_area(1), norm_area(2));
	else
        sample = getBinaryFeature(patch, n_bins);
        label_pos = reshape(fg_mask, norm_area(1)*norm_area(2),1);
        label_neg = reshape(bg_mask, norm_area(1)*norm_area(2),1);
        model = LogisticRegressionTrain(sample(label_pos,:), sample(label_neg,:), model);
    end

end