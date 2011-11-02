function [M] = mtrMatchImages2DManual(imgFilenameB0,imgFilenameTensors,outFilenameB0,outFilenameTensors,topIndices,M)

% imgFilename: Image that we are going to realign sub-segments of
% topIndices: Indices definining the top of each sub-segment
% M: matrices to translate (only 2d) each sub-segment if not defined user
%   can select

imgFilenameB0 = 'B0.nii.gz';
imgFilenameTensors = 'tensors.nii.gz';
outFilenameB0 = 'B0Warped.nii.gz';
outFilenameTensors = 'tensorsWarped.nii.gz';
topIndices = [0, 28, 56, 84];
M(:,:,1) = eye(4);
M(2,4,1) = -3;
M(:,:,2) = eye(4);
M(:,:,3) = eye(4);
M(2,4,3) = -3;

if( ieNotDefined('imgFilenameB0') )
    [f,p] = uigetfile({'*.nii';'*.*'},'Select a B0 for input...');
    if(isnumeric(f)), disp('Matching canceled.'); return; end
    imgFilenameB0 = fullfile(p,f); 
end
if( ieNotDefined('imgFilenameTensors') )
    [f,p] = uigetfile({'*.nii';'*.*'},'Select a Tensor image for input...');
    if(isnumeric(f)), disp('Matching canceled.'); return; end
    imgFilenameTensors = fullfile(p,f); 
end

if( ieNotDefined('topIndices') | isempty(topIndices) )
    error('Need top indices defined.');
end

if( ieNotDefined('M') | isempty(M) )
    error('Interactive selection of translation not defined.');
end

% Load image
niB0 = readFileNifti(imgFilenameB0);
niTensors = readFileNifti(imgFilenameTensors);

niB0Warped = niB0;
niB0Warped.fname = outFilenameB0;
niTensorsWarped = niTensors;
niTensorsWarped.fname = outFilenameTensors;

for ss = 2:length(topIndices)
    bI = topIndices(ss-1)+1;
    tI = topIndices(ss);
    niB0Warped.data(:,:,bI:tI) = int16(warpAffine3(double(niB0.data(:,:,bI:tI)),M(:,:,ss-1),[],[],'*nearest'));
    for ii = 1:6
        niTensorsWarped.data(:,:,bI:tI,ii) = int16(warpAffine3(double(niTensors.data(:,:,bI:tI,ii)),M(:,:,ss-1),[],[],'*nearest'));
    end
end
niB0.acpcXform = [diag(niB0.pixdim), -[size(niB0.data)./2.*niB0.pixdim]'; [0 0 0 1]];
niB0Warped.acpcXform = niB0.acpcXform;


bb = [-80,80; -120,90; -200,200]';
slice = [0,0,0]
h = figure;
showFigure(h, niB0Warped, niB0, bb, slice);
%set(h,'Position', [10, 50, 1000, 1000]);
set(h, 'PaperPositionMode', 'auto');

writeFileNifti(niB0Warped);
writeFileNifti(niTensorsWarped);

return;

function showFigure(fig, t1, b0, bb, slice, figName)
if(~exist('figName','var')) figName = 'Interpolated slices'; end
% Get X,Y and Z (L-R, A-P, S-I) slices from T1 and b0 volumes
[t1Xsl] = dtiGetSlice(t1.acpcXform,t1.data,3,slice(3),bb);
[t1Ysl] = dtiGetSlice(t1.acpcXform,t1.data,2,slice(2),bb);
[t1Zsl] = dtiGetSlice(t1.acpcXform,t1.data,1,slice(1),bb);
[b0Xsl] = dtiGetSlice(b0.acpcXform,b0.data,3,slice(3),bb);
[b0Ysl] = dtiGetSlice(b0.acpcXform,b0.data,2,slice(2),bb);
[b0Zsl] = dtiGetSlice(b0.acpcXform,b0.data,1,slice(1),bb);
% Max values for image scaling
t1mv = max([t1Xsl(:); t1Ysl(:); t1Zsl(:)])+0.000001;
b0mv = max([b0Xsl(:); b0Ysl(:); b0Zsl(:)])+0.000001;
% Create XxYx3 RGB images for each of the axis slices. The green and 
% blue channels are from the T1, the red channel is an average of T1 
% and b=0.
Xsl(:,:,1) = t1Xsl./t1mv.*.5 + b0Xsl./b0mv.*.5;
Xsl(:,:,2) = t1Xsl./t1mv.*.5; Xsl(:,:,3) = t1Xsl./t1mv.*.5;
Ysl(:,:,1) = t1Ysl./t1mv.*.5 + b0Ysl./b0mv.*.5;
Ysl(:,:,2) = t1Ysl./t1mv.*.5; Ysl(:,:,3) = t1Ysl./t1mv.*.5;
Zsl(:,:,1) = t1Zsl./t1mv.*.5 + b0Zsl./b0mv.*.5;
Zsl(:,:,2) = t1Zsl./t1mv.*.5; Zsl(:,:,3) = t1Zsl./t1mv.*.5;

% Show T1 slices
figure(fig); set(fig, 'NumberTitle', 'off', 'Name', figName);
figure(fig); subplot(3,3,1); imagesc(bb(:,1), bb(:,2), t1Xsl); 
colormap(gray); axis equal tight xy;
figure(fig); subplot(3,3,2); imagesc(bb(:,3), bb(:,1), t1Ysl); 
colormap(gray); axis equal tight xy;
figure(fig); subplot(3,3,3); imagesc(bb(:,3), bb(:,2), t1Zsl); 
colormap(gray); axis equal tight xy; 
axis equal tight;

% Show b=0 slices
figure(fig); subplot(3,3,4); imagesc(bb(:,1), bb(:,2), b0Xsl); 
colormap(gray); axis equal tight xy;
figure(fig); subplot(3,3,5); imagesc(bb(:,3), bb(:,1), b0Ysl); 
colormap(gray); axis equal tight xy;
figure(fig); subplot(3,3,6); imagesc(bb(:,3), bb(:,2), b0Zsl); 
colormap(gray); axis equal tight xy; 
axis equal tight;

% Show combined slices
figure(fig); subplot(3,3,7); imagesc(bb(:,1), bb(:,2), Xsl); 
axis equal tight xy;
figure(fig); subplot(3,3,8); imagesc(bb(:,3), bb(:,1), Ysl); 
axis equal tight xy;
figure(fig); subplot(3,3,9); imagesc(bb(:,3), bb(:,2), Zsl); 
axis equal tight xy; 
axis equal tight;

return;