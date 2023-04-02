# multimodal-psych

# DRAFT; still in writing

Fundamentals of system design in multimodal physiological measurements.

Mar. 15, 2023 Simon Kuwahara

---

Please cite the following paper:


```

TODO: change reference

Niioka, K., Uga, M., Nagata, T., Tokuda, T., Dan, I., & Ochi, K. (2018).Cerebral hemodynamic response during concealment of information about a mock crime: Application of a general linear model with an adaptive hemodynamic response function. Japanese Psychological Research, 60(4), 311-326.

```

@article{niioka2018cerebral,  
  title={Cerebral hemodynamic response during concealment of information about a mock crime: Application of a general linear model with an adaptive hemodynamic response function},  
  author={Niioka, Kiyomitsu and Uga, Minako and Nagata,   Taihei and Tokuda, Tatsuya and Dan, Ippeita and Ochi, Keita},  
  journal={Japanese Psychological Research},  
  volume={60},  
  number={4},  
  pages={311--326},  
  year={2018},  
  publisher={Wiley Online Library}
}

---

## Contents

- ./Cedrus_StimTracker_utils
  - ./C/debug_StimTracker.m : PTB utility for settig up/debugging Cedrus Stim Tracker with Psychtoolbox3.
  - ./C/readme_StimTracker.m : Demonstration code for first time users of Cedrus Stim Tracker with Psychtoolbox3.
- ./img : Images for README.md
- ./Niioka_etal_2023
  - ./N/CIT_FINAL_V2.m : Raw experiment code for the CIT paper. Note: Dirty code but left as is.
  - ./N/DateRandom4CIT.m : Function used in CIT_FINAL_V2.m. Note: function name and file name does not match.

## Guide for multimodal physiological measurements

In this README, we will focus on replicating or designing a new multimodal psychological measurement setup.  
We will first discuss general ideas of multimodal physiological measurements.  
Then, we will dive deeper into the details of how we combined fNIRS(ETG-4000) and psychopysiplogical measurement device(Polymate V AP5148).

## Prerequisite Knowledge

There are some good-to-knows before you actually setup a multimodal measurement.

- Basics of computer sciense.
  - Basic computer architechture.
  - Basic software engineering.
  - Basic programming.
  - Basic Linux.
  - How a computer monitor work(scanlines, interlacing, etc.).
    - CRT
    - Plasma
    - LCD(TN/VA/IPS)
    - OLED
  - Common comuputer bus types(physical connectors and communication protocols). For example...
    - USB
    - Display Port
    - HDMI
    - VGA
    - DVI
    - RS-232C(serial port)
    - IEEE 1284(parallel port)
    - D-Subminiature
    - RJ-45
    - PCI express

- Very, very basic knowledge of elecronics.
  - Ohm's law.
  - Basic knowledge like GND, co-ax cables, AC/DC, battery types, power connectors, etc.
  - How to use a multimeter.
  - How to use a soldering iron.

