%快捷删除运行结果
%tracker:删除某tracker的运行结果  
%seqtype:删除该tracker对应的序列的结果，不输入默认删除该tracker运行的所有的结果
function rmResult(tracker, seqtype)
    if nargin < 2, seqtype = 'all'; addpath('../util');end
    
    switch seqtype
        case 'all',  
            seqs = configSeqs;
            for i = 1:length(seqs),
                s = seqs{i};
                result_path = ['results/results_OPE_CVPR13/', s.name, '_', tracker, '.mat'];
                delete(result_path);
           end
        otherwise,  
            result_path = ['results/results_OPE_CVPR13/', seqtype, '_', tracker, '.mat'];
            delete(result_path);
    end
    
    delete('perfMat/overall/*.mat');
%    delete('perfMat/figs/*.mat');
end