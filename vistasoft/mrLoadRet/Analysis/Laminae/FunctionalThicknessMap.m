function map = FunctionalThicknessMap(ampMap)

% map = FunctionalThicknessMap(ampMap);
%
% Calculate the functional thickness map associated with the input ampMap,
% a cell array that is the same size as the presently selected flat map.
% Returns a double array where each element is the functional thickness in
% mm.
%
% Ress, 04/05

nCells = length(ampMap(:));
map = repmat(NaN, size(ampMap));

waitH = waitbar(0, 'Calculating functional thickness map...');
for ii=1:nCells
  waitbar(ii/nCells, waitH);
  data = ampMap{ii};
  if ~isempty(data)
    amps = data(:, 1);
    t = data(:, 3);
    aSum = sum(amps(:));
    cen = sum(amps .* t) / aSum;
    map(ii) = 2 * sqrt(sum(amps .* (t - cen).^2) / aSum);
  end
end

close(waitH);
