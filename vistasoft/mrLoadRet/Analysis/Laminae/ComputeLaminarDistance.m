function view = ComputeLaminarDistance(view, nSize)

% view = ComputeLaminarDistance(view);
%
% Creates a laminar distance map for this session. If the laminar-distance
% volume map has already been created, this is a quick table look-up
% operation. If it isn't available, this code will call WhiteDistance.m,
% which creates this map and saves it in the current volume directory.
%
% Ress, 6/04

mrGlobals

if exist('vANATOMYPATH', 'var')
  [anatpath, name] = fileparts(vANATOMYPATH);
  fName = fullfile(anatpath, 'laminae.mat');
  if exist(fName, 'file')
    disp('Loading laminar distance volume...')
    load(fName), end
end

if ~exist('dist', 'var')
  qq = questdlg('Compute volumetric laminar distance map?', '?', 'Yes', 'No', 'No');
  if ~strcmp(qq, 'Yes'), return, end
  if ~exist('nSize', 'var'), nSize = 10; end
  dist = WhiteDistance(10);
  if isempty(dist)
    Alert('Laminar distance calculation failed');
    return
  end
end

dist = permute(dist, [2, 1, 3]);
view.laminae = dist(coords2indices(view.coords, size(dist)));
SaveLaminae(view);
