function [view,newMeshNum] = meshBuild(view,hemisphere)
% Build a 3D mesh for visualization and analysis
%
%   [view,newMeshNum] = meshBuild(view,[hemisphere]);
%
%  Using mrVista data, build a mesh, save it in a file in the anatomy
%  directory, and add the mesh to the 3D Control Window pull down
%  options.   
%
%  A mrMesh window is opened as well, showing the computed mesh.
%
%  Hemisphere options include 'left','right', and 'both'.  
%    Default is 'left'.  
%    !!!!(Problem with 'both' at present).
%
% Example:
%    [VOLUME{1},newMeshNum] = meshBuild(VOLUME{1},'left');
%    VOLUME{1} = viewSet(VOLUME{1},'currentmeshn',newMeshNum);
%
% See also:  meshBuildFromClass, meshBuildFromNiftiClass, meshSmooth,
%            meshColor 
%
% 11/05 ras: also saves mesh path.
%
% (c) Stanford VISTA Team 2008

% Programming TODO
%   We have created trouble for building 'both' meshes.  We need a new
%   procedure.
%

% Be sure anatomy is loaded (we need it for the mmPerVox field)
if isempty(view.anat), view = loadAnat(view); end
if ieNotDefined('hemisphere'), hemisphere = 'left'; end
% if strcmp('hemisphere','both'), error('meshBuild does not run properly for hemi=both'); end

newMeshNum = viewGet(view,'nmesh') + 1;

% Parameters we establish in this routine
[meshName,numGrayLayers,hemiNum] = readParams(newMeshNum,hemisphere);
if isempty(meshName), newMeshNum = newMeshNum - 1; return; end   % User pressed cancel.

mmPerVox = viewGet(view,'mmPerVoxel');

wbar = waitbar(0.1, ...
    sprintf('meshBuild: Combining white and gray matter...'));

% Load left, right, or both hemispheres.  
if (hemiNum==1)
    [voxels,view] = meshGetWhite(view, 'left', numGrayLayers);
elseif (hemiNum==2)
    [voxels,view] = meshGetWhite(view, 'right', numGrayLayers);
elseif (hemiNum == 0)
    [voxels,view] = meshGetWhite(view, 'left', numGrayLayers);
    [voxels,view] = meshGetWhite(view, 'right', numGrayLayers,voxels);
end

host = 'localhost';
windowID = -1;

% We build a smoothed (mesh) and an unsmoothed mesh (tenseMesh) with these calls
waitbar(0.35,wbar,sprintf('Building mesh'));

% When mrmBuild calls work on Linux, eliminate the second condition.
% if ispc
    [newMesh, tenseMesh] = mrmBuild(voxels,viewGet(view,'mmPerVox'),1);
% else
%     [newMesh, lights, tenseMesh] = ...
%         mrmBuildMesh(voxels, mmPerVox, host, windowID, ...
%         'RelaxIterations', relaxIterations, ...
%         'MeshName',meshName, ...
%         'QueryFlag',1,...
%         'SaveTenseMesh');
%     newMesh = meshSet(newMesh,'lights',lights);
% end

% Must have a name
newMesh = meshSet(newMesh,'name',meshName);
tenseMesh = meshSet(tenseMesh,'name',sprintf('%s-tense',meshName));

% waitbar(0.65,wbar,sprintf('meshBuild: Unsmoothed mesh vertex to gray mapping'));
initVertices = meshGet(tenseMesh,'vertices');
newMesh = meshSet(newMesh,'initialvertices',initVertices);
vertexGrayMap = mrmMapVerticesToGray(...
    initVertices, ...
    viewGet(view,'nodes'), ...
    viewGet(view,'mmPerVox'),...
    viewGet(view,'edges'));

newMesh = meshSet(newMesh,'vertexGrayMap',vertexGrayMap);
newMesh = meshSet(newMesh,'name',meshName);
newMesh = meshSet(newMesh,'nGrayLayers',numGrayLayers);

waitbar(0.9,wbar,sprintf('meshBuild: Saving mesh file %s',meshGet(newMesh,'name')));

% Save mesh file
[newMesh newMesh.path] = mrmWriteMeshFile(newMesh);

waitbar(1,wbar,sprintf('meshBuild: Done')); 
pause(0.5);
close(wbar);

% Now refresh the UI
view = viewSet(view,'addandselectmesh',newMesh);

return;

%---------------------------------------
function classFile = verifyClassFile(view,hemisphere)

