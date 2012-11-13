package com.lilcodemonkey.workers
{

  import flash.display.Bitmap;
  import flash.display.BitmapData;
  import flash.display.Shape;
  import flash.display.Sprite;
  import flash.events.Event;
  import flash.external.ExternalInterface;
  import flash.system.Capabilities;
  import flash.text.TextField;
  import flash.utils.getTimer;
  import flash.utils.setInterval;

  /**
   * This test showcases the backward-compatible use of AS3 Workers.  It runs
   * in all versions of the Flash Player, and takes advantage of AS3 workers
   * whenever possible (Flash Player >= 11.4 && Worker.isSupported)
   *
   * A notable exception is Google Chrome under Windows (PPAPI)... for some
   * reason Google has disabled workers in their bundled version of Flash 11.4
   *
   * This simple demo does not demonstrate intra-thread communication.
   */
  public class WorkerCompatTest extends Sprite
  {
    private var shape:Shape;
    private var bitmap:Bitmap;

    // Constructor
    public function WorkerCompatTest():void
    {
      stage.align = 'topLeft';
      stage.scaleMode ='noScale';
      stage.frameRate = 60;

      showInfo();

      if (WorkerCompat.workersSupported) {
        // Setup threading
        setupThreads();
      } else {
        // Fallback: Do all the work in this thread
        doGuiWork();
        doBackgroundWork();
      }
    }

    private function showInfo():void
    {
      var userAgent:String;
      try {
        userAgent = ExternalInterface.call("(function() { return window.navigator.userAgent })");
      } catch (e:Error) {
        userAgent = "unknown";
      }

      var text:TextField = new TextField();
      text.width = text.height = 500;
      text.x = 105;
      text.text = "Flash Player version: " + Capabilities.version+"\n"+
                  "userAgent: "+userAgent+"\n"+
                  "WorkerClass: "+WorkerCompat.Worker+"\n"+
                  "workersSupported: " + WorkerCompat.workersSupported;
      addChild(text);
    }

    private function setupThreads():void
    {
      if (WorkerCompat.Worker.current.isPrimordial) {
        // Main thread runs this
        doGuiWork();

        // And creates a duplicate of itself to run as the background worker
        var bgWorker:* = WorkerCompat.WorkerDomain.current.createWorker(this.loaderInfo.bytes);
        bgWorker.start();
      } else {
        // Background thread runs this
        doBackgroundWork();
      }
    }

    private function doGuiWork():void
    {
      shape = new Shape();
      bitmap = new Bitmap(new BitmapData(100, 100, false, 0x0));
      addChild(bitmap);
      this.addEventListener(Event.ENTER_FRAME, onFrame);
    }

    private function doBackgroundWork():void
    {
      // Every 200 ms, burn the CPU for 170 ms
      setInterval(function():void {
        var t:Number = getTimer();
        while (getTimer()-t < 170) { }
      }, 200);
    }

    private function onFrame(e:Event):void
    {
      var t:Number = getTimer();

      // Fade to black
      shape.graphics.clear();
      shape.graphics.beginFill(0x0, 0.05);
      shape.graphics.drawRect(0,0,100,100);
      bitmap.bitmapData.draw(shape);

      // Draw red circle/line
      shape.graphics.clear();
      shape.graphics.lineStyle(3, 0xff0000, 1, true);
      shape.graphics.drawCircle(50, 50, 46);
      shape.graphics.moveTo(50, 50);
      shape.graphics.lineTo(50+45*Math.cos(t/300), 50+45*Math.sin(t/300));
      bitmap.bitmapData.draw(shape);
    }

  }

}
