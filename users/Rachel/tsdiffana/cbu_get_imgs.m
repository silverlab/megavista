function imgs = cbu_get_imgs(n, prompt)
% wrapper to fetch image names via gui for SPM99-SPM5

if nargin < 1
  n = Inf;
end
if nargin < 2
  prompt = 'Select images';
end
switch spm('ver')
 case {'SPM5','SPM8'}
  imgs = spm_select(n, 'image', prompt);
 case 'SPM2'
  imgs = spm_get(n, '*.IMAGE', prompt);
 case 'SPM99'
  imgs = spm_get(n, '*.img', prompt);
 otherwise
  error(sprintf('What ees thees version "%s"', spm('ver')));
end
