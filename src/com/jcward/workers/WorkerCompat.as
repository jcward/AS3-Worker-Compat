package com.jcward.workers {

  import flash.utils.getDefinitionByName;
  import flash.utils.ByteArray;

  /**
   * This class provides dynamic (runtime-lookup) access to the classes
   * necessary to utilize AS3 Workers (Worker, WorkerDomain, etc). As such,
   * this class is backward compatible with Flash Players prior to version
   * 11.4, where static class imports (import flash.system.Worker) would
   * cause runtime errors like:
   *
   * ReferenceError: Error #1065: Variable flash.system::Worker is not defined
   *
   * This class provides dynamic access to the following classes (minimum
   * Flash Player versions noted, below which the accessors will return null)
   *
   *  flash.system.Worker - 11.4+
   *  flash.system.WorkerState - 11.4+
   *  flash.system.WorkerDomain - 11.4+
   *  flash.system.MessageChannel - 11.4+
   *  flash.system.MessageChannelState - 11.4+
   *  flash.concurrent.Condition - 11.5+
   *  flash.concurrent.Mutex - 11.5+
   *
   * So for example, where you would do this:
   *
   *   import flash.system.Worker;
   *   import flash.system.WorkerDomain;
   *
   *   if (Worker.isSupported && Worker.current.isPrimordial) {
   *     var myWorker:Worker = WorkerDomain.current.createWorker(swfbytes);
   *   }
   *
   * Instead do this:
   *
   *   import com.jcward.WorkerCompat;
   *
   *   if (WorkerCompat.workersSupported && WorkerCompat.Worker.current.isPrimordial) {
   *     var myWorker:* = WorkerCompat.WorkerDomain.current.createWorker(swfbytes);
   *   }
   */
  public class WorkerCompat
  {
    private static var _cachePrimed:Boolean = false;
    private static var _cachedWorkersSupported:Boolean;
    private static var _cached11dot5:Boolean;
    private static var _cachedWorkerClass:Class;
    private static var _cachedWorkerDomainClass:Class;
    private static var _cachedWorkerStateClass:Class;
    private static var _cachedMessageChannelClass:Class;
    private static var _cachedMessageChannelStateClass:Class;
    private static var _cachedConditionClass:Class;
    private static var _cachedMutexClass:Class;

    /**
     * Returns true iff Flash Player >= 11.4 and Worker.isSupported is true
     *
     * Will return false for Flash Player < 11.4
     * Note: Also returns false for Chrome/Windows PPAPI 11.4
     *       (Workers disabled by Google)
     */
    public static function get workersSupported():Boolean
    {
      if (!_cachePrimed) primeCache();
      return _cachedWorkersSupported;
    }

    /**
     * Accessor for Worker class
     *
     * Will return null for Flash Player < 11.4
     */
    public static function get Worker():Class
    {
      if (!_cachePrimed) primeCache();
      return _cachedWorkerClass;
    }

    /**
     * Accessor for WorkerDomain class
     *
     * Will return null for Flash Player < 11.4
     */
    public static function get WorkerDomain():Class
    {
      if (!_cachePrimed) primeCache();
      return _cachedWorkerDomainClass;
    }

    /**
     * Accessor for WorkerState class
     *
     * Will return null for Flash Player < 11.4
     */
    public static function get WorkerState():Class
    {
      if (!_cachePrimed) primeCache();
      return _cachedWorkerStateClass;
    }

    /**
     * Accessor for MessageChannel class
     *
     * Will return null for Flash Player < 11.4
     */
    public static function get MessageChannel():Class
    {
      if (!_cachePrimed) primeCache();
      return _cachedMessageChannelClass;
    }

    /**
     * Accessor for MessageChannelState class
     *
     * Will return null for Flash Player < 11.4
     */
    public static function get MessageChannelState():Class
    {
      if (!_cachePrimed) primeCache();
      return _cachedMessageChannelStateClass;
    }

    /**
     * Accessor for Condition class
     *
     * Will return null for Flash Player < 11.5
     */
    public static function get Condition():Class
    {
      if (!_cachePrimed) primeCache();
      return _cachedConditionClass;
    }

    /**
     * Accessor for Mutex class
     *
     * Will return null for Flash Player < 11.5
     */
    public static function get Mutex():Class
    {
      if (!_cachePrimed) primeCache();
      return _cachedMutexClass;
    }

    /**
     * Utility function to set a ByteArray as shareable
     *
     * Will null-op for Flash Player < 11.5
     */
    public static function setShareable(ba:ByteArray, value:Boolean=true):void
    {
      if (!_cachePrimed) primeCache();
      if (_cached11dot5) {
        Object(ba).shareable = value;
      }
    }

    private static function primeCache():void
    {
      // Init to < 11.4 state
      _cachedWorkerClass = null;
      _cachedWorkerDomainClass = null;
      _cachedWorkerStateClass = null;
      _cachedMessageChannelClass = null;
      _cachedMessageChannelStateClass = null;
      _cachedConditionClass = null;
      _cachedMutexClass = null;
      _cachedWorkersSupported = false;
      _cached11dot5 = false;

      // Try to setup Flash 11.4+ class references
      try {
        _cachedWorkerClass = getDefinitionByName("flash.system.Worker") as Class;
        _cachedWorkerDomainClass = getDefinitionByName("flash.system.WorkerDomain") as Class;
        _cachedWorkerStateClass = getDefinitionByName("flash.system.WorkerState") as Class;
        _cachedMessageChannelClass = getDefinitionByName("flash.system.MessageChannel") as Class;
        _cachedMessageChannelStateClass = getDefinitionByName("flash.system.MessageChannelState") as Class;
      } catch (e:Error) { }

      // Try to setup Flash 11.5+ class references
      try {
        _cachedConditionClass = getDefinitionByName("flash.concurrent.Condition") as Class;
        _cachedMutexClass = getDefinitionByName("flash.concurrent.Mutex") as Class;
        _cached11dot5 = true;
      } catch (e:Error) { }

      if (_cachedWorkerClass) {
        _cachedWorkersSupported = Object(_cachedWorkerClass).isSupported;
      }
      _cachePrimed = true;
    }
  }
}
