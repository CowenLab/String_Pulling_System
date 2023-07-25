function M = Tight_matrix(M,buffer)
% Gets rid of or trims off rows and columns on the edges that are zero.
if nargin < 2
    buffer = 0;
end
if isempty(M)
    return
end
left_kill_ix = 1;
right_kill_ix = Cols(M);
up_kill_ix = 1;
down_kill_ix = Rows(M);

bad_rows = sum(M,2)==0;
bad_cols = sum(M,1) ==0;
cnt = 1;
while bad_rows(cnt) == 1
    up_kill_ix = cnt;
    cnt = cnt + 1;
end
up_kill_ix = up_kill_ix - buffer;
if up_kill_ix < 1
    up_kill_ix = 1;
end



cnt = length(bad_rows);
while bad_rows(cnt) == 1
    down_kill_ix = cnt;
    cnt = cnt - 1;
end
down_kill_ix = down_kill_ix + buffer;
if down_kill_ix > Cols(M)
    down_kill_ix = Cols(M);
end


cnt = 1;
while bad_cols(cnt) == 1
    left_kill_ix = cnt;
    cnt = cnt + 1;
end

left_kill_ix = left_kill_ix - buffer;
if left_kill_ix < 1
    left_kill_ix = 1;
end



cnt = length(bad_cols);
while bad_rows(cnt) == 1
    right_kill_ix = cnt;
    cnt = cnt - 1;
end
right_kill_ix = right_kill_ix + buffer;
if right_kill_ix > Cols(M)
    right_kill_ix = Cols(M);
end





IX = false(Cols(M),1);
IX(1:left_kill_ix) = true;
IX(right_kill_ix:end) = true;

M(:,IX) = [];

IX = false(Rows(M),1);
IX(1:up_kill_ix) = true;
IX(down_kill_ix:end) = true;

M(IX,:) = [];
