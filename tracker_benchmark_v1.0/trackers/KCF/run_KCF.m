function results=run_KCF(seq, res_path, bSaveImage)

    kernel_type = 'gaussian';
 	%parameters based on the chosen kernel or feature type
	kernel.type = kernel_type;
	show_visualization = 1;
	features.gray = false;
	
	padding = 1.5;  %extra area surrounding the target
	lambda = 1e-4;  %regularization
	output_sigma_factor = 0.1;  %spatial bandwidth (proportional to target)   
    
    interp_factor = 0.02;  %0.02
    kernel.sigma = 0.5;

    
    kernel.poly_a = 1;
    kernel.poly_b = 9;

    features.hog = true;
    features.hog_orientations = 9;
    cell_size = 4;
  
    img_files = seq.s_frames;
    video_path = 'KCF';
    target_sz = [seq.init_rect(1,4), seq.init_rect(1,3)];
    pos = [seq.init_rect(1,2), seq.init_rect(1,1)] + floor(target_sz/2);

    [positions, time] = tracker(video_path, img_files, pos, target_sz, ...
    padding, kernel, lambda, output_sigma_factor, interp_factor, ...
    cell_size, features, show_visualization);

    results.type = 'rect';
    results.res = positions;%each row is a rectangle
    results.fps = time;

    
    
    
    


