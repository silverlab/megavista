
% copytextx

function copytextx(matrix);

dlmwrite( 'filename.txt', matrix, '\t' );
!cat filename.txt | pbcopy
