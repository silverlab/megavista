function [wghts, trnEr] = myLasso(dsnMtrx, respVar)

nmFlds = 10;
[mdl_pos, wghts, res_mean, res_std] = crossvalidate(@lars, nmFlds, 1000, dsnMtrx, respVar, 'lasso', 0, 0, [], 0);
 
% lets calculate the training error
[rows,cols] = size(dsnMtrx);
prdctns = zeros(rows,1);

for ii=1:rows
  prdctns(ii,1) = dsnMtrx(ii,:) * wghts';
end

if (size(respVar, 1) ~= size(prdctns, 1))
    error('response variable and prediction have different dimensions');
end

avgActual = mean(respVar);

SStot = 0;
SSerr = 0;
for ii=1:size(respVar, 1)
    SStot = SStot + (respVar(ii,1) - avgActual)^2;
    SSerr = SSerr + (respVar(ii,1) - prdctns(ii,1))^2;
end

trnEr = 1 - (SSerr/SStot);
%note: 
% variance explained: val = 1 - (model.rss ./ model.rawrss);