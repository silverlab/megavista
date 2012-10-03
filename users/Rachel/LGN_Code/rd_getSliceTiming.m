function [sliceOrder sliceTiming TR] = rd_getSliceTiming(dicomFile, plotFigs)

info = dicominfo(dicomFile);
sliceTiming = info.Private_0019_1029;
TR = info.RepetitionTime;
nSlices = numel(sliceTiming);

fprintf('\nFound %d slices\nTR = %d\n', nSlices, TR)

[orderedTiming sliceOrder] = sort(sliceTiming);

if plotFigs
    figure
    hold on
    plot(sliceTiming)
    plot(sliceTiming,'.')
    xlabel('slice')
    ylabel('time acquired')
end

