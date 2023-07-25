function cid = CID_from_filenames(data_dir,tfilenames)
%function CID_get_filenames(CID,root_data_dir)
% Get the filenames for the CIDs passed in 
%see Cell_ID for a description of a CID
animal = str2num(data_dir(1:4));
session = str2num(data_dir(6:end));
for ii =1:length(tfilenames)
    [p,n,e] = fileparts(tfilenames{ii});
    uix = findstr(n,'_');
    clu = str2num(n((uix+1):end));
    switch n(1:2)
        case 'HI';
            ch = 1000;
        case 'R1';
            ch = 1001;
        case 'R2';
            ch = 1002;
        case 'TT';
            ch = str2num(n(3:(uix-1)));
        otherwise
            error('asfadsa')
    end
    cid(ii) = Cell_ID(animal,session,ch,clu,1);
end
return