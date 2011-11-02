function val = fgGet(fg,param,varargin)
%Get values from a fiber group structure
%
%  val = fgGet(fg,param,varargin)
%
% Parameters
%
%    'name'
%    'type'
%    'colorrgb'
%    'thickness'
%    'visible'
%    'fibers'
%    'fibernames'
%    'fiberindex'
%
%  Other stuff ...
%     {'uniqueimagecoords'}
%     {'n samples per fiber ')
%      {'uniqueimagecoords'}
%     {'node to imagecoords'}
%      'tensors'
%      'nfibers'
%      {'fibernodes','nodes'}
%
% See also: dwiGet/Set, fgCreate; fgSet
%
% (c) Stanford VISTA Team

%% Programming TODO:
%   We should store the transforms needed to shift the fg coordinates
%   between acpc and image space.

%%
if notDefined('fg'),error('fiber group required.'); end
if notDefined('param'), error('param required.'); end

val = [];

switch mrvParamFormat(param)
    case 'name'
        val = fg.name;
    case 'type'
        val = fg.type;
    case 'colorrgb'
        val = fg.colorRgb;
    case 'thickness'
        val = fg.thickness;
    case 'visible'
        val = fg.visible;
        
        % Fibers
    case {'fibers'}
        % Either all the fibers, or a subset of the fibers
        % val = fgGet(fg,'fibers',list);
        %
        % The return contains each set of fiber coordinates as a 3xN matrix. 
        % dtiH (mrDiffusion) requires that the fiber coordinates be stored
        % as a set of cell arrays because it represents many different
        % fibers in each group, and the fibers have different lengths.
        if ~isempty(varargin)
            list = varargin{1};
            val = cell(length(list),1);
            for ii=1:length(list)
                val{ii} = fg.fibers{ii};
            end  
        else
            val = fg.fibers;
        end
    case 'fibernames'
        val = fg.fiberNames;
    case 'fiberindex'
        val = fg.fiberIndex;
    case 'tensors'
        val = fg.tensors;
    case 'nfibers'
        val = length(fg.fibers);
    case {'fibernodes','nodes'}
        nFibers = fgGet(fg,'n fibers');
        val = zeros(nFibers,1);
        for ii=1:nFibers
            val(ii) = length(fg.fibers{ii});
        end
        
    case {'nsamplesperfiber','nfibersamples'}
        % fgGet(fg,'n samples per fiber ')
        % How many samples per fiber.  This is about equal to
        % their length in mm, though we need to write the fiber lengths
        % routine to actually calculate this.
        nFibers = fgGet(fg,'n fibers');
        val = zeros(1,nFibers);
        for ii=1:nFibers
            val(ii) = length(fg.fibers{ii});
        end
        % Fiber coordinates
    case {'imagecoords'}
        % Return the image coordinates of a specified list of fibers 
        %   c = fgGet(fgImg,'discrete coords',fgNumbers,xForm);
        %
        % Fiber coords are represented at fine resolution in ACPC space.
        % These coordinates are rounded and in image space
        
        if ~isempty(varargin)
            fList = varargin{1};
            if length(varargin) > 1
                xForm = varargin{2};
                % Put the fiber coordinates into image space
                fg = dtiXformFiberCoords(fg,xForm);
            end
        else
            % In this case, the fiber coords should already be in image
            % space.
            nFibers = fgGet(fg,'n fibers');
            fList = 1:nFibers;
        end
        
        % Pull out the coordinates and round them.  These are in image
        % space.
        nFibers = length(fList);
        val = cell(1,nFibers);
        if nFibers == 1
            val = round(fg.fibers{fList(1)}');
        else
            for ii=1:nFibers
                val{ii} = round(fg.fibers{fList(ii)}');
            end
        end
        
    case {'uniqueimagecoords'}
        % Return the unique coordinates of all the fibers 
        %   coords = fgGet(fg,'unique image coords');
        % These are image coords, and thus rounded.
        %
        if isempty(varargin), error('ACPC to image transform required'); end
        xForm = varargin{1};
        fg = dtiXformFiberCoords(fg,xForm);
        val = round(horzcat(fg.fibers{:})');
        val = unique(val,'rows');
        
    case {'nodetoimagecoords','node2voxel','nodetovoxel','node2imagecoords'}
        % fgGet(fg,'node 2 voxel',xForm.acpc2img,coords)
        %
        % We create a cell array,node2voxel{} of the same size as the fibers{}. The
        % entries of node2voxel specify whether a node in the fiber is inside of a
        % particular row in coords.  If the node is not in any of the coords, the
        % entry is set to 0.  This means that node is outside the 'coords'
        % of interest.
        if length(varargin) == 2
            % Normal.
            xForm = varargin{1};
            coords = varargin{2};
            fg = dtiXformFiberCoords(fg,xForm);
        else
            error('Not sure what to do here.');
        end

        nFiber = fgGet(fg,'n fibers');
        fprintf('%d nFibers\n',nFiber);
        val = cell(nFiber,1);
        for ii=1:nFiber
            if ~mod(ii,200), fprintf('%d ',ii); end
            % Node coordinates in image space
            nodeCoords = fgGet(fg,'image coords',ii);

            % The values in loc are the row of the coords matrix that contains
            % that sample point in a fiber.  For example, if the number 100 is
            % in the 10th position of loc, then the 10th sample point in the
            % fiber passes through the voxel in row 100 of coords.
            [tf, val{ii}] = ismember(nodeCoords, coords, 'rows');
        end
        fprintf('Done\n');
        
    otherwise
        error('Unknown fg parameter: "%s"\n',param);
end

return
