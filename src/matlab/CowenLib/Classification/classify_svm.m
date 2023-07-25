function c = classify_svm(tst_data,trn_d,trn_g)
% function c = classify_svm(d,g,tst_data)
% A wrapper for the SVM toolbox. Make sure that it's installed. See
%      http://www.csie.ntu.edu.tw/~cjlin/libsvm/
%
% cowen
model = svmtrain(trn_g, trn_d); % , '-c 1 -g 2'
c = svmpredict(ones(Rows(tst_data),1), tst_data, model);
