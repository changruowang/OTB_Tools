function [positions, fps] = dsst(params)
    global n_frame;
    global History;
    global History1;
    target_sz = params.wsize;
    pos = params.init_pos;
    img_files = params.img_files;
    
    resize_image = (sqrt(prod(target_sz)) >= 100);
    if resize_image,
            pos = floor(pos / 2);
            target_sz = floor(target_sz / 2);
    end
    window_sz = floor(target_sz * (1 + params.padding));


    output_sigma = sqrt(prod(target_sz)) * (params.t_output_sigma_factor) / (params.cell_size);
    yf = fft2(gaussian_shaped_labels(output_sigma, floor(window_sz / params.cell_size)));
   
    t_cos_window = single(hann(size(yf,1)) * hann(size(yf,2))');

    num_frames = numel(params.img_files);
    % parameters

    nScales = params.number_of_scales;
    scale_step = params.scale_step;
    scale_sigma_factor = params.s_sigma_factor;
    scale_model_max_area = params.scale_model_max_area;


    % desired scale filter output (gaussian shaped), bandwidth proportional to
    % number of scales
    scale_sigma = nScales/sqrt(33) * scale_sigma_factor;
    ss = (1:nScales) - ceil(nScales/2);
    ys = exp(-0.5 * (ss.^2) / scale_sigma^2);
    ysf = single(fft(ys));
    % store pre-computed translation filter cosine window
    %为啥要分情况？
    % store pre-computed scale filter cosine window
    if mod(nScales,2) == 0
        scale_window = single(hann(nScales+1));
        scale_window = scale_window(2:end);
    else
        scale_window = single(hann(nScales));
    end;

    % scale factors
    ss = 1:nScales;
    scaleFactors = scale_step.^(ceil(nScales/2) - ss);

    % compute the resize dimensions used for feature extraction in the scale
    % estimation
    scale_model_factor = 1;
    if prod(target_sz) > scale_model_max_area
        scale_model_factor = sqrt(scale_model_max_area/prod(target_sz));
    end
    scale_model_sz = floor(target_sz * scale_model_factor);
%scale_model_sz 用来限制尺度采样图像的大小 将尺度的采样值大小限制在一定大小之下
    currentScaleFactor = 1;

    % to calculate precision
    positions = zeros(numel(img_files), 4);
    setGlobal(numel(img_files));
    % to calculate FPS
    time = 0;

    % find maximum and minimum scales
    im = imread(img_files{1});
    if resize_image,
		im = imresize(im, 0.5);
    end
    min_scale_factor = scale_step ^ ceil(log( max(5 ./ window_sz)) / log(scale_step));
    max_scale_factor = scale_step ^ floor(log(min([size(im,1) size(im,2)] ./ target_sz)) / log(scale_step));

    for frame = 1:num_frames,
        n_frame = frame;
        if frame == 90,
            aaaa = 1;
        end 
        
        %load image
        im = imread(img_files{frame});

        if resize_image,
			im = imresize(im, 0.5);
        end
        
        tic();
        if frame > 1
            zf = fft2(get_translation_sample(im, pos, window_sz, currentScaleFactor, t_cos_window)); 
            % calculate the correlation response of the translation filter
            kzf = gaussian_correlation(zf, model_xf, params.t_sigma);
           
%             response_cf = real(ifft2(model_alphaf .* kzf));
%             response_cf = circshift(response_cf, floor(size(response_cf) / 2) - 1); 
     
            responsef = model_alphaf .* kzf;
            interp_sz = 4*size(responsef);
            responsef = resizeDFT2(responsef, interp_sz);
            response_cf = ifft2(responsef,'symmetric');  %equation for fast detection 
            if frame==2,
                [row, col] = find(response_cf == max(response_cf(:)), 1); 
                row2 = mod(row - 1 + floor((interp_sz(1)-1)/2), interp_sz(1));
                col2 = mod(col - 1 + floor((interp_sz(2)-1)/2), interp_sz(2)); 
                shift_pix = [row2, col2] - [row, col];
            end
            response_cf = circshift(response_cf, shift_pix); 
%             [row, col] = find(response_cf == max(response_cf(:)), 1);
%             center = floor((interp_sz-1)/2);
%             pos = pos + round(([row, col] - center) * currentScaleFactor);
		
            patch = get_subwindow(im, pos, window_sz, currentScaleFactor);
		    [likelihood_map] = getColourMap(patch, bg_hist, fg_hist, 2^5, false);
		    likelihood_map(isnan(likelihood_map)) = 0;
			response_pwp = getCenterLikelihood(likelihood_map, target_sz);
            response_pwp = mexResize(response_pwp, size(response_cf), 'auto');
            
            alpha = calWeight(bg_hist, fg_hist, response_cf);
            response = response_pwp*alpha + (1-alpha)*response_cf;
            [vert_delta, horiz_delta] = find(response == max(response(:)), 1); %1 找到第一个不为0的元素
            center = floor((interp_sz-1)/2);
            pos = pos + ([vert_delta, horiz_delta] - center)* currentScaleFactor;    
    
%             response = response_pwp*alpha + (1-alpha)*response_cf;
%             [vert_delta, horiz_delta] = find(response == max(response(:)), 1); %1 找到第一个不为0的元素
%             center = floor(size(response) / 2);
%             pos = pos + params.cell_size * ([vert_delta, horiz_delta] - center)* currentScaleFactor;    
			
            xs = get_scale_sample(im, pos, target_sz, currentScaleFactor * scaleFactors, scale_window, scale_model_sz);
            xsf = fft(xs,[],2);
            scale_response = real(ifft(sum(sf_num .* xsf, 1) ./ (sf_den + params.s_lambda)));
            recovered_scale = find(scale_response == max(scale_response(:)), 1);
            currentScaleFactor = currentScaleFactor * scaleFactors(recovered_scale);
             if currentScaleFactor < min_scale_factor
                currentScaleFactor = min_scale_factor;
             elseif currentScaleFactor > max_scale_factor
                currentScaleFactor = max_scale_factor;
            end
        end
 
        %返回的x1为 18+9+1的28维fhog特征 w*h*28
        % extract the training sample feature map for the translation filter
        xf = fft2(get_translation_sample(im, pos, window_sz, currentScaleFactor, t_cos_window)); 
        kf = gaussian_correlation(xf, xf,params.t_sigma);
        alphaf = yf ./ (kf + params.t_lambda);   %equation for fast training

        xs = get_scale_sample(im, pos, target_sz, currentScaleFactor * scaleFactors, scale_window, scale_model_sz);
        xsf = fft(xs,[],2);
        new_sf_num = bsxfun(@times, ysf, conj(xsf));
        new_sf_den = sum(xsf .* conj(xsf), 1);

        patch = get_subwindow(im, pos, window_sz, currentScaleFactor);
        if frame == 1
            % first frame, train with a single image     
            model_alphaf = alphaf;
            model_xf = xf;

            sf_den = new_sf_den;
            sf_num = new_sf_num;
			
  			[bg_hist, fg_hist] = updateHistModel(true, patch, window_sz, target_sz,0 ,0 ,0);
        else
            % subsequent frames, update the model
            model_alphaf = (1 - params.t_learning_rate) * model_alphaf + params.t_learning_rate * alphaf;
            model_xf = (1 - params.t_learning_rate) * model_xf + params.t_learning_rate * xf;
            sf_den = (1 - params.s_learning_rate) * sf_den + params.s_learning_rate * new_sf_den;
            sf_num = (1 - params.s_learning_rate) * sf_num + params.s_learning_rate * new_sf_num;

            
            [bg_hist, fg_hist] = updateHistModel(false, patch, window_sz, target_sz, bg_hist, fg_hist, 0.04);
			mySubplot(2,1,2,1,likelihood_map,'obj.likelihood','parula');
            mySubplot(2,1,2,2,response_pwp,'center likelihood','parula');
            drawnow
        end

        % calculate the new target size
        now_target_sz = floor(target_sz * currentScaleFactor);

        positions(frame,:) =  [pos([2,1]) - now_target_sz([2,1])/2, now_target_sz([2,1])];
        time = time + toc();


        %visualization
        if params.visualization == 1
            rect_position = [pos([2,1]) - now_target_sz([2,1])/2, now_target_sz([2,1])];
            if frame == 1,  %first frame, create GUI
                figure('Name',['Tracker - ' 'DSST_2']);
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
        end
    end
    csvwrite('History.txt',History);
%     csvwrite('History1.txt',History1);
    if resize_image,
            positions = positions * 2;
    end
    fps = num_frames/time;
end



%             response = real(ifft2(model_alphaf .* kzf));
%             [vert_delta, horiz_delta] = find(response == max(response(:)), 1); %1 找到第一个不为0的元素
%             if vert_delta > size(zf,1) / 2,  %wrap around to negative half-space of vertical axis
%                 vert_delta = vert_delta - size(zf,1);
%             end
%             if horiz_delta > size(zf,2) / 2,  %same for horizontal axis
%                 horiz_delta = horiz_delta - size(zf,2);
%             end
%             pos = pos + params.cell_size * [vert_delta - 1, horiz_delta - 1] * currentScaleFactor;

%             responsef = model_alphaf .* kzf;
%             interp_sz = 4*size(responsef);
%             responsef = resizeDFT2(responsef, interp_sz);
%             response = ifft2(responsef,'symmetric');  %equation for fast detection
%             [row, col] = find(response == max(response(:)), 1); 
%             disp_row = mod(row - 1 + floor((interp_sz(1)-1)/2), interp_sz(1)) - floor((interp_sz(1)-1)/2);
%             disp_col = mod(col - 1 + floor((interp_sz(2)-1)/2), interp_sz(2)) - floor((interp_sz(2)-1)/2);
%             pos = pos + round([disp_row, disp_col]*currentScaleFactor);
          
%             responsef = model_alphaf .* kzf;
%             interp_sz = 4*size(responsef);
%             responsef = resizeDFT2(responsef, interp_sz);
%             response = ifft2(responsef,'symmetric');  %equation for fast detection 
%             if frame==2,
%                 [row, col] = find(response == max(response(:)), 1); 
%                 row2 = mod(row - 1 + floor((interp_sz(1)-1)/2), interp_sz(1));
%                 col2 = mod(col - 1 + floor((interp_sz(2)-1)/2), interp_sz(2)); 
%                 shift_pix = [row2, col2] - [row, col];
%             end
%             response_cf = circshift(response, shift_pix); 
%             [row, col] = find(response_cf == max(response_cf(:)), 1);
%             center = floor((interp_sz-1)/2);
%             pos = pos + round(([row, col] - center) * currentScaleFactor);