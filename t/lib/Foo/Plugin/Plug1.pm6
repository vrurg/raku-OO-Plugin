use v6.d;
use OO::Plugin;
unit package Foo::Plugin;
plugin TestPlug1 {
    # our %meta =
    #     after => 'SomePlugin',
    #     demands => 'AnotherPlugin',
    #     ;

    plugin-meta
        version => v1.2.3,
        ;

    method a-wrapper (|) is plug-around('Some::Class' => '*', 'Other::Class' => 'other-method') {
        note "Just a wrapper";
    }
}
