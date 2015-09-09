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

function Camera(ip, name){
	this.ip = ip;
	this.name = name;
}

Camera.prototype.imageURL = function(){
	return "http://" + this.ip + "/jpg/image.jpg";
}

Camera.prototype.capture = function(){
	var i = 0;
	var obj = this;
	mkdirSync("./" + this.name);
	console.log("Capturing in 3 seconds");
	setTimeout(function pull(){
		if(i < 25){
			http.get(obj.imageURL(), function(res){
				res.on("end", function(){
					console.log("Got image " + i);
					beep();
					setTimeout(pull, 1000);
				});
				i++;
				var ws = fs.createWriteStream("./" + obj.name + "/" + obj.name + "_" + i + ".jpg");
				res.pipe(ws);
			});
		}
	}, 3000);
}

var camera1 = new Camera("192.168.1.131", "camera1");
var camera2 = new Camera("192.168.1.127", "camera2");
var camera3 = new Camera("192.168.1.121", "camera3");
var camera4 = new Camera("192.168.1.114", "camera4");

camera1.capture();
camera2.capture();
camera3.capture();
camera4.capture();
