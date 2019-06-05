function results=run_CN(seq, res_path, bSaveImage)

%parameters according to the paper
params.padding = 1.0;         			   % extra area surrounding the target
params.output_sigma_factor = 1/16;		   % spatial bandwidth (proportional to target)
params.sigma = 0.2;         			   % gaussian kernel bandwidth
params.lambda = 1e-2;					   % regularization (denoted "lambda" in the paper)
params.learning_rate = 0.075;			   % learning rate for appearance model update scheme (denoted "gamma" in the paper)
params.compression_learning_rate = 0.15;   % learning rate for the adaptive dimensionality reduction (denoted "mu" in the paper)
params.non_compressed_features = {'gray'}; % features that are not compressed, a cell with strings (possible choices: 'gray', 'cn')
params.compressed_features = {'cn'};       % features that are compressed, a cell with strings (possible choices: 'gray', 'cn')
params.num_compressed_dim = 2;             % the dimensionality of the compressed features
params.visualization = 0;
target_sz = [seq.init_rect(1,4), seq.init_rect(1,3)];
params.init_pos =  [seq.init_rect(1,2), seq.init_rect(1,1)] + floor(target_sz/2);
params.wsize = floor(target_sz);
params.img_files = seq.s_frames;
params.video_path = 'CN';

[positions, fps] = color_tracker(params);


positions = [(positions(:,[2,1]) - floor((positions(:,[4,3]) - 1)/2)) ,positions(:,[4,3])];

disp(['fps: ' num2str(fps)])
results.type = 'rect';
results.res = positions;%each row is a rectangle
results.fps = fps;
 

    
    
    
    


