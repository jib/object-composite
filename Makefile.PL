use ExtUtils::MakeMaker;
use strict;

WriteMakefile (
    NAME            => 'Object::Composite',
    VERSION_FROM    => 'lib/Object/Composite.pm', # finds $VERSION
    dist            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    PREREQ_PM       => {    'Carp'          => 0,
                            'Test::More'    => 0,
                    },
    AUTHOR          => 'Jos Boumans <kane[at]cpan.org>',
	ABSTRACT        => 'Build transparent composite objects',
);             
