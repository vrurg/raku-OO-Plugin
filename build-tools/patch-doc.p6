#!/usr/bin/env perl6
# use Grammar::Tracer;
use lib 'lib';
use OO::Plugin;

grammar MyPOD {
    token TOP {
        [
            <pod>
            || <dummy>
        ]+
    }

    token dummy {
        [ <!before <.pod-begin>> . && . ]+
    }

    token pod-begin {
        ^^ '=begin' \h
    }

    token pod-start ( $pod-kw is rw ) {
        <pod-begin> \h* $<pod-kw>=\w+ { $pod-kw = ~$/<pod-kw> } \h* $$
    }

    token pod-end ( $pod-kw ) {
        ^^ '=end' \h+ $pod-kw \h* $$
    }

    token pod {
        :my $pod-kw;
        <pod-start( $pod-kw )>
        [
            || <pod-link>
            || <pod-text>
        ]+
        <pod-end( $pod-kw )>
    }

    token pod-text {
        .+? <?before 'L<' || [^^ '=end']>
    }

    token pod-link {
        'L' '<' <link-module> '|' <link-url> '>'
    }

    token link-module {
        [ <.alnum>+ ] ** 1..* % '::'
    }

    token link-url {
        $<link-prefix>=[ 'https://github.com/' .+? '/blob/v' ] <version> $<link-suffix>=[ '/' [<!before '>'> . && .]+ ]
    }

    token version {
        [\d+] ** 3 % '.'
    }
}

class MyPOD-Actions {
    has Bool $.replaced is rw = False;

    method version ($m) {
        # note "USING VER: ", OO::Plugin.^ver;
        my $pver = OO::Plugin.^ver;
        $.replaced = Version.new( $m ) ≠ $pver;
        $m.make( ~$pver );
    }

    # method link-url ($m) {
    #     $m.make( $m<link-prefix> ~ $m<version> ~ $m<link-suffix> )
    # }

    method FALLBACK ($name, $m) {
        $m.make(
            $m.chunks.map( { given .value { .?made // ~$_ } } ).join
        );
    }
}

sub MAIN ( Str:D $pod-file, Str :o($output)? is copy, Bool :r($replace)=False ) {
    my Bool $backup = False;
    my $src = $pod-file.IO.slurp;
    my $actions = MyPOD-Actions.new;
    my $res = MyPOD.parse( $src, :$actions );

    die "Failed to parse the source" unless $res;

    if $actions.replaced {
        if !$output and $replace {
            $backup = True;
            $output = $pod-file;
        }

        if $backup {
            my $idx = 0;
            my $bak-file = $pod-file ~ ".bk";
            while $bak-file.IO.e {
                $bak-file = $pod-file ~ (++$idx).fmt(".%02d.bk");
            }
            $pod-file.IO.rename( $bak-file );
        }

        if $output {
            $output.IO.spurt( $res.made );
        }
        else {
            say $res.made;
        }
    }
}
