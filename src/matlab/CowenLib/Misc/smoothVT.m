function smoothVT( boom_scale )
% smoothVT()
%
% Input: VT.interp file is read from current directory.
% Output: VT.pvd file written to current directory.
%
% Smooths position data by averaging with previous position.
% Finds head direction from velocity if greater than a threshold,
% else from the alignment of blob centers if two are present,
% else returns "no heading" as a NaN.
%
% Rewritten 3-13-00 to use acausal filtering, meaning that
% smoothing is done at each point by considering samples occurring
% both before and after.

cmplx = sqrt(-1);

in_fid = fopen( 'VT.interp', 'r' );
out_fid = fopen( 'VT.pvd', 'w' );
out_bin_fid = fopen( 'VTpvd.bin','wb' );
hist_fid = fopen( 'heading.dat', 'w' );

% Read through and find the number of lines.
% Use this info to set data sizes.
% This time-consuming process is required because
% these data are in ascii and memory size does
% not provide adequate info to compute samples.
n=0;
%line = fgets( in_fid );
line = fscanf( in_fid, '%d', 7 );
while ( ~feof( in_fid ) )
	n = n + 1;
	%line = fgets( in_fid );
    line = fscanf( in_fid, '%d', 7 );
end
Nsamples = n
fseek(in_fid,0,-1); % Resets the file pointer.

% Pre-allocate needed matrix.

data = zeros( Nsamples, 8 );
D = zeros( Nsamples, 1 );
V = zeros( Nsamples, 1 );

% Read all data from VT.interp.
prevX = 0;
prevY = 0;
pprevX = 0;
pprevY = 0;
prevD = 0;

n=0;
%line = fgets( in_fid );
line = fscanf( in_fid, '%d', 7 );
while ( ~feof( in_fid ) )
	% Display progress.
	n = n + 1;
	if ( mod(n,1000)==0 )
		msg = sprintf('Pass 1 : %d samples of %d', n, Nsamples )
	end

    for j=1:7
        data(n,j) = line(j);
    end
    %[tmp, line] = strtok(line);
    %j=0;
    %while  length(line)>0
    %    j=j+1;
    %    if strcmp( tmp, 'NaN' )
    %        data(n,j) = 0;  % MAKE ALL NaN's '0'
    %    else
    %        data(n,j) = str2num(tmp);
    %    end
    %    [tmp, line] = strtok(line);
    %end
    %if j ~= 9
    %    msg = 'error on read'
    %    return;
    %end

	% Compute distances between 1-2 and 1-3 blobs.
	% If 1-3 is greater than 1-2, but less than some limit, swap 2-3.
	d12 = sqrt( (data(n,2)-data(n,4))^2 + (data(n,3)-data(n,5))^2 );
	d13 = sqrt( (data(n,2)-data(n,6))^2 + (data(n,3)-data(n,7))^2 );
	if (~isnan(d13))
		if ( d13 > d12 ) % rear light might be 3rd.
			if ( d13 < 75 ) % its not too far away, so swap.
				swapInVector( data(n,:), 2, 3 );
			end
		end
	end

	% Compute heading from re-arranged blobs.
	Db = atan2( (data(n,3)-data(n,5)), (data(n,2)-data(n,4)) );

	% Compute final direction by averaging boom heading and
	% red/green blobs if they are there.
	%if ( ~isnan( data(n,8) ) )
	%	if ( ~isnan( Db ) )
	%		% Perform addition on the complex circle to avoid wrap probs.
	%		C = exp(cmplx*(.5*Db + .5*data(n,8)));
	%		D(n) = atan2( imag(C), real(C) );
	%	else
	%		D(n) = data(n,8);
	%	end
	%else
	%	D(n) = Db;
	%end

	% Final check on D being a NaN.
	if ( isnan(Db) )
		if ( ~isnan(prevD) )
			D(n) = prevD;
		else
			D(n) = 0;
      end
   else
      D(n) = Db;
	end

	% Compute average location of blobs and compute velocity from previous.
	V(n) = sqrt( (data(n,2)-pprevX)^2 + (data(n,3)-pprevY)^2 );

	prevX = data(n,2);
	prevY = data(n,3);
	pprevX = prevX;
	pprevY = prevY;
	prevD = D(n);

	%line = fgets( in_fid );
    line = fscanf( in_fid, '%d', 7 );
end

% The smoothing operation uses a WINDOW of variable size.
% WINDOW samples both pre and post will be considered
% for each samples being smoothed.

WINDOW = 20;
b = ones(1,WINDOW)/(WINDOW);

% Now, use samples from the past and future to smooth the present (acausal filtering).
% Filtering uses Matlab's "filtfilt" routine which sets the order of filtering
% by the 'b' coefficient, which roughly states how many samples are used in each fit.
% "filtfilt" returns all NaN's if any data point is a NaN.  This will cause problems
% at the start of the file where VT.interp contains a few startup NaN's.

xx = filtfilt( b, 1, data(:,2) );           % x position
yy = filtfilt( b, 1, data(:,3) );           % y position
vv = filtfilt( b, 1, V(:) );                % velocity
dd = filtfilt( b, 1, exp( cmplx * D(:) ) ); % head direction
dd = atan2( imag(dd), real(dd) );
% Compute angular velocity.
CdHD = exp( cmplx * ( diff(dd) ) );
dHD = atan2( imag(CdHD), real(CdHD) ); 					    % angular vel
dHD(length(dHD)+1) = 0;
% Reduce the velocity given the angular velocity, then compute acceleration.
vv = vv - boom_scale * abs(dHD);
% Set a floor of 0.
mask = find( vv < 0 );
vv(mask) = 0;
acc = diff( vv );
acc( length(acc) + 1 ) = 0; % To make the same length as other vectors.
% Calc turns.
turn = findTurns( dHD );

for n=1:Nsamples
	fprintf( out_fid, '%d %d %d %f %f %f %f %d\n', ...
			data(n,1), round(xx(n)), round(yy(n)), ...
			vv(n), dd(n), acc(n), dHD(n), turn(n) );
	fwrite( out_bin_fid, data(n,1),'integer*4' );
	fwrite( out_bin_fid, round(xx(n)),'integer*4' );
	fwrite( out_bin_fid, round(yy(n)),'integer*4' );
	fwrite( out_bin_fid, vv(n),'real*4' );
	fwrite( out_bin_fid, dd(n),'real*4' );
	fwrite( out_bin_fid, acc(n),  'real*4' );
	fwrite( out_bin_fid, dHD(n),  'real*4' );
	fwrite( out_bin_fid, turn(n), 'real*4' ); % Just call first samples all straight ahead.

end

fclose( in_fid );
fclose( out_fid );
fclose( out_bin_fid );
fclose( hist_fid );
