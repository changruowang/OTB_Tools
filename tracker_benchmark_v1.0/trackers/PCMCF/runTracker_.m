addpath('./utility')
base_path = 'F:/TrackingDataset/Benchmark2015/';
%base_path = 'F:\TrackingDataset\LiuData/';
video_path = choose_video(base_path);
if isempty(video_path), return, end  %user cancelled
[img_files, pos, target_sz, ground_truth, video_path] = ...
    load_video_info(video_path);



params = readParams('params.txt');
params.init_pos = floor(pos) + floor(target_sz/2);
%params.init_pos = pos + target_sz/2;
params.target_sz = round(target_sz);
params.img_files = img_files;
params.img_path = video_path;
im = imread([video_path img_files{1}]);
if(size(im,3)==1)
    params.grayscale_sequence = true;
end
n_imgs = numel(img_files);

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