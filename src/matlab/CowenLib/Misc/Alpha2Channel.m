function  c = Alpha2Channel(alpha,num)
alpha = upper(alpha);
c = nan;
if findstr(alpha,'CSC')
    c = str2num(alpha(4:end))+144;
else
    if nargin == 1
        if strcmp(alpha(1:2),'TT')
            c = str2num(alpha(3:end));
        else
            switch(upper(alpha))
                case {'HIPP' 'SC_HIPP' 'SCHIPP' 'SEHIPP'}
                    c = 1000;
                case {'SCR1' 'SER1' 'R1'}
                    c = 1001;
                case {'SCR2' 'SER2' 'R2'}
                    c = 1002;
                otherwise
                    a = alpha(1);
                    num = str2num(alpha(2:end));
                    c = 12*(char(a)-65) + num;
            end
        end
    else
        c = 12*(char(alpha)-65) + num;
    end
end