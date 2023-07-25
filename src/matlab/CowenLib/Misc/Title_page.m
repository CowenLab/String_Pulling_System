function Title_page(T,T2,T3,T4,T5)
%
% Pass in some text and this program will print it out on a nice title
% page
%
% INPUT: up to 5 separate text strings
%
% OUTPUT: A full page title text. Large font and centered. Each text
% string appears under the previous one.
%
%function Title_page(T,T2,T3,T4,T5)
%

% cowen Sat Jun  5 09:25:21 1999
figure
orient tall
axis off
h = text(.5,1,T);
set(h,'HorizontalAlignment', 'center')
set(h,'FontSize', 34)
if nargin >= 2
  h2 = text(.5,.8,T2);
  set(h2,'FontSize', 34)
  set(h2,'HorizontalAlignment', 'center')
  if nargin >= 3
    h3 = text(.5,.6,T3);
    set(h3,'FontSize', 18)
    set(h3,'HorizontalAlignment', 'center')
    if nargin >= 4
      h4 = text(.5,.4,T4);
      set(h4,'FontSize', 14)
      set(h4,'HorizontalAlignment', 'center')
      if nargin >= 5      
	h5 = text(.5,.2,T5);
	set(h5,'FontSize', 14)
	set(h5,'HorizontalAlignment', 'center')
	if nargin > 5
	  error('Too many lines');
	end
      end
    end
  end    
end
