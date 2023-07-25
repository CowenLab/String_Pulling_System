function h = Homedir();
%function Homedir();
% Return the home directory of the user.
if strcmp(computer, 'PCWIN')
  D = dir('C:\Source_code\');
  if length(D)>0
    h = 'c:\';
  else 
    h = 'D:\nsma\cowen';
  end
else
   h = getenv('HOME');
end