- Basics of data acquisition(DAQ).
  - NI has a great video. Check it out.  
  [https://www.ni.com/ja-jp/shop/data-acquisition/sensor-fundamentals--data-acquisition-basics-and-terminology.html](https://www.ni.com/ja-jp/shop/data-acquisition/sensor-fundamentals--data-acquisition-basics-and-terminology.html)

If you're familiar with these topics, great!  
But for anyone who's not a tech-savvy nerd, playing around with a single board computer like a Raspberry-Pi or an Arduino is highly recomended.  
They share many key concepts with multimodal psychological experiment setups and troubleshooting problems are usually just a quick google search.

## Basic Hardware Setup in Psychological Experiments

Most of psychological experiments are based on the Stimulus-Organism-Response(S-O-R) model.

![S-O-R model](img/sor.png)

The physical setups for them can be devied into three parts; "Stimulus", "Organism" and "Response".  
Since "Organism" will be our participant, our system would consist of the "Stimulus" component and the "Response" coponent.

![S-O-R model with input/output](img/sor_io.png)

The "Stimulus" component would be our computer running stimulus presentation software like Psychtoolbox3.

The "Response" component would be any measurement system like fNIRS, eye trackers etc.

If these two are independent, we need time synchronization between all components in oder to do any analysis related to the time domain. For example, the most basic measure of them would be reaction time.

![S-O-R model with sync](img/sor_sync.png)

There are multiple ways to achieve synchronization but in psychological measurements, it will be convenient to set the stimulus component as the "master clock".

![Stimulus presentation is master clock](img/stim_master.png)

In the logged data in each measurement system, there would be a variable that records the sync signal.  
If we compare the sync signal and find corresponding rows, we could connect the data using the sync signal as the key.  

![connect hypothetical data using sync signal](img/sync_data.png)

When actually designing a measurement setup, we must consider the degree of system integration for each measurement device. We can categorize them into three levels. Note that this is just a general discription and details could vary depending on the specific system.

1. Systems that have no i/o that can connect to the stimulus presentation computer. These are not designed to be connected to computers and the measured values are usually designed to be read visually. These are pretty much useless and you will not see them in devices that specialize in psychological measurement.  
example: regular mercury/alcohol thermometer
2. Systems that equip one-way receive only standard i/o for synchronization signals. These will be the most common type you will see and will often have a connector for TTL or RS-232C. We will discuss these protocols in the next chapter.  
example: fNIRS and majority of psychophysiological measurement systems
3. Systems that are highly integrated and could "talk" with the stimulus presentation computer. These are capable to expand beyond the S-O-R model. These can give the stimulus presentation computer instant direct feedback and quickly change the stimulus according to the parrticipant's response.  
example: keyboard, mouse and majority of eye trackers

![combining systems with different levels of integration](img/integration_level.png)

## Common Protocols for Synchronization Signals

We will focus our discussion on combining measurement systems in level 2 mentioned above, "Stimulus" to "Response" one-way sync signal connection.  
For the old folks, this is all common knowledge, but it seems that's not the case for the younger crowd.  
This is understandable because any information regarding synchronization is poorly documented and you're not finding that in the psychology field in the first place.

There are two common protocols used for sync signals in physiological measurements.

- TTL
- RS-232C

Here is a comparison of these two protocols.

|| TTL | RS-232C |
|---|---|---|
| related standards | IEEE 1284 | EIA/TIA-232 |
| tx voltage mark(1) | 2.4 ~ 5V | 5 ~ 15V |
| tx voltage space(0) | 0 ~ 0.4V | -5 ~ -15V |
| rx voltage mark(1) | 2 ~ 5V | 3 ~ 15V |
| rx voltage space(0) | 0 ~ 0.8V | -3 ~ -15V |
| common connectors | DB25, BNC, RJ45 | DB9, RJ45, DB15, DB25, USB |
| voltage domain | digital | digital |
| time domain | analog | digital |
| latency | low | high |
| signal | binary(ON or OFF) | ASCII character |

### TTL

TTL is the most simple form of communication; just connect a line and apply a voltage. The line is considered high(1) when there's a volatage applied, and considered low(0) when 0V.

The term "high" and "low" have synonyms.  
They all mean the binary states of a line.

- hi/lo
- mark/space(from the punched tape era)
- on/off
- 1/0
- pull up/pull down

![TTL voltage](./img/ttl.png)

Most devices are either 3.3V or 5V.  
The voltage usually don't matter as long as we're operating in the standard voltage range, but we have seen cases where the receiving end prefers 5V for some reason.  
**Always check the manufacturer's documentation.**  
TTL is so simple that DIY solutions can be easily implemented.
If going DIY, remember to be conservative in what you send and liberal in what you accept.

TTL can only send a binary signal per line(1bit/ch), so we usually use multiple lines.
The max. # of lines or channels depends on the specific system but there are usually 8 channels(8bits=1byte) as parallel port has 8 ch.

![using 3 ch. of TTL](img/ttl_3ch.png)

TTL could be sent via parallel port.  
Many modern motherboards lack not only the connector but even the header pins so a PCI-e adapters would be an option if that's the case.  
Unfortunately, there is no just-works solution when it comes to controlling the parallel port.  
Also, specialized USB adapters are becoming more and more common.  
The PTB GitHub wiki has great information.
[https://github.com/Psychtoolbox-3/Psychtoolbox-3/wiki/FAQ#ttl-triggers](https://github.com/Psychtoolbox-3/Psychtoolbox-3/wiki/FAQ#ttl-triggers)

![parallel port](img/parallel_port.png)

If you're dealing with visual stimuli, it is better to send TTL signal directly from the computer monitor rather than the stimulus presentation computer.  
This is because computer monitors can't light up instantly and will always have "lag".

![computer monitors have lag](img/display_lag.png)

We can use a photo diode or devices with light sensor input such as the Cedrus StimTracker.  
By attaching the light sensor directly to the computer monitor and  controling the color of the display output under the light sensor using the stimulus presentation software, we can send TTL at the exact moment when the visual stimulus gets presented.

![light sensor](img/litesensor.png)

Due to how computer monitors work, it is ideal to place the light sensor at the same height as the visual stimulus.  
The lower the refresh rate, this will have a larger effect.

| refresh rate | milliseconds per frame |
|-|-|
| 60Hz | 16.66... |
| 120Hz | 8.333... |
| 144Hz | 6.944... |
| 240Hz | 4.166... |
| 360Hz | 2.777... |

If you're not familiar with how computer monitors work, check out this awesome video on YouTube where they shot footage of a computer monitor working using a high-speed camera.  
[https://youtu.be/3BJU2drrtCM](https://youtu.be/3BJU2drrtCM)

![placement of light sensor](img/sensor_position.png)

#### Blessing from the gaming industry

LCD displays used to have noticable latency but thanks to the rise of the gaming industry, modern gaming displays have become extremely fast both in latency and refresh rate. Plus, most even have decent color accuracy.  
As of Mar.2023 the fastest available monitors have a refresh rate of 500Hz and a GTG(gray-to-gray)response time of 0.5ms.  
(We do NOT recommend bleeding edge technology unless you really need it.)

On the other hand, OLED has drastically improved in the recent years.  
OLED has more suitable characteristics overall compared to LCD and might become mainstream in psychological experiments in the very near future.  
Computer monitor technology is rapidly evolving and the need for light sensors might even change in the near future.  
**Know your equipment and requirements!**

Behaviorial responses could also be measured using TTL.  
By connecting a 3.3V or 5V power source and a switch, we can send TTL when the participant presses on the switch.  
(Note that you will need to cosider switch bounce/contact bounce unless you are using an optical switch.)  

Though this was one solution for the horrible time accuracy of conventional keyboards, we rarely use TTL for behaviorial measures unless we have a claer objective.  
Thanks to the gaming industry, our lives became much easier.  
Modern high-end gaming keyboards with high poling rates have the same or even better time accuracy compared to specialized behaviorial response measurement devices.

### RS-232C

Since RS-232C is still commonly used in a wide variety of industries, many industrial and networking equipment relies on a serial console.  
It is so common that it's highly likely that you yourself or someone around you is regularly using RS-232C.  
We will only focus on the very basics for the unacquanted for now.  
If you're interested, you can find information fairly easily with just a quick Google search.

RS-232C is the most simple form fo serial communication.  
When using TTL we could only send 1bit of data per channel at a given point of time.  
If we set a cycling frequency(Baud rate), we can send a burst of bits at once on a single line.

![set clock](img/serial.png)

If we predefine the meaning for the sequence of 1s and 0s, i.e. like ASCII, we can send meaningful information only using a single line.

![sending ASCII](img/send_ascii.png)

Most programming languages have functions for RS-232C and USB or PCI-e adapters for serial ports are widely available for modern computers.  
It will most likely work out-of-the-box compared to parallel port.

![serial port](img/serial_port.png)

Since RS-232C requires time duration and more processing than TTL, there will be always be a larger delay compared to TTL.  
Use RS-232C when time accuracy is not critical or use it in conjunction with TTL.  
Time accuracy will improve if you code in C++ and wrap it in Matlab, Python, etc.

## The Setup in the Paper

Below is a list of the main components of this experiment setup.

| | |
|---|---|
| stimulus presentation | Psychtoolbox 3 on Win10 (i7-10510U 24G) |
| display | Dell S2319HS (1920*1080 60Hz GTG5ms) |
| sync signal control | Cedrus StimTracker Quad gen2 |
| fNIRS | Hitachi ETG-4000 |
| physiological measurements | Miyuki Polymate V AP5148 |

Disclaimer: **Running PTB on Windows is a BAD idea! Use Linux!**

The sync signal was controlled by the StimTracker.

![overview of experiment setup](img/experiment_setup.png)

### Stimulus presentation computer to StimTracker

The stimulus presentation computer and StimTracker was connected with serial over USB.

Cedrus XID commands were sent via serial.  
The StimTracker will convert the XID commands to TTL signals.  
The TTL duration for each XID command call was set to 1 sec.
Details are explained in /Cedrus_StimTracker_utils/readme_StimTracker.m.  
Raw source code is /Niioka_etal_2023/CIT_FINAL_V2.m.

| sent information | USB ch. | TTL ch. |
|---|---|---|
| Start of experiment | USB0 | ch.1 |
| End of experiment | USB1 | ch.2 |

### Display to StimTracker

A light sensor was attached to the top-left of the display and sent TTL signal whenever the screen under the light sensor was lit white.  
The light sensor was attached to the top-left because it was important to have less visual distractions rather than exact time accuracy in this experiment.  
From the officially stated specs of the monitor, the delay is estimated to be about 13~15ms.

In PTB, We used the ```Screen('gluDisk',...)``` function and adjusted the position and diameter so either a black or white circle will be rendered under the light sensor for all of the frames.  
Details are explained in /Cedrus_StimTracker_utils/readme_StimTracker.m.  
Raw source code is /Niioka_etal_2023/CIT_FINAL_V2.m.

| sent information | TTL ch. |
|---|---|
| stimulus onset | ch.8 |

### StimTracker to measurement systems

TTL is sent from the DIN connector behind the StimTracker.  
The pin-out can be found in Cedrus's official support page.  
[https://cedrus.com/support/stimtracker/tn1960_quad_ttl_output.htm](https://cedrus.com/support/stimtracker/tn1960_quad_ttl_output.htm)  

We made a custom cable with a DIN connector and a D-sub 9 pin connector on each side.  
Then, we split the lines using an old D-sub 9-pin to BNC adapter box.
