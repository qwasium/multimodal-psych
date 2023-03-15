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

clear all
clear device
commandwindow
homeDir = fileparts(mfilename('fullpath'));
sca
PsychDefaultSetup(2);
% Screen('Preference', 'SyncTestSettings', 0.002); %only when noisy


%% detect StimTracker and open serial port %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% parameters
device_found = 0;
ports = serialportlist("available");

% search serial ports
for p = 1:length(ports)

    device = serialport(ports(p),115200,"Timeout",1);
    device.flush()
    write(device,"_c1","char")
    query_return = read(device,5,"char");

    % Cedrus device detected
    if ~isempty(query_return) && query_return == "_xid0"
        device_found = 1;
        break
    end
end

% Cedrus devices undetected
if device_found == 0
    disp("No XID device found. Exiting.")
    return % exit script
end

%% まずはじめに設定："mp"コマンドを使ってTTLパルスの持続時間を設定
% 
% 後述の"mh"コマンドを使って指定したチャンネルでTTLトリガーを出力するが、その際は以下の
% "mp"コマンドで設定する持続時間（今回の場合1000ms）が適用される。
% 
% "mp" + "持続時間"
% 
% ・持続時間：パルス持続時間（ミリ秒）、デフォルト値=0(持続時間無限)、4バイト、リトルエンディアン
% 
% TTLパルスのデフォルト持続時間を1秒に設定するコマンドは十六進数・ASCIIに変換すると以
% 下のようになる。※これらは数値としては全て同じである。
% 
% 【注意】バイトオーダーはリトルエンディアンなので逆順になる（わからなければ必ずググれ）
% 
%  m    p            1000
% 0x6D 0x70   0xE8 0x03 0x00 0x00   <- hex
% 109  112    232   3    0    0     <- ASCII

write(device, [0x6D, 0x70, 0xE8, 0x03, 0x00, 0x00], "uint8"); 

% write(device,sprintf("mp%c%c%c%c", 232, 3, 0, 0), "char");



%% "mh"コマンドをつかってUSB経由で指定チャンネルでTTLトリガーを送信する 
% 今回のUSBによるTTLトリガーの送信は全て"mh"コマンドを使用するのでここで説明しておく。
% 
% "mh" + "チャンネル"
% 
% ・チャンネル：長さ2バイト、8チャンネルの各ビットにつき1=Hi/0=Lo、StimTrackerの場合
% は8チャンネルのみなので全16桁のうち上8桁は無視、リトルエンディアン
% 
% 上の"mp"コマンドで指定した持続時間のTTLパルスを送信できる。
% 例えば、チャンネル1,2,3(USB0,1,2)のみ送信する場合は以下のようになる。
%
% 【注意】チャンネルのビット順は逆になるのでch8,ch7,...,ch2,ch1の順番で2進数で表記する。
% 
%  m    h     0b00000111
% 0x6D 0x68   0x07 0x00     <- hex
% 109  104     7    0       <- ASCII
% 
% write(device, [0x6D, 0x68, 0xE0, 0x00], "uint8"); %input by hex
%  または
% write(device,sprintf("mh%c%c", 7, 0), "char"); %input by ASCII
% 
% 末尾のコメントにチャンネルのビット指定の例をいくつか載せているので参考に。
% 
% 初期設定時に全てのチャンネルをLoに落としておくと癖をつけておくと良い
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

    Screen('gluDisk', wptr, bkClr, litSenX, litSenY, litDiam); %light sensor(ch8) Lo
    flipT = Screen('Flip', wptr);
    write(device,sprintf("mh%c%c", 1, 0), "char"); %USB0(ch1)
    
    for i = 1:3
    
        % 注視点表示
        Screen('gluDisk', wptr, bkClr, litSenX, litSenY, litDiam); %light sensor(ch8) Lo
        Screen('DrawTexture', wptr, fixTex, [], fixPos, [],0); %fixation cross
        flipT = Screen('Flip', wptr, flipT+swchT-0.5/hz);
        
        % 視覚刺激提示開始
        Screen('gluDisk', wptr, whClr, litSenX, litSenY, litDiam); %light sensor(ch8) Hi
        DrawFormattedText(wptr, stimTxt, 'center', 'center', stimClr); %visual stimulus
        flipT = Screen('Flip', wptr, flipT+fixT-0.5/hz);
        write(device,sprintf("mh%c%c", 2, 0), "char"); %USB1(ch2)

        % litT < stimT の場合は、litT秒後にライトセンサーの出力だけを落として、それ以外は全く同じ刺激を提示する
        Screen('gluDisk', wptr, bkClr, litSenX, litSenY, litDiam); %light sensor(ch8) Lo
        DrawFormattedText(wptr, stimTxt, 'center', 'center', stimClr); %全く同じ視覚刺激をレンダリング
        Screen('Flip', wptr, flipT+litT-0.5/hz); %刺激提示時間がstimTとなるようにflipTにflip時刻を記録しない

        % 視覚刺激提示終了
        Screen('gluDisk', wptr, bkClr, litSenX, litSenY, litDiam); %light sensor(ch8) Lo
        flipT = Screen('Flip', wptr, flipT+stimT-0.5/hz);
    
    end
    write(device,sprintf("mh%c%c", 4, 0), "char"); %USB2(ch3)
    WaitSecs(2); % 初回呼び出しは時間精度低い
    sca

catch me    
    sca
    ListenChar(0);
    rethrow(me)

end
sca
clear device



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 【参考】チャンネルの指定は2進数で考える
% 
% 上述の通り、チャンネルは2進数でch8,ch7,...,ch2,ch1の順番で指定する。
% 
% 【例】
% USB0 (ch.1)のみ
% 0b000000001
% 0x01 0x00    <- hex
%  1    0      <- ASCII
% 
% USB1 (ch.2)のみ
% 0b00000010
% 0x02 0x00    <- hex
%  2    0      <- ASCII
% 
% USB1 (ch.2) && USB2 (ch.3) 
% 0b00000110
% 0x06 0x00    <- hex
%  6    0      <- ASCII
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 【参考】"mx"コマンドでUSB経由で任意のTTL出力をする方法
% 
% USB経由で任意のチャンネルをHiまたはLoにするには上のようにシリアルポートのアドレスを特
% 定したうえでそのポートに以下のようにASCII文字列をリトルエンディアンで送信する。
% 
% "mx" + "持続時間" + "チャンネル" + "パルスの回数" + "パルス間隔"
% 
% ・持続時間：2バイトのパラメーター。"0"でLo、"0xFFFF"でHi、他は任意の数字を指定する
% ことでミリ秒単位でTTLのパルスの長さを指定する。
% 
% ・チャンネル：2バイトのパラメーター。"1"で指定したビットのチャンネルにコマンドが適用
% され、"0"で指定したビットのチャンネルは無視される。
% 
% ・パルスの回数：1バイトのパラメーター。TTL出力の際のパルスの回数を指定する。持続時間
% が"0"または"0xFFFF"の場合は無視される。
% 
% ・パルス間隔：2バイトのパラメーター。パルス間の間隔。パルスの回数が2未満の場合は無視さ
% れる。
% 
% 詳細は公式サポートページを参照。この他にもたくさんのコマンドが載っている。
% https://www.cedrus.com/support/xid/commands.htm
% 
% 例えば、USB 0,1,2で1秒間のパルスを一回だけ出力する場合は以下の文字列を送信する。
%  m    x    ,    1000   , 0b00000111  ,  1    ,     0
% 0x6D 0x78    0xE8 0x03    0x07 0x00    0x01    0x00 0x00  <-hex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%