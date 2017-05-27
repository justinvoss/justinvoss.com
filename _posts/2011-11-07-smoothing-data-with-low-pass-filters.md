---
layout: post
title: Smoothing Data with Low-Pass Filters
guid: http://justinvoss.com/2011/11/07/smoothing-data-with-low-pass-filters
---

I should have paid more attention in my math classes.
There's actually a lot of neat things you can do with a good working knowledge of math: 
I've started to go back over the material I should have learned in college and
I'm trying to apply it to programming.

One handy trick is an algorithm called a [low-pass filter][].
This basically takes a stream of data and filters out everything but the low-frequency signal.
Effectively, this "smooths" out the data by taking out the jittery, high-frequency noise.

[low-pass filter]: http://en.wikipedia.org/wiki/Low-pass_filter

Like I said before, my math skills are weak, but looking at the algorithmic implementation on
Wikipedia it seems like it's basically a weighted average: some of the data is from the previously
filtered value, and some of the data is from the raw stream.
Here's my breakdown of what each piece means:

* The `alpha` value determines exactly how much weight to give the previous data vs the raw data.
* The `dt` is how much time elapsed between samples.
* I don't totally understand what the `RC` value is for, but by playing with it's value it's possible to control the aggressiveness of the filter:
  bigger values mean smoother output.


Demo Time: Fun with the Accelerometer
-------------------------------------

So, how can we apply this to something useful?

If you haven't already seen [GitHub's 404 page][gh404], go take a look:
make sure you move your mouse around the page.
See how the images move around in parallax? 
If you visit the same page on your smartphone, it can even use the accelerometer
in your device to make the images move.

[gh404]: https://github.com/404

I thought it would be neat to replicate the effect in a native iOS app.
Grabbing data from the accelerometer and shifting the views around is pretty
easy, but the result is poor.
The accelerometer is way too sensitive to small movements, and it makes the app
feel over-caffeinated.

Low-pass filtering to the rescue!

Here's a before-and-after video. Each version of the app is using the same recorded
accelerometer data, running in a 10-second loop. The version on the left is using
the raw data, while the version on the right is using data run through a low-pass filter.

The results should speak for themselves: the filtered data is a little slower to react,
but moves smoothly and deliberately. The raw data jumps and twitches too much for comfort.

<div class="blockimage" style="position: relative; width: 100%; height: 0; padding-bottom: 74.96%">
  <iframe style="position: absolute; top: 0; left: 0; width: 100%; height: 100%" src="http://player.vimeo.com/video/31734175?portrait=0" frameborder="0" webkitAllowFullScreen="true" allowFullScreen="true"> </iframe>
</div>


Show Me the Code!
-----------------

First things first, let's get some accelerometer data.
I put this in my view controller's `viewWillAppear:` method.

{% highlight objectivec %}
NSOperationQueue *accelerometerQueue = [NSOperationQueue mainQueue];
self.motionManager = [[CMMotionManager alloc] init];
[self.motionManager setAccelerometerUpdateInterval:(1.0 / 20)];
[self.motionManager startAccelerometerUpdatesToQueue:accelerometerQueue withHandler:^(CMAccelerometerData *data, NSError *error) {
    [self updateViewsWithFilteredAcceleration:data.acceleration];
}];
{% endhighlight %}


The `updateViewsWithFilteredAcceleration:` does the actual filtering.

{% highlight objectivec %}
- (void)updateViewsWithFilteredAcceleration:(CMAcceleration)acceleration
{
    static CGFloat x0 = 0;
    static CGFloat y0 = 0;
    
    const NSTimeInterval dt = (1.0 / 20);
    const double RC = 0.3;
    const double alpha = dt / (RC + dt);
    
    CMAcceleration smoothed;
    smoothed.x = (alpha * acceleration.x) + (1.0 - alpha) * x0;
    smoothed.y = (alpha * acceleration.y) + (1.0 - alpha) * y0;
    
    [self updateViewsWithAcceleration:smoothed];
    
    x0 = smoothed.x;
    y0 = smoothed.y;
}
{% endhighlight %}


And finally, the `updateViewsWithAcceleration:` method actually moves the center points of the views.

{% highlight objectivec %}
- (void)updateViewsWithAcceleration:(CMAcceleration)acceleration;
{
    CGPoint center = self.view.center;
    const CGFloat maxOffset = 200;
    
    CGPoint frontCenter  = CGPointMake(center.x - (+1.0 * maxOffset * acceleration.x),
                                       center.y + (+1.0 * maxOffset * acceleration.y));

    CGPoint middleCenter = CGPointMake(center.x - (+0.2 * maxOffset * acceleration.x),
                                       center.y + (+0.2 * maxOffset * acceleration.y));
    
    CGPoint backCenter   = CGPointMake(center.x - (-1.0 * maxOffset * acceleration.x),
                                       center.y + (-1.0 * maxOffset * acceleration.y));    
    
    self.frontView.center = frontCenter;
    self.middleView.center = middleCenter;
    self.backView.center = backCenter;
}
{% endhighlight %}


Pretty simple, right? The math isn't that bad, and it gives us a great result.
This is just a small example of what real math can do for your app.
In the next few months, I'll try to do some more posts about using advanced math
and statistics to make more intelligent systems.

If anyone's interested, I can do a follow-up post about how I recorded the accelerometer for playback later.


