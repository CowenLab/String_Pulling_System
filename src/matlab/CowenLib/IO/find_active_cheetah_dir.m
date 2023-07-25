function ched = find_active_cheetah_dir()
% Finds the most recent cheetah data directory and returns it.
%
% cowen
if exist('D:\Cheetah_data','dir')
    data_dir = 'D:\Cheetah_data';
elseif exist('E:\Cheetah_data','dir')
    data_dir = 'E:\Cheetah_data';
elseif exist('C:\Cheetah_data','dir')
    data_dir = 'C:\Cheetah_data';
elseif exist('F:\Cheetah_data','dir')
    data_dir = 'F:\Cheetah_data';
else
    error('NO DATA DIR FOUND')
end

d = dir(data_dir);
for ii = 1:length(d)
    if (d(1).isdir)
        try
            [y,mo,dy,h,mi,s] = strread(d(ii).name,'%d%d%d_%d%d%d','delimiter','-');
            m(ii) = datenum(y,mo,dy,h,mi,s);
        catch
            m(ii) = 0;
        end
    else
        m(ii) = 0;
    end
end

[mx,idx] = max(m(3:end)); % ignore the . and .. directories.
idx = idx + 2;
ched = fullfile(data_dir,d(idx).name);
