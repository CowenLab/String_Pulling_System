function WriteHeader(fp, varargin)

% WriteHeader(fp, H1, H2, H3, ...)
%
% INPUTS
%    fp = file pointer
%    H1, H2, H3, ... = lines (strings) to write out as header
% 
% OUTPUTS: none
%  
% Writes NSMA header
%
% ADR 1998
% version U3.0
% status PROMOTED

fprintf(fp, '%%%%BEGINHEADER\n');
fprintf(fp, '%% Program: matlab\n');
fprintf(fp, [ '%% Date: ', datestr(now), '\n']);
fprintf(fp, [ '%% Directory: ', pwd, '\n']);
fprintf(fp, [ '%% Hostname: ', getenv('HOST'), '\n']);
fprintf(fp, [ '%% User: ', getenv('USER'), '\n']);

for iH = 1:length(varargin)
  fprintf(fp, '%% %s\n', varargin{iH});
end
fprintf(fp, '%%%%ENDHEADER\n');
