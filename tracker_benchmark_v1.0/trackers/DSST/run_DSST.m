function results=run_DSST(seq, res_path, bSaveImage)

%parameters according to the paper
params.padding = 1.0;         			% extra area surrounding the target
params.output_sigma_factor = 1/16;		% standard deviation for the desired translation filter output
params.scale_sigma_factor = 1/4;        % standard deviation for the desired scale filter output
params.lambda = 1e-2;					% regularization weight (denoted "lambda" in the paper)
params.learning_rate = 0.025;			% tracking model learning rate (denoted "eta" in the paper)0.025;
params.number_of_scales = 33;           % number of scale levels (denoted "S" in the paper)
params.scale_step = 1.02;               % Scale increment factor (denoted "a" in the paper)
params.scale_model_max_area = 512;      % the maximum size of scale examples
params.visualization = 1;

target_sz = [seq.init_rect(1,4), seq.init_rect(1,3)];
params.init_pos = [seq.init_rect(1,2), seq.init_rect(1,1)] + floor(target_sz/2);
%params.init_pos = floor(pos) + floor(target_sz/2);
params.wsize = floor(target_sz);

params.img_files = seq.s_frames;
params.video_path = 'DSST';

[positions, fps] = dsst(params);

positions = [(positions(:,[2,1]) - floor((positions(:,[4,3]) - 1)/2)) ,positions(:,[4,3])];

disp(['fps: ' num2str(fps)])
results.type = 'rect';
results.res = positions;%each row is a rectangle
results.fps = fps;
%calculate precisions
% [distance_precision, PASCAL_precision, average_center_location_error] = ...
%     compute_performance_measures(positions, ground_truth);

% fprintf('Center Location Error: %.3g pixels\nDistance Precision: %.3g %%\nOverlap Precision: %.3g %%\nSpeed: %.3g fps\n', ...
%     average_center_location_error, 100*distance_precision, 100*PASCAL_precision, fps);






