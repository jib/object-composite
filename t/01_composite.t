use Test::More 'no_plan';
use strict;

BEGIN { chdir 't' if -d 't' };
BEGIN { use lib '../lib' };

my $Class       = 'Object::Composite';
my $RegMeth     = 'register';
my $AccMeth     = 'mk_accessors';
my $TestClass   = 'My::Test';
my $CompMeth    = '$My::Test::COMPOSITE_METHOD';

use_ok( $Class );
can_ok( $Class, $_ ) for $RegMeth, $AccMeth;

### set up the classes:
{   no strict 'refs';

    ### generate @ISA and sub new/parent_meth
    @{$TestClass ."::ISA"} = ($Class);
}

### basic object tests;
{   my $obj = $TestClass->new;
    ok( $obj,                   "Object created" );
    isa_ok( $obj,               $TestClass );
    isa_ok( $obj,               $Class );

    my $acc = 'acc1';
    $obj->$AccMeth( $acc );
    can_ok( $obj,               $acc );
}    

### registering normal subs
{   my $obj = $TestClass->new;
    ok( $obj,                   "Object created" );

    my $meth    = 'meth1';
    my $called  = 0;
    ok( $obj->$RegMeth( $meth => sub { $called++; return @_ } ),
                                "   Method '$meth' registered" );
    can_ok( $obj,               $meth );
    
    my @res = $obj->$meth( $$ );
    ok( scalar(@res),           "   Method '$meth' called" );
    is_deeply( \@res, [$obj, $$],
                                "       Returns expeced values" );
    ok( $called,                "       Caller flag toggled" );
}    
                                    
### registering normal subs
{   my $obj = $TestClass->new;
    ok( $obj,                   "Object created" );

    my $meth    = 'meth2';
    my $called  = 0;
    ok( $obj->$RegMeth( qr/^meth/, sub { $called=eval"$CompMeth"; return @_ } ),
                                "   Method '$meth' registered" );
    can_ok( $obj,               $meth );
    
    ### call the method
    {   my @res = $obj->$meth( $$ );
        ok( scalar(@res),       "   Method '$meth' called" );
        is_deeply( \@res, [$obj, $$],
                                "       Returns expeced values" );
        ok( $called,            "       Caller flag toggled" );
        is( $called, $meth,     "       Right method name stored: '$called'" );
    }
    
    ### regiser another regex, this time matching more precisely.
    ### however, first registered, first served;
    $called = 0;
    ok( $obj->$RegMeth( qr/^$meth/, sub { die } ),
                                "   Another method maching '$meth' registered");
    {   my @res = eval { $obj->$meth( $$ ) };
        ok( scalar(@res),       "   Method '$meth' called" );
        is_deeply( \@res, [$obj, $$],
                                "       Returns expeced values" );
        ok( $called,            "       Caller flag toggled" );
        ok( !$@,                "   Right method was called" );
    }
}

### register another regex,.. be sure this one gets called
{   my $obj = $TestClass->new;
    ok( $obj,                   "Object created" );

    my $meth    = '_meth2';
    my $called  = 0;
    ok( $obj->$RegMeth( qr/^$meth/, sub { $called++; return @_ } ),
                                "   Method '$meth' registered" );
    can_ok( $obj,               $meth );
    
    my @res = $obj->$meth( $$ );
    ok( scalar(@res),           "   Method '$meth' called" );
    is_deeply( \@res, [$obj, $$],
                                "       Returns expeced values" );
    ok( $called,                "       Caller flag toggled" );
}

### error tests
{   my $obj = $TestClass->new;
    ok( $obj,                   "Object created" );

    eval { $obj->$RegMeth( {} => sub {} ) };
    ok( $@,                     "   Registering with a bogus key failed" );
    like( $@, qr/Type argument/,
                                "       Proper error detected" );
    
    eval { $obj->$RegMeth( $$ => $$ ) };
    ok( $@,                     "   Registering with a bogus value failed" );
    like( $@, qr/Subroutine argument/,
                                "       Proper error detected" );

    eval { $obj->$$ };
    ok( $@,                     "   Calling non-existant methods fail" );
    like( $@, qr/$$/,           "       Proper error detected" );


    eval { $Class->$RegMeth( $$ => sub {} ) };
    ok( $@,                     "   Calling register on $Class failed" );
    like( $@, qr/$Class/,       "       Proper error deteced" );
}









