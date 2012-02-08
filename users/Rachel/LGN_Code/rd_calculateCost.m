function cost = rd_calculateCost(coefs, valsTrain, coords, mpThresh)

metric = valsTrain*coefs';

cost = rd_zDistanceCost(metric, coords, mpThresh);
