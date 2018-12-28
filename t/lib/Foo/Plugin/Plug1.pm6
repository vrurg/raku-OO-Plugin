use v6.d;
use OO::Plugin;

plugin TestPlug1 {
    our %meta =
        after => 'SomePlugin',
        requires => 'AnotherPlugin',
        ;

    plugin-meta mykey => "my value", version => v1.2.3;

    method a-wrapper (|) is plug-around('Some::Class' => '*', 'Other::Class' => 'other-method') {
        note "Just a wrapper";
    }
}
