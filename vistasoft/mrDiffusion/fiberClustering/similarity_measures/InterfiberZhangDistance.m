function [Dt, totalDist] = InterfiberZhangDistance(curve1, curve2, Tt)
%[Dt, totalDist] = InterfiberZhangDistance(curve1, curve2, [Tt=2])
%Distance between two fibers which are defined as two 3xN sets of 3d coordinates. 

%The metric is described in Zhang et al. (2003) IEEE Transactions on Vizualization and Computer Graphics 9(4) 
%Calculated on a point by point basis. Note: by defition, if a point on a shorter fiber is closer to
%the other fiber than Tt, this point does NOT contribute to the overal curve-to-curve distance measure.
%“In order to emphasize important differences between a pair of trajectories, we average the distance between them only 
%over the region where they are at least Tt apart; smaller differences are assumed to be insignificant”.
%Although arguable, it is natural to set Tt to data voxel size /not sure, before or after resampling/ (as Zhang 2003 did). 
%Here the default value is set to 1mm despite the fact that out data are commonly 2x2x2.

%Dt is above-the-threshold (that is, minus Tt) average point-to-curve distance  across all points on a shortest
%fiber to another fiber.  

%The output variable totalDist is simply Dt+Tt, the average point-to-curve distance between the two fibers. 
%These output arguments are different by a constant,  however included since the first
%one is the "definition" of the distance by Zhang et al., and the second
%one is easier to interpret. Also totalDist is reported as at least at Tt (even for two fibers which are closer than Tt).


%ER 11/2008
%ER 04/2009 added "totalDist" output and introduced a default value for Tt to be 0 (all points contribute to the distance measure).

if (~exist('Tt', 'var'))
 Tt=0; %Pairs of points in two curves which are closer than Tt are not considered when computing the distance between fibers. 
end

if size(curve1, 1)~=3 || size(curve2, 1)~=3
   error('Both curves must be 3xN');
end

%Instead, use a compiled function "nearpoints": For each point in one set,
%find the nearest point in another.
%[indices, bestSqDist] = nearpoints(src, dest)
%- src is a 3xM array of points
%- dest is a 3xN array of points
%- indices is a 1xM vector, in which each element tells which point
%  in dest is closest to the corresponding point in src.  
%That is, for each point in short curve, "bestSqDist" gives point-to-curve
%dist.
%
if size(curve1, 2)<size(curve2, 2)
    [indices, bestSqDist]=nearpoints(curve1, curve2);
else
    [indices, bestSqDist]=nearpoints(curve2, curve1);
end
if length(find(bestSqDist>Tt))<=0
    Dt=0; %Expansive but useless. Precisely, Tt=sum(sqrt(bestSqDist))/length(bestSqDist); We keep it as a constant Tt.
else
    Dt=sum(sqrt(bestSqDist(bestSqDist>Tt))-Tt)/length(find(bestSqDist>Tt)); 
end
totalDist=Dt+Tt;

return;

%%%%%%The slow way (gives equivalent result)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
   
    if size(curve1, 2)<size(curve2, 2)
        scurve=curve1;  %shorter
        lcurve=curve2; %longer curve
    else
        scurve=curve2; 
        lcurve=curve1;
    end

    countpoints=0;  sumdist=0;

    for pnt=1:size(scurve,2)
        distVector = sqrt((lcurve(1, :)-scurve(1, pnt)).^2 + (lcurve(2, :)-scurve(2, pnt)).^2+(lcurve(3, :)-scurve(3, pnt)).^2);
        p2curveDist=min(distVector); %Shortest point to curve distance

        if p2curveDist>Tt
            countpoints=countpoints+1;
            sumdist= sumdist+ (p2curveDist-Tt);
        end

    end

    if countpoints>0
        Dt=sumdist/countpoints;
    else
        Dt=0; 
    end
