package net.iab {
  
  import flash.events.Event;
  
  public interface IVPAID {
    // Properties
    function get adLinear() : Boolean;
    function get adExpanded() : Boolean;
    function get adRemainingTime() : Number;
    function get adVolume() : Number;
    function set adVolume(value : Number) : void; 
  
    // Methods 
    function handshakeVersion(playerVPAIDVersion : String) : String;
    function initAd(width : Number, height : Number, viewMode : String, desiredBitrate : Number, creativeData :
String, environmentVars : String) : void;
    function resizeAd(width : Number, height : Number, viewMode : String) : void; 
    function startAd() : void;
    function stopAd(event:Event=null) : void;
    function pauseAd(event:Event=null) : void;
    function resumeAd(event:Event=null) : void;
    function expandAd() : void;
    function collapseAd() : void;
    
  };
};