function D = Dropbox_dir()
D = [];
[~,username] = dos('ECHO %USERNAME%');
if exist('G:\DropBox\Dropbox','dir')
    D = 'G:\DropBox\Dropbox';
elseif exist('E:\Dropbox','dir')
    D = 'E:\Dropbox';
elseif exist(['C:\Users\' username(1:end-1) '\Dropbox'],'dir')
    D = ['C:\Users\' username(1:end-1) '\Dropbox'];
end
