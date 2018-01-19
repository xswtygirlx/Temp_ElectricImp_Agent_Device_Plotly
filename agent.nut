// Agent Code
#require "Dweetio.class.nut:1.0.1"
#require "Plotly.class.nut:1.0.1"

// Create a Dweet instance
local client = DweetIO();
local traces = ["Temperature", "Humidity", "Battery"];
local equipment = "Upright Freezer";
local max_temp = 80;
local min_battery = 3.3;
local plotly_username = "xswtygirlx";
local plotly_password = "lorrmu78c3";
local mailgun_from = "postmaster@sandboxbf4d4295bdf14373a9cfcf073e183bac.mailgun.org";
local mailgun_to   = "mmtina@hotmail.com"
local mailgun_apikey = "key-ca099e815ce9cc4c2676db81c0e3143f";
local mailgun_domain = "sandboxbf4d4295bdf14373a9cfcf073e183bac.mailgun.org";

/* //use this section for debugging
// Add a function to post data from the device to your stream
function postReading(reading) {
   // Note: reading is the data passed from the device, ie.
   // a Squirrel table with the key 'temp'
   // Use the imp's unique device ID as the key for the data stream
   //client.dweet(reading.id, reading, null);
   server.log("Agent temp is " + reading.temp + "F");
}

// Register the function to handle data messages from the device
device.on("reading", postReading);
//*/

function loggerCallback(error, response, decoded) {
   if (error == null) {
       server.log(response.body);
   } else {
       server.error(error);
   }
}
// returns time string, +7200 is for +1 GMT (Berlin)
// use 3600 and multiply by the hours +/- GMT.
// e.g for +5 GMT local date = date(time()+18000, "u");
function getTime()
{
   local now = date(time()-25200);

   local sec = now.sec;
   local min = now.min;
   local hour = now.hour;
   local day = now.day;
   local month = now.month+1;
   local year = now.year;

   if (now.hour > 23)
   {
       now.hour = 0;
       now.day++;
   }
   if (month < 10)
   {
       month = "0" + (month).tostring();
   }
   if (now.day < 10)
   {
       day = "0" + (now.day).tostring();
   }

   return year+"-"+month+"-"+day+" "+hour+":"+min+":"+sec;
}
function mailgun(subject, message)
{
 //local request = http.post("https://api:" + apikey + "@api.mailgun.net/v2/" + domain + "/messages", {"Content-Type": "application/x-www-form-urlencoded"}, "from=" + from + "&to=" + to + "&subject=" + subject + "&text=" + message);
 local request = http.post("https://api:" + mailgun_apikey + "@api.mailgun.net/v3/" + mailgun_domain + "/messages", {"Content-Type": "application/x-www-form-urlencoded"}, "from=" + mailgun_from + "&to=" + mailgun_to + "&subject=" + subject + "&text=" + message);
 local response = request.sendsync();
 server.log("Mailgun response: " + response.body);
}
function postToPlotly(reading) {
   //local timestamp = plot1.getPlotlyTimestamp();
   local timestamp = getTime();
   plot1.post([
       {
           "name" : "Temperature F",
           "x" : [timestamp],
           "y" : [reading["temp"]],
           "fill": "tozeroy",
           "line": {
               "shape": "linear",
               "smoothing": 1
           },
           "type": "scatter"
       },
       {
           "name" : "Humidity %",
           "x" : [timestamp],
           "y" : [reading["humid"]],
           "fill": "tozeroy",
           "line": {
               "shape": "linear",
               "smoothing": 1
           },
           "type": "scatter"
       },
       {
           "name" : "Battery Life",
           "x" : [timestamp],
           "y" : [reading["batterylife"]],
           "fill": "tozeroy",
           "line": {
               "shape": "linear",
               "smoothing": 1
           },
           "type": "scatter"
       }], loggerCallback);
       //Do checks for business operations
       if (reading["temp"] > max_temp ) {
           mailgun("High Temp Alert", equipment + " temp is too high: " + reading["temp"] + " F");
       }
       if (reading["batterylife"] < min_battery ) {
           mailgun("Low Battery Alert", equipment + " needs a new 9v battery soon.  Current Battery Life in Voltage: " + reading["batterylife"]);
       }
}
function constructorCallback(error, response, decoded) {
   if (error != null) {
       server.error(error);
       return;
   }

   local timestamp = plot1.getPlotlyTimestamp();

   device.on("reading", postToPlotly);
   //device.on("reading", postReading);

   plot1.setTitle(equipment + "Temperature", function(error, response, decoded) {
       if (error != null) {
           server.error(error);
           return;
       }
       plot1.setAxisTitles("Time", "Temperature", function(error, response, decoded) {
           if (error != null) {
               server.error(error);
               return;
           }
           server.log("See plot at " + plot1.getUrl());
       });
   });
}

plot1 <- Plotly(plotly_username, plotly_password, equipment, true, traces, constructorCallback);
//mailgun("High Temp Alert", "Temp is too high: ");  //debugging mailgun.

//local now = getTime();
//server.log("Current Time:" + now);
// Enhancement 1: Battery level low.
// Enhancement 2: Email someone when temp is below or above some set level.
// Enhancement 3: Based on #2, based on time of the day, when defrost is over.
// Enhancement 4: App for iphone and andriod.
// Enhancement 5: Interchangeable degree in F / C . 
