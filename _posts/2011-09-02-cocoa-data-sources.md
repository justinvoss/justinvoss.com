---
layout: post
title: Creating and Consuming Data Sources in UIKit
guid: http://justinvoss.com/2011/09/02/cocoa-data-sources
---

By popular demand in the comments from [last week's article on delegates][last-week],
this week's article is about data sources.
I'll talk about what a data source is, why UIKit uses them, and how you can write
your own views that consume data sources.

[last-week]: http://justinvoss.com/2011/08/26/intro-to-delegation/


What is A Data Source?
----------------------

A data source is a species of delegate. It's a separate object that provides data to
another according to a defined standard. That standard can be formal, like an Objective-C
protocol, but doesn't need to be.

The most common UIKit class that consumes data sources is [UITableView][]. Typically, the view
controller of a particular screen will be both the delegate and the data source for a 
UITableView that takes up most or all of screen. This pattern is so common, in fact, that
Apple includes a view controller class called [UITableViewController][] that does all this
wiring for you!

[UITableView]: https://developer.apple.com/documentation/uikit/uitableview
[UITableViewController]: https://developer.apple.com/documentation/uikit/uitableviewcontroller


To provide data to the table view, the data source implements at least these methods:

{% highlight objectivec %}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{% endhighlight %}

The first method, `tableView:numberOfRowsInSection:`, is called by the table view to
determine how many rows are in the section with the given index. By default, a table view
has only one section, so in the simplest case the `section` argument will always be zero.[^sections]
The data source should consult whatever data it has and return the number of rows the
table view should display.

[^sections]: If you need to have more than one section, the `numberOfSectionsInTableView:` will 
    let you control how many are displayed. The `tableView:numberOfRowsInSection:` will be called
    once for each section.

The second method, `tableView:cellForRowAtIndexPath:`, is how the table view will determine
what content to display for a particular row in the table. The object returned here is an
instance of `UITableViewCell`, which is a fully-fledged `UIView` subclass.
The `indexPath` argument is essentially a list of integers that describes the section and
row that the table view needs a cell for. To get the individual values, call the `section`
and `row` methods:[^indexpath]

[^indexpath]: The `section` and `row` methods actually aren't in the default implementation of
    `NSIndexPath`: they're added by a UIKit category. These two helper methods are just
    wrappers around the `indexAtPosition:` method.

{% highlight objectivec %}
NSUInteger section = [indexPath section];
NSUInteger row = [indexPath row];
{% endhighlight %}

The actual implementation of `tableView:cellForRowAtIndexPath:` is specific to the data you
want to display. As an extremely simple example, here's what it might look like if you wanted
a plain table view and your data is simply an array of strings, in the `names` attribute.

{% highlight objectivec %}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSString *currentName = [self.names objectAtIndex:indexPath.row]
    cell.textLabel.text = currentName;
    
    return cell;
}
{% endhighlight %}

The business with `dequeueReusableCellWithIdentifier:` is a caching mechanism that `UITableView`
uses to avoid creating more cells than is strictly necessary. Since only a handful of cells will
ever be on-screen at any given instant, there's no reason to create any more than a handful of cell
objects. As soon as a cell moves off-screen, it becomes reusable as a cell that's about to come on-screen.


The Reason for Data Sources
---------------------------

You might be thinking that this seems like overkill. Why create a separate object and two separate
methods for controlling some cells in a list?

The biggest reason is performance. For a small amount of data, the benefits of using the data source pattern
won't be clear. But look at how many songs are in your iTunes library on your iDevice (you can see the
total in Settings > General > About). Right now, I have 1,297 songs on my iPhone. When I tap on the Songs
tab in the iPod app, only about eight rows are on-screen at a time. If every song was loaded in-memory, 1,289
of them would be wasted space because the user can't see them.

Instead, the only pieces of information that need to be calculated are:

* How many total songs are there?
* What are the first eight?

The total is an easily-cached number, since the music library on iOS is relatively static, and the first few rows
are quick to look up in SQLite.[^sqlite]

[^sqlite]: That's assuming, of course, that the library data is in a SQLite database. It very well may not be, I
    don't know. The data in your own apps probably will be, since that's one of the storage backends Core Data uses.
    
