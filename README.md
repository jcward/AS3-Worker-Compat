AS3-Worker-Compat
=================

ActionScript Worker wrapper for compatibility with all AS3 versions of the
Flash Player (9 and later)

What does it do?
=================

The WorkerCompat wrapper simply uses dynamic-lookup to determine if the Worker
API is available and supported.  This allows SWFs compiled with this code to be
playable on all version of the Flash Player, not just those with Worker support
(11.4 and later).

This wrapper is an alternative to using static imports, which would cause a
runtime-error in Flash Player earlier than 11.4, something like:

<pre>
 An ActionScript error has occurred:
  ReferenceError: Error #1065: Variable flash.system::Worker is not defined.
</pre>

Demo / Usage
=================

See the WorkerCompatTest.as example, and the compiled <a href="http://lilcodemonkey.com/github/AS3-Worker-Compat/WorkerCompatTest.swf">WorkerCompatTest.swf</a> for
the demo.  The demo shows a red "radar-like" graphic that is generated
on-the-fly, while also running a CPU-burning while loop.

If AS3 Workers are supported, the two tasks are run on separate threads
and the graphic is a smooth fading radar (subject of course to processor
performance and other system processes.)

If AS3 Workers are not supported, both tasks are run on the same thread
(AS3 is inherently single-threaded) and the radar graphic is choppy.

<a href="http://github.com/jcward/AS3-Worker-Compat/blob/master/demo_output.png">demo_output.png</a> shows examples of both:

<img src="http://lilcodemonkey.com/github/AS3-Worker-Compat/demo_output.png"/>

Most importantly, the above demo SWF can be run on any Flash Player
version 9 or above.  Be aware, with the flexibility of dynamic class
lookup, you lose compile-time error checking.  I will investigate adding
some options for easily switching between compile-time-checking and
runtime-backward-compatibility.
