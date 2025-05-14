import serial
import threading
import time
import random
import tkinter as tk
from itertools import count
import os
from datetime import datetime

import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg


# open a serial connection
serialPico = serial.Serial("COM8", 115200)
serialPico.write("a".encode('utf-8'))  # Send quit command to the serial device

# Get current date and time for file naming
datetime_str = datetime.today().strftime('%Y-%m-%d_%H-%M-%S')
serialPico.write(datetime_str.encode('utf-8')) 
print(datetime_str)

# Command to send
command = "r"

# variables for graph
plt.style.use('fivethirtyeight')
x_vals = []
y_vals = []
index = count()

# Measurment/unit variables
measurment = 0.0
unit = 'g'
new_unit = 'g'

# Recording variables
isRecStarted = False
isRecording = False
fileCnt = 0
filePath = os.path.dirname(__file__) + "/" + datetime_str + "/"
startMillis = int(round(time.time() * 1000))

# Misc variables
latest_serial_value = None
stop_threads = False


def close_window():
    global serialPico
    global file
    global isRecording
    global stop_threads

    print("Closing application...")

    serialPico.write("x".encode('utf-8'))  # Send quit command to the serial device
    stop_threads = True  # Signal the thread to stop
    time.sleep(0.05)     # Give it a moment to exit cleanly

    try:
        if isRecording and file:
            file.close()
    except:
        pass

    try:
        if serialPico.is_open:
            serialPico.close()
    except:
        pass

    plt.close('all')
    root.destroy()

def read_serial_data():
    global latest_serial_value
    global isRecording
    global file
    global stop_threads
    global measurment
    global serialPico

    # Read serial data while window is open and data is available
    while not stop_threads:
        try:
            if serialPico.in_waiting > 0:
                if serialPico.is_open:
                    latest_serial_value = serialPico.readline().decode('utf-8')
                

                if latest_serial_value is not None:
                    data = latest_serial_value.strip()

                    if data == "r":
                        toggle_recording()
                        continue
                    
                    value_str = data.split(",")[-1][:-1]  # Optional: Get measurment value for GUI label
                    
                    # If measurment is not a null, set to default value of 10.0
                    try:
                        measurment = float(value_str)
                    except ValueError:
                        measurment = 10.0  

                    # Record to file is recording is active
                    if isRecording:
                        file.write(f"{data[:-1]},{data[-1:]}\n")
                        

        except Exception as e:
            print(f"Error reading serial data: {e}")
            break  # Exit thread on error


# Create a thread to continuously read serial data in the background
serial_thread = threading.Thread(target=read_serial_data, daemon=True)
serial_thread.start()


# Function to animate the plot
def animate(i):
    global startMillis
    global unit
    global measurment

    measurment_label.config(text=f"{measurment:.2f}")

    x_vals.append(next(index))
    y_vals.append(measurment)

    if len(x_vals) > 100:
        x_vals.pop(0)
        y_vals.pop(0)

        # Dynamically adjust x-axis if needed
        ax1.set_xlim(max(0, x_vals[0]), x_vals[-1])

    # Update the plot line instead of clearing
    line.set_data(x_vals, y_vals)



def toggle_recording():
    global isRecStarted
    global isRecording
    global fileCnt
    global file
    

    isRecording = not isRecording
    print(f"Record {isRecording}")

    
    if isRecording and not isRecStarted:
        isRecStarted = True
        os.mkdir(filePath)

    if isRecording:
        fileCnt += 1
        file = open(filePath + str(fileCnt) + ".csv", "a+")
        recCanvas.itemconfig(recLight, fill='green')
        recState_label.config(text="ON")

    else:
        file.close()
        recCanvas.itemconfig(recLight, fill='red')
        recState_label.config(text="OFF")
        

def recordBtn_click():
    command = "r"
    serialPico.flush()
    serialPico.write(command.encode('utf-8'))
    serialPico.flushInput()

