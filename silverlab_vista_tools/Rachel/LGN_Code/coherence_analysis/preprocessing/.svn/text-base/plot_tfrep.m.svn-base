function plot_tfrep(tfrep)

    if strcmp(tfrep.type, 'strfpak')
        tfrep.type = 'ft';
    end

    %% type checking
    allowedTypes = {'ft', 'wavelet', 'lyons'};    
    if ~ismember(tfrep.type, allowedTypes)
        error('Cannot display time-frequency representation of type %s!\n', tfrep.type);
    end

    %% plot stuff common to all types
	imagesc(tfrep.t, tfrep.f, tfrep.spec);
    axis xy;
    v_axis = axis;
    v_axis(1) = min(tfrep.t);
    v_axis(2) = max(tfrep.t);
    v_axis(3) = min(tfrep.f); 
    v_axis(4) = max(tfrep.f);
    axis(v_axis);
    xlabel('Time'), ylabel('Frequency');
    
    %% plot type-specific stuff
    switch tfrep.type
        
        case 'ft'
            
            DBNOISE = 50;
            maxB = max(max(tfrep.spec));
            minB = maxB - DBNOISE;
            
            caxis('manual');
            caxis([minB maxB]);
            
            cmap = spec_cmap();
            colormap(cmap);            
            %colorbar;
            
        case 'wavelet'

            
        case 'lyons'
            
            colormap('default');
            %colorbar;
            
    end
    
    
