function [voxelFFTRaw voxelFFT meanFFT data] = rd_plotVoxelFFT(voxelData, view, scan, plotFlag, voxelIDs)

% INPUTS:   voxelData is a numTimePoints x numVoxels matrix
%           view and scan as usual
%           plotFlag 1 for plotting, 0 for no plotting
%           voxelIDs a vector of voxel ID numbers for plot labeling

nVoxels = size(voxelData,2);

if ieNotDefined('plotFlag'), plotFlag = 1; end
if ieNotDefined('voxelIDs'), voxelIDs = 1:nVoxels; end

nCycles   = numCycles(view, scan);
maxCycles = round(numFrames(view, scan)/2); % number of frequencies to plot

voxelFFTRaw = fft(voxelData);
voxelFFT  = 2*abs(voxelFFTRaw) / size(voxelData,1);
% voxelFFT  = 2*abs(fft(voxelData)) / size(voxelData,1);
meanFFT = mean(voxelFFT,2);

% Set up data 
x = (1:maxCycles)';
y = voxelFFT(2:maxCycles+1,:);

data.x = x(1:maxCycles);
data.y = y(1:maxCycles,:);

%Calculate Z-score
% Compute the mean and std of the non-signal amplitudes.  Then compute the
% z-score of the signal amplitude w.r.t these other terms.  This appears as
% the Z-score in the plot.  This measures how many standard deviations the
% observed amplitude differs from the distribution of other amplitudes.
lst = logical(ones(size(x)));
lst(nCycles) = 0;
data.zScore = (y(nCycles,:) - mean(y(lst,:))) ./ std(y(lst,:));

%Plots
if plotFlag == 1
    
    newGraphWin

    for vox = 1:nVoxels

        subplot(nVoxels,1,vox);

        % header
        headerStr = 'Mean Amp Spectrum, Voxelwise';
        set(gcf,'Name',headerStr);

        % plot it
        plot(x,y(:,vox),'bo','LineWidth',2);
        hold on
        if nCycles>1
            plot(x(1:nCycles-1),y(1:nCycles-1, vox),'b','LineWidth',2)
            plot(x(nCycles-1:nCycles+1),y(nCycles-1:nCycles+1, vox),'r','LineWidth',2)
            plot(x(nCycles+1:maxCycles),y(nCycles+1:maxCycles, vox),'b','LineWidth',2)
        else
            plot(x,y(:,vox),'b','LineWidth',2)
        end
        hold off

        % Ticks
        fontSize = 10;
        xtick=nCycles:nCycles:(maxCycles+1);
        set(gca,'xtick',xtick);
        set(gca,'FontSize',fontSize)
        
        grid on
        
        % Annotation on bottom subplot
        if vox == nVoxels
            xlabel('Cycles per scan','FontSize',fontSize)
            ylabel('Percent modulation','FontSize',fontSize)
        end
        
        % title
        if mod(vox,5)==1
            title(['Voxel ' num2str(voxelIDs(vox))])
        end

        %Z-score
        str = sprintf('Z-score %0.2f', data.zScore(vox));
        text(double(max(x)*0.82), double(max(y(:,vox))*0.78), str);
%         text(1,1,str);

        %Put data in gca
        set(gca,'UserData', data);

    end

end