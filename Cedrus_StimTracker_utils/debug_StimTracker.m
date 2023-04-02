%% test and tuning script for Cedrus StimTracker
% @author: Simon Kuwahara
% MATLAB R2022a
% Ubuntu 22.04
% UTF-8
% Dell S2319HS 1920*1080 60Hz
% -------------------------------------------------------------------------
% 
% 
% -------------------------------------------------------------------------
% comments are in Japanese. If broken, open in Japanese language environment.
% 
% **dependencies**
% MATLAB R2019b or later.
% Requires Psychtoolbox 3.
% 
%
% 
%% このデモコードの内容
% 
% 
% USB bit0 :       channel 1
% USB bit1 :       channel 2
% USB bit2 :       channel 3
% Light Sensor 1 : channel 8
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all %#ok<CLALL> 
clear device
commandwindow
homeDir = fileparts(mfilename('fullpath'));
sca
PsychDefaultSetup(2);
% Screen('Preference', 'SyncTestSettings', 0.002); %only when noisy


%% detect StimTracker and open serial port %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% parameters
deviceFound = 0;
boudRate    = 115200;
ports       = serialportlist("available");

% search serial ports
for p = 1:length(ports)

    device = serialport(ports(p),boudRate,"Timeout",1);
    device.flush()
    write(device,"_c1","char")
    queryReturn = read(device,5,"char");

    % Cedrus device detected
    if ~isempty(queryReturn) && queryReturn == "_xid0"
        deviceFound = 1;
        break
    end
end

% Cedrus devices undetected
if deviceFound == 0
    disp("No XID device found. Exiting.")
    return % exit script
end

write(device,sprintf("mp%c%c%c%c", 232, 3, 0, 0), "char"); % mp1000
write(device, [0x6D, 0x68, 0x00, 0x00], "uint8"); % lower all lines


%% PTB Parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
scr   = max(Screen('Screens')); % 環境依存
bkClr = BlackIndex(scr);
whClr = WhiteIndex(scr);

% light sensor parameters 環境依存　モニターにあわせてパラメーターを調整する
litSenX = 15;  %発光位置X
litSenY = 15;  %発光位置Y
litDiam = 10;  %発光範囲直径
litT    = 2.0; %発光時間秒

% task parameters
bgClr   = (bkClr+whClr)/2; % bg:background
fixClr  = bkClr;
stimClr = bkClr;
swchT   = 0.5;
stimT   = 5.0;
stimTxt = 'STIM ON';


try

    %% open window %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    [wptr, wRect] = PsychImaging('OpenWindow', scr, bgClr); % 環境依存

    % initial settings
    Priority(1);
    hz = Screen('NominalFrameRate', wptr, 1);
    Screen('BlendFunction', wptr, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    [xCntr, yCntr] = RectCenter(wRect);


    %% Start Task %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

    exitLoop = false;
    While ~exitLoop
        
        if key == esc
            exitLoop = true;
        end
    
    sca

catch me    
    sca
    ListenChar(0);
    rethrow(me)

end
sca
clear device