// Device Code
#require "APDS9007.class.nut:2.2.1"
#require "LPS25H.class.nut:2.0.1"
#require "Si702x.class.nut:1.0.0"

// Establish a global variable to hold environmental data
data <- {};
data.temp <- 0;
data.humid <- 0;
data.batterylife <- 0;

// Instance the Si702x and save a reference in tempHumidSensor
hardware.i2c89.configure(CLOCK_SPEED_400_KHZ);
local tempHumidSensor = Si702x(hardware.i2c89);

// Instance the LPS25H and save a reference in pressureSensor
local pressureSensor = LPS25H(hardware.i2c89);
pressureSensor.enable(false);

// Instance the APDS9007 and save a reference in lightSensor
local lightOutputPin = hardware.pin5;
lightOutputPin.configure(ANALOG_IN);

local lightEnablePin = hardware.pin7;
lightEnablePin.configure(DIGITAL_OUT, 1);

local lightSensor = APDS9007(lightOutputPin, 47000, lightEnablePin);

// Configure the LED (on pin 2) as digital out with 0 start state
local led = hardware.pin2;
led.configure(DIGITAL_OUT, 0);

// Set up imp Pin 9 as an analog input
local batteryVoltagePin = hardware.pin9;
batteryVoltagePin.configure(ANALOG_IN);

function getReadings() {
    data.batterylife <- getPin9Voltage();
    server.log("The voltage on Pin 9 is: " + data.batterylife);

    tempHumidSensor.read(
        function(reading) {
            if ("err" in reading) {
                // if an error is detected, log the error message so we can fix it
                server.error("Error reading temperature: "+reading.err);
            } else {
                //data.temp = reading.temperature * 9 / 5 + 32;
                data.temp <- reading.temperature;
                data.humid <- reading.humidity;
                server.log("The temperature reading is: " + data.temp);
                // Send the data to the agent
                agent.send("readingFromDevice", data);

                imp.onidle(function() { server.sleepfor(3000); } );  //sleep for 10 sec use for debugging
            }
        }
    );
}
function getPin9Voltage() {
    // Returns value in volts, between 0.0 and 3.3
    local voltage = hardware.voltage();
    local reading = hardware.pin9.read();
    return (reading / 65535.0) * voltage;
}
function takeTemp() {
    tempHumidSensor.read(function(reading) {
        // The read() method is passed a function which will be
        // called when the temperature data has been gathered.
        // This 'callback' function also needs to handle our
        // housekeeping: flash the LED to show a reading has
        // been taken; send the data to the agent;
        // put the device to sleep

        // Create a Squirrel table to hold the data - handy if we
        // later want to package up other data from other sensors
        local data = {};

        // Check for errors returned from the sensor class
        // This can occur if hardware is defective or improperly connected
        if ("err" in reading) {
            // if an error is detected, log the error message so we can fix it
            server.error("Error reading temperature: "+reading.err);
        } else {
            // Get the temperature using the Si7020 object’s readTemp() method
            // Add the temperature using Squirrel’s 'new key' operator
            data.temp <- reading.temperature;
            //server.log("Temp is " + data.temp);
            // Send the imp's unique device ID as the key for our data stream
            data.id <- hardware.getdeviceid();

            // Log the temperature for debug
            //server.log(format("Got temperature: %0.1f deg C", data.temp));

            // Send the packaged data to the agent
            agent.send("reading", data);

            // Flash the LED to show we've taken a reading
            //flashLed();
        }
    });

    // Schedule the next reading
    imp.wakeup(10, takeTemp);
}

// Take a temperature reading as soon as the device starts up
// Note: when the device wakes from sleep (caused by line 86)
// it runs its device code afresh - ie. it does a warm boot
getReadings();
