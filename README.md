AS3-Worker-Compat
=================

ActionScript Worker wrapper for compatibility with all AS3 versions of the
Flash Player (9 and later)

<b>NEW:</b> v0.2.1 includes AsyncScheduler and JPEGEncoder demo

About
=====

What it does
------------

The WorkerCompat wrapper simply uses dynamic-lookup to determine if the Worker
API is available and supported.  This allows SWFs compiled with this code to be
playable on all version of the Flash Player, not just those with Worker support
(11.4 and later).

As such, it also allows you to use an older compiler (Flash CS6, older version
of Flash Builder or Flex, etc) to take advantage of Workers.

Features
========

* v0.1
  * WorkerCompat - backward-compatible Worker wrapper
* v0.2
  * XTSharedObject - dead-simple cross-thread data sharing
* v0.2.1
  * AsyncSchedule - asynchronous scheduler utility
  * JPEGEncoder - Adobe lib with new pseudo-threaded encodeAsync() method
  * JPEGEncoderTest - Demo showing the use of JPEGEncoder

See <a href="https://github.com/jcward/AS3-Worker-Compat/edit/master/README.md#feature-details">Feature Details</a> below for more info.

Demos
=====

The demos showcase various aspects of the AS3-Worker-Compat library.  All will run
in all versions of the Flash Player, and run via the use of Workers when supported,
falling back to pseudo-thread techniques when not.

WorkerCompatTest
----------------

The WorkerCompatTest demo shows a red "radar-like" graphic that is generated on-the-fly,
while also running a CPU-burning while loop.  This demo SWF works in all Flash
Player versions.

<a href="http://jcward.com/github/WorkerCompatTest_v0.2.1/WorkerCompatTest.swf">Try it now in your browser</a>.

If AS3 Workers are supported, the two tasks are run on separate threads
and the graphic is a smooth fading radar.

If AS3 Workers are not supported, both tasks are run on the same thread
(AS3 is inherently single-threaded) and the radar graphic is choppy -
intentionally, for demonstrative purposes.  In a real-world application
you'd attempt to balance your background logic to leave the UI as smooth
as possible even without Workers.

Here's a screenshot of the demo in two browsers, one supporting Workers and
the other not.

<img width="400" src="http://jcward.com/github/WorkerCompatTest_v0.2.1/screenshot.png"/>

JPEGEncoderTest
---------------

The JPEGEncoderTest demo compares various JPEG encoding schemas:
* synchronous native encoding (when supported, FP 11.3+)
* synchronous encoding
* asynchronous encoding utilizing the AsyncScheduler class
  * Using AsyncScheduler.LOW, MEDIUM, and HIGH priorities

<a href="http://jcward.com/github/JPEGEncoderTest_v0.2.1/JPEGEncoderTest.swf">Try it now in your browser</a>.

Here's a screenshot of the demo in two browsers, one supporting Workers and
the other not.  Noteice that with Worker support, asynchronous JPEG encoding
does not reduce UI framerates.

<img width="400" src="http://jcward.com/github/JPEGEncoderTest_v0.2.1/screenshot.jpg"/>

Feature Details
===============

What it doesn't do
------------------

There's no magic - if your SWF is running in an environment without Worker
support, there will still be UI blocking and pseudo-threading.  You'll need
to write your application with this in mind to handle either case.  However,
using this library you'll get the peace of mind that:
 * your SWF will run on all Flash Players (and even compile to AIR for
   mobile, which also doesn't support Workers), and
 * it'll simply take advantage of Worker threads when they're available.

Also, be aware when using dynamic/runtime class lookup, you don't get
compile-time type checking on those classes (Worker, WorkerDomain, etc).
However, when building the demos, I found that I didn't use those classes
at all but to instantiate my worker.  After that, it's all application logic.

What's New in v0.2.1
--------------------

This release brings a utility, AsyncScheduler, that makes converting synchronous, loop-based
algorithms (like JPEG encoding) into asynchronous, pseudo-threadable
algorithms easy.  Pseudo-threads are a must if you're going to support older,
non-threading Flash Players, but it's not a bad idea to write asynchronous
code even when utilizing Workers.  It allows a single background thread to
service many tasks simultaneously.

Consequently, a new demo, JPEGEncoderTest, is new in v0.2.1 showcasing this
new functionality.  The standard JPEGEncoder library by Adobe was ported to
asynchronous code using the AsyncScheduler.async helper function.

In WorkerCompatTest I also updated the code to better reflect that doGuiWork
should be responsible for setting up the stage (not necessarily the constructor,
since that's shared with the background worker).

Oh, I also changed the library namespace from com.lilcodemonkey to com.jcward -
hope that didn't perturb anyone.  :)

What's New in v0.2
------------------

The major new feature in v0.2 is XTSharedObject.  If your first concern is a
SWF that plays in all Flash Players, your second concern is how to easily get
your threads communicating together.

XTSharedObject is a dead-simple Object that's shared between all threads,
again, coded to work the same whether the Flash Player supports Workers or
not.  There are usage requirements / gotchas at the top of the comments in
XTSharedObject.as, and the WorkerCompatTest demo now uses it to pass a count
value from the background worker to the foreground.

While being incredibly easy to use, XTSharedObject is not the most performant
way to share data between threads - if you're passing around large chunks of
data you should use shared ByteArrays (available in FP 11.5+) - maybe I'll
add such support later.

What's New in v0.1
------------------

The initial release, v0.1 introduced the WorkerCompat wrapper.  It contains
the dynamic class lookup calls which are the basis of detecting the Worker
API regardless of Flash Player version.

This wrapper is an alternative to using static imports, which would cause a
runtime-error in Flash Players earlier than 11.4, something like:

<pre>
 An ActionScript error has occurred:
  ReferenceError: Error #1065: Variable flash.system::Worker is not defined.
</pre>

Usage / Conversion
==================

Using WorkerCompat is as simple as changing these hard-coded worker references:

<pre>
  import flash.system.Worker;
  import flash.system.WorkerDomain;

  ...

  if (Worker.isSupported && Worker.current.isPrimordial) {
    var myWorker:Worker = WorkerDomain.current.createWorker(swfbytes);
  }
</pre>

To this:

<pre>
  import com.jcward.WorkerCompat;

  ...

  if (WorkerCompat.workersSupported && WorkerCompat.Worker.current.isPrimordial) {
    var myWorker:* = WorkerCompat.WorkerDomain.current.createWorker(swfbytes);
  }
</pre>

License (FreeBSD)
=================

Copyright (c) 2012, Jeff Ward
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met: 

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer. 
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution. 

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those
of the authors and should not be interpreted as representing official policies, 
either expressed or implied, of the FreeBSD Project.
