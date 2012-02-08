function cost = rd_calculateCost2(coefs, valsTrain, coords, mpProp)

metric = valsTrain*coefs';

cost = rd_zDistanceCost2(metric, coords, mpProp);
