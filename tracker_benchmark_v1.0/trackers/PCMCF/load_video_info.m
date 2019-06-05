function [img_files, pos, target_sz, ground_truth, video_path] = load_video_info(video_path)

% [img_files, pos, target_sz, ground_truth, video_path] = load_video_info(video_path)

%text_files = dir([video_path '*_frames.txt']);
%f = fopen([video_path text_files(1).name]);
%frames = textscan(f, '%f,%f');
%fclose(f);
video_path = [video_path 'img/'];
f = fopen([video_path 'frames.txt']);
frames = textscan(f, '%f,%f');
fclose(f);

%text_files = dir([video_path '*_gt.txt']);
%assert(~isempty(text_files), 'No initial position and ground truth (*_gt.txt) to load.')
%f = fopen([video_path text_files(1).name]);

f = fopen([video_path 'groundtruth_rect.txt']);
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

%set initial position and size
target_sz = [ground_truth(1,4), ground_truth(1,3)];
pos = [ground_truth(1,2), ground_truth(1,1)];

ground_truth = [ground_truth(:,[2,1]) + (ground_truth(:,[4,3]) - 1) / 2 , ground_truth(:,[4,3])];

%see if they are in the 'imgs' subfolder or not
% if exist([video_path num2str(frames{1}, 'imgs/img%05i.png')], 'file'),
%     video_path = [video_path 'imgs/'];
%     img_files = num2str((frames{1} : frames{2})', 'img%05i.png');
% elseif exist([video_path num2str(frames{1}, 'imgs/img%05i.jpg')], 'file'),
%     video_path = [video_path 'imgs/'];
%     img_files = num2str((frames{1} : frames{2})', 'img%05i.jpg');
% elseif exist([video_path num2str(frames{1}, 'imgs/img%05i.bmp')], 'file'),
%     video_path = [video_path 'imgs/'];
%     img_files = num2str((frames{1} : frames{2})', 'img%05i.bmp');
% else
%     error('No image files to load.')
% end

if exist([video_path num2str(frames{1}, '%04i.png')], 'file'),
    img_files = num2str((frames{1} : frames{2})', '%04i.png');
elseif exist([video_path num2str(frames{1}, '%04i.jpg')], 'file'),
    img_files = num2str((frames{1} : frames{2})', '%04i.jpg');
elseif exist([video_path num2str(frames{1}, 'i%04i.bmp')], 'file'),
    img_files = num2str((frames{1} : frames{2})', '%04i.bmp');
elseif exist([video_path num2str(frames{1}, '1%04i.bmp')], 'file'),
    img_files = num2str((frames{1} : frames{2})', '1%04i.bmp');
elseif exist([video_path num2str(frames{1}, '%05i.png')], 'file'),
    img_files = num2str((frames{1} : frames{2})', '%05i.png');
elseif exist([video_path num2str(frames{1}, '%05i.jpg')], 'file'),
    img_files = num2str((frames{1} : frames{2})', '%05i.jpg');
elseif exist([video_path num2str(frames{1}, 'i%05i.bmp')], 'file'),
    img_files = num2str((frames{1} : frames{2})', '%05i.bmp');
    error('No image files to load.')
end

%list the files
img_files = cellstr(img_files);

end

