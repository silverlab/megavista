function Q = fgTensors(fgImg,dParms)
%Calculate a tensor for forward modeling at each point of each fiber
%
%  Q = fgTensors(fgImg,dParms)
%
% Q is a cell array of the same length as the number of fibers
% Each Q{ii} contains a matrix of (nPoints x 9) tensors.  
%
% To put the tensor into the quadratic form, use T = reshape(T,3,3);  
% eigs(T) calculates the axial diffusivity (largest) and so forth.
% 
% Example:
%  d_ad = 1.5; d_rd = 0.3; 
%  dParms(1) = d_ad; dParms(2) = d_rd; dParms(3) = d_rd;
%  fgImg.Q = fgTensors(fgImg,dParms)
% 
% See also: s_mictSimples (vistaproj/microtrack)
%
% (c) Stanford VISTA Team 2011

nFibers = length(fgImg.fibers);
Q = cell(1,nFibers);
for ii=1:nFibers
    thisFiber = fgImg.fibers{ii};
    imgGradient = gradient(thisFiber);
    nPoints = size(thisFiber,2);
    T = zeros(nPoints,9);
    for jj=1:nPoints
        [U S V] = svd(imgGradient(:,jj));
        T(jj,:) = reshape(U'*diag(dParms)*U,1,9);
    end
    
    % T is a matrix; each row is a 1,9 version of the tensor.
    % reshape(T(1,:),3,3) turns it into a 3x3
    Q{ii} = T;
end

return
