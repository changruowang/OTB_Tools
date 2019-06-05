function pixelProb = getPixelProb(patch, model, n_bins)

    sz = size(patch);
    sample = getBinaryFeature(patch, n_bins);
    pixelProb = LogisticRegressionTest(sample, model);
    pixelProb = reshape(pixelProb, sz(1), sz(2));
    
end
