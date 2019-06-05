function alpha = calWeight(histBg,histObj,cf_response)
global History;
% global History1;
global n_frame;
%%计算相关滤波的APCE判据
tmp1 = (max(cf_response(:)) - min(cf_response(:)))^2; 
tmp2 = mean((cf_response(:) - min(cf_response(:))).^2);
APCE = tmp1 / tmp2;


bg = histBg(:);
fg = histObj(:);

tmp = bg .* fg;
bh = sum(tmp.^0.5);
sim = 1 - (1 - bh)^0.5;
alpha = 0.0;

if APCE <=10,
    if sim <=0.55,
        alpha = 0.45;
    else 
        alpha = 0.3;
    end 
else 
    if sim<=0.45,
        alpha = 0.32;
    end 
    if sim>0.45 && sim<0.57,
        alpha = 0.2;
    end 
    if sim>=0.57,
        alpha = 0;
    end 
end  

% if APCE <= 20,
%     learningRate = 0;  
% end
History(n_frame, 1:3) = [sim APCE alpha];
if n_frame>2,
    History(n_frame, 6) = mean(History(1:n_frame-1, 2));
end
% History1(n_frame) = APCE;
end

% if APCE <=10,
%     if sim <=0.55,
%         alpha = 0.5;
%     else 
%         alpha = 0.2;
%     end 
% else 
%     if sim<=0.45,
%         alpha = 0.32;
%     end 
%     if sim>0.45 && sim<0.57,
%         alpha = 0.2;
%     end 
%     if sim>=0.57,
%         alpha = 0;
%     end 
% end  

