#!/usr/bin/perl
# ---   *   ---   *   ---
# IMGPROMPT TEMPLE
# Defines prompt templates!
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS,
# lyeb,

# ---   *   ---   *   ---
# deps

package imgprompt::temple;

  use v5.36.0;
  use strict;
  use warnings;

  use English qw(-no_match_vars);

  use lib "$ENV{ARPATH}/lib/sys/";
  use Style;

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.2;#a
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# replaces variables in template

sub temple($class,%O) {


  # validate ;>
  $class->perr('no scene provided for template!')
  if ! exists $O{scene};


  # deref elements and give
  return {map {

    if(exists $O{$ARG}) {

      ($class->fhave($O{$ARG}))
        ? ($ARG=>$class->fetchp($O{$ARG},'-ur -nb'))
        : ($ARG=>$O{$ARG})
        ;

    } else {()};

  } scene => grep {$ARG ne 'scene'} keys %O};

};

# ---   *   ---   *   ---
# ^expand keywords in string!

sub replpass($class,$O) {

  map {

    my $re   = uc $ARG;
       $re   = qr{$re};

    my $s    = $O->{$ARG};
       $s  //= null;


    $O->{scene}=~ s[$re][$s]sxmg;

  } grep {$ARG ne 'scene'} keys %$O;

  return;

};

# ---   *   ---   *   ---
# ^copy to clipboard and give

sub xtemple($class,%O) {

  my $out=$class->temple(%O);
  $class->xclip($out);

  return;

};

# ---   *   ---   *   ---
1; # ret
