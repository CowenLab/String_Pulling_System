function saveas_try(fh,fname,ext)
% Will continue to try savease until it works. This is inresponse to
% saveas's unrelaibilty or due to network issues that temporarily cause the
% save to fail - this prevents a long script from crashing due to a failed
% saveas.

keep_trying = 1;

while keep_trying ==1
    try
        switch nargin
            case 2 
                saveas(fh,fname)
            case 3
                saveas(fh,fname,ext)
            otherwise
                error('Wrong num of args')
        end
        keep_trying = 0;
    catch
        disp('saveas failed, trying again')
        pause(3.0)
    end
end