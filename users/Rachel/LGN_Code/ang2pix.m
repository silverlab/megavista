function p = ang2pix(ang, screen_dim, screen_res, view_dist, angle_type)

% function p = ang2pix(ang, screen_dim, screen_res, view_dist, angle_type)
%
% ang = visual angle in degrees
% p = pixel distance in pixels
% angle_type = 'central' or 'radial'. defaults to central.
%
% view_dist = viewing distance in preferred units (eg. cm)
% screen_dim = a screen dimension (eg. width of screen) in preferred units (eg. cm)
% screen_res = resolution of that screen dimension (eg. width) in pixels
%
% Note that 1 pi radians = 180 degrees. Also note that screen_dim/screen_res 
% is just a ratio to convert between pixels and the units you used to measure 
% viewing distance.
%
% By Rachel Denison

if ~exist('angle_type','var')
    angle_type = 'central';
end

switch angle_type
    case{'central',[]}

        p = 2 * view_dist * tan((ang/2)*(pi/180)) * (screen_res/screen_dim);

    case{'radial'}

        p = view_dist * tan(ang*(pi/180)) * (screen_res/screen_dim);
end

