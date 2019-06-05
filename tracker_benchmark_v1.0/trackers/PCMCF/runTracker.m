function runTracker(sequence, start_frame)
% RUN_TRACKER  is the external function of the tracker - does initialization and calls trackerMain

    %% Read params.txt
    params = readParams('params.txt');
	%% load video info
	sequence_path = ['F:/TrackingDataset/Benchmark2015/',sequence,'/','img/'];
    %%%img_path = [sequence_path 'imgs/'];
    img_path = sequence_path;
    
    
    f = fopen([sequence_path 'groundtruth_rect.txt']);
    %ground_truth = textscan(f, '%f,%f,%f,%f');  %[x, y, width, height]
    %ground_truth = cat(2, ground_truth{:});
    try
        ground_truth = textscan(f, '%f,%f,%f,%f', 'ReturnOnError',false);  
    catch  %#ok, try different format (no commas)
        frewind(f);
        ground_truth = textscan(f, '%f %f %f %f');  
    end
    fclose(f);
    ground_truth = cat(2, ground_truth{:});
    region = ground_truth(1,:);

    ground_truth = [ground_truth(:,[2,1]) + (ground_truth(:,[4,3]) - 1) / 2 , ground_truth(:,[4,3])];
    
    %% Read files
    %%%text_files = dir([sequence_path '*_frames.txt']);
    
    %display([sequence_path text_files(1).name]);
    %%%f = fopen([sequence_path text_files(1).name]);
    f = fopen([sequence_path 'frames.txt']);
    frames = textscan(f, '%f,%f');
    %display(frames);
%     if exist('start_frame')
%         frames{1} = start_frame;
%     else
%         frames{1} = 1;
%     end
    
    fclose(f);
    
    %params.bb_VOT = csvread([sequence_path 'groundtruth.txt']);
    params.bb_VOT = csvread([sequence_path 'groundtruth_rect.txt']);
    %region = params.bb_VOT(frames{1},:);
    %%%%%%%%%%%%%%%%%%%%%%%%%
    % read all the frames in the 'imgs' subfolder
    %%%dir_content = dir([sequence_path 'imgs/']);
    dir_content = dir(sequence_path);
    
    % skip '.' and '..' from the count
    n_imgs = frames{2} - frames{1} + 1;
    
    img_files = cell(n_imgs, 1);
    for ii = 1:n_imgs
        img_files{ii} = dir_content(ii+2).name;
    end
       
    img_files(1:start_frame-1)=[];

    im = imread([img_path img_files{1}]);
    % is a grayscale sequence ?
    if(size(im,3)==1)
        params.grayscale_sequence = true;
    end

    params.img_files = img_files;
    params.img_path = img_path;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if(numel(region)==8)
        % polygon format
        [cx, cy, w, h] = getAxisAlignedBB(region);
    else
        x = region(1);
        y = region(2);
        w = region(3);
        h = region(4);
        cx = x+w/2;
        cy = y+h/2;
    end

    % init_pos is the centre of the initial bounding box
    params.init_pos = [cy cx];
    params.target_sz = round([h w]);
    [params, bg_area, fg_area, area_resize_factor] = initializeAllAreas(im, params);
	if params.visualization
		params.videoPlayer = vision.VideoPlayer('Position', [100 100 [size(im,2), size(im,1)]+30]);
	end
    % in runTracker we do not output anything
	params.fout = -1;
	% start the actual tracking
	results = trackerMain(params, im, bg_area, fg_area, area_resize_factor,n_imgs);
    
   [distance_precision, PASCAL_precision, average_center_location_error] = ...
    compute_performance_measures(results.positions, ground_truth);

fprintf('Center Location Error: %.3g pixels\nDistance Precision: %.3g %%\nOverlap Precision: %.3g %%\nSpeed: %.3g fps\n', ...
    average_center_location_error, 100*distance_precision, 100*PASCAL_precision, results.fps); 
    
    fclose('all');
end
