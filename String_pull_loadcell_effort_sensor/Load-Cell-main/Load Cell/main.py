from hx711.hx711_pio import HX711
from machine import Pin
import math
import time
import utime
import select
import sys
import sdcard
import uos

startTimeMs = time.ticks_ms()

# Assign chip select (CS) pin (and start it high)
cs = machine.Pin(13, machine.Pin.OUT)

# Intialize SPI peripheral (start with 1 MHz)
spi = machine.SPI(1,
                  baudrate=1000000,
                  polarity=0,
                  phase=0,
                  bits=8,
                  firstbit=machine.SPI.MSB,
                  sck=machine.Pin(10),
                  mosi=machine.Pin(11),
                  miso=machine.Pin(12))


# Initialize SD card
try:
    sd = sdcard.SDCard(spi, cs)
    isSDconnected = True
except Exception as e:
    print("SD card not found or failed to initialize:", e)
    isSDconnected = False

# Mount filesystem
if isSDconnected:
    vfs = uos.VfsFat(sd)
    uos.mount(vfs, "/sd")



# Create an instance of a polling object 
poll_obj = select.poll()
# Register sys.stdin (standard input) for monitoring read events with priority 1
poll_obj.register(sys.stdin,1)
   


###  Load Cell Variables  ###
pin_OUT = Pin(15, Pin.IN, pull=Pin.PULL_DOWN)
pin_SCK = Pin(14, Pin.OUT)
hx711 = HX711(pin_SCK, pin_OUT, state_machine=0)
value = 0


# Record Button Variables
isRecording = False
fileCnt = 0
fileName = "/sd/" + str(datetime) + "/" + str(fileCnt)
file = None


#Get the current time
current_time = utime.localtime()

#Format the current time as "dd/mm/yyyy HH:MM"
datetime = "{}-{:02d}-{:02d}_{:02d}-{:02d}-{:02d}".format(current_time[0], current_time[1], current_time[2], current_time[3], current_time[4], current_time[5])
print(datetime)

    
def toggleRec():
    global ledState
    global isRecording
    global fileCnt
    global file
    global datetime
    
    # Flip Recording state
    isRecording = not isRecording
    
    # Check if recording is active, and if SC card is plugged in
    if (isRecording and isSDconnected):
        fileCnt = fileCnt + 1
        fileName = "/sd/" + str(datetime) + "/" + str(fileCnt)
        file = open(str(fileName) + ".csv","a")
        print("Start Recording GUI " + str(fileCnt))
    
    elif (isRecording and isSDconnected == False):
        print("Start Recording GUI " + str(fileCnt))
        
    elif (isRecording == False and isSDconnected):
        file.close()
        print("Stop Recording GUI " + str(fileCnt))
    
    elif (isRecording == False and isSDconnected == False):
        print("Stop Recording GUI " + str(fileCnt))
    


def main():
    unit = 'g'
    isAcquiring = False
    
    # Load Cell Local Variables
    tareVal = 0
    resolution = 1
    
    # Record Button Global Variables
    global isRecordingstartTimeMs
    global ledState
    global file
    global datetime
    

    # Initial Tare
    hx711.tare()
    tareVal = hx711.read()
    

    # MAIN Loop
    while(True):
        valueSum = 0
        valueAvg = 0
        
    ### Get Commands From GUI ###
        if poll_obj.poll(0):
            
            # Read one character from sys.stdin
            command = sys.stdin.read(1)
            command = command.strip()
            print(command)  # Used as a confirmation response to GUI commands
            
            if command:
                if command == "r":  # Record
                    toggleRec()
                        
                elif command == "t":  # Tare
                    hx711.tare()
                    tareVal = hx711.read()
                    
                elif command == "u":   # Unit
                    
                    if unit == 'g':
                        unit = 'N'
                        
                    elif unit == 'N':
                        unit = 'g'
                        
                elif command == "a":   # Acquire
                    isAcquiring = True
                    
                    while poll_obj.poll(0) == 0:
                        continue
                        
                    datetime = sys.stdin.read(19)
                    datetime = datetime.strip()
                    print(datetime)
                    
                    # Make new folder with every acwuisition comand
                    if isSDconnected:
                        uos.mkdir("/sd/" + datetime)
                    
                elif command == "x":      # Quit
                    isAcquiring = False
            
        
        if isAcquiring:
            
            ### Fing Average for resolution window; Used for data smoothing ###
            for i in range(resolution):
                valueRaw = 0
                valueRaw = hx711.read()
                valueSum = valueSum + valueRaw
                 
            valueAvg = valueSum / resolution
            value = (valueAvg - tareVal)/27000

            # Determine which unit is being used and convert value accordingly
            if unit == 'N':
                value = value * 0.00981
             
            timeMs = time.ticks_ms() - startTimeMs
            
            ### Format and Print ###
            value = math.floor(value*100000)/100000
            print('{},{}{}'.format(timeMs, value, unit))
        
            
            ### Write to File if recording  ###
            if (isRecording == True and isSDconnected):
                file.write(str(timeMs)+","+str(value)+","+str(unit)+"\n")


try:
    main()
except KeyboardInterrupt:
    print("Exiting...")

        
