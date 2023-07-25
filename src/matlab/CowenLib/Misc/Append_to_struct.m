function X = Append_to_struct(X,varargin)
% This routine takes(or makes) a structure X and adds on fields with the variable names passed in 
% through varargin. The values of these fields are appended vertically to these fields. This
% is very useful if you want to keep a matrix record of the output a series of iterations in a 
% model or test.
%
% INPUT: A variable that will or does form a structure of the variables you want to save.
%
% OUTPUT: The structure returned with the values and fields of varargin appended to the bottom
%

% cowen 1/27/2000

for ii = 2:nargin
  try
    eval(['X.' inputname(ii) ';']);
  catch
    %disp('Initializing new variable')
    eval(['X.' inputname(ii) ' = [];']);
  end
  if ischar(varargin{ii-1})
    % Append strings...
    A = eval(['X.' inputname(ii) ]);
    B = char(varargin(ii-1));
    C = feval('strvcat',A,B);
    eval(['X.' inputname(ii) ' = C;']);
  else
    % Append row vectors or scalars
    % TO DO: Check to see if the input vector is longer than the current number of columns 
    % used in this vector. If so, expand the current matrix to account for this.
    
    eval(['X.' inputname(ii) ' = [X.' inputname(ii) ';' sprintf('%f\t',varargin{ii-1}) '];']);
  end
end
