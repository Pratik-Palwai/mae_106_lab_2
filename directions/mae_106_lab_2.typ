#set page(paper: "us-letter", margin: 0.5in, fill: white)
#set text(size: 10pt, fill: black)
#set par(justify: false, leading: 0.72em, spacing: 1.05em)
#set list(marker: [-], spacing: 0.5em, body-indent: 0.4em)
#set enum(spacing: 0.5em, body-indent: 0.4em)
#show list: set block(above: 0.8em, below: 0.8em)
#show enum: set block(above: 0.8em, below: 0.8em)
#show raw.where(block: true): set text(size: 8.5pt)

// Layout helpers with consistent vertical spacing hierarchy
#let sec(num, title, body) = {
    block(above: 1.4em, below: 0.75em, sticky: true)[
        #box(width: 1.4em, align(right, num))
        #h(0.4em)
        #title
    ]
    pad(left: 1.8em, body)
}

#let sub(label, body) = {
    block(above: 0pt, below: 1.05em)[#body]
}

#let cont(body) = {
    block(above: 0pt, below: 1.05em)[#body]
}

#let fig(path, w, caption) = {
    block(above: 0.4em, below: 1.05em, breakable: false, width: 100%)[
        #align(center)[
            #image(path, width: w)
            #v(0.25em)
            #caption
        ]
    ]
}

// Centered Title Block
#align(center)[
    #text(size: 16pt)[MAE106 Lab \#2 - Data acquisition systems and filters]
    #v(0.35em)
    #text(size: 11pt)[
        University of California, Irvine \
        Department of Mechanical and Aerospace Engineering
    ]
]
#v(0.5em)

#sec[1][Goals][
    #sub[a][To learn how to sample an analog sensor signal into a microcontroller, process the data, and generate an output signal; implement both analog and digital filters and understand their applications in robotics and your final project; observe and characterize the dynamic behavior of a first-order linear system; and implement pulse-width modulation (PWM) to control average output voltage.]
]

#sec[2][Parts & equipment][
    #cont[
        #pad(left: -1.8em)[
            #align(center)[
                #table(
                    columns: (auto, auto),
                    stroke: 0.5pt,
                    inset: 4pt,
                    [*Qty*], [*Part/Equipment*],
                    [1], [Oscilloscope],
                    [1], [Breadboard],
                    [2], [10 k$Omega$ Potentiometers],
                    [Various], [Wires],
                    [1], [Multimeter],
                    [1], [ESP32-C3 Super Mini],
                    [1], [USB Type-C to Type-A cable],
                    [1], [USB fuse],
                    [1], [Capacitor],
                )
            ]
        ]
    ]
]

#sec[3][Introduction][
    #sub[a][Electromechanical designs frequently require measuring physical quantities using transducers (such as potentiometers, thermometers, and accelerometers) that convert physical states into electrical voltages. To process these measurements in software and act on them, a microcontroller (here, an ESP32-C3 programmed with the Arduino framework) serves as a compact data acquisition (DAQ) system that converts continuous analog signals into discrete binary representations through analog-to-digital (A/D) conversion.]
    #cont[After processing the digitized measurements, the microcontroller can generate control signals to drive actuators like LEDs or motors via digital-to-analog (D/A) conversion, as illustrated in Figure 1.]
    #fig("figure_1.png", 55%, [Figure 1: Common configuration for a data acquisition (DAQ) system])
]

#sec[4][Safety First][
    #sub[a][Here are some safety rules to follow when working on your experiments:]
    #cont[
        - Double check circuits for proper connections and polarity prior to applying the power. For this lab, power the potentiometers from the 3.3V pin (not 5V), and never turn the filter potentiometer all the way to its zero-resistance end stop!
        - Set test instruments for proper function and range prior to taking a measurement.
        - Never touch circuits where electricity can go from one arm to the other, making a path through your heart.
        - Never place food or drinks near your electronics workspace.
    ]
]

