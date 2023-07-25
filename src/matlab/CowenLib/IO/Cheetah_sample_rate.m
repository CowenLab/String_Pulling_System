%
%Spike_count_nt('Sc5.ntt')
%cwd = pwd;
%cd (find_active_cheetah_dir)

% one record = 	__int64 qwTimeStamp, qwTimeStamp0;
%	long dwParams[10]; long = 16 bytes?
%	short snData[128]; short = 8 bytes
% 128 * 16 + 8 * 32 + 64 + 32 + 32 = 2432
% Ideally, this should just take the last minute of data.

d = dir('*.Ntt')
st = inf;
ed = 0;
ns = zeros(1,length(d))
ns_30sec = zeros(1,length(d))
FieldSelection = [1 0 0 0 0];
ExtractHeader = 0; ExtractMode = 4;
     
for ii = 1:length(d)
    [ns(ii),start_ts,end_ts] = Spike_count_nt(d(ii).name);
    % only take the last 30 seconds of data.
    st = min([st start_ts]);
    ed = max([ed end_ts]);
    lab{ii} = d(ii).name;
end
%ModeArray = [(ed - 30*1e4) ed]*100; % Get only records in range
for ii = 1:length(d)
    %    [t] = ReadTT(d(ii).name);
    % Just read in the data from the last 30 seconds.
%    [t] = ReadTT(d(ii).name,[(ed - 30*1e4) ed],3); % THIS IS TOO SLOW - EVEN WHEN YOU DO RESTRICT IT!!
    %ns_30sec = length(find( t > (ed - 30*1e4) ));
    %[t] =  Nlx2MatSpike( d(ii).name, FieldSelection, ExtractHeader, ExtractMode, ModeArray ); % Arg - just as slow.
    %    
%    ns_30sec(ii) = length(t);
    ns_30sec(ii) = nan;
    fprintf('.')
end

samp_rate_30_sec = ns_30sec/30;
samp_rate = ns/((ed-st)/1e4);
bar([samp_rate;samp_rate_30_sec]')
hold on
plot([0 length(d)],[70 70],'r:')
ylabel('Hz')
set(gca,'XTick',1:length(d))
set(gca,'XTickLabel',lab)
legend('all','30sec')
% Convert to MB for a 3 hour recording session.
disp('For a 3 hour recording')
MB = (samp_rate * 60 * 60 * 3 * 2432)./1e6

%cd(cwd)