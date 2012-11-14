package com.lilcodemonkey.workers {

  import flash.utils.getDefinitionByName;

  /**
   * This class provides dynamic (runtime-lookup) access to
   * AS3 Workers in a way that is backward compatible with Flash
   * Players prior to version 11.4, where static class imports
   * would cause runtime class definition errors.
   */
  public class WorkerCompat
  {
    private static var _cachePrimed:Boolean = false;
    private static var _cachedWorkersSupported:Boolean;
    private static var _cachedWorkerClass:Class;
    private static var _cachedWorkerDomainClass:Class;
    private static var _cachedWorkerStateClass:Class;
    private static var _xtSharedObject:Object;

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

    private static function primeCache():void
    {
      // Init to < 11.4 state
      _cachedWorkerClass = null;
      _cachedWorkerDomainClass = null;
      _cachedWorkerStateClass = null;
      _cachedWorkersSupported = false;

      // Try to setup Flash 11.4+ class references
      try {
        _cachedWorkerClass = getDefinitionByName("flash.system.Worker") as Class;
        _cachedWorkerDomainClass = getDefinitionByName("flash.system.WorkerDomain") as Class;
        _cachedWorkerStateClass = getDefinitionByName("flash.system.WorkerState") as Class;
        _cachedWorkersSupported = true;
      } catch (e:Error) { }
      _cachePrimed = true;
    }
  }
}
