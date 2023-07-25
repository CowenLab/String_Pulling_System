function [Closest_ix_in_B] = Align_two_vectors(A,B)
% You have two sequences of numbers, A and B. Assume that there is a fair
% amount of overlap between these two sequences. We want to find the best
% way to align the two sequences. Also assume that some chunks of data in
% either sequence are missing. Find the best matches of B that correspond
% to the sequences in A and vice versa.
%
% HOW: Go to the middle of A, take a chunk of 5 numbers. Find the
% corresponding match in B (if there are two, then expand the sequence
% until there is only one). If not match is found, find a different
% location in A and try again. Once a match is found, keep sliding A
% forward and backward, marking the indices in A that correspond to the
% indices in B and vice versa until you lose a record.
%
% Repairing blocks of missing data:
%
% OUTPUT: Closest_ix_in_B = a vector of length A of the indices in B that most closely matches the
%         numbers in A. Nan's indicate points of no match.
%
%
% cowen 2011

if nargin == 0
    % for testing.
    A = rand(1000,1);
    B = [rand(200,1); A; rand(400,1)];
    % Now let's fuck with B
    B = B + double(rand(size(B)) > 0.99);
end


CHUNK_SIZE = 5;
CHUNK_SIZE_M1 = CHUNK_SIZE - 1;
Closest_ix_in_B = zeros(size(A))*nan;

start_points = [round(length(A)/2) round(length(A)/4) round(length(A)/1.2)  round(length(A)/6)  round(length(A)/1.05) ];

%
n_tries = 0;
match_in_A = [];
match_in_B = [];
found_count = 0;
while (found_count == 0 && n_tries < length(start_points) )
    pos_A = start_points(n_tries+1);
    
    for iB = 1:(length(B)-CHUNK_SIZE)
        if all(A(pos_A:(pos_A + CHUNK_SIZE_M1)) == B(iB:(iB + CHUNK_SIZE_M1)))
            found_count = found_count + 1;
            match_in_B(found_count) = iB;
            %Closest_ix_in_B(pos_A) = iB;
        end
    end
    n_tries = n_tries + 1;
    
end

if found_count ==0
    n_tries
    disp('NO ALIGNEMNT FOUND')
    return
end

if found_count > 1
    disp('More than one alignment found. Choosing the best one.')
    for ii =1:length(match_in_B)
        if all(A(pos_A:(pos_A + CHUNK_SIZE)) == B(match_in_B(ii):(match_in_B(ii) + CHUNK_SIZE)))
            break;
        end
    end
    match_in_B = match_in_B(ii);
end

%% We now have a start point. From here, keep sliding forward until you find
% reasonable matches.
start_B = match_in_B;
start_A = start_points(n_tries);
% Take the next sequence in A and compare it to B. If a match, then link
% the two. If not, then go up to sweep_forward points in B, looking for a
% match. If no match, then abandon ship and assume no alignment and go to
% the next sequence in A.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for pos_A = start_A:(length(A)- CHUNK_SIZE_M1)
    found_it = false;
    for pos_B = start_B:(min([start_B+50 length(B)]))
        if (pos_B + CHUNK_SIZE_M1) > length(B)
            break
        end
        if all(A(pos_A:(pos_A + CHUNK_SIZE_M1)) == B(pos_B:(pos_B + CHUNK_SIZE_M1)))
            Closest_ix_in_B(pos_A) = pos_B;
            found_it = true;
            break;
        end
    end
    if found_it
        start_B = pos_B + 1;
    else
        start_B = start_B + 1;
    end
end

%% Do the same thing but go backwards..
start_B = match_in_B-1;
for pos_A = (start_A-1):-1:CHUNK_SIZE_M1 % Go backwards
    found_it = false;
    for pos_B = start_B:-1:(max([start_B-50 CHUNK_SIZE_M1]))
        if all(A(pos_A:(pos_A + CHUNK_SIZE_M1)) == B(pos_B:(pos_B + CHUNK_SIZE_M1)))
            Closest_ix_in_B(pos_A) = pos_B;
            found_it = true;
            break;
        end
    end
    if found_it
        start_B = pos_B - 1;
    else
        start_B = start_B - 1;
    end
end

%% If there is noise in the data, then there should be some Nan's. Go
% through some of the Nan's and try to find the closest match in B by
% sliding forward and backward through these blocks, looking for matches.
%
% TO DO!
new_Closest_ix_in_B = Closest_ix_in_B;
bad_ix_in_A = find(isnan(new_Closest_ix_in_B));
fix_count = 0;
for ii = 2:length(bad_ix_in_A)
     % if the previous one was good, then check to see if the current one
     % is good.
     if ~isnan(new_Closest_ix_in_B(bad_ix_in_A(ii)-1))
         %fprintf('.')
         A_val = A(bad_ix_in_A(ii));
         b_ix = new_Closest_ix_in_B(bad_ix_in_A(ii)-1)+1;
         if b_ix > length(B)
             break;
         end
         B_val = B(b_ix);
         if A_val == B_val
             fix_count = fix_count + 1;
             new_Closest_ix_in_B(bad_ix_in_A(ii)) = b_ix;             
         end
     end
end
%     figure
%     plot(new_Closest_ix_in_B,'r.-')
%     hold on 
%     plot(Closest_ix_in_B,'b.-')
Closest_ix_in_B = new_Closest_ix_in_B;
disp(['Matched ' num2str(sum(~isnan(Closest_ix_in_B))) ' of ' num2str(length(Closest_ix_in_B)) ' points. That''s ' num2str(sum(~isnan(Closest_ix_in_B))/length(Closest_ix_in_B)) ' of A and ' num2str(sum(~isnan(Closest_ix_in_B))/length(B)) ' of B. Fixed ' num2str(fix_count) ' extra points'])

