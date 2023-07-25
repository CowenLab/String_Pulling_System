function EPOCH = Identify_epochs(POS,epoch_names)
% Indetify Epochs
if nargin < 2
    epoch_names = 'S1,ER1,S2,WM1,S3';
end
if iscell(epoch_names)
    new_epoch_names = [];
    for ii = 1:length(epoch_names)
        new_epoch_names = [new_epoch_names epoch_names{ii} ' '];
    end
    epoch_names = new_epoch_names;
end
EPOCH = [];
if nargin == 0
    load('POS.mat')
end
%% Restrict the data.
cla;plot(POS(:,1), POS(:,2));
a = axis;
[x, y] = ginput(2);
while (x > a(1))
    cla;plot(POS(:,1), POS(:,2));
    %epoch_names(epoch_names)
    %startend = x;
    l=input(['Enter label for epoch (e.g. ' epoch_names ')'],'s');
    if isnumeric(l)
        disp('Epoch name must start with a character')
        l=input(['Enter label for epoch (e.g. ' epoch_names ')'],'s');
    end
    eval(['EPOCH.' l ' = [' num2str(x') '];']);
    [x, y] = ginput(2);
end
