function [outputImage,affineMatrix] = affine_from_values_B(inputImage, ...
    translationX, translationY, rotation,Sx,Sy,Shx,Shy)
%% function affine_from_values
% Inputs:
% - a 2D image
% - the coeficients for the affine matrix
% Note rotation is in radians
% Return a transformed image and the affine matrix.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% used to build affine matrix compliant with andy's k-space transforms !!!
% SHENANIGANS ENSUE !!!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% x = (size(inputImage,1)+1)/2;
% y = (size(inputImage,2)+1)/2;
% x = -1;
% y = -1;
% x = 0;
% y = 0;
    % Rotation about the image center plus translation
    %rigidMatrix=[cos(rotation), -sin(rotation), -y*cos(rotation) + x*sin(rotation) + y + translationX; ...
    %             sin(rotation), cos(rotation), -y*sin(rotation) - x*cos(rotation) + x + translationY; ...
    %             0, 0, 1]; % Page 19 of the registration slides. Notice x and y are swaped because of matlab index mapping.
             
    % Rotation about the image center with translation and scalling 
    %rigidMatrix=[Sx*cos(rotation), -Sx*sin(rotation), Sx*(-y*cos(rotation) + x*sin(rotation)) + y + translationX; ...
    %             Sy*sin(rotation), Sy*cos(rotation), Sy*(-y*sin(rotation) - x*cos(rotation)) + x + translationY; ...
    %             0, 0, 1]; % In the notebook. Again, indexes are swapped
    %             because I also swapped the X and Y at the size().

% rotation = -rotation;
% % Scaling in the intuitive sense
% Sx = 1/Sy;
% Sy = 1/Sx;    
%     
% % translation from origin to point (x,y)     
% %P1 = [1, 0, -x; ...
% %      0, 1, -y; ...
% %      0, 0, 1];         
% % translation back to the origin from point (x,y)
% P1 = [1, 0, x; ...
%       0, 1, y; ...
%       0, 0, 1];
%     
% % final translation of the image  
% T = [0, 0, translationY; ...
%      0, 0, -translationX; ...
%      0, 0, 0];
%  
% % rotation matrix 
% R = [cos(rotation), -sin(rotation), 0; ...
%      sin(rotation), cos(rotation), 0; ...
%      0, 0, 1];
%  
% % scalling matrix 
% Sc = [Sx, 0, 0; ...
%       0, Sy, 0; ...
%       0, 0, 1];
%   
% % shearing matrix  
% Sh = [1, Shx, 0; ...
%       -Shy, 1, 0; ...
%       0, 0, 1];
%   
% % Final affinity transmutation matrix magic thingie. Every operation is performed about the center of the image.  
% affineMatrix = (P1*Sh*Sc*R/P1) + T;


% Make the matrix
% x = double((y2-y1+1))/2;
% y = double((x2-x1+1))/2;

x= 0;
y= 0;

% translation from origin to point (x,y)     
P1 = [1, 0, -x; ...
      0, 1, -y; ...
      0, 0, 1];         
% translation back to the origin from point (x,y)
P2 = [1, 0, x; ...
      0, 1, y; ...
      0, 0, 1];

% final translation of the image  
% T = [1, 0, translationX; ...
%      0, 1, -translationY; ...
%      0, 0, 1];
T = [0, 0, translationX; ...
     0, 0, -translationY; ...
     0, 0, 0];

% rotation matrix 
R = [cos(rotation), -sin(rotation), 0; ...
     sin(rotation), cos(rotation), 0; ...
     0, 0, 1];

% scalling matrix 
Sc = [Sx, 0, 0; ...
      0, Sy, 0; ...
      0, 0, 1];

% shearing matrix  
Hx = [1, 0, 0; ...
      Shx, 1, 0; ...
      0, 0, 1];
Hy = [1, Shy, 0; ...
      0, 1, 0; ...
      0, 0, 1];
  
% Final affinity transmutation matrix magic thingie. Every operation is performed about the center of the image.  
% affineMatrix = (P2*T*R*Sc*Hy*Hx*P1);
affineMatrix = (P2*R*Sc*Hy*Hx*P1)+T;

outputImage = resampleImage(inputImage, ...
    getDeformationFieldFromAffine(inputImage, affineMatrix));

end