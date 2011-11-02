function dwiPlot(pType,dwi,varargin)
% Gateway routine for plotting diffusion weighted images
%
%   dwiPlot(pType,dwi,varargin)
%
% dwi is a struct with fields containing
%  .ni
%  .bvecs
%  .bvals
%
% Types of plots
%   bvecs:   The bvecs
%   ADC:     The ADC shown as lengths of the corresponding bvecs
%            If a tensor is also passed, then the predicted ADC is shown as
%            a surface
%
% Example:
%   dwiPlot('bvals',dwi);
%   dwiPlot('bvecs',dwi);
%   dwiPlot('adc',dwi,ADC);
%   dwiPlot('adc',dwi,ADC,Q);
%
%
% See also:
%
% (c) Stanford VISTA Team, 2011

if notDefined('pType'), pType = 'bvecs'; end

pType = mrvParamFormat(pType);

switch pType
    case {'bvals'}
        bvals = dwi.bvals;
        h = mrvNewGraphWin;
        plot(1:length(bvals),bvals,'-x');
        xlabel('Scan')
        ylabel('B-value')
        set(gca,'ylim',[min(bvals(:)),max(bvals(:))*1.05])
        grid on

    case {'bvecs'}
        % To become a dwiGet(dwi,'bvals positive')
        % Find the positive values
        bvals = dwi.bvals;
        bvecs = dwi.bvecs;
        lst   = (bvals == 0);
        bvals = bvals(~lst);
        bvecs = bvecs(~lst,:);

        tmp = diag(bvals)*bvecs; tmp = unique(tmp,'rows');
        T = delaunay3(tmp(:,1),tmp(:,2),tmp(:,3));

        mrvNewGraphWin;
        tetramesh(T,tmp);
        axis on; grid on; axis equal; colormap(gray)

    case {'adc'}
        % Plot the adc values along the bvecs
        % If a Q is passed in as the 2nd argument, use that tensor to plot
        % the predicted surface.

        if isempty(varargin), error('ADC data required.');
        else adc = varargin{1};
        end

        t = sprintf('ADC: ');
        % Start the figure
        mrvNewGraphWin;
        cmap = autumn(255);

        % We use this to get the predicted ADC values from the tensor
        % We plot the surface if available.
        if length(varargin) > 1
            % User passed in Q, make the predicted peanut
            Q = varargin{2};
            [X,Y,Z] = sphere(15);
            [r,c] = size(X);

            v = [X(:),Y(:),Z(:)];
            adcPredicted = diag(v*Q*v');
            v = diag(adcPredicted)*v;

            x = reshape(v(:,1),r,c);
            y = reshape(v(:,2),r,c);
            z = reshape(v(:,3),r,c);
            surf(x,y,z,repmat(256,r,c),'EdgeAlpha',0.1);
            axis equal, colormap([cmap; .25 .25 .25]), alpha(0.5)
            camlight; lighting phong; material shiny;
            set(gca, 'Projection', 'perspective');
            hold on
            t = sprintf('%s Predicted (surf) and',t);
        end

        % The diffusion weighted bvecs
        bvecs = dwiGet(dwi,'diffusion bvecs');

        % Compute and plot vector of measured adcs
        adcV = diag(adc)*bvecs;
        plot3(adcV(:,1),adcV(:,2),adcV(:,3),'.')
        grid on
        title(sprintf('%s Measured (points)',t));

    otherwise
        error('Unknown plot type: %s\n',pType);
end

return
