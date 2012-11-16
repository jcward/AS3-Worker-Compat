package com.lilcodemonkey.workers {

  import flash.utils.getTimer;
  import flash.utils.setTimeout;

  public class AsyncHelper {

    private static var pending_jobs:Vector.<AsyncJob>;
    private static var jobs:Vector.<AsyncJob>;
    private static var prioritySum:Number = 0;

    private static var timeOfFullPass:Number;
    private static var timeBetweenRuns:Number;

    public static function loop(context:Object,
                                loopFunc:Function,
                                priority:Number=1):void
    {
      if (jobs==null) {
        jobs = new Vector.<AsyncJob>();
        pending_jobs = new Vector.<AsyncJob>();
      }

      if (priority<1) { priority = 1; }
      pending_jobs.push(new AsyncJob(priority, loopFunc, context));

      if (pending_jobs.length==1 && jobs.length==0) {
        startScheduler();
      }
    }

    private static function startScheduler():void
    {
      trace("startScheduler!");
      if (WorkerCompat.workersSupported &&
          !WorkerCompat.Worker.current.isPrimordial) {
        // no need to waste time on background threads
        timeBetweenRuns = 1;
        timeOfFullPass = 150;
      } else {
        timeBetweenRuns = 10;
        timeOfFullPass = 20;
      }
      runScheduler();
    }

    private static function runScheduler():void
    {
      checkPendingJobs();
      for (var i:int=jobs.length-1; i>=0; --i) {
        var j:AsyncJob = jobs[i];
        var t0:uint = getTimer();
        var duration:uint = (j.priority/prioritySum)*timeOfFullPass;

        var complete:Boolean = j.loopFunc.call(j.context, t0+duration);
        if (complete) {
          jobs.splice(i, 1);
        }
      }
      if (jobs.length>0 || pending_jobs.length>0) {
        setTimeout(runScheduler, timeBetweenRuns);
      }
    }

    private static function checkPendingJobs():void
    {
      while (pending_jobs.length>0) {
        var j:AsyncJob = pending_jobs.pop();
        prioritySum += j.priority;

        // Insert in reverse-priority order
        var i:int = jobs.length;
        for (; i>0; i--) {
          if (j.priority > jobs[i-1].priority) break;
        }
        jobs.splice(i, 0, j);
      }
    }

  }
}

class AsyncJob {
  public var priority:Number;
  public var loopFunc:Function;
  public var context:Object;

  public function AsyncJob(p:Number, l:Function, c:Object):void
  {
    priority = p;
    loopFunc = l;
    context = c;
  }
}
