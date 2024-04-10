clc, clear, close all

x = [0, 10, 200, 255];
y = [0, 100, 150, 255];
plot(x,y,'b');
title('Theory Question for 2a')
xlim([0 255]); xlabel('Input')
ylim([0 255]); ylabel('Output')
saveas(gcf(), '2d_graph.jpg', 'jpg');