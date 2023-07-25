function h = Database_dir();
% Returns the directory that contains the databases used to manage all of
% our data.
if isdir('U:\Cowen\Databases');
    h = 'U:\Cowen\Databases';
elseif isdir('C:\Cowen\Databases')
    h = 'C:\Cowen\Databases';
else
    error('No database directory found') 
end

