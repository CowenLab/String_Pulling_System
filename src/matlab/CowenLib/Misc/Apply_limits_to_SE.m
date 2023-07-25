function Apply_limits_to_SE(varargin)
% Just run this in the directory that has the .lim files and the .nse
% files. It will then produce the appropriate .t files.
if nargin == 0
    f = find_files('*.lim');
else
    f = find_files(varargin{1});
end

for fn = 1:length(f)
    
    all_lines = textread(f{fn},'%s','delimiter','');
    limits = [];
    
    for ii = 1:length(all_lines)
        [cl(ii) cl(ii) ftype{ii}] = strread(all_lines{ii},'%d%d%s%*[^\n]','delimiter',' ');
        L = strread(all_lines{ii},'%s','delimiter',' ');
        P = zeros((length(L)-3)/3,3);
        limcount = 1;
        for character_count = 4:3:length(L)
            P(limcount,1) = str2num(L{character_count});    
            P(limcount,2) = str2num(L{character_count+1});    
            P(limcount,3) = str2num(L{character_count+2});    
            limcount = limcount + 1;
        end
        
        switch ftype{ii}{1}
            case 'wv'
                limits = [limits;P];
            case 'Params'
                % param values are identified by negative values.
                P(:,1) = -1*P(:,1);
                limits = [limits;P];
            otherwise
                error('Corrupted file.')
        end
        clear P;
    end
    
    % Load the wv file.
    tmp = strread(f{fn},'%s','delimiter','_');
    elecname = tmp{2};
    wvfile = ['SE_' elecname '.nse'];
    new_way = 1;
    if new_way
        tstxtfile = ['SE_' elecname '_' num2str(cl(1)) '_from_lim.tstxt'];
        lims = limits';
        lims = lims(:);
        RethresholdSE_nt(wvfile,tstxtfile,lims,1,1)
    else
        tfile = ['SE_' elecname '_' num2str(cl(1)) '_from_lim.t'];
        [t,Params,wv] = nlx2matSE(wvfile,1,0,0,1,1,0);
        GoodIdx = 1:length(t);
        for lim = 1:size(limits,1)
            if limits(lim,1) > 0
                GoodIdx = GoodIdx(find(wv(limits(lim,1),1,GoodIdx) < max(limits(lim,2:3)) & wv(limits(lim,1),1,GoodIdx) >= min(limits(lim,2:3))));
            else
                GoodIdx = GoodIdx(find(Params(abs(limits(lim,1)),GoodIdx) < max(limits(lim,2:3)) & Params(abs(limits(abs(lim),1)),GoodIdx) >= min(limits(abs(lim),2:3))));
            end
        end
        
        % Write the .t file.
        fp = fopen(tfile, 'wb', 'b');
        if (fp == -1)
            errordlg(['Could not open file"' filenamefn '".']);
        end
        WriteHeader(fp, 'T-file', 'Output from Apply_limits_to_SE''Time of spiking stored in timestamps -- units are whatever was passed in.', 'as unsigned integer');
        fwrite(fp, floor(unique(t(GoodIdx)/100)), 'uint32');
        fclose(fp);
        clear t Params wv GoodIdx
        pack
    end
end
