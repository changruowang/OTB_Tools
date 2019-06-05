function results=run_Contrast2(seq, res_path, bSaveImage)

params.padding = 1.5;         			% extra area surrounding the target
params.t_lambda = 1e-4;		
params.t_output_sigma_factor =  0.1;
params.t_learning_rate = 0.02;
params.t_sigma = 0.5;
params.cell_size = 4;
params.visualization = 1;

params.s_lambda = 1e-2;
params.s_sigma_factor = 1/4;
params.s_learning_rate = 0.025;
params.scale_step = 1.03;
params.scale_model_max_area = 512; 
params.number_of_scales = 33; 

target_sz = [seq.init_rect(1,4), seq.init_rect(1,3)];
params.init_pos = [seq.init_rect(1,2), seq.init_rect(1,1)] + floor(target_sz/2);
params.wsize = floor(target_sz);
params.img_files = seq.s_frames;


[positions, fps] = dsst(params);

disp(['fps: ' num2str(fps)])
results.type = 'rect';
results.res = positions;%each row is a rectangle
results.fps = fps;





