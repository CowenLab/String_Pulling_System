function [Y,xdim] = Crosscorr_from_files(file1,file2,filetype,xcorr_window_msec,xcorr_bin_size_msec)
% INPUT : 2 files to xcorr
%         filetype: 't', 'tstxt' (timestamped text in units of 1/1e6 sec), 'txt' (timstamped text, in units of 1sec)
%         the total duration of the xcorr.
%         xcorr_bin_size_msec
% OUTPUT: the xcorr plot if no output specified, else provide the bincounts and labels.
%function [y,binlabels] = Crosscorr_from_files(file1,file2,filetype,xcorr_window_sec,xcorr_bin_size_msec,divisor_to_seconds)
%
% cowen

switch filetype
case 't'
    divisor_to_seconds = 1e4;
    tfp = fopen(file1, 'rb','b');
    if (tfp == -1)
        warning([ 'Could not open tfile ' file1]);
        return
    end
    ReadHeader(tfp);    
    t1 = fread(tfp,inf,'uint32');	%read as 32 bit ints
    fclose(tfp);

    tfp = fopen(file2, 'rb','b');
    if (tfp == -1)
        warning([ 'Could not open tfile ' file2]);
        return
    end
    ReadHeader(tfp);    1
    t2 = fread(tfp,inf,'uint32');	%read as 32 bit ints
    fclose(tfp);
case 'tstxt'
    divisor_to_seconds = 1e6;
    t1 = load(file1);
    t2 = load(file2);
case 'txt'
    divisor_to_seconds = 1;
    t1 = load(file1);
    t2 = load(file2);
otherwise
    disp('filetype not supported yet')
    return
end
t1 = t1/divisor_to_seconds;
t2 = t2/divisor_to_seconds;

nbins = round(xcorr_window_msec/xcorr_bin_size_msec);
[Y, xdim] = CrossCorr(t1*10000, t2*10000, xcorr_bin_size_msec, nbins);
if nargout ==0
    figure
    %plot(xdim,Y)
    
    barp(xdim-.5*xcorr_bin_size_msec,Y); % subtract .5binsize so that bins are centered on the xlabels
    a = axis;
    a(3) = min(Y); 
    axis(a)
    xlabel('msec')
    ylabel('Count')
    title(['XCorr ' file1 ' Vs ' file2 ]);
end

