function [imX,imY,imZ] = checkBrains(baseDir,fileFragment,imageType,excludeList,xSlice,ySlice,zSlice)
% function [imX,imY,imZimX,imY,imZ] = checkBrains(baseDir,fileFragment,imageType,excludeList,xSlice,ySlice,zSlice)
%
% A makeMontage-based hack to do quick check on groups of brains - displays
% the 3 montages show the same 3 2D slices (axial, saggital, coronal) of a group of 
% brains 
%
% baseDir: Specifies directory containing image files/subject directories
% fileFragment: Specifies character string present in every image
% imageType: Choose b0 ('b0'), fa ('fa'), or anatomy ('anat') - defaults to b0.  
% Note that checkBrains uses analyze-format images of b0 and FA
%
% Optional arguments xSlice, ySlice, and zSlice (default 45,45,30) allow
% you to check specific axial, saggital, and coronal slices 

if(~exist('baseDir','var'))
    baseDir = [];
end
if(~exist('fileFragment','var'))
    fileFragment = [];
end
if(~exist('excludeList','var'))
    excludeList = [];
end
if (nargin < 3)
    imageType = 'b0';
end

files = findSubjects(baseDir,fileFragment,excludeList);

N = length(files);
[dir file blah blahblah] = fileparts(files{1});

h = waitbar(0, ['Loading ' num2str(N) ' brains...']);
if (strmatch(imageType,'b0')) %B0 image
   dt = load(files{1}, 'b0', 'xformToAcPc');
   sl = dt.xformToAcPc\[0 0 0 1]';
   sl = round(sl(1:3));
   sz = size(dt.b0);
   X = zeros(sz(3),sz(2),N+1);
   Y = zeros(sz(3),sz(1),N+1);
   Z = zeros(sz(1),sz(2),N+1);
   for g = 1:N
        dt = load(files{g}, 'b0');
        im = dt.b0;
        X(:,:,g) = mrAnatHistogramClip(double(flipud(permute(squeeze(im(sl(1),:,:)), [2,1]))), 0.4, 0.99);
        Y(:,:,g) = mrAnatHistogramClip(double(flipud(permute(squeeze(im(:,sl(2),:)), [2,1]))), 0.4, 0.99);
        Z(:,:,g) = mrAnatHistogramClip(double(squeeze(im(:,:,sl(3)))), 0.4, 0.99);
        waitbar(g/N,h);
    end
    imgTitle = 'B0 Map';
elseif (strmatch(imageType,'fa')) %FA image
   dt = load(files{1}, 'b0', 'xformToAcPc');
   sl = dt.xformToAcPc\[0 0 0 1]';
   sl = round(sl(1:3));
   sz = size(dt.b0);
   X = zeros(sz(3),sz(2),N+1);
   Y = zeros(sz(3),sz(1),N+1);
   Z = zeros(sz(1),sz(2),N+1);
   for g = 1:N
        dt = load(files{g}, 'dt6');
        [eigVec, eigVal] = dtiSplitTensor(dt.dt6);
        im = dtiComputeFA(eigVal);
        X(:,:,g) = flipud(permute(squeeze(im(sl(1),:,:)), [2,1]));
        Y(:,:,g) = flipud(permute(squeeze(im(:,sl(2),:)), [2,1]));
        Z(:,:,g) = squeeze(im(:,:,sl(3)));
        waitbar(g/N,h);
    end
    imgTitle = 'FA Map';
else %Anatomy image
   dt = load(files{1}, 'anat');
   sl = dt.anat.xformToAcPc\[0 0 0 1]';
   sl = round(sl(1:3));
   sz = size(dt.anat.img);
   X = zeros(sz(3),sz(2),N+1);
   Y = zeros(sz(3),sz(1),N+1);
   Z = zeros(sz(1),sz(2),N+1);
   for g = 1:N
        dt = load(files{g}, 'anat');
        im = dt.anat.img;
        X(:,:,g) = mrAnatHistogramClip(double(flipud(permute(squeeze(im(sl(1),:,:)), [2,1]))), 0.4, 0.99);
        Y(:,:,g) = mrAnatHistogramClip(double(flipud(permute(squeeze(im(:,sl(2),:)), [2,1]))), 0.4, 0.99);
        Z(:,:,g) = mrAnatHistogramClip(double(squeeze(im(:,:,sl(3)))), 0.4, 0.99);
        waitbar(g/N,h);
    end
    imgTitle = 'T1 Map';
end
close(h);
X(:,:,N+1) = mean(X(:,:,1:N), 3);
Y(:,:,N+1) = mean(Y(:,:,1:N), 3);
Z(:,:,N+1) = mean(Z(:,:,1:N), 3);
imX = makeMontage(X);figure; imagesc(imX); axis image; colorbar; colormap gray;
title([dir,' (N = ',num2str(N), '), X = ',num2str(sl(1)), ' of ',imgTitle]); 
imY = makeMontage(Y);figure; imagesc(imY); axis image; colorbar; colormap gray;
title([dir,' (N = ',num2str(N), '), Y = ',num2str(sl(2)), ' of ',imgTitle]);
imZ = makeMontage(Z);figure; imagesc(imZ); axis image; colorbar; colormap gray;
title([dir,' (N = ',num2str(N), '), Z = ',num2str(sl(3)), ' of ',imgTitle]);
return
    
