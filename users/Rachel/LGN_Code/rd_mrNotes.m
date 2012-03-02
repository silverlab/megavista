% rd_mrNotes.m

% mrnotes 2012-02-27
roi2coords = INPLANE{1}.ROIs(2).coords;
roi2coords12 = roi2coords(:,roi2coords(3,:) == 12);
inds = sub2ind([128 128],roi2coords12(1,:),roi2coords12(2,:));
roi2map = zeros(128);
roi2map(inds) = 1;