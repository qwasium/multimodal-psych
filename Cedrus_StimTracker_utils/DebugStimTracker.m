%% test and tuning script for Cedrus StimTracker
% @author: Simon Kuwahara
% GNU/Octave 6.4.0
% Ubuntu 22.04
% UTF-8
% Dell S2319HS 1920*1080 60Hz
% -------------------------------------------------------------------------
% 
% 
% -------------------------------------------------------------------------
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
Screen('Preference', 'SyncTestSettings', 0.002); % remove in production environment
dummyMode = true;


%% detect StimTracker and open serial port %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~dummyMode
    
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

end

%% PTB Parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
scr   = max(Screen('Screens')); % select screen here
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
    [wptr, wRect] = PsychImaging('OpenWindow', scr, bgClr);

    % initial settings
    Priority(1);
    hz = Screen('NominalFrameRate', wptr, 1);
    Screen('BlendFunction', wptr, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    [xCntr, yCntr] = RectCenter(wRect);
    ListenChar(2);

    %% Start Task %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

    exitLoop = false;

%     DrawFormattedText(wptr, 'press any key to start', 'center', 'center', bkClr);
    

    flipT = Screen('flip', wptr);

    while 1
        [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();
        keyCode = find(keyCode, 1);
        if keyIsDown == 1         
            if keyCode == KbName('ESCAPE')
                break;
            end

        end % keyIsDown
    end % loop
    ListenChar(0);
    sca

catch me    
    sca
    ListenChar(0);
    rethrow(me)

end
sca
clear device