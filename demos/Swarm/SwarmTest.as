package
{

  import flash.display.Shape;
  import flash.display.Sprite;
  import flash.text.TextField;
  import flash.events.Event;
  import flash.utils.getTimer;
  import flash.utils.setTimeout;

  import com.jcward.workers.WorkerCompat;
  import com.jcward.workers.XTSharedObject;
  import com.jcward.workers.AsyncScheduler;

  /**
   * This test showcases a real-world use case of Workers: AI.
   */
  public class SwarmTest extends Sprite
  {
    private const NUM:int = 200;
    private var shape:Shape;

    private var xtSharedObject:Object;
    private var xx:Vector.<Number>;
    private var yy:Vector.<Number>;

    // Constructor
    public function SwarmTest():void
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

    private function doGuiWork():void
    {
      stage.align = 'topLeft';
      stage.scaleMode ='noScale';
      stage.frameRate = 60;

      xtSharedObject.num = NUM;
      xtSharedObject.stageWidth = stage.stageWidth;
      xtSharedObject.stageHeight = stage.stageHeight;

      var t:TextField = new TextField();
      t.width = 400;
      t.text = "Workers? "+WorkerCompat.workersSupported;
      addChild(t);

      shape = new Shape();
      addChild(shape);
      this.addEventListener(Event.ENTER_FRAME, onFrame);
    }

    private function doBackgroundWork():void
    {
      xx = new Vector.<Number>(NUM);
      yy = new Vector.<Number>(NUM);

      // Setup swarm
      var i:int;
      for (i = xtSharedObject.num-1; i>=0; i--) {
        xx[i] = Math.random()*xtSharedObject.stageWidth;
        yy[i] = Math.random()*xtSharedObject.stageHeight;
      }

      // Assign-back
      xtSharedObject.x = xx;
      xtSharedObject.y = yy;

      if (WorkerCompat.workersSupported) {
        // Use the background thread heavily
        AsyncScheduler.setParams(AsyncScheduler.HIGH);
      } else {
        // Stutter UI as little as possible without workers
        AsyncScheduler.setParams(AsyncScheduler.LOW);
      }

      // Asynchronous movement calculation
      i = xtSharedObject.num-1;
      var j:int = xtSharedObject.num-1;
      var forceX:Number;
      var forceY:Number;
      AsyncScheduler.async(this,
        function(timeout:int):Boolean {
          for (; i>=0; i--) { if (getTimer()>timeout) { return false; }
            forceX = forceY = 0;
            var ix:Number = xx[i];
            var iy:Number = yy[i];
            var jx:Number;
            var jy:Number;
            var dist:Number;
            var angle:Number;

            for (; j>=0; j--) { if (getTimer()>timeout) { return false; }
              if (j==i) continue;

              jx = xx[j];
              jy = yy[j];

              dist = Math.pow((ix-jx)*(ix-jx)+(iy-jy)*(iy-jy), 0.3);
              angle = Math.atan2(jy-iy, jx-ix);
              if (dist < 20+10*Math.random()) {
                forceX -= 5*Math.cos(angle)/(5+dist);
                forceY -= 5*Math.sin(angle)/(5+dist);
              } else {
                forceX += 5*Math.cos(angle)/(5+dist);
                forceY += 5*Math.sin(angle)/(5+dist);
              }
            }
            j = xtSharedObject.num-1; // reset loop

            // attraction to center
            jx = xtSharedObject.stageWidth/2;
            jy = xtSharedObject.stageHeight/2;

            dist = Math.pow((ix-jx)*(ix-jx)+(iy-jy)*(iy-jy), 0.3);
            angle = Math.atan2(jy-iy, jx-ix);
            //if (Math.cos(getTimer()/300)<0.9) {
              forceX += 80*Math.cos(angle)/(10+dist);
              forceY += 80*Math.sin(angle)/(10+dist);
            //} else {
            //  forceX -= 40*Math.cos(angle)/(10+dist);
            //  forceY -= 40*Math.sin(angle)/(10+dist);
            //}

            xx[i] += forceX;
            yy[i] += forceY;

          }
          i = xtSharedObject.num-1; // reset loop

          // Assign-back
          xtSharedObject.x = xx;
          xtSharedObject.y = yy;

          return false; // this task is indefinite
      });
    }

    private function onFrame(e:Event):void
    {
      shape.graphics.clear();
      shape.graphics.beginFill(0xff0000);

      var x:Vector.<Number> = xtSharedObject.x;
      var y:Vector.<Number> = xtSharedObject.y;

      if (x && y) {
        for (var i:int=xtSharedObject.num-1; i>=0; i--) {
          shape.graphics.drawCircle(x[i], y[i], 3);
        }
      }
    }
  }
}
