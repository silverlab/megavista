function [co]=copreview(reconVersion,pfile,slice,cycles,junkimages)
% co = copreview('reconVersion','pfile',slice,cycles,[junkimages])
%
%   Reconstructs one slice from a Pfile and creates the
%   correlation and phase maps. If junkimages is given, this
%   number of leading frames will be skipped. cycles relates to
%   the remaining number of frames.
%
%   An mx- (mex-file) Version of the recon program is required.
%
%
% RETURNS
%
%   A vector with the complex correlation at each pixel.
%
% EXAMPLE
%
%   co = copreview('grecons30_mx','/red/u7/mri/mtret/082399/Raw/Pfiles/P07168.7',12,6,3);
%

tmp.reconVersion=reconVersion;

if exist('junkimages','var')
  tmp.junkFirstFrames=junkimages;
end

tmp.reconVersion
tmp
pfile
slice

t=feval(tmp.reconVersion,tmp,pfile,slice,slice);
co=coranal(uint162double(t{1,1}'),cycles*2*pi/length(t{1,1}(1,:)));

n=round(sqrt(length(t{1,1}(:,1))));
for i=1:n
  for j=1:n
        img1(j,i)=abs(co((i-1)*n+j));
	img2(j,i)=angle(co((i-1)*n+j));
  end
end

subplot(2,1,1); imagesc(img1);
subplot(2,1,2); imagesc(img2);


