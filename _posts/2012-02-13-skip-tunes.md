---
layout: post
title: Skip Tunes for Mac
guid: http://justinvoss.com/2012/02/13/skip-tunes
---

Last week, my latest client project went live on the App Store. I'm thrilled to (somewhat belatedly) announce [Skip Tunes][website],
a menu bar app for controlling iTunes, Rdio, and Spotify. It's on sale right now for just [$0.99 on the Mac App Store][appstore].

[Greg Dougherty][greg], my client, has done a great job getting press attention for the app.
So far, it's been mentioned on [The Unofficial Apple Weblog][tuaw], [CNET][cnet], [Lifehacker][lifehacker], 
[Cult of Mac][cultofmac], [Macworld][macworld] (3.5 out of 5 Mice) and a few other websites.
Not long after launching, it even climbed to the #1 Music app in nine different countries!

<div class="blockimage">
<img width="750" height="643" src="/static/post_assets/2012-02-13-skiptunes-website.png" alt="">
</div>

[website]: http://skiptunes.com/
[appstore]: http://bit.ly/skip-tunes-app

[greg]: http://www.gregdougherty.com/

[tuaw]: http://www.tuaw.com/2012/02/13/daily-mac-app-simple-skip-tunes-feels-like-it-should-be-part-of/
[lifehacker]: http://lifehacker.com/5882964/skip-tunes-gives-you-menu-bar-access-to-controls-for-rdio-spotify-and-itunes
[cnet]: http://howto.cnet.com/8301-11310_39-57373279-285/gain-easy-control-of-your-music-with-mac-app-skip-tunes/
[cultofmac]: http://www.cultofmac.com/146543/skip-tunes-a-simple-way-to-control-itunes-or-spotify-from-your-macs-menu-bar-review/
[macworld]: http://www.macworld.com/article/165456/2012/02/skip_tunes_is_a_simple_and_elegant_music_controller.html


Behind the Scenes
-----------------

*Warning: serious technical details ahead.*


### Chameleon

When I started working on the custom UI for the app, I tried to use the AppKit collection of classes:
`NSView`, `NSButton`, `NSTextField`, and friends. It didn't take long before I was really frustrated with
how hard it was to customize the appearance of these controls. For example, on iOS it's easy to use
a custom image as the background of a `UIButton`, you just call `setBackgroundImage:forState:`.
Using that method, you can even specify two different images: one to use normally, and another
to use when the control is actually being pressed.

Getting the same thing done with `NSButton` is not so easy.

The most straightfoward way to get a custom image is to subclass `NSButtonCell` and
override it's `drawBezelWithFrame:inView:` method, which is not at all obvious if 
you're not familiar with the way `NSControl` uses cells for drawing.
Then, for each button, you have to instruct it to use your custom 
cell class instead of the default class.
To show a different image when the button is pressed, your implementation of that 
cell method has to inspect the `isHighlighted` property to see if the user
is holding down the mouse button.
When drawing that `NSImage`, you need to make sure you use the right drawing method that respects
the flipped or non-flipped setting for the image and the graphics context.

None of the above is rocket science, but it's a lot of work for what seems like a really easy task.
(Kudos to the UIKit team for taking the opportunity to rethink and clean up these interfaces.)

Instead of wrangling all this myself, I took a shortcut and used an open
source framework called [Chameleon][].

Created by [The Iconfactory][], Chameleon is a re-implementation of a big chunk
of UIKit on top of AppKit. In a nutshell, it lets developers write iOS code
that runs on OS X.

Chameleon really shines when you want to use the same code to produce both an iOS and
a Mac app, but in this case it was worth it just to use the better APIs from UIKit.

I was able to write most of the Skip Tunes user interface
using `UIView`, `UIButton`, `UILabel`, and even `UIViewController` in addition to AppKit
classes like `NSStatusItem` and `NSWorkspace`.

[Chameleon]: http://chameleonproject.org/
[The Iconfactory]: http://iconfactory.com/

<div class="blockimage">
<img width="749" height="330" src="/static/post_assets/2012-02-13-chameleon.png" alt="">
</div>

If I had to do it over again, I think I would still use Chameleon, although I think I would
try a bit harder to get AppKit to behave. I generally don't like using cross-platform
toolkits, but in this case the result was good enough to make up for it.


### Scripting Bridge

The job of actually controlling and inspecting the media players falls onto AppleScript.
Luckily, all three apps have similar scripting interfaces, so it wasn't hard to create
an abstraction layer on top of them.

Along the way, I learned a couple of neat tricks about Scriping Bridge, which is an API
for using AppleScript from Objective-C.

To generate header files for each app, I used two command line tools: `sdef` and `sdp`.
Together, they take the scripting definition for an app and output an Objective-C `.h`
file that you can include in your app. Here's how I generated the header for iTunes:

    sdef /Applications/iTunes.app/ | sdp -fh --basename iTunes -o ~/Desktop/iTunes.h

The `basename` is used to generate some of the object names in that header file.
In the above example, the `iTunes.h` file contains classes named `iTunesApplication`,
`iTunesPlaylist`, etc.

I also learned that the `SBApplication` object, which represents your app's connection
to the scriptable app, can have a delegate that it reports errors to. This was
really helpful during development, because I could see where things were going wrong.


### Distributed Notifications

If your app needs to respond to the behaviour of other apps, the way that Skip Tunes
needs to respond to the media player starting, stopping, or changing tracks, you
need to see if `NSDistributedNotificationCenter` has the information you need.
Some apps will broadcast notifications over this channel about their state, which can
save your app from doing nasty polling.

For example, whenever the state of playback changes, iTunes publishes a
`com.apple.iTunes.playerInfo` notification on this notification center. Instead of
checking iTunes's state over Scripting Bridge every second, I just register for
this notification and wait to hear back.

If you go down this route, though, make sure to listen to `NSWorkspace` notifications,
too, since opening and closing apps doesn't usually send those state change notifications.


Go Get It!
----------

You're still here? Go [buy Skip Tunes][appstore], already!
