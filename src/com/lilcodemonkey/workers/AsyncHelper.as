package com.lilcodemonkey.workers {

  public class AsyncHelper {

    private static var jobs:Vector.<AsyncJob> = new Vector.<AsyncJob>([]);
    private static var prioritySum:Number = 0;

    private static var timeOfFullPass:Number;
    private static var timeBetweenRuns:Number;

    public static function loop(context:Object,
                                loopFunc:Function,
                                priority:Number=1):void
    {
      if (priority<1) { priority = 1; }
      prioritySum += priority;

      // Insert in priority order
      var i:int = 0;
      for (; i<jobs.length; i++) {
        if (priority > jobs[i].priority) break;
      }
      jobs.splice(i, 0, new AsyncJob(context, loopFunc, priority));

      if (jobs.length==1) {
        startScheduler();
      }
    }

    private static function startScheduler():void
    {
      if (WorkerCompat.workersSupported &&
          !WorkerCompat.Worker.current.isPrimordial) {
        // no need to waste time on background threads
        timeBetweenRuns = 1;
        timeOfFullPass = 50;
      } else {
        timeBetweenRuns = 10;
        timeOfFullPass = 20;
      }
      runScheduler();
    }

    private static function runScheduler():void
    {
      if (jobs.length>0) {
        setTimeout(runScheduler, timeBetweenRuns);
      }
    }

  }

}
