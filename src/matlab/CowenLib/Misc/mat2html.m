function mat2html()
if ~exist('html_docs','dir')
    mkdir html_docs
end

dos(['F:\MatlabR12\sys\perl\win32\bin\perl.exe C:\Src\matlab\mat2html\mat2html.pl -H ' fullfile(pwd,'html_docs')])