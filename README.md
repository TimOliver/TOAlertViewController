# TOAlertViewController

<img src="https://raw.githubusercontent.com/TimOliver/TOAlertViewController/master/screenshot.jpg" width="600" align="right" alt="TORoundedButton" />


[![Actions Status](https://github.com/TimOliver/TOAlertViewController/workflows/CI/badge.svg)](https://github.com/TimOliver/TOAlertViewController/actions)
[![Version](https://img.shields.io/cocoapods/v/TOAlertViewController.svg?style=flat)](http://cocoadocs.org/docsets/TOAlertViewController)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/TimOliver/TOAlertViewController/master/LICENSE)
[![Platform](https://img.shields.io/cocoapods/p/TOAlertViewController.svg?style=flat)](http://cocoadocs.org/docsets/TOAlertViewController)
[![PayPal](https://img.shields.io/badge/paypal-donate-blue.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=M4RKULAVKV7K8)
[![Twitch](https://img.shields.io/badge/twitch-timXD-6441a5.svg)](http://twitch.tv/timXD)

`TOAlertViewController` is a custom re-implementation of `UIAlertController` with a much more modern visual design. It features a large bold title
and rounded action buttons in line with the more modern design language of iOS that started appearing since 2017.

# Features

* A much more modern look and field than the native `UIAlertController` class (As of iOS 13).
* Includes theming for default, and destructive action buttons.
* Provides an optional dark mode appearance.
* Smooth presentation and dismissal animations.
* Uses `UIVisualEffectView` to produce a subtle 'depth-of-field' effect when presented.

# Examples

`TOAlertViewController` features a complete default configuration useful for most app instances, but can be easily modified beyond that.

```objc

    TOAlertViewController *alertController = [[TOAlertViewController alloc]
                                              initWithTitle:@"Are you sure?" message:@"This action may take some time to complete. Are you sure you wish to perform this action?"];

    alertController.defaultAction = [TOAlertAction alertActionWithTitle:@"Yes" action:^{ NSLog(@"Default Button Tapped!"); }];
    alertController.cancelAction = [TOAlertAction alertActionWithTitle:@"Cancel" action:^{ NSLog(@"Cancel Button Tapped!"); }];

    [self presentViewController:alertController animated:YES completion:nil];

```

# Requirements

`TOAlertViewController` will work with iOS 11 and above. While written in Objective-C, it will easily import into Swift.
It also requires the [`TORoundedButton`](https://github.com/TimOliver/TORoundedButton) library to be installed in your app.

## Manual Installation

Copy the contents of the `TOAlertViewController` folder to your app project. 
Download a copy of [`TORoundedButton`](https://github.com/TimOliver/TORoundedButton) and also be sure to install that into your project as well.

## CocoaPods

CocoaPods automatically manages importing `TORoundedButton` itself.

```
pod 'TOAlertViewController'
```

## Carthage

```
github "TimOliver/TORoundedButton"
github "TimOliver/TOAlertViewController"
```

# Credits

`TOAlertViewController` was created by [Tim Oliver](http://twitter.com/TimOliverAU) as a component of [iComics](http://icomics.co).

The iOS device mockup art was also created by Tim Oliver and is [available on Dribbble](https://dribbble.com/shots/1129682-iPod-touch-5G-PSD-Template).

# License

`TOAlertViewController`  is available under the MIT license. Please see the [LICENSE](LICENSE) file for more information. ![analytics](https://ga-beacon.appspot.com/UA-5643664-16/TOAlertViewController/README.md?pixel)
