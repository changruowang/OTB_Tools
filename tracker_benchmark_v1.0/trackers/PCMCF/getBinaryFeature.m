function out = getBinaryFeature(patch, n_bins)

    sz = size(patch);

    if size(patch,3) == 1
        sample = reshape(patch, sz(1)*sz(2), 1);
        sample = floor(double(sample) / (256 / n_bins));
        sample = sample + 1;
        a = 1:sz(1)*sz(2);
        out = zeros(sz(1)*sz(2), n_bins);
        b = double(sample');
        ind = sub2ind(size(out), a, b);
        out(ind) = 1;
    elseif size(patch,3) == 3
        sample = reshape(patch, sz(1)*sz(2), 3);
        sample = floor(double(sample) / (256 / n_bins));
        sample = sample + 1;
        a = 1:sz(1)*sz(2);
        out1 = zeros(sz(1)*sz(2), n_bins);
        out2 = zeros(sz(1)*sz(2), n_bins);
        out3 = zeros(sz(1)*sz(2), n_bins);
       
        b1 = double(sample(:,1)');
        b2 = double(sample(:,2)');
        b3 = double(sample(:,3)');
        
        ind1 = sub2ind(size(out1), a, b1);
        ind2 = sub2ind(size(out2), a, b2);
        ind3 = sub2ind(size(out3), a, b3);
        
        out1(ind1) = 1;
        out2(ind2) = 1;
        out3(ind3) = 1;


        out = [out1,out2,out3];
    end
end