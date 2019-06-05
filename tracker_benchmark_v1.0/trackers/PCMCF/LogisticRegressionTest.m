function prob = LogisticRegressionTest(data, model)

prob = 1 ./ (1 + exp(- (model.w(1:end-1)' * data') - model.w(end)));
% prob = 1 ./ (1 + exp(- (model.w' * data.feat)));