use v6.d;
use OO::Plugin::Class;

role X::Plugin {
    has Plugin:D $.plugin is required;
}

class CX::Plugin::Last does X::Control does X::Plugin {
    has $.rc is required;

    method message { "<last plug control exception>" }
}
