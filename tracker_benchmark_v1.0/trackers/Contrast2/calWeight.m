function alpha = calWeight(histBg,histObj)
global History;
global n_frame;

bg = histBg(:);
fg = histObj(:);

tmp = bg .* fg;
bh = sum(tmp.^0.5);
History(n_frame) = 1 - (1 - bh)^0.5;
alpha = 0;
end

