function createdate = File_creation_date(fname)
% Dir just has modification time.
[~,str] = dos(['dir ' fname]);
c = textscan(str,'%s');
createdate = c{1}{16};