package Tree::Persist::File::XML;

use strict;
use warnings;

use base qw( Tree::Persist::File );

use Scalar::Util qw( blessed refaddr );
use UNIVERSAL::require;
use XML::Parser;

our $VERSION = '1.01';

sub _reload {
    my $self = shift;

    my $linenum = 0;
    my @stack;
    my $tree;
    my $parser = XML::Parser->new(
        Handlers => {
            Start => sub {
                shift;
                my ($name, %args) = @_;

                my $class = $args{class}
                    ? $args{class}
                    : $self->{_class};
                $class->require or die $UNIVERSAL::require::ERROR;

                my $node = $class->new( $args{value} );

                if ( @stack ) {
                    $stack[-1]->add_child( $node );
                }
                else {
                    $tree = $node;
                }

                push @stack, $node;
            },
            End => sub {
                $linenum++;
                pop @stack;
            },
        },
    );

    $parser->parsefile( $self->{_filename} );

    $self->_set_tree( $tree );

    return $self;
}

my $pad = ' ' x 4;

sub _build_string {
    my $self = shift;
    my ($tree) = @_;

    my $str = '';

    my $curr_depth = $tree->depth;
    my @closer;
    foreach my $node ( $tree->traverse ) {
        my $new_depth = $node->depth;
        $str .= pop(@closer) while @closer && $curr_depth-- >= $new_depth;

        $curr_depth = $new_depth;
        $str .= ($pad x $curr_depth)
                . '<node class="'
                . blessed($node)
                . '" value="'
                #XXX Need to encode the value.
                . $node->value
                . '">' . $/;
        push @closer, ($pad x $curr_depth) . "</node>\n";
    }
    $str .= pop(@closer) while @closer;

    return $str;
}

1;
__END__

=head1 NAME

Tree::Persist::File::XML - A handler for Tree persistence

=head1 SYNOPSIS

Please see L<Tree::Persist> for how to use this module.

=head1 DESCRIPTION

This module is a plugin for L<Tree::Persist> to store a L<Tree> to an XML
file.

=head1 PARAMETERS

This class requires no additional parameters than are specified by its parent,
L<Tree::Persist::File>.

=head1 METHODS

Tree::Persist::File::XML is a sub-class of L<Tree::Persist::File>, and inherits all its methods.

=head1 XML SPEC

The XML used is very simple. Each element is called "node". The node contains
two attributes - "class", which represents the L<Tree> class to build this
node for, and "value", which is the serialized value contained in the node (as
retrieved by the C<value()> method.) Parent-child relationships are represented
by the parent containing the child.

NOTE: This plugin will currently only handle values that are strings or have a
stringification method.

=head1 TODO

=over 4

=item *

Currently, the value is not XML-encoded.

=back

=head1 CODE COVERAGE

Please see the relevant section of L<Tree::Persist>.

=head1 SUPPORT

Please see the relevant section of L<Tree::Persist>.

=head1 AUTHORS

Rob Kinyon E<lt>rob.kinyon@iinteractive.comE<gt>

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

Thanks to Infinity Interactive for generously donating our time.

=head1 COPYRIGHT AND LICENSE

Copyright 2004, 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
