function [vw] = smLoadMeshes(model, vw)
% Opens mesh associated with the given model.
% To be called by smSaveMeshImage or some similar function.
%   [vw] = smLoadMeshes(model, vw)
%
%
if (~isstruct(vw))
    error('pass the view structure for the second argument');
end

% by default we assume we will load a mesh
loadMesh = true; 
setMeshView = true; 

meshFile = smGet(model, 'roixmesh');
meshView = smGet(model, 'meshview');

if (isempty(meshFile))
    fprintf(1, 'Warning: MeshFile is not specified in the model. Will try to use current mesh.\n');
    loadMesh = false; 
end

if (isempty(meshView))
    fprintf(1, 'Warning: MeshView is not specified. Using current mesh view. \n');
    setMeshView = false; 
end


% but we first check currently loaded meshes to make sure it is not already
% loaded
m = viewGet(getCurView,'allmeshes');
for n = 1:length(m)
     % if the requested mesh is already loaded, return without doing anything
     if strcmpi(m{n}.filename, smGet(model, 'roixmesh')), 
         loadMesh = false;
         vw = viewSet(vw, 'currentmeshn', n);
     end
end

% load the mesh
if loadMesh, vw = meshLoad(vw, meshFile, 1); end

% set the mesh to the desired view in order to visusalize the ROIs
if setMeshView, meshRetrieveSettings(viewGet(vw, 'CurMesh'), meshView); end

% update the mesh
vw = meshColorOverlay(vw);

return

