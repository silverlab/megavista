function t_mrdArcuateXvalidate(dSig,A,rows)
% function t_mrdArcuateXvalidate()
%
% 
%
% 

% make A full, to work with cvx.
A = full(A);

% get training and test datasets:
trainingData   = dSig(rows);
trainingDesign = A(rows,:);

testData   = dSig(~rows);
testDesign = A(~rows,:);

n = size(trainingDesign,2);
fFraction = .2;       % limit to the variance of the weights 
l = 0;                % Lower and upper bounds on the weights
u = 1;
cvx_precision('low')  % We can handle low precision during testing.
cvx_solver sedumi     % set the solver (sedumi or sdpt3)

cvx_begin            % start te cvx environment
   variable cvx_w(n) % set the variable we are looking to fit in the cvx environment

   minimize(norm(trainingDesign * cvx_w - trainingData,1)) % minimize using L1 norm

   % set constrains to the minimization, upper and lower bounds for the
   % weights and a small variance across the weights
   subject to
      norm(cvx_w,1) <= fFraction*n;
      cvx_w >= l;
      cvx_w <= u;
cvx_end