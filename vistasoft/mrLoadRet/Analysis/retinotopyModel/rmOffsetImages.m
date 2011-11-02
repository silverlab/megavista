function stim = rmOffsetImages(stim, params)
% function stim = rmOffsetImages(stim, params)
%
% Offset a retinotopic mapping stimulus to compensate for eye position. 
%
% Eye Movement position should be encoded in visual angle, with one (x, y)
% coordinate pair per stimulus frame. The coordinates should be in the
% fields:
%   params.stim(curScan).eyePosition.x 
%   params.stim(curScan).eyePosition.y 
%
% Alternatively, the coordinates can be encoded as a matrix (2 x nFrames):
%   params.stim(curScan).eyePosition 
%
% 12/2008: JW


%% If no eye movement data, return without doing anything
if ~checkfields(stim, 'eyePosition'),
    return;
end

%% Otherwise

% Parse eye eyePosition data
[x, y] = parseEyePositionData(stim);

% Get stimulus mesh grid in visual angle
[m n step] = prfSamplingGrid(params);

% Convert eye positions from degrees to pixels 
x = round(x / step);
y = round(y / step);

% Initialize an image of the correct 2D dimenstions
im = zeros(size(m));

% Jitter stimulus frame-by-frame to compensate for eye position
for f = 1:stim.nFrames
    % Reshape image from 1D to 2D
    im(stim.instimwindow) = stim.images(:, f);
    
    % Jitter in opp direction to eye movement
    %   Note that x must be negated, since a positive shift in x means a
    %   rightward eye position (and hence a leftward shift in the image),
    %   and leftward image shifts are represented by negative numbers. But
    %   y is not negated, since a positive shift in y means an upward eye
    %   movement (and hence a downward shift in the image), and downward
    %   image shifts are represented by positive numbers.
    im = circshift(im, [y(f), -x(f)]);
    
    % Delete portion of image that was wrapped 
    if y(f) >= 0, 
        im(1:y(f), :) = 0; 
    else
        im(end-y(f):end, :) = 0; 
    end

    if -x(f) >=0
        im(:, 1:-x(f)) = 0;
    else
        im(:, end+x(f):end) = 0; 
    end
    
    
    % Reshape from 2D to 1D
    stim.images(:, f) = im(stim.instimwindow);
end

% --------------------------------------------------------------
% test
% h = figure;
% im = zeros(size(m));
% 
% for f = 1:stim.nFrames
%     % reshape image from 1D to 2D
%     im(stim.instimwindow) = stim.images(:, f);
%     figure(h);
%     imagesc(im);
%     axis image off;
%     pause(0.1)
% end
%---------------------------------------------------------------

return











function [x, y] = parseEyePositionData(stim);

if checkfields(stim, 'eyePosition', 'x') && checkfields(stim, 'eyePosition', 'y')
    x = stim.eyePosition.x;
    y = stim.eyePosition.y;
end

if isnumeric(stim.eyePosition)
    if size(stim.eyePosition) == [2 stim.nFrames]; 
        x = stim.eyePosition(1, :);
        y = stim.eyePosition(2,:);
    elseif size(stim.eyePosition) == [stim.nFrames 2]
        x = stim.eyePosition(:, 1);
        y = stim.eyePosition(:, 2);
    else
        error('[%s]: Eye movement data is not a 2 x nFrames matrix'); 
    end
end

return    


