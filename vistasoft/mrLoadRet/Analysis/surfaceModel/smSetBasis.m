function  model = smSetBasis(model)
% Determine basis set for predictor tseries for surface model
% (see smMain.m)
%   model = smSetBasis(model)

basisType = smGet(model, 'basisType');

switch lower(basisType)
    
    case {'none', 'original data', 'raw', 'raw data', 'original'}
        tSeries          = smGet(model, 'tSeriesPredictor');
        basis.functons   = eye(size(tSeries,2));
        basis.projection = tSeries * coeff;
        
        model = smSet(model, 'basis functions',  basis.functons);
        model = smSet(model, 'basis projection', basis.projection);
        
    case {'pca', 'principal components', 'pcs', 'princomp', 'princomps'}          
        model = smBasisMakePCs(model);
        
    case {'gaussians', 'gaussian'}
        model = smBasisMakeGaussians(model);
end

return
