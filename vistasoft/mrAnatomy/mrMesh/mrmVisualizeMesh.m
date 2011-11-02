function [msh] = mrmVisualizeMesh(oldMsh,mmPerVox,host,id);
%
%

% Obsolete.  Use meshVisualize
%
warning('Obsolete, use meshVisualize')
evalin('caller','mfilename')

return;

% transparency is off by default because it is slow.
meshName = '';
relaxIter = 0;
backColor = [1,1,1];  

if ieNotDefined('oldMsh'), error('The mesh is required.'); end
if ieNotDefined('mmPerVox'), mmPerVox = [1 1 1]; end
if ieNotDefined('host'), host = 'localhost'; end
if ieNotDefined('id'), id = 1; end

% Set initial parameters for the mesh.
msh = meshDefault(host,id,mmPerVox,relaxIter,meshName);

% If the window is already open, no harm is done.
msh = mrmInitHostWindow(msh); 

% Initializes the mesh
[msh, lights] = mrmInitMesh(msh,backColor);

% Adds an actor
msh = mrmSet(msh,'addactor');

% Updates data
if isField(oldMsh,'data')
    msh.data.vertices = oldMsh.data.vertices;
    msh.data.triangles = oldMsh.data.triangles;
    msh.data.colors = oldMsh.data.colors;
    msh.data.normals = oldMsh.data.normals;
else
    msh.data.vertices = oldMsh.vertices;
    msh.data.triangles = oldMsh.triangles;
    msh.data.colors = oldMsh.colors;
    msh.data.normals = oldMsh.normals;
end

msh.data.camera_space = 0;
msh.data.rotation = eye(3);

% Sets the origin
msh = mrmSet(msh,'origin',-mean(msh.data.vertices'));

% Loads the mesh
mrmSet(msh,'data');




