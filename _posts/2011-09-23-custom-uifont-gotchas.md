---
layout: post
title: Custom UIFont Gotchas
guid: http://justinvoss.com/2011/09/23/custom-uifont-gotchas
comments_enabled: true
---

Custom fonts are fun! Getting custom fonts to work with `UIFont` isn't always as much fun.
The tricky part that gets me every time is getting the font name right: it has little or
nothing to do with the filename of the font. How am I supposed to figure out what name to use?!
It turns out the developers at Apple are way ahead of me: the easiest way to get the 
name right it just ask the `UIFont` class what names it knows.

Thanks to [Richard Warrender's article about custom fonts on iOS][richard], I discovered the
awesome `+[UIFont familyNames]` and `+[UIFont fontNamesForFamilyName:]` methods. The first
returns a list of every font family the system recognizes. The second takes one of those family
names and returns a list of font names associated with it. The font name is the one you should
give to `+[UIFont fontWithName:size:]` to get your custom font.

You still have to do the regular "add your font file to the project and specify it in your
`Info.plist`" dance, but that's not the hard part.

Hopefully this saves you some time and frustration!


[richard]: http://richardwarrender.com/2010/08/custom-fonts-on-ipad-and-iphone/