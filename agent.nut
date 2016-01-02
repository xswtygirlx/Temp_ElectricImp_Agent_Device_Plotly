#require "Plotly.class.nut:1.0.0"

function loggerCallback(error, response, decoded) {
    if (error == null) {
        server.log(response.body);
    } else {
        server.error(error);
    }
}

function postToPlotly(reading) {
    local timestamp = plot1.getPlotlyTimestamp();
    //x axis format for time is: 2015-11-31 22:54:38
    //local now = date();
    //now.hour = now.hour - 8 % 24;
    //local timestamp = now.year + "-" + now.month + 1 % 12 + "-" + now.day + " " + now.hour + ":" + now.min + ":" + now.sec
    //server.log("Inside postToPlotly:" + timestamp);

    plot1.post([
        {
            "name" : "Temperature F",
            "x" : [timestamp],
            "y" : [reading["temp"]]
        },
        {
            "name" : "Humidity %",
            "x" : [timestamp],
            "y" : [reading["humid"]]
        }], loggerCallback);
}

function constructorCallback(error, response, decoded) {
    if (error != null) {
        server.error(error);
        return;
    }

    device.on("reading", postToPlotly);

    plot1.setTitle("Home Temperature Data", function(error, response, decoded) {
        if (error != null) {
            server.error(error);
            return;
        }

        plot1.setAxisTitles("Time", "Climate", function(error, response, decoded) {
            if (error != null) {
                server.error(error);
                return;
            }
            //local now = date();
            //now.hour = now.hour - 8 % 24;
            //local timestamp = now.year + "-" + now.month + 1 % 12 + "-" + now.day + " " + now.hour + ":" + now.min + ":" + now.sec
            //server.log("Inside ConstructorCallback:" + timestamp);

            server.log("See plot at " + plot1.getUrl());
        });
    });
}

local traces = ["Temperature", "Humidity"];
plot1 <- Plotly("xswtygirlx", "lorrmu78c3", "HomeTemperature", true, traces, constructorCallback);

//timestamp testing:
//local now = date();
//now.hour = now.hour - 8 % 24;
//local timestamp = now.year + "-" + now.month + 1 % 12 + "-" + now.day + " " + now.hour + ":" + now.min + ":" + now.sec
//server.log("Local Time:" + timestamp);

