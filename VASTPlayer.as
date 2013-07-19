package {  

  import flash.display.*;
  import flash.events.*;
  import flash.net.*;
  import flash.media.*;
  import flash.utils.*;
  import flash.system.*;

  import com.buchok.Console;

  import net.iab.VPAIDEvent;

  public class VASTPlayer extends MovieClip {

    private const DEFAULT_XML = 'xml/interactive.xml';
    private var _mediaFileUrl:String;
    private var _impressions = [];
    private var _tracking = { 
                              'impression': [], 
                              'firstQuartile': [],
                              'midpoint': [],
                              'thirdQuartile': [],
                              'complete': []
                            };
    private var quartiles = [
                              { progress: .25,  type: 'firstQuartile' }, 
                              { progress: .5,   type: 'midpoint' },
                              { progress: .75,  type: 'thirdQuartile' }
                            ];
    
    function VASTPlayer() {
      stage.align = StageAlign.TOP_LEFT;
      addEventListener(Event.ADDED_TO_STAGE, handleAddedToStage);
    }

    private function handleAddedToStage(event:Event) : void {
      var url = root.loaderInfo.parameters['vast'] || DEFAULT_XML;
      var loader = new URLLoader();
      loader.addEventListener(Event.COMPLETE, handleVastXml);
      loader.load(new URLRequest(url));
    }

    private function handleVastXml(event:Event) : void {
      // http://www.freeformatter.com/xml-formatter.html
      XML.ignoreWhitespace = false;
      var xml = new XML(event.target.data);
      for (var i = 0; i < xml.Ad.InLine.Impression.length(); i++) {
        var impression = xml.Ad.InLine.Impression[i].text();
        _tracking['impression'].push(encodeURIComponent(impression));
      }
      var trackingEvents = xml.Ad.InLine.Creatives.Creative.Linear.TrackingEvents.Tracking;
      for (i = 0; i < trackingEvents.length(); i++) {
        if (_tracking[trackingEvents[i].@event])
          _tracking[trackingEvents[i].@event].push(trackingEvents[i].text());
      }
      var mediaFile = xml.Ad.InLine.Creatives.Creative.Linear.MediaFiles.MediaFile;
      _mediaFileUrl = mediaFile.text();
      var apiFramework = xml.Ad.InLine.Creatives.Creative.Linear.MediaFiles.MediaFile.@apiFramework;
      if (apiFramework.length() > 0 && apiFramework.toLowerCase() === 'vpaid') {
        loadVPAIDFile();
      } else {
        loadVideoFile();
      }
    }

    private function track(type) : void {
      if (!_tracking[type]) return;

      _tracking[type].forEach(function(url) {
        Console.log(url);
        // flash.net.sendToURL(new URLRequest(url));
      });
    }

    private function loadVPAIDFile() : void {
      var loaderContext:LoaderContext = new LoaderContext();
      loaderContext.applicationDomain = new ApplicationDomain(ApplicationDomain.currentDomain);
      var loader = new Loader();
      loader.contentLoaderInfo.addEventListener(Event.COMPLETE, handleVPAIDLoaded);
      loader.load(new URLRequest(_mediaFileUrl), loaderContext);
    }

    private function handleVPAIDLoaded(event:Event) : void {
      var ad = event.target.content;
      // Handshake here, if we want.
      // ...
      ad.addEventListener(VPAIDEvent.AdLoaded, function() { 
        addChild(ad);
        ad.startAd(); 
      });
      ad.addEventListener(VPAIDEvent.AdImpression, function(){ track('impression'); });
      ad.addEventListener(VPAIDEvent.AdStarted, function(){ track('started'); });
      ad.addEventListener(VPAIDEvent.AdVideoFirstQuartile, function(){ track('firstQuartile'); });
      ad.addEventListener(VPAIDEvent.AdVideoMidpoint, function(){ track('midpoint'); });
      ad.addEventListener(VPAIDEvent.AdVideoThirdQuartile, function(){ track('thirdQuartile'); });
      ad.addEventListener(VPAIDEvent.AdVideoComplete, function(){ track('AdVideoComplete'); });
      ad.initAd(640, 360, 'normal', null, null, null);
    }


    private function loadVideoFile() : void {
      var connection:NetConnection = new NetConnection();
      connection.client = this;
      connection.addEventListener(NetStatusEvent.NET_STATUS, handleNetStatus);
      connection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, destroyStream);
      connection.connect(null);
    }

    private function connectStream(event:NetStatusEvent) : void {
      event.target.removeEventListener(NetStatusEvent.NET_STATUS, handleNetStatus);
      event.target.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, destroyStream);
      
      var netStream:NetStream = new NetStream(event.target as NetConnection);
      var video:Video = new Video();
      video.attachNetStream(netStream);
      video.width = 640;
      video.height = 360;
      video.x = 0;
      video.y = 0;
      addChild(video);
      
      var onMetaData = function(data:Object) {
        var duration = data.duration;
        var checkTime = function() {
          var progress = netStream.time / duration;
          if (progress >= 1) {
            track('complete');
            clearInterval(interval);
          } else {
            if (progress >= quartiles[0].progress) {
              track(quartiles[0].type);
              quartiles.shift();
            }
          }
          // Log the progress:
          Console.log(progress);
        };
        var interval = setInterval(checkTime, 500);
      }

      netStream.client = { onMetaData : onMetaData };
      netStream.addEventListener(NetStatusEvent.NET_STATUS, handleNetStatus);
      netStream.play(_mediaFileUrl);
      track('impression');
    }

    private function handleNetStatus(event:NetStatusEvent) : void {
      switch(event.info.code) {
        case "NetConnection.Connect.Success":
          connectStream(event);
          break;
        case "NetConnection.Connect.Rejected":
        case "NetConnection.Connect.Failed":
        case "NetStream.Play.StreamNotFound":
        case "NetStream.Play.Failed":
         destroyStream(event);
      }
    }
    
    private function destroyStream(event:NetStatusEvent) : void {
      event.target.removeEventListener(NetStatusEvent.NET_STATUS, handleNetStatus);
      event.target.close();
    }

  };
};