%���ɾ�����н��
%tracker:ɾ��ĳtracker�����н��  
%seqtype:ɾ����tracker��Ӧ�����еĽ����������Ĭ��ɾ����tracker���е����еĽ��
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