function newFg = dtiFiberMidSagSegmentMIND(fg,nPts,clipHemi)
%
% function newFg = dtiFiberMidSagSegment(fg, [nPts=10], [clipHemi='both'])
% 
% Takes a fiber goup and clips the fibers to nPts
% of the midSagital plane.
% 
% If nPts is not passed in the default is 10. 
%
% The default is to clip both left and right sides (clipHemi='both'). If
% clipHemi=='left' then only the left side (i.e. fiber coords X < 0) is
% clipped. Alternately, you can ask for just the right side (X>0) to be
% clipped.
%
% History:
% 04/29/2009 LMP wrote the function based on code from RFD
% 12.16.2009 LMP adapted from a previous version via trac.
%

if(~exist('fg','var') || isempty(fg))
    error 'You must pass in fiber group (fg) struct. Use dtiReadFibers.';
end

% The number of points to keep to each side of mid-sag
if(~exist('nPts','var') || isempty(fg))
    disp('Setting number of points to 10.');
    nPts = 10;
end
if(~exist('clipHemi','var') || isempty(clipHemi))
    disp('Clipping both left and right.');
    clipHemi = 'b';
end
if(~ischar(clipHemi)||~ismember(clipHemi(1),'blr'))
    error('clipHemi must be a char array with the first letter b|l|r.');
end

% Clean the fibers. This will ensure there is only one point that crosses
% the midline.
fg = dtiCleanFibers(fg,[],250);

newFg = dtiNewFiberGroup(sprintf('%s_midSag%02d', fg.name, nPts));

% Now find the point closest to the midline for each fiber
n = 0;
for(ii=1:numel(fg.fibers))
    curFiber = fg.fibers{ii};
    % We only operate on the first row of fiber coords (left-right coord)
    midSagDist = abs(curFiber(1,:));
    nFiberPts = numel(midSagDist);
    meanInd = mean(curFiber(1,:));
    ind = find(midSagDist==min(midSagDist));
    % Only assign the mid sag segment to fibers that have enough points and
    % are within 1mm of the midline.
    if(ind>nPts && ind<=nFiberPts-nPts && midSagDist(ind)<1)
        midSagInds = [ind-nPts:ind+nPts];
        % Ensure the fiber coords go from left-to-right
        leftMeanCoord = mean(curFiber(1,midSagInds(1:nPts)));
        rightMeanCoord = mean(curFiber(1,midSagInds(nPts+2:end)));
        if(leftMeanCoord>rightMeanCoord)
            % fiber coordinate order needs to be flipped
            curFiber = fliplr(curFiber);
            midSagInds = fliplr(size(curFiber,2)-midSagInds+1);
        elseif(leftMeanCoord==rightMeanCoord)
            % if we can't tell left from right, just skip it
            continue;
        end
        n = n+1;
        if(clipHemi(1)=='l')
            newFg.fibers{n,1} = curFiber(:,midSagInds(1):end);
        elseif(clipHemi(1)=='r')
            newFg.fibers{n,1} = curFiber(:,1:midSagInds(end));
        else
            newFg.fibers{n,1} = curFiber(:,midSagInds);
        end
        
    end

end


return

