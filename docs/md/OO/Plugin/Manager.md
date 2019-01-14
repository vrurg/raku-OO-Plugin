NAME
====

OO::Plugin::Manager - the conductor for a plugin orchestra.

SYNOPSIS
========

    my $mgr = OO::Plugin::Manager.new( base => 'MyApp' )
                .load-plugins
                .initialize( plugin-parameter => $param-value );

DESCRIPTION
===========

Most of the description for the functionality of this module can be found in [OO::Plugin::Manual](https://github.com/vrurg/Perl6-OO-Plugin/blob/v0.0.3/docs/md/OO/Plugin/Manual.md). Here we just cover the technical details and attributes/methods.

TYPES
=====

enum `PlugPriority`
-------------------

Constants defining where the user whants to have a particular plugin:

  * `plugFirst` – in the beginning of the plugin list

  * `plugNormal` – in the middle of the list

  * `plugLast` – in the end of the list

Read about [sorting](https://github.com/vrurg/Perl6-OO-Plugin/blob/v0.0.3/docs/md/OO/Plugin/Manual.md#sorting) in [OO::Plugin::Manual](https://github.com/vrurg/Perl6-OO-Plugin/blob/v0.0.3/docs/md/OO/Plugin/Manual.md).

ATTRIBUTES
==========

### has Bool $.debug

When _True_ will print debug info to the console.

### has Str $.base

The base namespace where to look for plugin modules. See @.namespaces below.

### has Positional @.namespaces

Defines a list of namespaces within $.base attribute where to look from plugin modules. I.e. if set to the default <Plugin Plugins> then the manager will load modules from ::($.base)::Plugin or ::($.base)::Plugins.

### has Callable[<anon>] &.validator

Callback to validate plugin. Allows the user code to check for plugin compatibility, for example. (Not implemented yet)

### has Bool $.strict

In strict mode non-pluggable classes/methods cannot be overriden.

### has Positional @.load-errors

Errors collected while loading plugin modules. List of hashes of form 'Module::Name' => "Error String".

### has Bool $.initialized

Indicates that the manager object has been initialized; i.e. method initialize() has been run.

### has <anon> $.event-workers

Number of simulatenous event handlers running. Default is 3

### has Real:D $.ev-dispatcher-timeout

Number of seconds for the dispatcher to wait for another event after processing one. Default 1 sec.

METHODS
=======

routine normalize-name
----------------------

  * `normalize-name( Str:D $plugin, Bool :$strict = True )`

    Normalize plugin name, i.e. makes a name in any form and returns FQN. With `:strict` fails if no plugin found by the name in `$plugin`. With `:!strict` fails with a text error. Always fails if more than one variant for the given name found what would happen when two or more plugins register common short name for themselves.

  * `normalize-name( Str:D :$plugin, Bool :$strict = True )`

    Similar to the above variant except that it takes named argument `:plugin`.

routine short-name
------------------

Takes a plugin name and returns its corresponding short name.

  * `short-name( Str:D $name )`

  * `short-name( Str:D :$fqn )`

    A faster variant of the method because it doesn't attempt to normalize the name and performs fast lookup by FQN.

  * `short-name( Plugin:U \plugin-type )`

    Gives short name by using plugin's class itself. This is a faster version too because it also uses FQN lookup.

        my $sname = $plugin-manager.short-name( $plugin-obj.WHAT );

routine meta
------------

Returns plugin's META `Hash`.

  * `meta( Str:D $plugin )`

  * `meta( Str:D :$fqn )`

    Faster version, avoids name normalization.

SEE Also
========

[OO::Plugin::Manual](https://github.com/vrurg/Perl6-OO-Plugin/blob/v0.0.3/docs/md/OO/Plugin/Manual.md), [OO::Plugin](https://github.com/vrurg/Perl6-OO-Plugin/blob/v0.0.3/docs/md/OO/Plugin.md), [OO::Plugin::Class](https://github.com/vrurg/Perl6-OO-Plugin/blob/v0.0.3/docs/md/OO/Plugin/Class.md) [OO::Plugin::Registry](https://github.com/vrurg/Perl6-OO-Plugin/blob/v0.0.3/docs/md/OO/Plugin/Registry.md),

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

