var http = require("http");
var fs = require("fs");
var beep = require("beepbeep");

var mkdirSync = function(path){
	try {
		fs.mkdirSync(path);
	}
	catch(e){
		if(e.code != 'EEXIST') throw e;
	}
}

function Camera(ip, pan, tilt, name){
	this.ip = ip;
	this.pan = pan;
	this.tilt = tilt;
	this.name = name;
}

Camera.prototype.tiltURLcmd = function(){
	return "http://" + this.ip + "/axis-cgi/com/ptz.cgi?camera=1&tilt=" + this.tilt;
}

Camera.prototype.panURLcmd = function(){
	return "http://" + this.ip + "/axis-cgi/com/ptz.cgi?camera=1&pan=" + this.pan;
}

Camera.prototype.imageURL = function(){
	return "http://" + this.ip + "/jpg/image.jpg";
}

//var camera = new Camera("192.168.1.131", 130, 30, "camera1");
//var camera = new Camera("192.168.1.127", 110, 40, "camera2");
//var camera = new Camera("192.168.1.121", 150, 30, "camera3");
//var camera = new Camera("192.168.1.114", 30, 30, "camera4");
var camera = new Camera("192.168.1.131", 130, 30, "marker");

mkdirSync("./" + camera.name);
http.get(camera.tiltURLcmd(), function(res){
	http.get(camera.panURLcmd(), function(res){
		var i = 0;
		console.log("Capturing in 3 seconds");
		setTimeout(function pull(){
			if(i < 20){
				http.get(camera.imageURL(), function(res){
					res.on("end", function(){
						console.log("Got image " + i);
						beep();
						setTimeout(pull, 3000);
					});
					i++;
					var ws = fs.createWriteStream("./" + camera.name + "/image" + i + ".jpg");
					res.pipe(ws);
				});
			}
		}, 3000);
	});
});

