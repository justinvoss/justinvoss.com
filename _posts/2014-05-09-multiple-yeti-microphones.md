---
layout: post
title: Multiple Yeti Microphones
---

A few months ago, [I wrote about our process][bts] for recording [Low Earth Orbit][theshow].
Here's what I said about our microphone setup:

>  Our setup is pretty simple: a laptop, a Yeti microphone, and the three of us 
>  huddled around it. I have some wild idea that someday we'll each have our own 
>  mic and be sitting in real sound booths, like an honest-to-god radio show, but 
>  we haven't reached that level of crazy yet. The multiple-mic setup would be 
>  handy, though, because I think it would give us more options during editing: 
>  for example, the volume of each host's voice could be adjusted independently.

Recording the show has gotten more complex since then (we have videos now;
check out [our YouTube channel][yt]), but the multi-microphone dream has become a
reality. Now we have two Yeti microphones, and we record them simultaneously.

This wasn't easy to get configured, though. There isn't a lot of information
about this online, so I'm writing this mostly as a warning to others and as
bait for Google.

**TL;DR version: out of the box, you cannot use multiple Yeti microphones
on the same Mac.**

The longer version: it is possible, but you'll need to send one of the mics
back to Blue, the manufacturer, for a firmware update.

[bts]: http://justinvoss.com/2013/12/10/low-earth-orbit/
[theshow]: http://lowearthorbit.fm/
[yt]: http://youtube.com/lowearthshow

## The Symptoms

There are plenty of tutorials online that show you how to record multiple USB
mics at once using your Mac. They usually go something like this:

1. Plug in both microphones.
2. Open the Audio MIDI Setup app.
3. Create an Aggregate Device.
4. Add both microphones to this new aggregate.
5. In your audio recording app, select this aggregate as your input device.

Scott and I have exactly the same microphone: the [Blue Yeti][yeti].
When we tried to follow these steps, things stopped working around step 4:
only one microphone would show up in the list as an available device.
Each one worked by itself, but if we tried to use both at once, only one
would actually work.

[yeti]: http://bluemic.com/yeti/


## The Solution

USB devices may have serial numbers. For the devices that have them,
those serial numbers would ideally be unique to every individual device: a special snowflake,
no two alike.

In reality, this isn't always the case. Sometimes two devices will have the
same serial number. This may or may not be a problem. In our particular case with Yetis,
it's a problem.

If you plug a Yeti microphone into your Mac and open the System Information app,
you can actually see the serial number for yourself. Highlight the
*Yeti Stereo Microphone* entry, and you'll see a line that says something like

    Serial Number:    REV8

I tried this with both my microphone and Scott's, and they both were using
`REV8` as their serial number. Whoops! I suspect all Yeti mics use this number.

After emailing the support team at Blue, they told me they could update my
mic with a new serial number: I just needed to provide proof-of-purchase,
mail them my microphone, and they'd send it back with a new serial number.

It took a week or two, but this definitely did the trick: Blue reprogrammed
my mic to use the serial number `777`, and we've been successfully using
both microphones together ever since.

<div class="blockimage">
<img src="/static/post_assets/2014-05-09-yetis/Yeti-Serial-Numbers.png" alt="" title="">
</div>

Other models from Blue may also be affected; I've seen people online
mention very similar issues when trying to use two [Snowball][snowball] microphones
together, and I suspect it's the same underlying problem.

[snowball]: http://bluemic.com/snowball/

This problem was surprisingly hard to track down, so hopefully this helps
someone else figure out their microphone woes.
