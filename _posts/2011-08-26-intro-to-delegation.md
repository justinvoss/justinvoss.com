---
layout: post
title: Intro to Delegation - Core Location and Address Book UI
---

In [my article last week about target-action][target-action], I mentioned the delegate pattern as 
another common pattern in Cocoa. Apple's libraries make heavy use of delegation so you can reuse 
their code without needing to subclass the provided classes.

To illustrate how to implement delegates, I'll talk briefly about both the Core Location and
Address Book frameworks that are included in the iOS SDK.

[target-action]: http://justinvoss.com/2011/08/19/cocoa-target-action/


What is a Delegate?
-------------------

A delegate is a helper object that can react to or control events happening in another object.
For example, a `UITableView` object notifies it's delegate whenever the user taps on a row in the table,
asks it's delegate what height to use for each row, and informs the delegate when cells are edited.[^table]

[^table]: Table views in particular have two helper objects: the delegate and the datasource. The datasource is what
    the table view uses to determine what information to display, while the delegate controls almost every
    other aspect of the view.

Unlike the target-action pattern, the delegate doesn't get to choose it's own method names: they're 
defined by the class that uses it. Often the delegate is expected to implement more than one method in
order to have the most control over the other object. A common pattern is to have one method for successful
completion of a task, and another method for failure.

APIs that rely on hardware or the network often use delegation as way to provide asynchronous responses.
When using the [Core Location][corelocation] framework, your code may start a request for GPS data, but the chip 
needs a while to warm up and connect to the satellites. Instead of blocking or polling the hardware,
your code provides delegate methods that will be notified when the location data is ready to be used.

[corelocation]: http://developer.apple.com/library/ios/#documentation/CoreLocation/Reference/CoreLocation_Framework/_index.html#//apple_ref/doc/uid/TP40007123

{% highlight objectivec %}
- (void)viewDidAppear:(BOOL)animated
{
  CLLocationManager *locationManager = [[CLLocationManager alloc] init];
  locationManager.delegate = self;
  [locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)location
           fromLocation:(CLLocation *)oldLocation
{
  NSLog(@"The device's new location is: %@", location);
}
{% endhighlight %}

The `viewDidAppear:` method starts up the location framework, which abstracts away the details of the
GPS (or cell tower triangulation). The `startUpdatingLocation` method returns immediately, so your
app's main thread won't be blocked.

At some point in the future, after the framework has determined the user's location, the
`locationManager:didUpdateToLocation:fromLocation:` method will be called.[^denied] As the user moves around,
the location manager will continue to call this method on the delegate until you ask it to stop
updating the location.

[^denied]: Not only could there be several seconds between the two method calls above, but iOS will 
    ask the user for their permission before revealing their GPS location. If the user denies you, 
    the second method may never be called at all!


Side Note: Protocols
--------------------

When working with delegates, you'll hear a lot about Objective-C protocols. In a nutshell, a protocol is
a lot like an interface in other object-oriented languages. Some methods may be required, others may
be marked as optional.

To declare that your class conforms to a particular protocol, you put the name of the protocol in 
angle brackets after the superclass name.

{% highlight objectivec %}
@interface AddContactDelegate : NSObject <ABPeoplePickerNavigationControllerDelegate> {
    NSMutableArray *contacts;
}

@end
{% endhighlight %}


The Address Book UI
-------------------

If your app needs to interact with the user's contact list, you can access the data programmatically using
the [Address Book and Address Book UI frameworks][ab-docs]. The first is designed to give your app access to the
underlying contact data. The second is a set of pre-built views and interface elements for displaying,
editing, and choosing contacts.

[ab-docs]: http://developer.apple.com/library/ios/#documentation/ContactData/Conceptual/AddressBookProgrammingGuideforiPhone/Introduction.html#//apple_ref/doc/uid/TP40007744

When displaying the Address Book UI views, your code participates by setting itself as a delegate of the
Apple-provided views. As the user makes their selections, your delegate will be notified and have the
opportunity to affect the workflow.

To prompt the user to choose a property (like phone number) for a contact, you have to create an `ABPeoplePickerNavigationController`
and give it a delegate. In [Photo Dialer][photo-dialer]'s case, that delegate is a `AddContactDelegate`.
Here's the actual code that one of the view controllers uses to present the UI:

[photo-dialer]: http://bit.ly/photo-dialer

{% highlight objectivec %}
// a long time ago, in a view controller far, far away

- (IBAction)addContact:(id)sender
{
    ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
    [picker setDisplayedProperties:[NSArray arrayWithObject:[NSNumber numberWithInt:kABPersonPhoneProperty]]];
    picker.peoplePickerDelegate = [[AddContactDelegate alloc] init];
    [self presentModalViewController:picker animated:YES];
}

{% endhighlight %}

The actual display of the user's contacts, and managing the stack of views involved, is handled entirely
by Apple's code. The only time Photo Dialer has to worry about it is in the delegate methods. As the user
selects a contact, selects a phone number, or presses "cancel", the delegate is notified.

After some of the methods, the delegate can tell the UI to stop allowing the user to drill down. This
doesn't dismiss the view, however: you still have to manually remove it from the screen.

{% highlight objectivec %}

#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>


@implementation AddContactDelegate

- (id)init
{
    if(self = [super init]) {
        contacts = [[[ContactDataLoader sharedLoader] loadContactData] retain];
    }
    return self;
}

- (void)dealloc
{
    [contacts release];
    [super dealloc];
}

#pragma mark - People Picker

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
    [peoplePicker dismissModalViewControllerAnimated:YES];
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
    return YES;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker 
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
                                property:(ABPropertyID)property 
                              identifier:(ABMultiValueIdentifier)identifier
{
    
    PDContact *newContact = [PDContact contactFromABRecord:person identifier:identifier];
    [contacts addObject:newContact];
    [[ContactDataLoader sharedLoader] saveContactData];
    [peoplePicker dismissModalViewControllerAnimated:YES];
    
    return NO;
}

@end

{% endhighlight %}

The specifics of what all the Address Book objects represent isn't important, except that an
`ABRecordRef` represents a particular person, and the `ABMultiValueIdentifier` specifies which
of potentially many phone numbers the user tapped on.

By wrapping these views in a reusable class and providing a mechanism for a delegate to participate,
Apple has allowed us to remove a lot of code that we would normally have to write ourselves.


Delegating in Your Code
-----------------------

When designing your own objects, take a minute to consider if the app-specific features could be
implemented by a delegate, leaving reusable code in the original class. For example, if your app uses
WebSockets to connect to a live stream of data, split the WebSocket-specifics into a generic class that
delegates to an app-specific class. You might find that with just a few delegate methods, most of 
the code can be reused in another app without changes: just give it a different delegate.

When using a delegate from your class, keep a few tips and tricks in mind:

* Don't retain the delegate. Most of Apple's classes don't, so users of your code will be surprised
  with an ugly memory leak if yours does.
* The first argument to each delegate method should be the object that triggered the call. It seems
  redundant now, but as soon as you need to handle two objects with the same delegate, you'll be glad
  you added it.
* Consider defining the required methods in a protocol. It's a bit more work up front, but then 
  the compiler will be able to help you spot any omissions.
* If you don't use a protocol, or have optional methods in your protocol, make sure to use
  `respondsToSelector:` to make sure the delegate supports the method you're about to call.


Next Week
---------

What do you want to read for next Friday's article? I'm thinking either data sources, or diving
into something more advanced, like working with REST APIs or Bonjour networking. Cast your vote
for next week's topic in the comments!

