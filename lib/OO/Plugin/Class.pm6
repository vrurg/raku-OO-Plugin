use v6.d;
unit module OO::Plugin::Class;

class Plugin:auth<CPAN:VRURG>:ver<0.0.0>:api<0> is export {
    has $.plugin-manager is required where { is-plug-mgr $_ };

    proto method on-event (|) {*}

    proto method on-callback (|) {*}
}

role Pluggable is export {
    has $.plugin-manager is required where { is-plug-mgr $_ };
}

class PlugRecord is export {
    #| Instance of the object the original method has been called upon
    has Any:D $.object is required;
    #| Name of the method being called
    has Str:D $.method is required;
    #| Parameters the method has been called with
    has Capture:D $.params is rw is required;
    #| Data to be passed across plugin's plugs only. I.e. if a plugin defines 'before' and 'after' plugs then this data
    #| would only be available to them, not to the plugs from other plugins.
    has $.private is rw;
    #| Data shared among all plugs of the current method.
    has %.shared;
    #| Plug stage
    has Str:D $.stage is rw where * ~~ any <before around after>;
    #| Plugin-suggested return value
    has $!rc;
    #| Indicates that $!rc was set.
    has Bool:D $!rc-set = False;

    method set-rc ( $!rc is copy ) {
        $!rc-set = True;
    }

    method reset-rc {
        $!rc = Nil;
        $!rc-set = False;
    }

    method has-rc { $!rc-set }
    method rc { $!rc }
}

sub is-plug-mgr ( $obj ) {
    require ::('OO::Plugin::Manager');
    $obj ~~ ::('OO::Plugin::Manager')
}