#sec[5][Part 1: Analog Filters and Pulse-Width Modulation (PWM)][
    #sub[a][Real-world sensor readings and actuator commands often require conditioning through signal filters. Filters appear across engineering systems (from audio crossovers and equalizers to automotive and aerospace control loops), where they suppress unwanted noise on sensors like strain gauges, tachometers, and potentiometers. Viewing mechanical assemblies (such as a vehicle's steering system) as frequency filters also helps clarify how physical hardware responds to slow versus rapid inputs.]
    #cont[In this lab, you will investigate the RC circuit, which operates as either a low-pass or high-pass filter. A low-pass filter passes low-frequency content while attenuating high-frequency noise (such as interference from overhead lighting or radio signals); similarly, any object with mass behaves like a mechanical low-pass filter, moving substantially under slow forces while barely displacing under rapid vibrations. Conversely, a high-pass filter suppresses low-frequency drift while preserving fast signal variations, making it useful for removing baseline wander from muscle or brain electrodes.]

    #cont[*First-Order Linear Systems:* An RC network is governed by a first-order ordinary differential equation, making it a classic physical realization of a first-order linear system. Because the same mathematical structure describes a wide variety of electrical, mechanical, thermal, chemical, and biological processes, measuring an RC circuit builds practical intuition for first-order dynamics across engineering domains.]
    #fig("figure_2.png", 50%, [Figure 2: Low-pass RC filter schematic and square-wave response])
    #cont[The circuit in Figure 2 functions as a low-pass filter, attenuating high-frequency components in $V_"in"$ while allowing low frequencies to pass to $V_"out"$. When driven by a square wave, the sharp rising and falling edges contain high-frequency sinusoidal harmonics (via Fourier decomposition). Because the capacitor $C$ must charge and discharge through the resistor $R$, it acts as a charge reservoir that slows rapid voltage transitions. Applying Kirchhoff's voltage and current laws gives the step response:
        $ V_"out" = V_"in" (1 - e^(-t / (R C))) $
        where $tau = R C$ is the system time constant.]

    #cont[*Time Constant:* The time constant $tau$ characterizes how quickly a first-order linear time-invariant (LTI) system responds to a step change. Evaluating the step response at elapsed time $t = tau$ yields:
        $ V_"out" = V_"in" (1 - e^(-1)) approx 0.632 times V_"in" $
        Physically, $tau$ is the time required for a rising step response to reach $1 - 1/e$ (about $63.2\%$) of its asymptotic value, or for a decaying response to fall to $1/e$ (about $36.8\%$) of its starting value. It also determines the filter's cutoff frequency, the threshold beyond which higher frequencies are attenuated:
        $ omega_c = 1 / tau "rad/s", quad f_c = 1 / (2 pi tau) "Hz" $]

    #cont[*Pulse-Width Modulation (PWM):* Standard digital output pins on the ESP32-C3 can only switch between two fixed voltage levels (0V and 3.3V). To generate intermediate effective voltages (such as for dimming an LED or regulating motor speed), microcontrollers use pulse-width modulation (PWM). PWM switches a digital pin ON and OFF at a high frequency over a fixed period $T$, where the ratio of ON duration $t_1$ to total period $T$ defines the duty cycle ($0\%$ is always OFF; $100\%$ is always ON).]
    #fig("figure_3.png", 50%, [Figure 3: PWM timing parameters ($t_1$ pulse duration, $T$ period) and filtered voltage levels across duty cycles])
    #cont[Routing a PWM waveform through a low-pass filter with a sufficiently long time constant averages the pulses into an approximately constant DC voltage proportional to the duty cycle (many electromechanical loads, including DC motors, inherently act as low-pass filters). Plug the ESP32 into the computer through the USB fuse, then assemble the circuit in Figure 4, using one potentiometer to set the analog input voltage on pin 3 (`POTENTIOMETER_PIN`) and the second potentiometer as the adjustable resistor $R$ in the RC low-pass filter driven by the PWM output on pin 4 (`OUTPUT_PIN`).]
    #cont[IMPORTANT: Power the input potentiometer from the ESP32's 3.3V pin, not 5V, since the ESP32-C3 input pins are only rated for 3.3V. Position the filter potentiometer knob near the center of its range before powering the circuit, and never turn it all the way to the zero-resistance end stop (verify with your multimeter's ohmmeter mode). Setting $R = 0$ creates a transient short circuit while the capacitor charges, which can damage the microcontroller.]
    #fig("figure_4.png", 55%, [Figure 4: Breadboard circuit for Part 1 showing PWM generation and RC low-pass filtering])

    #cont[*Code - Part 1:* Before starting, set up VScode, PlatformIO, and the ESP32 by following the instructions in the lab folder's "README.md". All the code for this lab is stored in "src/main.cpp". The `LAB_SECTION` constant at the top of the file chooses which part of the lab runs: set it to `1` for this part, then build and upload the code to the board. In this mode, the `sendPWM` task reads the potentiometer on `POTENTIOMETER_PIN` (12-bit ADC, 0-4095) every $4 "ms"$ and writes a proportional PWM duty cycle (0-255) to `OUTPUT_PIN`. The `serialPrintPart1` task prints the raw potentiometer reading over serial every $10 "ms"$.]

    #cont[*Sampling Rate:* The sampling rate specifies how many discrete measurements per second the microcontroller's A/D converter acquires (e.g., $100 "Hz"$ equals $100$ samples per second). By the Nyquist Sampling Theorem, accurately reconstructing a continuous waveform requires sampling at least twice its highest frequency component (the Nyquist frequency, such as $20 "Hz"$ minimum for a $10 "Hz"$ sine wave), though practical implementations typically sample $10$ to $100$ times faster. Examine the `vTaskDelay` calls in "src/main.cpp" to determine how the $250 "Hz"$ sampling rate is established, and why the serial output runs at a different ($100 "Hz"$) rate.]

    #cont[*Practical Exam \#1:* Build the circuit in Figure 4 and demonstrate to your TA that turning the input potentiometer adjusts the PWM pulse width on oscilloscope CH1 across duty cycles of $90\%$, $50\%$, and $10\%$. Show the filtered output on CH2 and demonstrate how adjusting the filter potentiometer alters the RC time constant, explaining how to measure $tau$ directly from the oscilloscope display. Tune the potentiometer to its maximum resistance (longest time constant and lowest cutoff frequency), vary the duty cycle, and explain how the circuit functions as a D/A converter. Finally, identify where the code sets the sampling and serial output rates, which you will use to convert your report plots' horizontal axis into seconds.]
]

