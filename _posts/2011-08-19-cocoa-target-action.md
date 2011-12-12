---
layout: post
title: Cocoa's Target-Action Pattern
---

Despite being a thin wrapper on top of C, Objective-C has dynamic features that make it
feel more like a peer to Ruby than to C++. In this short article, I'll introduce one of
those features and show you how to use it in your code to reduce coupling and increase reuse.


Selectors
---------

A selector is essentially the name of an Objective-C method, realized as an object in code.
It has the type `SEL`, which is a primitive (no memory management needed).
The actual contents of the selector are opaque, but you can get one from a method name with
the `@selector()` syntax.


{% highlight objectivec %}

SEL setToolbar = @selector(setToolbarItems:animated:);

{% endhighlight %}


You can also get a selector from an NSString. This is handy if you want to store the selector
in a config file.


{% highlight objectivec %}

SEL setToolbar = NSSelectorFromString(@"setToolbarItems:animated:");

{% endhighlight %}


Using Selectors
--------------------

Once you have the selector, there's a few things you can do with it.

You can ask an object if it responds to that selector; this is like asking if the object
implements this method. If you've ever done reflection in Java, prepare for a breath of
fresh air!

{% highlight objectivec %}

if ([controller respondsToSelector:@selector(setToolbarItems:animated:)]) {
  /* it's possible to set toolbar items on this controller */
}

{% endhighlight %}


You can ask an object to perform that selector:

{% highlight objectivec %}

// direct
[controller viewDidLoad];

// indirect
SEL action = @selector(viewDidLoad);
[controller performSelector:action];

{% endhighlight %}


This is the same as calling the method directly, but because the selector could come from a
variable, it's possible to change the method at runtime.

For example, `UIBarButtonItem` uses a target and action to call your code when the button is tapped.
You might have some code in your view controller like this:


{% highlight objectivec %}

- (void)viewDidLoad
{
  
  button = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                            style:UIBarButtonItemStyleBordered
                                           target:self
                                           action:@selector(doneButtonHit:)];
  // more code
}

- (void)doneButtonHit:(id)sender
{
  NSLog(@"The done button was tapped!");
}

{% endhighlight %}


When you run the app and tap on the button, you'll see "The done button was tapped!" in the console.
It's as if the button has a line of code like `[controller doneButtonHit:self]`, but obviously it
doesn't: the button is a generic object that you can use off-the-shelf. The secret sauce is `performSelector`!

This pattern, called "target-action", is used throughout Cocoa, especially in user interface code.
It allows the UI widgets to stay generic, while making it easy to integrate your custom controller
without needing to subclass anything.


Implementing Target-Action
--------------------------

Let's write a really simple object that implements the target-action pattern. We'll call it a button,
but we'll skip writing any view-related code. For simplicity, let's assume that when the user taps
on the button, the button will receive the `tap` message.

Here's our interface.

{% highlight objectivec %}

@interface JVButton : NSObject {
  id _target;
  SEL _action;
}

- (void)initWithTarget:(id)target action:(SEL)action;

- (void)tap;

@end

{% endhighlight %}


And here's the implementation.


{% highlight objectivec %}

@implementation JVButton

- (void)initWithTarget:(id)target action:(SEL)action
{
  self = [super init];
  if (self) {
    _target = target;
    _action = action;
  }
  return self;
}

- (void)tap
{
  [_target performSelector:_action withObject:self];
}

@end

{% endhighlight %}


The init method is simple, just some vanilla setup. We store the target and action for later. Notice
that we don't retain the target.

In the `tap` method, we ask the target to perform the action. We also pass the button as an argument to
the action. There's a bunch of variations on the basic `performSelector:` method to help with things
like passing arguments or delaying before performing: check Apple's documentation for all of them.

The controller wired up to this button might look like this:


{% highlight objectivec %}

- (void)viewDidLoad
{
  button = [[JVButton alloc] initWithTarget:self action:@selector(customButtonTapped:)];
}

- (void)customButtonTapped:(id)sender
{
  NSLog(@"The custom button was tapped!");
}

{% endhighlight %}


If you look back at the example with `UIBarButtonItem`, you'll see that they're almost identical!
Mimicking Apple's code is easier than it sounds, right? :)


When to Use Target-Action
-------------------------

The best time to reach for this pattern is when:

 * You need or want one object to stay generic (e.g., the button class) but be able to call into custom code.
 * The generic object has exactly one action to perform (e.g., being tapped).

If the generic object has more than one action to perform, or needs to collect information from your custom code,
your problem is probably better solved with the delegate pattern or the data source pattern.
I'll cover those in later articles.

