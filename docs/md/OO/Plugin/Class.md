NAME
====

OO::Plugin::Class - collection for service classes.

EXPORTS
=======

Classes
-------

### class PluginMessage

This class is used to provide a plugin with information about the current call. In its pure form the plugin manager is using objects of this class to communicate with callbacks.

### has Capture:D $.params

Parameters the method has been called with

### has Mu $.private

Data only available to a single plugin. This data would exists strictly within one execution chain and won't be exposed to the code from other plugins.

### has Associative %.shared

Data shared among all the plugins. This attribute is similar to .private except this data is shared; i.e. what is set by one plugin can be read or changed by others.

### method set-rc

```perl6
method set-rc(
    $!rc is copy
) returns Nil
```

This method sets the suggested return value for the current execution chain.

### method reset-rc

```perl6
method reset-rc() returns Nil
```

Reset the suggested return value.

### method has-rc

```perl6
method has-rc() returns Bool
```

Returns _True_ if the suggested return value has been set.

### method rc

```perl6
method rc() returns Mu
```

Suggested return value

### has Any:D $.object

Instance of the object the original method has been called upon

### has Str:D $.method

Name of the method being called

### has <anon> $.stage

Plug stage

