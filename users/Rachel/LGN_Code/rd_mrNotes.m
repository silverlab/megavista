% rd_mrNotes.m

% mrnotes 2012-02-27
roi2coords = INPLANE{1}.ROIs(2).coords;
roi2coords12 = roi2coords(:,roi2coords(3,:) == 12);
inds = sub2ind([128 128],roi2coords12(1,:),roi2coords12(2,:));
roi2map = zeros(128);
roi2map(inds) = 1;

% 2012-03-03
er_chopTSeries2.m 
% calculates many of the tc fields in timeCourseUI
% allTcs and meanTcs are averaged across trials, with normBsl
% amps = mean amplitude during peak period - mean amp during baseline
% period

tc_visualizeGlm 
% leads to
tc_applyGlm
% leads to
glm

% mrVista does *not* include the condition specified as baseline (cond=0)
% in the design matrix.
% regression is done in a really simple step, b = Y\X