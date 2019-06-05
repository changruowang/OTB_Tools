function [prob_lut, prob_map] = getForegroundBackgroundProbs(frame, obj_rect, num_bins, bin_mapping)
%GETFOREGROUNDBACKGROUNDPROBS Computes the probability lookup table for the
%object vs surrounding region model.
% Parameters:
%   frame       Input (color) image cropped to contain only the surrounding
%               region
%   obj_rect    Rectangular object region
%   num_bins    Number of bins per channel (scalar)
%   bin_mapping Maps intensity values to num_bins bins


[rows, cols, layers] = size(frame);
%%size of object
obj_row = round(obj_rect(2));
obj_col = round(obj_rect(1));
obj_width = round(obj_rect(3));
obj_height = round(obj_rect(4));

if obj_row + obj_height > rows, obj_height = rows - obj_row; end
if obj_col + obj_width > cols, obj_width = cols - obj_col; end

if nargout > 1
  prob_map = zeros(rows, cols);
end

if layers == 3
  % Color image      
  obj_hist = zeros(num_bins, num_bins, num_bins, 'double'); %obj surr的区别
  surr_hist = zeros(num_bins, num_bins, num_bins, 'double');%存储各个bin的数量

  % Histogram over full image   统计surr部分的颜色直方图
  [x,y] = meshgrid(1:cols, 1:rows);
  idx_map = sub2ind([rows, cols], y(:), x(:));
  idx_1 = sub2ind([rows, cols, layers], y(:), x(:), ones(numel(x), 1));
  idx_2 = sub2ind([rows, cols, layers], y(:), x(:), 2.*ones(numel(x), 1));
  idx_3 = sub2ind([rows, cols, layers], y(:), x(:), 3.*ones(numel(x), 1));
  %idx_1 idx_2 idx_3 分别表示为图像r,g,b层的序号索引  比如frame(idx_1) 输出为所有r层值
  bin_1 = bin_mapping(frame(idx_1)+1);   %将r层r的像素值映射到bin中                                
  bin_2 = bin_mapping(frame(idx_2)+1);   %bin_mapping是大小为256的映射数组
  bin_3 = bin_mapping(frame(idx_3)+1);
                                         %r,g,b各划分16个bin
                                         %则r,g,b联合起来的bin最多16*16*16
  idx_hist_full = sub2ind(size(surr_hist), bin_1, bin_2, bin_3);
  bins = unique(idx_hist_full);          %统计联合的bin的种类（最多16*16*16个）
  for b = bins                           %统计各个bin的数量
    surr_hist(b) = nnz(idx_hist_full == b);
  end

  % Histogram over object region    同上 统计目标部分的颜色直方图
  [x,y] = meshgrid(max(1,obj_col):(obj_col+obj_width), max(1,obj_row):(obj_row+obj_height));
  idx_1 = sub2ind([rows, cols, layers], y(:), x(:), ones(numel(x), 1));
  idx_2 = sub2ind([rows, cols, layers], y(:), x(:), 2.*ones(numel(x), 1));
  idx_3 = sub2ind([rows, cols, layers], y(:), x(:), 3.*ones(numel(x), 1));

  bin_1o = bin_mapping(frame(idx_1)+1);
  bin_2o = bin_mapping(frame(idx_2)+1);
  bin_3o = bin_mapping(frame(idx_3)+1);

  idx_hist_obj = sub2ind(size(obj_hist), bin_1o, bin_2o, bin_3o);
  bins = unique(idx_hist_obj);
  for b = bins
    obj_hist(b) = nnz(idx_hist_obj == b);
  end
  %目标与背景的颜色直方图各部分占比
  prob_lut = (obj_hist + 1) ./ (surr_hist + 2);
  if nargout > 1
    prob_map(idx_map) = prob_lut(idx_hist_full);
  end
  %prob_map  得到背景图每个像素的颜色其对应的同类块的比例
elseif layers == 10
  obj_hist = zeros(1,1,layers, 'double');
  surr_hist = zeros(1,1,layers, 'double');

  for r = 1:rows
    for c = 1:cols
      surr_hist = surr_hist + (frame(r,c,:)+1)/2;
      if r >= obj_row && r < obj_row+obj_height && c >= obj_col && c < obj_col+obj_width
        obj_hist = obj_hist + (frame(r,c,:)+1)/2;
      end
    end
  end
  prob_lut = (obj_hist + 1) ./ (surr_hist + 2);
  
elseif layers == 1
  % Color image
  obj_hist = zeros(num_bins, 1, 'double');
  surr_hist = zeros(num_bins, 1, 'double');

  % Histogram over full image
  [x,y] = meshgrid(1:cols, 1:rows);
  idx_map = sub2ind([rows, cols], y(:), x(:));

  bin = bin_mapping(frame(idx_map)+1);
  
  idx_hist_full = sub2ind(size(surr_hist), bin);
  bins = unique(idx_hist_full);
  for b = bins
    surr_hist(b) = nnz(idx_hist_full == b);
  end

  % Histogram over object region
  [x,y] = meshgrid(max(1,obj_col):(obj_col+obj_width), max(1,obj_row):(obj_row+obj_height));
  idx = sub2ind([rows, cols], y(:), x(:));

  bin_1o = bin_mapping(frame(idx)+1);

  idx_hist_obj = sub2ind(size(obj_hist), bin_1o);
  bins = unique(idx_hist_obj);
  for b = bins
    obj_hist(b) = nnz(idx_hist_obj == b);
  end
  
  prob_lut = (obj_hist + 1) ./ (surr_hist + 2);
  if nargout > 1
    prob_map(idx_map) = prob_lut(idx_hist_full);
  end  
else
  error('Not supported\n');
end

end

