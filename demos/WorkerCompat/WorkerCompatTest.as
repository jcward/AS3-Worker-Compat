package
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
  import flash.utils.setTimeout;

  import com.jcward.workers.WorkerCompat;
  import com.jcward.workers.XTSharedObject;

  /**
   * This test showcases the backward-compatible use of AS3 Workers.  It runs
   * in all versions of the Flash Player, and takes advantage of AS3 workers
   * whenever possible (Flash Player >= 11.4 && Worker.isSupported)
   *
   * A notable exception is Google Chrome under Windows (PPAPI)... for some
   * reason Google has disabled workers in their bundled version of Flash 11.4
   *
   * Very simple cross-thread data sharing (again, in any Flash Player) is
   * achieved via getting/setting values on xtSharedObject.
   */
  public class WorkerCompatTest extends Sprite
  {
    private var shape:Shape;
    private var bitmap:Bitmap;
    private var count:TextField;

    private var xtSharedObject:Object;

    // Constructor
    public function WorkerCompatTest():void
    {
      // Get a reference to the cross-thread shared object
      xtSharedObject = new XTSharedObject();

      if (WorkerCompat.workersSupported) {
        // Setup threading
        if (WorkerCompat.Worker.current.isPrimordial) { // Main thread runs this
          doGuiWork();
          // Creates a duplicate of this worker to run as the background worker
          var bgWorker:* = WorkerCompat.WorkerDomain.current.createWorker(this.loaderInfo.bytes);
          bgWorker.start();
        } else { // Background thread runs this
          doBackgroundWork();
        }
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
      text.text = "WorkerCompatTest v0.2.1\n"+
                  "Flash Player version: " + Capabilities.version+"\n"+
                  "userAgent: "+userAgent+"\n"+
                  "Worker Class (11.4+): "+WorkerCompat.Worker+"\n"+
                  "Mutex Class (11.5+): "+WorkerCompat.Mutex+"\n"+
                  "workersSupported: " + WorkerCompat.workersSupported;
      addChild(text);
    }

    private function doGuiWork():void
    {
      stage.align = 'topLeft';
      stage.scaleMode ='noScale';
      stage.frameRate = 60;
      showInfo();

      shape = new Shape();
      bitmap = new Bitmap(new BitmapData(100, 100, false, 0x0));
      addChild(bitmap);
      count = new TextField();
      count.width = 500;
      count.y = 105;
      addChild(count);
      this.addEventListener(Event.ENTER_FRAME, onFrame);
    }

    private function doBackgroundWork():void
    {
      var tick:int = 0;
      xtSharedObject.tick = 0;

      // Every 400 ms, burn the CPU for 370 ms
      setInterval(function():void {
        var t0:Number = getTimer();
        var dt:int = 0;
        while (dt < 370) {
          tick++;

          // If you set this every cycle, it can saturate the
          // shared object and crash the flash player.  Let's
          // send an update every 16 ms (roughly every frame)
          if (dt % 16 == 0) {
            xtSharedObject.tick = tick;
          }

          dt = getTimer()-t0;
        }
      }, 400);
    }

    private function onFrame(e:Event):void
    {
      var t:Number = getTimer();

      var tick:int = xtSharedObject.tick;
      count.text = 'Background worker count = '+tick+
        ', ~'+(Math.floor(10*(tick/t))/10)+' Kps';

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