#sec[6][Part 2: Digital filters][
    #sub[a][Like analog filters, digital filters reshape signal characteristics, but they operate in software on discrete samples rather than continuously on physical voltages. Because digital filter parameters are defined in code instead of hardware components, they can be modified immediately without swapping resistors or capacitors, though they require a processor to execute.]
    #cont[A general digital filter calculates the current filtered sample $y_k$ from past filtered outputs ($y_(k-1), y_(k-2), dots$) and current and past unfiltered inputs ($u_k, u_(k-1), u_(k-2), dots$). In this section, you will implement the first-order digital low-pass filter:
        $ y_k = (1 - gamma) u_k + gamma y_(k-1) $
        Wire the circuit in Figure 5 (potentiometer powered from 3.3V, wiper to pin 3) so that rotating the potentiometer adjusts the filter gain $gamma$ in real time while filtering an internally generated square wave. The square wave is also driven on pin 4, so you can view it on the oscilloscope.]
    #fig("figure_5.png", 45%, [Figure 5: Potentiometer circuit for Part 2 digital filter control])

    #cont[*Code - Part 2:* Set `LAB_SECTION` to `2` in "src/main.cpp", then build and upload the code to the board as before. In this mode, three FreeRTOS tasks run:
        - `sendSquareWave` toggles `square_wave_state` (and `OUTPUT_PIN`) every $100 "ms"$, producing a $5 "Hz"$ square wave.
        - `filterData` reads the potentiometer every $2 "ms"$ as a normalized filter strength $gamma$ between $0$ and $1$ (`potentiometer_val`), and passes the square wave through `averagingFilter`.
        - `serialPrintPart2` prints `square_wave_state`, `potentiometer_val`, and `filtered_signal` over serial every $4 "ms"$.
    ]

    #cont[*Practical Exam \#2:* Run the Part 2 code to generate an internal square wave and digitally filter it while adjusting the potentiometer. Capture both the unfiltered and filtered signals over serial (plot them live with the Serial Plotter extension described in "README.md", or copy the values into Excel or another graphing program), explain the observed behavior to your TA, and point out the exact line of code implementing the digital filter equation.]
    #cont[Note: If the Serial Monitor prints garbled characters or symbols, check for a baud-rate mismatch. The baud rate of the Serial Monitor or Serial Plotter must match the value in `Serial.begin(...)`; this project's "platformio.ini" sets it to 115200.]
]

#sec[7][Lab Report][
    #cont[
        1. Plot both the unfiltered and filtered signals from Part 2 on the same axes, converting the horizontal axis from sample index to elapsed time in seconds (Part 2 prints one sample every $4 "ms"$) and clearly labeling all axes and curves.
        2. Annotate and label the measured time constant $tau$ directly on the plot.
        3. Over a single square-wave cycle on the same graph, plot the analytical prediction derived from the solution to the first-order differential equation (do not use the discrete filter recurrence equation) using your estimated time constant from step 2, and label the plot with the equations for both the rising (ON) and falling (OFF) phases.
        4. Briefly explain how you could apply a low-pass filter in your final project (identifying which sensor is likely to be noisiest) and state whether an analog or digital filter would be preferable.
    ]
]

#sec[8][Checklist for report plots][
    #sub[a][Each student must submit an individual report prior to the start of the next lab session. All figures included in your report must meet the following standards:]
    #cont[
        - Include a descriptive title summarizing the data displayed.
        - Label both axes with physical quantities, appropriate scaling prefixes, and units (e.g., $1.2 mu"s"$ or $1.2 times 10^(-6) "s"$ rather than $0.0000012 "s"$).
        - Configure axis limits for clear visualization without clipping waveform peaks or leaving excessive empty margins.
        - Include a legend whenever two or more datasets appear on the same plot.
        - Use high-contrast, easy-to-read colors on a white background (avoid dark backgrounds or bright fluorescent markers).
        - Consult the sample plots on Canvas for formatting best practices.
    ]
]
