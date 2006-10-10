package Object::Composite;

use strict;
use Carp ();
use base 'Class::Accessor';

use vars qw[$VERSION $DEBUG $AUTOLOAD];

$DEBUG      = 0;
$VERSION    = '0.01_01';

my %Cache;
sub ___get_cache { return \%Cache };

=head1 NAME

Object::Composite -- Build transparent composite objects

=head1 SYNOPSIS

    package My::Class;
    use base 'Object::Composite';
    
    $parent_a = My::Parent::A->new;
    $parent_b = My::Parent::B->new;
   
    ### dispatch 'b_method' to $parent_b transparently
    __PACKAGE__->register( b_method => sub { $parent_b->method(@_) } );
   
    ### dispatch all methods starting with 'a_' to $parent_a
    __PACKAGE__->register( qr/^a_/,    sub { $parent_a->method(@_) } );

    ### create standard getters/setters
    __PACKAGE__->mk_accessors( 'acc' );

    
    
    ### in another piece of code, far far away...
    $obj = My::Class->new;      # provided by Object::Composite
    
    $obj->b_method( @args );    # dispatched to $parent_b
    $obj->a_something( @args ); # dispatched to $parent_a
    $obj->acc( 1 );             # dispatched to standard accessor

=head1 DESCRIPTION

Object::Composite allows you to build composite objects, which, behind
the scenes redispatch their calls to other objects. This is particularly
useful if you wish to have a unified interface to, for example, different
databases, objects, gateways, etc.

=head1 METHODS

=head2 $obj = Your::Class->new( ... );

Creates a new C<Your::Class> object, provided C<Your::Class> inherits
from C<Object::Composite>.

C<Object::Composite> itself inherits from C<Class::Accessor>, so any 
arguments you can pass to its C<new> method, you can pass here.

Please see the C<Class::Accessor> documentation for details.

=head2 Your::Class->mk_accessors( ... )

Creates standard accessors for C<Your::Class>, provided C<Your::Class> 
inherits from C<Object::Composite>.

C<Object::Composite> itself inherits from C<Class::Accessor>, so any 
arguments you can pass to its C<mk_accessors> method, you can pass here.

Please see the C<Class::Accessor> documentation for details.

=head2 $bool = Your::Class->register( METHODNAME|REGEX, \&SUB )

This registers a method for your class. If you pass a C<METHODNAME>,
the method will be installed in your namespace, dispatching to C<&SUB>.
If you choose to pass a C<REGEX>, the method will be resolved by an
C<AUTOLOAD> routine, and dispatched to C<THE SUBROUTINE ASSOCIATED TO
THE FIRST REGEX REGISTERED THAT MATCHES>.

See the C<SYNOPSIS> for examples.

=cut

sub register { 
    my $self    = shift;
    my $class   = ref $self || $self;
    my $type    = shift or return;
    my $sub     = shift or return;

    ### sanity checks
    Carp::croak( __PACKAGE__ . ' must be used as a base class' )
        if $class eq __PACKAGE__;
    
    Carp::croak( "Type argument must be Regex or method name" )
        unless !ref($type) or UNIVERSAL::isa( $type, 'Regexp' );
    
    Carp::croak( "Subroutine argument must be coderef" )
        unless UNIVERSAL::isa( $sub, 'CODE' );

    ### it's a string, we'll install the method
    unless( ref $type ) {
        no strict 'refs';
        *{$class .'::'. $type} = $sub;

    ### register it as an autoloadable method
    } else {
        push @{ $Cache{ $class } }, [ $type, $sub ];
    }
    
    return 1;
}

### custom 'can' as UNIVERSAL::can ignores autoload
sub can {
    my $self    = shift;
    my $class   = ref $self || $self;
    my $method  = shift or return;

    ### it's one of our regular methods
    if( $self->UNIVERSAL::can($method) ) {
        __PACKAGE__->___debug( "Can '$method' -- provided by package" );
        return $self->UNIVERSAL::can($method);
    }

    
    ### it's an accessor we provide;
    ### so we are an autoloaded method, so we only check against regexes.
    for my $aref ( @{ $Cache{ $class } } ) {
        my ($re, $sub) = @$aref;
        
        if ( $method =~ $re ) {
            __PACKAGE__->___debug(
                "Method '${class}::$method' matches '$re' "
            ) if $DEBUG;     
            
            return $sub;
        }            
    }

    ### we don't support it
    __PACKAGE__->___debug( "Cannot '$method'" );
    return;
}

sub AUTOLOAD {
    my $self    = shift;   
    my $class   = ref $self || $self;
    my $meth    = $AUTOLOAD;
    $meth       =~ s/.+:://;

    my $sub     = $self->can( $meth );

    no strict 'refs';
    local ${"$class\::COMPOSITE_METHOD"} = $meth;
    
    ### dipsatch if we found it
    ### no match? croak with the standard perl error
    $sub ? return $sub->($self, @_) 
         : Carp::croak( 
                qq[Can't locate object method "$meth" via package "$class"] );
}

sub DESTROY { 1 }

sub ___debug {
    return unless $DEBUG;

    my $self = shift;
    my $msg  = shift;
    my $lvl  = shift || 0;

    local $Carp::CarpLevel += 1;
    
    Carp::carp($msg);
}

=head1 GLOBAL VARIABLES

=head2 $COMPOSITE_METHOD

If a method call gets dispatched by a matching regex, the variable
C<$COMPOSITE_METHOD> will be set in C<the objects class>, analogous to
the C<$AUTOLOAD> variable for C<AUTOLOAD> methods.

=head1 SEE ALSO

C<Class::Accessor>

=head1 AUTHOR

This module by
Jos Boumans E<lt>kane@cpan.orgE<gt>.

=head1 COPYRIGHT

This module is
copyright (c) 2006 Jos Boumans E<lt>kane@cpan.orgE<gt>.
All rights reserved.

This library is free software;
you may redistribute and/or modify it under the same
terms as Perl itself.

=cut


1;
