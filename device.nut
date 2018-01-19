#require "APDS9007.class.nut:2.2.1"
#require "LPS25H.class.nut:2.0.1"
#require "Si702x.class.nut:1.0.0"

// How long to wait between taking readings
const INTERVAL_SECONDS = 60;  // Take reading every 3600 seconds = hourly

// Instance the Si702x and save a reference in tempHumidSensor
hardware.i2c89.configure(CLOCK_SPEED_400_KHZ);
local tempHumidSensor = Si702x(hardware.i2c89);

// Set up imp Pin 9 as an analog input
//local batteryVoltagePin = hardware.pin9;
//batteryVoltagePin.configure(ANALOG_IN);

data <- {};
data.humid <- 0;
data.batterylife <- 0;
data.temp <- 0;
// This function will be called regularly to take the temperature
// and log it to the device’s agent
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
        //local data = {};

        // Check for errors returned from the sensor class
        // This can occur if hardware is defective or improperly connected
        if ("err" in reading) {
            // if an error is detected, log the error message so we can fix it
            server.error("Error reading temperature: "+reading.err);
        } else {
            data.batterylife <- getPin9Voltage();
            server.log("The voltage on Pin 9 is: " + data.batterylife);

            // Get the temperature using the Si7020 object’s readTemp() method
            // Add the temperature using Squirrel’s 'new key' operator
            data.temp <- reading.temperature * 9 / 5 + 32;
            data.humid <- reading.humidity;
            server.log("Device temp is " + data.temp + "F");
            // Send the imp's unique device ID as the key for our data stream
            data.id <- hardware.getdeviceid();

            // Log the temperature for debug
            //server.log(format("Got temperature: %0.1f deg C", data.temp));

            // Send the packaged data to the agent
            agent.send("reading", data);

            // Flash the LED to show we've taken a reading
            //flashLed();

            imp.onidle(function() { server.sleepfor(INTERVAL_SECONDS); } );
        }
    });

    // Schedule the next reading
    //imp.wakeup(INTERVAL_SECONDS, takeTemp);
}

function getPin9Voltage() {
    // Returns value in volts, between 0.0 and 3.3
    local voltage = hardware.voltage();
    local reading = hardware.pin9.read();
    return (reading / 65535.0) * voltage;
}

// Take a temperature reading as soon as the device starts up
takeTemp();
