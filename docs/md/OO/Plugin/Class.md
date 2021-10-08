NAME
====

OO::Plugin::Class - collection for service classes.

EXPORTS
=======

Classes
-------

### class `PluginMessage`

This class is used to provide a plugin with information about the current call. In its pure form the plugin manager is using objects of this class to communicate with callbacks.

### has Capture:D $.params

Parameters the method has been called with

### has Mu $.private

Data only available to a single plugin. This data would exists strictly within one execution chain and won't be exposed to the code from other plugins.

### has Associative %.shared

Data shared among all the plugins. This attribute is similar to .private except this data is shared; i.e. what is set by one plugin can be read or changed by others.

### method set-rc

```raku
method set-rc(
    $!rc is copy
) returns Nil
```

This method sets the suggested return value for the current execution chain.

### method reset-rc

```raku
method reset-rc() returns Nil
```

Reset the suggested return value.

### method has-rc

```raku
method has-rc() returns Bool
```

Returns _True_ if the suggested return value has been set.

### method rc

```raku
method rc() returns Mu
```

Suggested return value

### class `MethodHandlerMsg`

Inherits from `PluginMessage`. Used to provide information for method handlers.

### has Any:D $.object

Instance of the object the original method has been called upon.

### has Str:D $.method

Name of the method being called.

### has <anon> $.stage

Stage of method call. Can be one of three strings: _before_, _around_, _after_.

### class <Plugin>

The base class of all plugins.

### has <anon> $.plugin-manager

The plugin manager object which created this plugin instance.

### has Str:D $.name

Plugin's fully qualified name.

### has Str:D $.short-name

Plugin's short name.

### method on-event

```raku
method on-event(
    Str:D $name,
    |
) returns Mu
```

Event handler.

### method on-callback

```raku
method on-callback(
    Str:D $cb-name,
    OO::Plugin::Class::PluginMessage:D $msg,
    |
) returns Mu
```

Callback handler.

SEE Also
========

[`OO::Plugin::Manual`](Manual.md), [`OO::Plugin::Manager`](Manager.md), [`OO::Plugin::Class`](Class.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

