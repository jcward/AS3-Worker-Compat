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
    /**
     * Accessor for Worker class
     *
     * Will return null for Flash Player < 11.4
     */
    public static function get Worker():Class
    {
      try { return getDefinitionByName("flash.system.Worker") as Class; }
      catch (e:Error) { }
      return null;
    }

    /**
     * Accessor for WorkerDomain class
     *
     * Will return null for Flash Player < 11.4
     */
    public static function get WorkerDomain():Class
    {
      try { return getDefinitionByName("flash.system.WorkerDomain") as Class; }
      catch (e:Error) { }
      return null;
    }

    /**
     * Accessor for WorkerState class
     *
     * Will return null for Flash Player < 11.4
     */
    public static function get WorkerState():Class
    {
      try { return getDefinitionByName("flash.system.WorkerState") as Class; }
      catch (e:Error) { }
      return null;
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
      try { return getDefinitionByName("flash.system.Worker").isSupported; }
      catch (e:Error) { }
      return false;
    }
  }

}
