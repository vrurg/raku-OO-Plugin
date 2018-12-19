use v6.d;
use OO::Plugin;

plugin TestPlug1:ver<0.0.1> {
    our %meta =
        after => 'SomePlugin',
        requires => 'AnotherPlugin',
        ;

    plugin-meta mykey => "my value", version => v1.2.3;

    method a-wrapper (|) is wrapper('Some::Class' => '*', 'Other::Class' => 'other-method') {
        note "Just a wrapper";
    }
    method a-wrapper1 (|) is wrapper( 'method-name' => 'Some::Class', "A::Class" ) {
        note "Just a wrapper";
    }

    method a-wrapper2 (|) is wrapper{class => Int, method => 'any'} {
    }
    method a-wrapper3 (|) is wrapper(method => 'any') {
    }
}
