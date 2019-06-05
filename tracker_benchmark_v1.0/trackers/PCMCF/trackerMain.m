function [results] = trackerMain(p, im, bg_area, fg_area, area_resize_factor,n)
%TRACKERMAIN contains the main loop of the tracker, P contains all the parameters set in runTracker
    Ave_cf = 0;
    isUpdateColorModel = true;
	
	t = 0:0.01:2;
    learning_rate_cf = 0.01 + 0.005 * 0.0007 ./(0.0007 + exp(-2.57 ./ (abs(t-1)+0.0001)));
    learning_rate_scale = 0.025 + 0.005 * 0.0007 ./(0.0007 + exp(-2.57 ./ (abs(t-1)+0.0001)));
	
    %% INITIALIZATION
    num_frames = n;
    % used for OTB-13 benchmark
    OTB_rect_positions = zeros(num_frames, 4);
    positions = zeros(num_frames, 4);
	pos = p.init_pos;
    target_sz = p.target_sz;
	num_frames = numel(p.img_files);
    % patch of the target + padding
    patch_padded = getSubwindow(im, pos, p.norm_bg_area, bg_area);
    % initialize hist model
    new_pwp_model = true;
    model = updateColorModel(new_pwp_model, patch_padded, bg_area, fg_area, target_sz, p.norm_bg_area, p.n_bins);
    ww = getPixelProb(patch_padded, model, p.n_bins);
    rgb = label2rgb(gray2ind(ww, 255) + 1, jet(255));
    init_area = sum(sum(ww>0.5)) + 1;
    ave_area = init_area;
    num_area = 1;
    new_pwp_model = false;
    % Hann (cosine) window
    if isToolboxAvailable('Signal Processing Toolbox')
        hann_window = single(hann(p.cf_response_size(1)) * hann(p.cf_response_size(2))');
    else
        hann_window = single(myHann(p.cf_response_size(1)) * myHann(p.cf_response_size(2))');
    end
    % gaussian-shaped desired response, centred in (1,1)
    % bandwidth proportional to target size
    output_sigma = sqrt(prod(p.norm_target_sz)) * p.output_sigma_factor / p.hog_cell_size;
    [rs, cs] = ndgrid((1:p.cf_response_size(1)) - floor(p.cf_response_size(1)/2), (1:p.cf_response_size(2)) - floor(p.cf_response_size(2)/2));
    y = exp(-0.5 / output_sigma^2 * (rs.^2 + cs.^2));
    y = gaussianResponse(p.cf_response_size, output_sigma);
    yf = fft2(y);
    %% SCALE ADAPTATION INITIALIZATION
    if p.scale_adaptation
        % Code from DSST
        scale_factor = 1;
        base_target_sz = target_sz;
        scale_sigma = sqrt(p.num_scales) * p.scale_sigma_factor;
        ss = (1:p.num_scales) - ceil(p.num_scales/2);
        ys = exp(-0.5 * (ss.^2) / scale_sigma^2);
        ysf = single(fft(ys));
        if mod(p.num_scales,2) == 0
            scale_window = single(hann(p.num_scales+1));
            scale_window = scale_window(2:end);
        else
            scale_window = single(hann(p.num_scales));
        end;

        ss = 1:p.num_scales;
        scale_factors = p.scale_step.^(ceil(p.num_scales/2) - ss);

        if p.scale_model_factor^2 * prod(p.norm_target_sz) > p.scale_model_max_area
            p.scale_model_factor = sqrt(p.scale_model_max_area/prod(p.norm_target_sz));
        end

        scale_model_sz = floor(p.norm_target_sz * p.scale_model_factor);
        % find maximum and minimum scales
        min_scale_factor = p.scale_step ^ ceil(log(max(5 ./ bg_area)) / log(p.scale_step));
        max_scale_factor = p.scale_step ^ floor(log(min([size(im,1) size(im,2)] ./ target_sz)) / log(p.scale_step));
    end

    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%
    t_imread = 0;
    %% MAIN LOOP
    tic;
    for frame = 1:num_frames
        if frame>1
            tic_imread = tic;
            im = imread([p.img_path p.img_files{frame}]);
            t_imread = t_imread + toc(tic_imread);
	    %% TESTING step
            % extract patch of size bg_area and resize to norm_bg_area
            
            im_patch_cf = getSubwindow(im, pos, p.norm_bg_area, bg_area);
            pwp_search_area = round(p.norm_pwp_search_area / area_resize_factor);
            % extract patch of size pwp_search_area and resize to norm_pwp_search_area
            im_patch_pwp = getSubwindow(im, pos, p.norm_pwp_search_area, pwp_search_area);
            % compute feature map
            
            xt = getFeatureMap1(im_patch_cf, p.feature_type, p.cf_response_size, p.hog_cell_size);
            
            % apply Hann window           
            xt_windowed = bsxfun(@times, hann_window, xt);
            % compute FFT
            xtf = fft2(xt_windowed);
%             kzf = gaussian_correlation(xtf, model_xf, kernel_sigma);
%             response_cf = real(ifft2(model_alphaf .* kzf)); 
            % Correlation between filter and test patch gives the response
            % Solve diagonal system per pixel.
            if p.den_per_channel
                hf = hf_num ./ (hf_den + p.lambda);
            else
                hf = bsxfun(@rdivide, hf_num, sum(hf_den, 3)+p.lambda);
            end
            response_cf = ensure_real(ifft2(sum(conj(hf) .* xtf, 3)));

            % Crop square search region (in feature pixels).
            response_cf = cropFilterResponse(response_cf, ...
                floor_odd(p.norm_delta_area / p.hog_cell_size));
            if p.hog_cell_size > 1
                % Scale up to match center likelihood resolution.
                response_cf = mexResize(response_cf, p.norm_delta_area,'auto');
            end
            %[likelihood_map] = getColourMap(im_patch_pwp, bg_hist, fg_hist, p.n_bins, p.grayscale_sequence);
            pixelProb = getPixelProb(im_patch_pwp, model, p.n_bins);
            
            now_area = sum(sum(pixelProb>0.5));
            % (TODO) in theory it should be at 0.5 (unseen colors shoud have max entropy)
            pixelProb(isnan(pixelProb)) = 0;
            % each pixel of response_pwp loosely represents the likelihood that
            % the target (of size norm_target_sz) is centred on it
            response_pwp = getCenterLikelihood(pixelProb, p.norm_target_sz);
            max_cf = max(max(response_cf));
            Ave_cf = (Ave_cf * (frame - 2) + max_cf) / (frame - 1);
            
            ratio = now_area * 1.0 / ave_area;
            %p.learning_rate_cf = 0.01 + 0.005 * 0.0007 /(0.0007 + exp(-2.57 / (abs(ratio-1)+0.0001)));
            %p.learning_rate_scale = 0.025 + 0.005 * 0.0007 /(0.0007 + exp(-2.57 / (abs(ratio-1)+0.0001)));
			
			if ratio > 2
				ratio = 2;
			end
			
			if ratio < 0.01
				ratio = 0.01;
			end
			
			p.learning_rate_cf = learning_rate_cf(floor(ratio*100));
            p.learning_rate_scale = learning_rate_scale(floor(ratio*100));
            
            if now_area > 0.7 * ave_area && now_area < 1.25 * ave_area
                ave_area = (ave_area * num_area + now_area) / (num_area + 1);
                num_area = num_area + 1;
                isUpdateColorModel = true;
                response = mergeResponses(response_cf, response_pwp, p.merge_factor, p.merge_method);
            else
                response = response_cf;
            end
            
%             if now_area > 0.7 * ave_area && now_area < 1.25 * ave_area
%                 response = mergeResponses(response_cf, response_pwp, p.merge_factor, p.merge_method);
%                 ave_area = (ave_area * num_area + now_area) / (num_area + 1);
%                 num_area = num_area + 1;
%                 isUpdateColorModel = true;
%                 p.learning_rate_cf = 0.015;
%                 p.learning_rate_scale = 0.03;
%             else
%                 response = response_cf;
%                 isUpdateColorModel = false;
%                 p.learning_rate_cf = 0.01; 
%                 p.learning_rate_scale = 0.025;
%             end

            [row, col] = find(response == max(response(:)), 1);
            center = (1+p.norm_delta_area) / 2;
            pos = pos + ([row, col] - center) / area_resize_factor;
            rect_position = [pos([2,1]) - target_sz([2,1])/2, target_sz([2,1])];

            %% SCALE SPACE SEARCH
            if p.scale_adaptation
                im_patch_scale = getScaleSubwindow(im, pos, base_target_sz, scale_factor * scale_factors, scale_window, scale_model_sz, p.hog_scale_cell_size);
                xsf = fft(im_patch_scale,[],2);
                scale_response = real(ifft(sum(sf_num .* xsf, 1) ./ (sf_den + p.lambda) ));
                recovered_scale = ind2sub(size(scale_response),find(scale_response == max(scale_response(:)), 1));
                %set the scale
                scale_factor = scale_factor * scale_factors(recovered_scale);

                if scale_factor < min_scale_factor
                    scale_factor = min_scale_factor;
                elseif scale_factor > max_scale_factor
                    scale_factor = max_scale_factor;
                end
                % use new scale to update bboxes for target, filter, bg and fg models
                target_sz = round(base_target_sz * scale_factor);
                avg_dim = sum(target_sz)/2;
                bg_area = round(target_sz + avg_dim);
                if(bg_area(2)>size(im,2)),  bg_area(2)=size(im,2)-1;    end
                if(bg_area(1)>size(im,1)),  bg_area(1)=size(im,1)-1;    end

                bg_area = bg_area - mod(bg_area - target_sz, 2);
                fg_area = round(target_sz - avg_dim * p.inner_padding);
                fg_area = fg_area + mod(bg_area - fg_area, 2);
                % Compute the rectangle with (or close to) params.fixed_area and
                % same aspect ratio as the target bboxgetScaleSubwindow
                area_resize_factor = sqrt(p.fixed_area/prod(bg_area));
            end

            if p.visualization_dbg==1
                mySubplot(2,1,5,1,im_patch_cf,'FG+BG','gray');
                mySubplot(2,1,5,2,likelihood_map,'obj.likelihood','parula');
                mySubplot(2,1,5,3,response_cf,'CF response','parula');
                mySubplot(2,1,5,4,response_pwp,'center likelihood','parula');
                mySubplot(2,1,5,5,response,'merged response','parula');
                drawnow
            end
        end

        %% TRAINING
        % extract patch of size bg_area and resize to norm_bg_area
        im_patch_bg = getSubwindow(im, pos, p.norm_bg_area, bg_area);
        % compute feature map, of cf_response_size
        xt = getFeatureMap1(im_patch_bg, p.feature_type, p.cf_response_size, p.hog_cell_size);
        % apply Hann window
        xt = bsxfun(@times, hann_window, xt);
        % compute FFT
        xtf = fft2(xt);
        %% FILTER UPDATE
        % Compute expectations over circular shifts,
        % therefore divide by number of pixels.
        
%         kf = gaussian_correlation(xtf, xtf, kernel_sigma);
%         alphaf = yf ./ (kf + lambda);
        
		new_hf_num = bsxfun(@times, conj(yf), xtf) / prod(p.cf_response_size);
		new_hf_den = (conj(xtf) .* xtf) / prod(p.cf_response_size);

        if frame == 1
            % first frame, train with a single image
		    hf_den = new_hf_den;
		    hf_num = new_hf_num;
            
%             model_alphaf = alphaf;
%             model_xf = xtf;
		else
		    % subsequent frames, update the model by linear interpolation
        	hf_den = (1 - p.learning_rate_cf) * hf_den + p.learning_rate_cf * new_hf_den;
	   	 	hf_num = (1 - p.learning_rate_cf) * hf_num + p.learning_rate_cf * new_hf_num;

%             model_alphaf = (1 - interp_factor) * model_alphaf + interp_factor * alphaf;
%             model_xf = (1 - interp_factor) * model_xf + interp_factor * xtf;

            %% BG/FG MODEL UPDATE
            % patch of the target + padding
            %[bg_hist, fg_hist] = updateHistModel(new_pwp_model, im_patch_bg, bg_area, fg_area, target_sz, p.norm_bg_area, p.n_bins, p.grayscale_sequence, bg_hist, fg_hist, p.learning_rate_pwp);
            if isUpdateColorModel
                model = updateColorModel(new_pwp_model, patch_padded, bg_area, fg_area, target_sz, p.norm_bg_area, p.n_bins, model);
            end
        end

        %% SCALE UPDATE
        if p.scale_adaptation
            im_patch_scale = getScaleSubwindow(im, pos, base_target_sz, scale_factor*scale_factors, scale_window, scale_model_sz, p.hog_scale_cell_size);
            xsf = fft(im_patch_scale,[],2);
            new_sf_num = bsxfun(@times, ysf, conj(xsf));
            new_sf_den = sum(xsf .* conj(xsf), 1);
            if frame == 1,
                sf_den = new_sf_den;
                sf_num = new_sf_num;
            else
                sf_den = (1 - p.learning_rate_scale) * sf_den + p.learning_rate_scale * new_sf_den;
                sf_num = (1 - p.learning_rate_scale) * sf_num + p.learning_rate_scale * new_sf_num;
            end
        end

        % update bbox position
        if frame==1, rect_position = [pos([2,1]) - target_sz([2,1])/2, target_sz([2,1])]; end

        rect_position_padded = [pos([2,1]) - bg_area([2,1])/2, bg_area([2,1])];

        OTB_rect_positions(frame,:) = rect_position;
        positions(frame,:) = [pos target_sz];
        
        if p.fout > 0,  fprintf(p.fout,'%.2f,%.2f,%.2f,%.2f\n', rect_position(1),rect_position(2),rect_position(3),rect_position(4));   end

        %% VISUALIZATION
%         if p.visualization == 1
%             if isToolboxAvailable('Computer Vision System Toolbox')
%                 im = insertShape(im, 'Rectangle', rect_position, 'LineWidth', 4, 'Color', 'black');
%                 im = insertShape(im, 'Rectangle', rect_position_padded, 'LineWidth', 4, 'Color', 'yellow');
%                 % Display the annotated video frame using the video player object.
%                 step(p.videoPlayer, im);
%             else
%                 figure(1)
%                 imshow(im)
%                 rectangle('Position',rect_position, 'LineWidth',2, 'EdgeColor','g');
%                 rectangle('Position',rect_position_padded, 'LineWidth',2, 'LineStyle','--', 'EdgeColor','b');
%                 drawnow
%             end
%         end
    if p.visualization == 1
        rect_position = [pos([2,1]) - target_sz([2,1])/2, target_sz([2,1])];
        if frame == 1,  %first frame, create GUI
            %figure('Number','off', 'Name',['Tracker - ' video_path]);
            im_handle = imshow(uint8(im), 'Border','tight', 'InitialMag', 100 + 100 * (length(im) < 500));
            rect_handle = rectangle('Position',rect_position, 'EdgeColor','g');
            text_handle = text(10, 10, int2str(frame));
            set(text_handle, 'color', [0 1 1]);
        else
            try  %subsequent frames, update GUI
                set(im_handle, 'CData', im)
                set(rect_handle, 'Position', rect_position)
                set(text_handle, 'string', int2str(frame));
            catch
                return
            end
        end
        
        drawnow
%         pause
    end
    end
    elapsed_time = toc;
    % save data for OTB-13 benchmark
    results.type = 'rect';
    results.res = OTB_rect_positions;
    results.fps = num_frames/(elapsed_time - t_imread);
    results.positions = positions;
end

% Reimplementation of Hann window (in case signal processing toolbox is missing)
function H = myHann(X)
    H = .5*(1 - cos(2*pi*(0:X-1)'/(X-1)));
end

% We want odd regions so that the central pixel can be exact
function y = floor_odd(x)
    y = 2*floor((x-1) / 2) + 1;
end

function y = ensure_real(x)
    assert(norm(imag(x(:))) <= 1e-5 * norm(real(x(:))));
    y = real(x);
end
