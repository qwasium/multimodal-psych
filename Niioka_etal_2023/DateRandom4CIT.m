function [Randomized_Order]=DateRandom4CIT
% hŒƒ’æ¦‰ñ”‚ª‚T‰ñ‚Ìê‡‚ÌhŒƒ’æ¦‡˜‚Ìƒ‰ƒ“ƒ_ƒ€‰»
% ‚¢‚¸‚êudisp_repv‚ÉŠî‚Ã‚¢‚Ä‰ü—Ç

item_num = 5;
disp_rep = 5;
%  tic
seed1=datestr(now,'MMSS');
seed2=str2num(seed1);
%seed2=5959

a1=Shuffle(1:1:item_num); 
a2=Shuffle(1:1:item_num); 
a3=Shuffle(1:1:item_num); 
a4=Shuffle(1:1:item_num); 
a5=Shuffle(1:1:item_num); 


% tic
for i=1:1:seed2
    b1(i,:)=Shuffle(a1);
    b2(i,:)=Shuffle(a2);
    b3(i,:)=Shuffle(a3);
    b4(i,:)=Shuffle(a4);
    b5(i,:)=Shuffle(a5);
%  i
end
% toc
a1=b1(i,:);a2=b2(i,:);a3=b3(i,:);
a4=b4(i,:);a5=b5(i,:);

Randomized_Order = [a1;a2;a3;a4;a5];
%  toc;
 
end
