clear a
EEGfiles = dir('e1_CR*_f');
timefiles = dir('e1_CR*_f*.ascii');
timefilenames =  {timefiles.name};
eegfilenames =  {EEGfiles.name};
disp('Viewing Sleep 1')
A = load(timefilenames{1});
B = CR_to_tsd(ReadCR(eegfilenames{1}));
a{1} = Restrict(Filter_200hz(B), A(1,1), A(end,2));
a{2} = ts(A(:,1));
a{3} = ts(A(:,2));
View_EEG(a)