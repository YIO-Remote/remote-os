<?php
function addNetwork($ssid, $rssi, $id)
{
	echo "<div id=\"$id\" class=\"networklist_element\" onClick=\"selectWifi('$id', '$ssid')\">
	<p>$ssid</p>";
	if ($rssi > -120 and $rssi < -80) {
		echo "<img class=\"imgwifi\" src='assets/icon-wifi-1.png'
		srcset='assets/icon-wifi-1.png 1x,
				assets/icon-wifi-1@2x.png 2x,
				assets/icon-wifi-1@3x.png 3x'
		style='max-width: 25px'/>";
	} else if ($rssi > -80 and $rssi < -40) {
		echo "<img class=\"imgwifi\" src='assets/icon-wifi-2.png'
		srcset='assets/icon-wifi-2.png 1x,
				assets/icon-wifi-2@2x.png 2x,
				assets/icon-wifi-2@3x.png 3x'
		style='max-width: 25px'/>";
	} else {
		echo "<img class=\"imgwifi\" src='assets/icon-wifi-full.png'
		srcset='assets/icon-wifi-full.png 1x,
				assets/icon-wifi-full@2x.png 2x,
				assets/icon-wifi-full@3x.png 3x'
		style='max-width: 25px'/>";
	}
	echo "<div class=\"vl\"></div>
	</div>";
}
?>
<!DOCTYPE html>
<html>
<head>
	<title>YIO Remote Wi-Fi Setup</title>	
	<meta charset="utf-8" />	
	<link rel="stylesheet" href="style.css" type="text/css" media="all" />
	<script>
	function selectWifi(obj, ssid) {
		var parent = document.getElementById('networklist_container');
		var children = parent.getElementsByClassName('networklist_element');

		var selected = document.getElementById(obj);

		for (var i=0; i<children.length; i++)
		{
			var e = children[i];
			if (e != selected) {
				e.style.display = 'none';
			}
		}

		// set input with value
		var inputField = document.getElementById("ssid_input");
		inputField.value = ssid;

		//show password
		document.getElementById("password").style.display = 'block';
	}

	function customWifi() {
		// hide all networks that were found
		var parent = document.getElementById('networklist_container');
		var children = parent.getElementsByClassName('networklist_element');

		for (var i=0; i<children.length; i++)
		{
			var e = children[i];
			e.style.display = 'none';
		}

		// show input fields
		document.getElementById("ssid").style.display = 'block';	
		document.getElementById("password").style.display = 'block';
	}
</script>
</head>
<body>
	<form action="wifi.php" method="POST">
		<div class='logo'>
			<img src='assets/yio-logo.png'
				srcset='assets/yio-logo.png 1x,
						assets/yio-logo@2x.png 2x,
						assets/yio-logo@3x.png 3x'
				style='max-width: 180px'/>
		</div>
		<p class="infotext">Let’s get started and set up your Wi-Fi connection.</p>		
		<div class="smalltitle">
			<p>Choose your Wi-Fi network</p>
		</div>
		<div id="networklist_container" class="networklist_container">
			<?php
				$output = shell_exec("cat /networklist");
				$lines = explode("\n", $output);

				$counter = 0;

				foreach($lines as $item) {
					$parts = explode(",", $item);
					if ($parts[1] != "")
					{
						addNetwork($parts[1], $parts[0], $counter);
						$counter++;
					}
				}	
			?>	
			<div id="othernetwork" class="networklist_element" onClick="customWifi()">
			<p>Join other network...</p>
			</div>
		</div>
		<p id="ssid" class="ssid">
			<input id="ssid_input" type="text" name="ssid" placeholder="Enter you Wi-Fi network’s name"/>
		</p>
		<p id="password" class="password">
			<input type="password" name="password" placeholder="Enter your Wi-Fi password" />
		</p>
		<p class="hiddeninput">
			<input id="timezone" type="text" name="timezone"/>
		</p>
		<p class="hiddeninput">
			<input id="time" type="text" name="time"/>
		</p>
		<p class="hiddeninput">
			<input id="date" type="text" name="date"/>
		</p>
		<div class="smalltitle topspace">
			<p>Time zone</p>
		</div>
		<div class="timezone">
		<p id="timezonetext"></p>
		</div>
		<div class="smalltitle topspace">
			<p>Time and date</p>
		</div>
		<div class="timedate">
			<p id="currenttime"></p>
			<p id="currentdate">Thursday, 22 August 2019</p>		
		</div>
		<p class="submit">
			<input type="submit" value="Next" />
		</p>
	</form>
</body>
<script>
	// get timezone
	document.getElementById('timezonetext').innerHTML = Intl.DateTimeFormat().resolvedOptions().timeZone

	// get current time
	// TODO use date format functions instead of manual formatting
	// TODO use current locale and timezone in dateTime format
	var today = new Date();
	var time = today.getHours() + ":" + today.getMinutes();
	document.getElementById('currenttime').innerHTML = time;

	// get current date
	var weekday = new Array(7);
	weekday[0] =  "Sunday";
	weekday[1] = "Monday";
	weekday[2] = "Tuesday";
	weekday[3] = "Wednesday";
	weekday[4] = "Thursday";
	weekday[5] = "Friday";
	weekday[6] = "Saturday";

	//get current month
	var month = new Array(12);
	month[0] = "Jan";
	month[1] = "Feb";
	month[2] = "Mar";
	month[3] = "Apr";
	month[4] = "May";
	month[5] = "Jul";
	month[6] = "Jun";
	month[7] = "Aug";
	month[8] = "Sep";
	month[9] = "Oct";
	month[10] = "Nov";
	month[11] = "Dec";

	var date = weekday[today.getDay()] + ", " + today.getDate() + " " + month[today.getMonth()] + " " + today.getFullYear();
	document.getElementById('currentdate').innerHTML = date;

</script>
</html>
