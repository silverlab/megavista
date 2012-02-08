%% Create a time-frequency representation structure
%   Input:
%       typeName: 'ft', 'wavelet', 'lyons'
%
%       params: parameters to assign tfrep (optional, if not given then
%           default values will be specified for type)
%
%   Output:
%       tfrep: the time-frequency structure, for use with display_tfrep
%
function tfrep = make_tfrep(typeName, params)


    %% type checking
    allowedTypes = {'ft', 'wavelet', 'lyons'};    
    if ~ismember(typeName, allowedTypes)
        error('Unknown time-frequency representation type: %s\n', typeName);
    end
        
    %% create structure
    tfrep = struct;
    tfrep.type = typeName;
    tfrep.t = [];
    tfrep.f = [];
    tfrep.spec =[];
    
    %% set default parameters where none are given
    if nargin < 2
        params = struct;
    end
                
    switch typeName
        
        case 'ft'                
            params = check_fields(params, {'fband', 'nstd', 'high_freq', 'low_freq', 'log'}, 'Must specify params.%s for ft!\n', {125, 6, 8000, 250, 1});
                
        case 'wavelet'
            %do nothing...
                
        case 'lyons'
            
            %check for AuditoryToolbox
            fpath = which('LyonPassiveEar_new_mod');
            if isempty(fpath)
                fprintf('Cannot locate Lyons model code, make sure you have AuditoryToolbox in your path.\n');
                return;
            end            
            
            % set default values
            flds = {'low_freq', 'high_freq', 'earQ', 'agc', 'differ', 'tau', 'step'};
            dvals = {250, 8000, 4, 1, 1, 3, 0.5};
            params = check_fields(params, flds, 'Must specify params.%s for lyons!\n', dvals);        
    end
    
    tfrep.params = params;
