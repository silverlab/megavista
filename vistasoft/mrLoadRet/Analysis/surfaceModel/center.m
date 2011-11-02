function Y = center(X)
% set mean of each column in a matrix to 0 by subtracting out mean 
% Y = center(X)

Y = X - repmat(mean(X), size(X,1), 1);

end