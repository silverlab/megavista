function Rsquare = t_mrdCrossValidateFiberModel(dSig,A,rows,ndir)

% Cross-validate fiber predictions
% dsig = the vector of diffusion measurements
% A    = the fiber prediction matrix
% rows = which rows to use

% The user must either pass in the rows to fit and hold out or the number
% of directions so that we can randomly hold out rows
if exist('rows','var') && ~isempty(rows);
    rows = logical(rows);
elseif ~exist('rows','var') || isempty(rows);
    % This is a randomly chosen direction to hold out for each voxel
    outVols = ceil(rand(length(dSig)./ndir,1).*ndir);
    % Now we will make a vector that has a 1 for each row of dsig to fit
    % and a 0 for each row to hold out for cross validation
    rows = [];
    for ii=1:length(outVols)
        tmp = ones(ndir,1)
        tmp(outVols(ii))=0;
        nextrow = length(rows)+1;
        rows(nextrow:nextrow+ndir-1) = tmp;
    end
   rows = logical(rows); 
end
% This is the data we will hold out for cross validation
tmp = full(A); %we're not sure if we have to make it a full before indexing
dsigV   = dSig(~rows);
AV      = tmp(~rows,:);

% now run the CVX code to solve the L1-minimization problem:
cvx_C = tmp(rows,:);
clear tmp
n = size(cvx_C,2);
cvx_dSig = dSig(rows);
fprintf('Start L1 minimization using CVX...\n')

l = 0;                % Lower and upper bounds on the weights
u = 1;
cvx_solver sedumi;
cvx_precision('low')  % We can handle low precision during testing.

cvx_begin       % start te cvx environment
variable cvx_w(n) % set the variable we are looking to fit in the cvx environment
minimize(norm(cvx_C * cvx_w - cvx_dSig,1)) % minimize using L1 norm
subject to
cvx_w >= l;
cvx_w <= u;
cvx_end

Rsquare = corr(AV * cvx_w, dsigV)^2;