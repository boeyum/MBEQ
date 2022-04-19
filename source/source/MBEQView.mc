using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Greg;
using Toybox.ActivityMonitor as Act;
using Toybox.Activity;
using Toybox.UserProfile;
using Toybox.Sensor;

class MBEQView extends WatchUi.WatchFace {
	hidden var maxPuls;
	hidden var stepGoal;
	hidden var stairGoal;
	hidden var hbSens;
	var errorScreen = false;
	var background, heartIcon, stepIcon, batteryIcon, mailIcon, trappIcon;
    var width;
    var height;
    var centerX;
    var centerY;
    var timeBase;
    var ibase1;
    var ibase2;
    var fbase1;
    var fbase2;
    var offbase;
    var iconBase;
    var secoff;
    var timeOff;
    var dateBase;
    var hrData = 0;
	var dag = [ "SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT" ];
    var mnd = [ "JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC" ];

    function initialize() {
        WatchFace.initialize();
        var daar = Greg.info(Time.now(), Time.FORMAT_SHORT).year;
        var baar = UserProfile.getProfile().birthYear;
        var aldr = (daar - baar);
        maxPuls = Math.round(211 - (aldr * 0.64));
        stepGoal = 10000;
        stairGoal = 10;
    }

    // Load your resources here
    function onLayout(dc) {
    	var wtype = guiSetUp(dc);
    	heartIcon = WatchUi.loadResource(Rez.Drawables.hjerte);
    	stepIcon = WatchUi.loadResource(Rez.Drawables.skritt);
    	batteryIcon = WatchUi.loadResource(Rez.Drawables.batt);
    	mailIcon = WatchUi.loadResource(Rez.Drawables.brev);
    	trappIcon = WatchUi.loadResource(Rez.Drawables.trapp);
//        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }

    // Update the view
    function onUpdate(dc) {
    	var bpmv;
    	var pros = 0;
        // Get and show the current time
        var clockTime = System.getClockTime();
        var dinfo = Greg.info(Time.now(), Time.FORMAT_SHORT);
        var hrIterator = Act.getHeartRateHistory(null, true);
        var sample = hrIterator.next();
        if (sample != null) {
        	if (sample.heartRate != null) {
        		var hb = sample.heartRate;
        		if(hb > 249) {
        			pros = 0;
        			bpmv = "0";
        		} else {
        			pros = ((hb * 100) / maxPuls);
        			bpmv = hb.format("%d");
        		}
        	} else {
        		pros = 0;
        		bpmv = "Err.";
        	}
        } else {
        	bpmv = "N/A";
        } 
        var steps = Act.getInfo().steps;
        var done = ((steps * 100) / stepGoal);
        var stairs = Act.getInfo().floorsClimbed;
        var basis = ((steps * 100) / stairGoal);
        
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
        
        if(errorScreen) {
	        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
			dc.drawText(centerX, centerY, Graphics.FONT_SMALL, "NOT SUPPORTED", Graphics.TEXT_JUSTIFY_CENTER);
        } else {
	        dc.drawBitmap(0, 0, background);
	        var charge = System.getSystemStats().battery;
	        dc.drawBitmap(width-fbase1+1, ibase1+5, batteryIcon);
	        dc.setColor(charge < 20 ? Graphics.COLOR_RED : Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
	        dc.fillRectangle(width-fbase1, ibase1+6, 24.0 * charge / 100.0, 9);
	        if (System.getDeviceSettings().notificationCount > 0) { 
	        	dc.drawBitmap(fbase2, ibase2, mailIcon);
	        }
	        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
	        dc.drawText(centerX, dateBase, Graphics.FONT_XTINY, dag[dinfo.day_of_week-1] + " " + mnd[dinfo.month-1] + " " + dinfo.day.format("%02d") + "  " + dinfo.year.format("%04d"), Graphics.TEXT_JUSTIFY_CENTER);
	        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
	       	dc.drawText(centerX-timeOff, timeBase, Graphics.FONT_NUMBER_HOT, Lang.format("$1$:$2$:", [clockTime.hour.format("%02d"), clockTime.min.format("%02d")]), Graphics.TEXT_JUSTIFY_CENTER);
	        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
	       	dc.drawText(centerX+75+secoff, timeBase+25, Graphics.FONT_NUMBER_MILD, clockTime.sec.format("%02d"), Graphics.TEXT_JUSTIFY_LEFT);
	       	// Heartbeat monitor
	        dc.setColor(getColorHeart(pros), Graphics.COLOR_TRANSPARENT);
	       	dc.drawBitmap(62, iconBase, heartIcon);
			dc.drawText(70, iconBase+15, Graphics.FONT_XTINY, bpmv, Graphics.TEXT_JUSTIFY_CENTER);	       	
	       	// Steps monitor
	        dc.setColor(getColor(done), Graphics.COLOR_TRANSPARENT);
	       	dc.drawBitmap(centerY-8, iconBase, stepIcon);
			dc.drawText(centerY, iconBase+15, Graphics.FONT_XTINY, steps, Graphics.TEXT_JUSTIFY_CENTER);	       	
	       	// Stairs monitor
	        dc.setColor(getColor(basis), Graphics.COLOR_TRANSPARENT);
	       	dc.drawBitmap(width-78, iconBase, trappIcon);
			dc.drawText(width-70, iconBase+15, Graphics.FONT_XTINY, stairs, Graphics.TEXT_JUSTIFY_CENTER);	       	
       	}
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
    }

	function guiSetUp(dc) {
     	width = dc.getWidth();
     	height = dc.getHeight();
        centerX = (width / 2);
        centerY = (height / 2);
		var mySettings = System.getDeviceSettings();
		if(mySettings.screenShape == System.SCREEN_SHAPE_ROUND) {
			if((width == 240) && (height == 240)) {
    			background = WatchUi.loadResource(Rez.Drawables.bakgrunn01);
	    		timeBase = 85;
	    		iconBase = 153;
	    		ibase1 = 40;
	   			ibase2 = 40;
	    		offbase = 70;
	    		secoff = 0;
	    		timeOff = 20;
	    		dateBase = 75;
	    		fbase1 = 70;
	    		fbase2 = 60;
			} else if((width == 260) && (height == 260)) {
    			background = WatchUi.loadResource(Rez.Drawables.bakgrunn02);
	    		timeBase = 85;
	    		iconBase = 165;
	    		ibase1 = 40;
	   			ibase2 = 40;
	    		offbase = 70;
	    		secoff = 0;
	    		timeOff = 20;
	    		dateBase = 75;
	    		fbase1 = 70;
	    		fbase2 = 60;
			} else if((width == 390) && (height == 390)) {
    			background = WatchUi.loadResource(Rez.Drawables.bakgrunn03);
	    		timeBase = 130;
	    		iconBase = 250;
	    		ibase1 = 80;
	   			ibase2 = 80;
	    		offbase = 70;
	    		secoff = 40;
	    		timeOff = 35;
	    		dateBase = 110;
	    		fbase1 = 90;
	    		fbase2 = 80;
			} else {
				errorScreen = true;
			}
		} else {
			errorScreen = true;
		}
	}
	
	function getColor(pros) {
		if(pros > 99) {
			return Graphics.COLOR_GREEN;
		} else if(pros > 39) {
			return Graphics.COLOR_BLUE;
		} else {
			return Graphics.COLOR_LT_GRAY;
		}
	}
	
	function getColorHeart(pros) {
		if(pros > 95) {
			return Graphics.COLOR_DK_RED;
		} else if(pros > 85)  {
			return Graphics.COLOR_RED;
		} else if(pros > 75)  {
			return Graphics.COLOR_YELLOW;
		} else if(pros > 65)  {
			return Graphics.COLOR_DK_GREEN;
		} else if(pros > 45)  {
			return Graphics.COLOR_GREEN;
		} else {
			return Graphics.COLOR_LT_GRAY;
		}
	}
}
