segments=LK_Segment_Pulls_Further();
close
fprintf("Pull Segments Identified\n")

paws=fieldnames(segments);

%%
%iterate through paws
for i=2:3
    phases=fieldnames(segments.(paws{i}));
    
    %iterate through phases
    for j=1:2
        idx=(segments.(paws{i}).(phases{j}));
        
        
        fprintf("Creating videos for the %s segment of the %s paw\n",phases{j},paws{i});
        
        %iterate through rows of indices
        for row=1:50:height(idx)
            
            %iterate thourgh columns of indices
            %for col=1:width(idx)-1
        
                %if ~isnan(idx{row,col}) && ~isnan(idx{row,col+1})
                if ~isnan(idx{row,1}) && ~isnan(idx{row,end})
                    %DLC_Create_Labeled_Video(idx{row,col},idx{row,col+1},[paws{i} '_' idx.Properties.VariableNames{col} '_' num2str(row)])
                    DLC_Create_Labeled_Video(idx{row,1},idx{row,end},[paws{i} '_' phases{j} '_' num2str(row)])

                end
                
            %end
        end
    end
end