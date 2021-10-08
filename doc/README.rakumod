
=begin pod
=head1 NAME

OO::Plugin – framework for working with OO plugins.

=head1 SYNOPSIS

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

=head1 DESCRIPTION

With this framework any application can have highly flexible and extensible plugin subsystem with which plugins would be
capable of:

=item method overriding
=item class overriding (inheriting)
=item callbacks
=item asynchronous event handling

The framework also supports:

=item automatic loading of plugins with a predefined namespace
=item managing plugin ordering and dependencies

Not yet supported but planned for the future is plugin compatibility management.

Read more in L<C<OO::Plugin::Manual>>.

=head1 SEE ALSO

L<C<OO::Plugin::Manual>>,
L<C<OO::Plugin>>,
L<C<OO::Plugin::Manager>>,
L<C<OO::Plugin::Class>>

=AUTHOR  Vadim Belman <vrurg@cpan.org>

=end pod
