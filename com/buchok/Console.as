package com.buchok {

  import flash.external.ExternalInterface;

  public class Console {

    public static function log(message) {
      message = message.toString();
      ExternalInterface.call("function(message) { if (window.console) { window.console.log(message); } }", message);
    }

  };
};