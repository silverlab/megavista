function msh = meshCreate(mshType)
% mrMesh creation routine
%   
%   msh = meshCreate(mshType);
%
% We only create a vistaMesh type.  In the future we may design additional
% mesh structures
%
% Stanford VISTA team

if ieNotDefined('mshType'), mshType = 'vistaMesh'; end

switch lower(mshType)
    case 'vistamesh'
        msh = vistaMeshCreate;
    otherwise
        error('Unknown mesh type %s\n',mshType);
end

return;


%------------------------------
function msh = vistaMeshCreate
%Default settings for a mrVista mesh
%
%   msh = vistaMeshCreate;
%
% Stanford VISTA Team

%
% fields = {'name', 'host', 'id', 'actor', 'mmPerVox', 'lights', 'origin', ...
%     'initialvertices', 'vertices', 'triangles', 'colors', 'normals', 'curvature',...
%     'ngraylayers', 'vertexGrayMap', 'fibers',...
%     'smooth_sinc_method', 'smooth_relaxation', 'smooth_iterations', 'mod_depth'};

msh.name = '';
msh.type = 'vistaMesh';
msh.host = 'localhost';
msh.id   = -1;
msh.filename = [];
msh.path = [];
msh.actor = [];
msh.mmPerVox = [];
msh.lights   = {};
msh.origin   = [];
msh.initVertices = [];
msh.vertices = [];
msh.triangles = [];
msh.colors = [];
msh.normals = [];
msh.curvature = [];
msh.grayLayers = [];
msh.vertexGrayMap =[];
msh.fibers = [];
msh.smooth_sinc_method = 0;
msh.smooth_relaxation = 0.5;
msh.smooth_iterations = 32;
msh.mod_depth = 0.25;

return;
