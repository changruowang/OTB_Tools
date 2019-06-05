function results=run_DAT(seq, res_path, bSaveImage)

    addpath('/src');
    cfg = default_parameters_dat();
    s_frames = seq.s_frames;
    positions = zeros(numel(s_frames), 4);  %to calculate precision
	times = zeros(numel(s_frames));
    for frame = 1:numel(s_frames),
        I = imread(s_frames{frame});

        ttrack = tic;
        if frame == 1
            [state, location] = tracker_dat_initialize(I, seq.init_rect, cfg); 
        else
            [state, location] = tracker_dat_update(state, I, cfg);
        end
        positions(frame,:) = location;
		times(frame) = toc(ttrack);

        % Visualization
        figure(1), clf
        imshow(I)
        rectangle('Position', seq.init_rect, 'EdgeColor', 'y', 'LineWidth', 2);
        rectangle('Position', location, 'EdgeColor', 'b', 'LineWidth', 2);
        drawnow
    end
results.res = positions;
results.type = 'rect';
results.fps = 45;
    
