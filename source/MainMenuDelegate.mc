using Toybox.WatchUi;
using Toybox.System;

class MainMenuDelegate extends WatchUi.MenuInputDelegate {

    function initialize() {
        MenuInputDelegate.initialize();
    }

    function onMenuItem(item) {
        if (item == :ChangeWorkout) {
            System.println("ChangeWorkout");
        } else if (item == :Instructions) {
            System.println("Instructions");
        } else if (item == :About) {
            System.println("About");
        }
    }
}