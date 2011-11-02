function [view, OK] = meshLoad(view, mshFileName, displayFlag)
% Load mesh from a file and add it to the 3D gray view.
%
%  [view, OK] = meshLoad(view, mshFileName, [displayFlag=0]);
%
% When we load the mesh, we also compute the vertexGrayMap on the fly.
% This defines the mapping from the mesh vertices into gray matter for
% that particular data set (defined in view).
%
% If the mesh filename is provided as a directory, will prompt the user for 
% a mesh file, starting in that directory. If it is set as 'firstmesh', it 
% will load the first mesh file in the view's current mesh directory.
%
% If the optional 'displayFlag' arg is set to 1, it will  open a mrMesh
% window for the mesh. [by default, it's set to 0: don't display, just
% load.]
%
% ras, 11/07: added display flag.

if notDefined('view'),			view = getCurView;					end
if notDefined('mshFileName'), mshFileName = viewGet(view, 'meshdir'); end
if notDefined('displayFlag'),	displayFlag = 0;					end

OK = 1;

if ismember(lower(mshFileName), {'firstmesh' 'newest' 'mostrecent'})
	meshDir = viewGet(view, 'MeshDir');
	w = dir( fullfile(meshDir, '*.mat') );
	[meshFiles I]= setdiff({w.name}, {'MeshSettings.mat' 'MeshAngles.mat'});
		
	if isempty(meshFiles)
		error(sprintf('No mesh files in the mesh directory: %s', meshDir));
	else
		if ismember(lower(mshFileName), {'newest' 'mostrecent'})
			% find most recent mesh file
			[dates order] = sortrows( datevec({w(I).date}) );
			mshFileName = fullfile(meshDir, meshFiles{ order(end) });
		else
			% find first in list
			mshFileName = fullfile(meshDir, meshFiles{1});
		end
	end
end

[msh meshDir] = mrmReadMeshFile(mshFileName);
if(isempty(msh)), OK = 0; return; end

% Updates the mesh mesh to a new format directly readable by the mex files
% GB 02/13/05
msh = meshFormat(msh);

% Create the appropriate map from mesh vertices to gray matter.  This can
% differ from session to session because we acquire different slices.
%
if ispref('VISTA', 'autoComputeV2GMap')
	autoComputeV2G = getpref('VISTA', 'autoComputeV2GMap');
else
	autoComputeV2G = 0;
end

if isempty(meshGet(msh,'vertexGrayMap')) | autoComputeV2G
    vertexGrayMap = mrmMapVerticesToGray(...
        meshGet(msh, 'initialvertices'),...
        viewGet(view, 'nodes'),...
        viewGet(view, 'mmPerVox'),...
        viewGet(view, 'edges'));

    msh = meshSet(msh, 'vertexgraymap', vertexGrayMap);
end

%% Also compute the grayVertexMap if it is a requested preference
if(ispref('VISTA','autoComputeG2VMap'))
    if (getpref('VISTA','autoComputeG2VMap'))
        disp('Computing g2vmap for mesh');
        if isempty(meshGet(msh,'grayVertexMap'))
            grayVertexMap = mrmMapGrayToVertices(...
                viewGet(view, 'nodes'),...
                meshGet(msh, 'initialvertices'),...
                viewGet(view, 'mmPerVox'));
            msh = meshSet(msh, 'grayvertexmap', grayVertexMap);
        end
    end
end


msh = meshSet(msh,'id',-1);

if(~isfield(msh, 'fibers')), msh = meshSet(msh, 'fibers', []); end

if displayFlag==1
	msh = meshVisualize(msh);
	mrmSet(msh, 'cursoroff');  % a preference ... feel free to change back
end

view = viewSet(view, 'addandselectmesh', msh);

return;