Besides the memory usage issues, it may be that not all of the data is known at the time that the table view needs to
be displayed. If each row has an image that needs to be downloaded from a web server, you obviously may not want to
fetch all the images up front: it would be wiser to wait until that particular row is on-screen before starting
the download.

Obviously, not every view in UIKit uses data sources: simple views like `UIImageView` just have a property that represents
the data they need to display. Even a view as complex as [`MKMapView`][mkmapview] doesn't use a data source: each pin on the map
is added manually with `addAnnotation:` or in bulk by setting the `annotations` property.[^mapview]
The right time to reach for the data source pattern is when performance is an issue and the data lends itself well to
being loaded piece-by-piece.

[mkmapview]: https://developer.apple.com/documentation/mapkit/mkmapview

[^mapview]: According to Apple's documentation, you should add all the annotations at once, even if they're not on-screen.
    As the user moves the map around, the map view will notify the delegate and ask it to create the pin views as-needed.
    So you could consider this a hybrid model of delegation and using a data source.

Besides performance, separating the presentation of the data from the mechanics of loading it is just good engineering.
The view only needs to know how to display the data. Where it comes from and how much of it is loaded is outside the 
scope of that the user interface needs to worry about.


Consuming Data Sources
----------------------

While writing your app, you may want to create a view that has the same constraints as a table view: it needs to 
potentially display a lot of data, but only a fraction of it will be needed at any given moment. Sounds like a job for
a data source!

The first step is to back away from the code and head for the whiteboard. Figure out your strategy for how the view
will interact with the data source; this will be different for every situation. When Kyle and I wrote the grid view
in Kowabunga, called `LOGridView`, we decided to use a data source because we knew that at some point we would want multiple pages of
icons. Our strategy was to create a simplified version of the `UITableView` data source. The two methods are:


{% highlight objectivec %}
- (NSUInteger)numberOfCellsInGridView:(LOGridView *)gridView;
- (LOGridViewCell *)gridView:(LOGridView *)gridView cellForObjectAtIndex:(NSUInteger)index;
{% endhighlight %}

The similarity between this and a table view data source should be obvious. The first method alone is enough for
the grid view to calculate how many pages of icons will be needed: it just divides the total by twelve, rounded up.

As each page of icons comes on-screen, the grid view asks the data source for more cells. The first page asks for
cells 0-11, the second pages asks for cells 12-23, etc.

After the grid view has been put on-screen and the data source is wired up, we call `reloadData` on the grid view
to start laying out the grid. Each page in the view is an instance of `LOGridViewPage`, which is a private class
that `LOGridView` uses to organize the cells. Each page has it's own `reloadData` method, which is called on
 each page as it's displayed:

{% highlight objectivec %}
// LOGridViewPage.m

- (void)reloadData
{
    // remove all the pre-existing cells
    [__cells makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [__cells removeAllObjects];
    
    if(__cells == nil) {
        __cells = [[NSMutableArray alloc] initWithCapacity:(self.endIndex - self.startIndex)];
    }
    
    for(NSUInteger index = self.startIndex; index < self.endIndex; index++) {

        LOGridViewCell *cell = [self.dataSource gridView:self.gridView cellForObjectAtIndex:index];
        cell.frame = [self frameForCellAtIndex:index];
  
        UITapGestureRecognizer *gesture = [[[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                   action:@selector(cellWasTapped:)] autorelease];
        [cell addGestureRecognizer:gesture];
        
        [__cells addObject:cell];
        
        [self addSubview:cell];		
    }
}
{% endhighlight %}

The heart of the method is the loop, where we load only the cells we need for this particular page. Each page
has attributes for the grid view, the data source, and the start and end indices, so it has enough information
to build up its grid of icons.

Your view will need a similar method, although the way you determine what to display and how you ask for it will
be different. Maybe instead of discrete pages, like Kowabunga, your app has a more fluid layout like `UITableView`.
In that case, you may need to calculate the start and end indices based on what's on-screen.

In general, you'll need to understand both how the data is retrieved and how it's displayed before you can determine
the right way to coordinate the two.


Until Next Time
---------------

That's it for this week. Leave a comment below if I glossed over any details or made any mistakes (as if that ever happens...)

Let me know what you want to read about next week! I might change gears and talk about a non-Cocoa topic, like Django
or Coffeescript. It's up to you!
