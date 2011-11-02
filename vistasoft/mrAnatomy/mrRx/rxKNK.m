function rx = rxKNK(rx)

% rx = rxKNK(rx);
%

if ieNotDefined('rx')
    cfig = findobj('Tag','rxControlFig');
    rx = get(cfig,'UserData');
end

mrGlobals;

if ieNotDefined('session'), session = pwd; end

if isstruct(session)
    % assume view; set globals
    %inplane = session;
    clear session;
elseif ischar(session)
    %sessDir = session;
    %HOMEDIR = session;
    loadSession;
    initHiddenInplane;
    clear session;
end

msgbox('Opening KNK Code for finer Alignment...');

% get original alignment
rxAlignment = rx.xform;
rxAlignment([1 2],:) = rxAlignment([2 1],:);
rxAlignment(:,[1 2]) = rxAlignment(:,[2 1]);
knk.TORIG = rxAlignment;

% convert to tr struct for use in alignvolumedata.m
knk.trORIG = matrixtotransformation(knk.TORIG,0,rx.volVoxelSize,size(rx.ref),size(rx.ref) .* rx.refVoxelSize);

% align it
alignvolumedata(rx.vol,rx.volVoxelSize,rx.ref,rx.refVoxelSize,knk.trORIG);

% define ellipse
doc defineellipse3d
[knk.f,knk.mn,knk.sd] = defineellipse3d(rx.ref);
rx.knk = knk;

return