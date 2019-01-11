NAME
====

OO::Plugin – framework for working with OO plugins.

SYNOPSIS
========

    use OO::Plugin;
    use OO::Plugin::Manager;

    class Foo is pluggable {
        has $.attr;
        method bar is pluggable {
            return 42;
        }
    }

    plugin Fubar {
        method a-bar ( $msg ) is plug-around( Foo => 'bar' ) {
            $msg.set-rc( pi ); # Will override &Foo::bar return value and prevent its execution.
        }
    }

    my $manager = OO::Plugin::Manager.new.initialize;
    my $instance = $manager.create( Foo, attr => 'some value' );
    say $instance.bar;  # 3.141592653589793

DESCRIPTION
===========

With this framework any application can have highly flexible and extensible plugin subsystem with which plugins would be capable of:

  * method overriding

  * class overriding (inheriting)

  * callbacks

  * asynchronous event handling

The framework also supports:

  * automatic loading of plugins with a predefined namespace

  * managing plugin ordering and dependencies

Not yet supported but planned for the future is plugin compatibility management.

Read more in [OO::Plugin::Manual](OO::Plugin::Manual).

SEE Also
========

[OO::Plugin](OO::Plugin), [OO::Plugin::Manager](OO::Plugin::Manager), [OO::Plugin::Class](OO::Plugin::Class)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