def tareBtn_click():
    print(f"Tare")
    command = "t"
    serialPico.write(command.encode('utf-8'))

def unitBtn_click():
    global unit

    command = "u"
    serialPico.write(command.encode('utf-8'))

    if unit == 'g':
        ax1.set_ylim(-0.01, 0.20)
        unit = 'N'

    elif unit == 'N':
        ax1.set_ylim(-1, 20)
        unit = 'g'

    unit_label.config(text=unit)
    print(f"Unit")



###########            MAIN            ###########

# Create GUI
root = tk.Tk()

# Bind the window close button (the "X" button) to the close_window function
root.protocol("WM_DELETE_WINDOW", close_window)


# Create Frames for bottom portion of gui
# top_frame = tk.Frame(root)
middle_frame = tk.Frame(root)
middle_right_frame = tk.Frame(middle_frame)
bottom_frame = tk.Frame(root)
bottom_left_frame = tk.Frame(bottom_frame)
bottom_right_frame = tk.Frame(bottom_frame)

# Create Title Label 
label = tk.Label(root, text="Force Applied on Load Cell")
label.config(font=("Arial", 30))

# Create Plot
canvas = FigureCanvasTkAgg(plt.gcf(), master=middle_frame)
ax1 = plt.gcf().subplots(1, 1)
line, = ax1.plot([], [], lw=2)
ax1.set_ylim(-1, 20)
ax1.set_xlim(0, 100) 

# Variables used to populate plot
x_vals = []
y_vals = []
index = count()

# Create Label to show current measurment
measurment_label = tk.Label(middle_right_frame, text="0.0", width=4, height=2)
unit_label = tk.Label(middle_right_frame, text=unit)
measurment_label.config(font=("Arial", 36))
unit_label.config(font=("Arial", 36))

# Create three buttons
record_button = tk.Button(bottom_right_frame, text="Record", height=2, width=10, bg= "light steel blue", command=recordBtn_click)
tare_button = tk.Button(bottom_right_frame, text="Tare", height=2, width=10, bg="light steel blue", command=tareBtn_click)
unit_button = tk.Button(bottom_right_frame, text="Unit", height=2, width=10, bg="light steel blue", command=unitBtn_click)

# Create Recording Light 
rec_label = tk.Label(bottom_left_frame, text="Recording")
rec_label.config(font=("Arial", 12))
recState_label = tk.Label(bottom_left_frame, text="OFF")
recState_label.config(font=("Arial", 12))
recCanvas = tk.Canvas(bottom_left_frame, width=100, height=100)

recLight = recCanvas.create_oval(20,40,40,60, fill="red", width=4)


## Layout ##
label.pack() 
middle_frame.pack()
bottom_frame.pack()
canvas.get_tk_widget().pack(side = tk.LEFT, expand = True, fill = tk.BOTH) 
middle_right_frame.pack(side = tk.LEFT, expand = True, fill = tk.BOTH)
bottom_left_frame.pack(side = tk.LEFT, expand = True, fill = tk.BOTH)
bottom_right_frame.pack(side = tk.LEFT, expand = True, fill = tk.BOTH)

# Pack the labels in bottom-right frame
measurment_label.pack(side = tk.LEFT) 
unit_label.pack(side = tk.LEFT) 

# Pack the buttons horizontally in bottom-left frame
tare_button.pack(side = tk.LEFT, expand = True) 
unit_button.pack(side = tk.LEFT, expand = True)
rec_label.pack(side = tk.LEFT, expand = True, fill = tk.BOTH)
recState_label.pack(side = tk.LEFT, expand = True, fill = tk.BOTH) 
recCanvas.pack(side = tk.LEFT, expand = True, fill = tk.BOTH)
record_button.pack(side = tk.LEFT, expand = True) 


# Handles Plot Animation
ani = FuncAnimation(plt.gcf(), animate, interval=100, blit=False, cache_frame_data=False)



tk.mainloop()

