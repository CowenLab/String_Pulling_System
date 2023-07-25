function [F, loadstr] = load_waveform_file(wave_filename, what_to_load, times_to_load, time_precision)
% Load in a waveform file, whether it be TT, SE, or ST -- this is
% a wrapper for all of the NLX2MAT functions.
%[TimeStamps, ScNumbers, CellNumbers, Params, DataPoints, NlxHeader]
% 
% INPUT
%  What to load is a 6 element vector that corresponds to the nlx function input. It's 
%   a vector of 0s and 1s that specifies which things to load according to ..
%    [TimeStamps, ScNumbers, CellNumbers, Params, DataPoints, NlxHeader]
% OUTPUT -- variable depending what you specify as input. it's a cell array.

if nargin < 4
   % time_precision = 'usec';
    time_precision = '.1msec';
end
if nargin < 3
    times_to_load = [];
    time_precision = '.1msec';
end

[p,n,e] = fileparts(wave_filename);
if findstr(n,'SE') | findstr(e,'nse')
    loadstr = 'SE';
elseif findstr(n,'TT')| findstr(e,'ntt')|findstr(e,'.tt')
    loadstr = 'TT';
elseif findstr(n,'ST')| findstr(e,'nse')
    loadstr = 'ST';
else
    error('Could not identify the filetype by the file name. Must have TT,SE,ST or .ntt,.nse,.nst')
end


funcstr = ['nlx2mat' loadstr];

F{sum(what_to_load)} = [];
if isempty(times_to_load)
    eval(['[F{:}] = ' funcstr '(wave_filename,' num2str(what_to_load(1)) ',' num2str(what_to_load(2)) ',' num2str(what_to_load(3)) ',' num2str(what_to_load(4)) ',' num2str(what_to_load(5)) ',' num2str(what_to_load(6)) ');']);
    if isempty(F{1})
        error('Could not load data')
    end
    
else
    
    if strcmpi(time_precision, '.1msec')
        % it's in the old, .1 msec precision (32 bit) so floor the times in the file and find the intersect.
        t_in_file = Nlx2MatSE(wave_filename,1,0,0,0,0,0);
        [t idx] = intersect(floor(t_in_file/100), times_to_load);
        disp(['Found ' num2str(length(t)) ' of the ' num2str(length(times_to_load)) ' requested records. Loading.'])
        times_to_load = t_in_file(idx);
    end
    try
        eval(['[F{:}] = ' funcstr '(wave_filename,' num2str(what_to_load(1)) ',' num2str(what_to_load(2)) ',' num2str(what_to_load(3)) ',' num2str(what_to_load(4)) ',' num2str(what_to_load(5)) ',' num2str(what_to_load(6)) ', times_to_load);']);
    catch
        F = [];
        disp('Could not open file')
        
    end
end