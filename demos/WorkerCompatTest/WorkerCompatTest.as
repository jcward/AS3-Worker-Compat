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

  import com.lilcodemonkey.workers.WorkerCompat;
  import com.lilcodemonkey.workers.XTSharedObject;

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
    public static var text:TextField;

    private var xtSharedObject:Object;

    // Constructor
    public function WorkerCompatTest():void
    {
      stage.align = 'topLeft';
      stage.scaleMode ='noScale';
      stage.frameRate = 60;

      // Get a reference to the cross-thread shared object
      xtSharedObject = new XTSharedObject();

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

      text = new TextField();
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
      if (WorkerCompat.Worker.current.isPrimordial) { // Main thread runs this
        doGuiWork();
        // Creates a duplicate of this worker to run as the background worker
        var bgWorker:* = WorkerCompat.WorkerDomain.current.createWorker(this.loaderInfo.bytes);
        xtSharedObject.attachWorker(bgWorker);
        bgWorker.start();
      } else { // Background thread runs this
        doBackgroundWork();
      }
    }

    private function doGuiWork():void
    {
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
      xtSharedObject.tick = 0;

      // Every 400 ms, burn the CPU for 370 ms
      setInterval(function():void {
        var t:Number = getTimer();
        while (getTimer()-t < 370) {
          xtSharedObject.tick++;
        }
      }, 400);
    }

    private function onFrame(e:Event):void
    {
      var t:Number = getTimer();

      count.text = 'Background worker count = '+xtSharedObject.tick;

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
