function [c] = tree_classify(s,t,g);
tree = treefit(t, g, 'method', 'classification' );
[c,dtnode] = treeval(tree, s);
