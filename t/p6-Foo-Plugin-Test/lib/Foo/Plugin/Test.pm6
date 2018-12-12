use v6;
unit module Foo::Plugin::Test;
use OO::Plugin;

our $b = pi;
our sub HEH is export {
    note "!!HEH";
    note %?RESOURCES;
    %?RESOURCES
}

class TestPlugin is OO::Plugin is export {

}
