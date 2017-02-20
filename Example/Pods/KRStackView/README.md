# KRStackView

[![CI Status](http://img.shields.io/travis/Joshua Park/KRStackView.svg?style=flat)](https://travis-ci.org/Joshua Park/KRStackView)
[![Version](https://img.shields.io/cocoapods/v/KRStackView.svg?style=flat)](http://cocoapods.org/pods/KRStackView)
[![License](https://img.shields.io/cocoapods/l/KRStackView.svg?style=flat)](http://cocoapods.org/pods/KRStackView)
[![Platform](https://img.shields.io/cocoapods/p/KRStackView.svg?style=flat)](http://cocoapods.org/pods/KRStackView)

## Intro
**KRStackView** arranges subviews like `UIStackView`, but supports earlier iOS versions and both auto-resizing and auto layout.

Subviews of a **KRStackView** instance will be arraged according to its `direction` property, so it's no longer necessary to do complicated calculation to set subviews' `origin`.

Also, as long as the subviews' `size` property are set properly, a **KRStackView** instance will automatically fit its' size to embrace all its subviews.

Laying out views can be as easy as defining origin of the **KRStackView** instance and setting the sizes of subviews. Other arrangments will be taken care of.

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

**KRStackView** can be used with auto resizing as well as auto layout.

## Installation

KRStackView is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "KRStackView"
```

## Usage
When using both programmatically and in the interface builder, the `size` of the `KRStackView` instance doesn't matter as much as the `origin` because it will grow its `bounds` according to the sizes of its subviews.

Also, the `origin` properties of each subview won't matter since they will be arranged according to the properties of the `KRStackView` instance. Just make sure to set the `size` properties accurately, and also the order in which they should be laid out.

##### Programmatically
Simply declare an instance of `KRStackView` and add subviews to it. Further customize by setting various properties as described below.
``` swift
// Using `init()`
let stackView1 = KRStackView()
stackView1.addSubview(view1)
stackView1.addSubview(view2)

// Using `init(frame:subviews:)`
let stackView2 = KRStackView(frame: CGRectZero, subviews:[view1, view2])
```

##### Interface Builder
Drag `UIView` from the `Object Library` and change the custom class to `KRStackView` in the `Identity Inspector`.

Add subviews into `KRStackView` like you would for `UIView` objects.

## Properties

> @IBInspectable public var enabled: Bool = true

Set this property to `false` if you want a normal `UIView`-like subview layout. Dynamically changing this property to `true` will result in a dynamic layout change.

The default value is `false`.

> public var direction: StackDirection = .Vertical

`KRStackView` arranges subviews according to the `direction` property, ignoring their initial `origin`. Dynamic changes will be reflected.

The default value is `.Vertical`. Possible values are `.Vertical` and `.Horizontal`.

> @IBInspectable public var translatesCurrentLayout: Bool = false

Set this property to `true` if you want the initial origins of subviews to be translated to their respective `KRStackView` properties.

This property can be used when you want the functionality of `KRStackView`s with existing `UIView`s or want the initial layout to be preserved but the view's layout can be changed dynamically.

The default is `false`. Also, this property is automatically set to `false` after `layoutSubviews()` is called.

> public var insets: UIEdgeInsets = UIEdgeInsetsZero

Insets will be based on the outer most bounds of subviews. This property is ignored if `translatesCurrentLayout` is set to `true`.

The default value is `UIEdgeInsetsZero`.

> @IBInspectable public var spacing: CGFloat = 8.0

This property defines the spacing between subviews. Use this property if all the subviews in the `KRStackView` instance should be spaced out evently.

The default value is `8.0`. This property is overridden if the `itemSpacing` is a non-nil value.

> public var itemSpacing: [CGFloat]?

This property defines the individual spacing between subviews. Each value is the spacing after the corresponding view in the `subviews` array, i.e. `itemSpacing![n]` is the spacing after `subviews[n]` of the `KRStackView` instance.

The number of values in the array should be `n-1` where `n` is the number of subviews in the `KRStackView` instance. Any values coming after the n-1th value will be ignored. If the number of values in the array is less than `n-1`, a fatal error is thrown.

If this property is set, the `spacing` property is ignored.
    
> public var alignment: ItemAlignment = .Origin

The `alignment` property defines the alignment of the subviews. If `direction` is set to `.Vertical`, this property defines how the subviews will be aligned horizontally, and vice versa.

The default value is `.Origin`. Possible values are `.Origin`, `.Center`, and `.EndPoint`. 

> public var itemOffset: [CGFloat]?

The `itemOffset` property defines the offset of each subview, based on the `alignment` property. If `direction = .Vertical` and `alignment = .Origin`, each value will offset the subview from the origin of the `KRStackView` on the x-axis, i.e. it would be as if the subview's `origin.x = offset`. 

Each item value is the offset of the corresponding view in the `subviews` array, i.e. `itemOffset![v]` is the offset for `subviews[n]`.
    
> @IBInspectable public var shouldWrap: Bool = false

The `shouldWrap` property will shrink the `bounds` to fit snugly, if there are any leftover space. If the subviews go beyond the `bounds` both vertically and horizontally, this property will seem to have no effect.

The default value is `false`.

## Author

Joshua Park, wmpark@knowre.com

## License

KRStackView is available under the MIT license. See the LICENSE file for more info.