classFile =  viewGet(view,'classFileName',hemisphere);
str = sprintf('Class %s',classFile)

r=questdlg(str);   
if ~strcmp(r,'Yes')
    switch hemisphere
        case 'left'
            view = viewSet(view,'leftClassFileName',[]); 
        case 'right'
            view = viewSet(view,'rightClassFileName',[]); 
    end
    classFile =  viewGet(view,'classFileName',hemisphere);
end

return;

%---------------------------------------
function voxels = classExtractWhite(voxels,data,voi,whiteValue)
%

% ras 05/07: the indexing of data seems off to me -- is this correct?
voxels(voi(1):voi(2), voi(3):voi(4), voi(5):voi(6)) = ...
    voxels(voi(1):voi(2), voi(3):voi(4), voi(5):voi(6)) ...
    | (data(voi(1):voi(2), voi(3):voi(4), voi(5):voi(6)) == whiteValue);

return;


%----------------------------------------
function [meshName,numGrayLayers,hemiNum,alpha,restrictVOI,relaxIterations] = ...
    readParams(newMeshNum,hemisphere)
%
%  readParams
%
% Internal routine to read the parameters for meshBuild
% 
meshName = sprintf('%sSmooth',hemisphere);
numGrayLayers = 0;
switch hemisphere
    case 'left'
        hemiNum = 1;
    case 'right'
        hemiNum = 2;
    case 'both'
        hemiNum = 0;
end

% transparency level (transparency is off by default, but if it gets turned
% on, this alpha parameter will have an effect).
alpha = 200;
restrictVOI = 1;
relaxIterations = 0.2;

prompt = {'Mesh Name:',...
        'Number of Gray Layers (0-4):',...
        'Hemisphere (0=both, 1=left, 2=right):',...
        % 'Default alpha (0-255):',...
        % 'Inflation (0=none, 1=lots):',...
        % 'Restrict to class VOI (0|1):'};
        };
defAns = {meshName,...
        num2str(numGrayLayers),...
        num2str(hemiNum),...
        % num2str(alpha),...
        % num2str(relaxIterations),...
        % num2str(restrictVOI)};
        };

resp = inputdlg(prompt, 'meshBuild Parameters', 1, defAns);

if(~isempty(resp))
    meshName = resp{1};
    numGrayLayers = str2num(resp{2});
    hemiNum = str2num(resp{3});
    % alpha = str2num(resp{4});
    % relaxIterations = round(str2num(resp{5})*160);  % Arbitrary choice, scales iters [0,160]
    % restrictVOI = str2num(resp{6});
else
    meshName = [];
    numGrayLayers = [];
    hemiNum = [];
    % alpha = [];
    % relaxIterations = [];  % Arbitrary choice, scales iters [0,160]
    % restrictVOI = [];
end

return;


%---------------------------------
function [voxels,view] = meshGetWhite(view, hemiName, numGrayLayers, voxels)
%
%
%

if ieNotDefined('view'), error('You must send in a volume view'); end
if ieNotDefined('hemiName'), error('You must define right,left or both'); end
if ieNotDefined('numGrayLayers'), numGrayLayers = 0; end

classFile = verifyClassFile(view,hemiName);
if isempty(classFile),
    close(wbar); newMeshNum = -1;
    voxels = [];
    return;
end
classFileParam = [hemiName,'ClassFile'];
view       = viewSet(view,classFileParam,classFile);

classData = viewGet(view,'classdata',hemiName);
if ieNotDefined('voxels'),
    voxelsOld = uint8(zeros(classData.header.xsize, ...
        classData.header.ysize, ...
        classData.header.zsize));
else
    voxelsOld = voxels;
end
voxels = zeros(classData.header.xsize, ...
        classData.header.ysize, ...
        classData.header.zsize);

% Restrict the white matter volume to a size equal to the ROI in which it
% was selected 
voxels = classExtractWhite(voxels,...
    classData.data,classData.header.voi,classData.type.white);
%   msh = meshColor(meshSmooth(meshBuildFromClass(voxels,[1 1 1])));
%   meshVisualize(msh);

% Add the gray matter
if(numGrayLayers>0)
    
    [nodes,edges,classData] = mrgGrowGray(classData,numGrayLayers);
    voxels = ...
        uint8( (classData.data == classData.type.white) | ...
        (classData.data == classData.type.gray));
end

voxels = uint8(voxels | voxelsOld);

return;
