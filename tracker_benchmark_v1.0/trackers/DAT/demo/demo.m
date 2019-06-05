%% DAT Demo
% Demonstrates the basic usage of DAT on the ball1 sequence of the VOT15
% challenge. Images have been downscaled by 50% to reduce download size.
% This demo works out-of-the-box, i.e. you do not need a working VOT setup.

clear
addpath('../src');

% Load annotations
groundtruth = poly2rect(dlmread('sequence/groundtruth.txt'));

% Load default settings
cfg = default_parameters_dat();

% Tracking
frames = 1:105;
times = zeros(size(frames));
for frame = frames
  I = imread(sprintf('sequence/%08d.jpg', frame));
  
  ttrack = tic;
  if frame == 1
    [state, location] = tracker_dat_initialize(I, groundtruth(frame,:), cfg); 
  else
    [state, location] = tracker_dat_update(state, I, cfg);
  end
  times(frame) = toc(ttrack);
  
  % Visualization
  figure(1), clf
  imshow(I)
  rectangle('Position', groundtruth(frame,:), 'EdgeColor', 'y', 'LineWidth', 2);
  rectangle('Position', location, 'EdgeColor', 'b', 'LineWidth', 2);
  drawnow
end
fprintf('Tracked %d frames in %.2f sec (%.2f fps)\n', length(frames), sum(times), 1/mean(times));
