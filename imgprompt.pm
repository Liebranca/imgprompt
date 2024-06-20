#!/usr/bin/perl
# ---   *   ---   *   ---
# IMGPROMPT
# Stable confussion
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS,
# lyeb,

# ---   *   ---   *   ---
# deps

package imgprompt;

  use v5.36.0;
  use strict;
  use warnings;

  use English qw(-no_match_vars);
  use lib "$ENV{ARPATH}/lib/sys/";

  use Style;

  use Type;
  use Bpack;

  use Arstd::Path;
  use Arstd::String;
  use Arstd::IO;
  use Arstd::WLog;

  use Shb7::Path qw(moo walk);

  use parent 'St';

  use lib "$ENV{ARPATH}/lib/";
  use daf;

  use parent 'imgprompt::temple';

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.8;#a
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# ROM

St::vconst {


  DEFAULT => {

    raw    => [],
    attrs  => {

      weight => 1.0,

      unroll => 0,
      break  => 0,

    },

    input  => null,
    output => null,

  },


  cache => sub {$_[0]->classcache('db')},
  idre  => qr{^\* \s*

    (?<path> [^\s]+) \s*
    (?<mod>  .+)?

  $}x,

  ext   => '.tl',


  # archiver data
  darn  => 'db',
  dard  => sub {

    my $base = dirof __FILE__;
    my $name = $_[0]->darn;

    return "$base/$_[0]/$name";

  },

  darf  => sub {
    my $root=$_[0]->dard;
    return "$root.daf";

  },

  dar   => sub {

    my $name=$_[0]->dard;
    my $full=$_[0]->darf;

    my $have=(-f $full)
      ? daf->fopen($name)
      : daf->fnew($name,blk_sz=>3)
      ;

    return $have;

  },

};

# ---   *   ---   *   ---
# cstruc

sub new($class,%O) {
  $class->defnit(\%O);
  return bless \%O,$class;

};

# ---   *   ---   *   ---
# file name expansion

sub fex($self,$name) {

  my $full =  $self->darn. "/$name" . $self->ext;
     $full =~ s[$FSLASH_RE+][/]sxmg;

  return $full;

};

# ---   *   ---   *   ---
# file exists?

sub fhave($self,$name) {

  return 0 if $name=~ qr{[,\(\)\[\]\s]};
  return $self->dar->fetch(
    $self->fex($name)

  );

};

# ---   *   ---   *   ---
# file search

sub fsearch($self,$name) {

  # expand
  my $path=$self->fex($name);

  # ^validate
  $self->err(
    "cannot find '%s' in db",
    args=>[$path]

  ) if ! $self->dar->fetch($path);


  return $path;

};

# ---   *   ---   *   ---
# get definition

sub fetch($self,$path) {

  my $cache=$self->cache;

  return (! exists $cache->{$path})
    ? $self->load($path)
    : $cache->{$path}
    ;

};

# ---   *   ---   *   ---
# ^from disk

sub load($self,$name) {

  # get ctx
  my $cache=$self->cache;

  # decode, cache and give
  my $path=$self->fsearch($name);

  $cache->{$name}=$self->from_bin($path);
  return $cache->{$name};

};

# ---   *   ---   *   ---
# ^iv

sub save($self,$name) {


  # check object before saving ;>
  $self->safe($name);

  # get ctx
  my $cache = $self->cache;
  my $path  = $self->fex($name);


  # update, encode and give
  $cache->{$name}=$self;

  $self->to_bin($path) or $self->err(
    "cannot write '%s' to db",
    args=>[$path],

  );


  return $path;

};

# ---   *   ---   *   ---
# throw unless object is OK

sub safe($self,$path) {


  # get ctx
  my $re = $self->idre;
  my @Q  = $self->emall;


  # expand until none left
  while(@Q) {

    # get object
    my $ar=shift @Q;

    # ^validate
    $self->err(
      'recursive expansion in [* %s]',
      args => $path,

    ) if $ar->[0] eq $path;


    # expand and go next
    my $have=$self->fetch($ar->[0]);
    unshift @Q,$have->emall;

  };

  return;

};

# ---   *   ---   *   ---
# get embedded object in string

sub emnext($self,$s) {

  return ($s=~ $self->idre)
    ? ($+{path},$+{mod})
    : ()
    ;

};

# ---   *   ---   *   ---
# ^get all embeded in instance

sub emall($self) {

  map {
    my @ar=$self->emnext($ARG);
    (@ar) ? [@ar] : () ;

  } @{$self->{raw}};

};

# ---   *   ---   *   ---
# expand embedded objects in raw

sub expand($self) {


  # get ctx
  my $re  = $self->idre;


  # consume input
  my @out = ();
  my @Q   = @{$self->{raw}};

  while(@Q) {


    # unpack
    my $s  = shift @Q;
    my @ar = $self->emnext($s);


    # have object?
    if(@ar) {
      my $have=$self->fetch($ar[0]);
      unshift @Q,$have->proc($ar[1]);

    # have token!
    } else {
      push @out,$s;

    };


  };


  return @out;

};

# ---   *   ---   *   ---
# gets modified copy of attributes

sub modattrs($self,@src) {

  my %attrs=%{$self->{attrs}};

  map {

    if($ARG=~ s[^\-][]) {

      my $key={
        ur => 'unroll',
        bk => 'break',

      }->{$ARG};

      $attrs{$key}=1;


    } elsif($ARG=~ s[^$COLON_RE\s*][]) {
      $attrs{weight}=$ARG if length $ARG;

    };

  } map {split $NSPACE_RE,$ARG} @src;


  $attrs{weight} .= '.00'
  if ! ($attrs{weight}=~ m[\.]);

  return %attrs;

};

# ---   *   ---   *   ---
# make raw token list from input

sub def($self,$s) {


  # need to make ice?
  $self=$self->new() if ! ref $self;


  # insert breaks
  $self->{input} =  $s;
  $self->{input} =~ s[$SEMI_RE][,BREAK,]sxmg;


  # cleanup list
  my @ar=(

    grep  {length $ARG}
    map   {

      strip \$ARG;

      $ARG=~ s[$NSPACE_RE][ ]sxmg;
      $ARG;

    } split $COMMA_RE,$self->{input}

  );


  # assign attributes
  my $re    = qr{^(?:\-|\:)};

  my @attrs = grep {  ($ARG=~ $re)} @ar;
     @ar    = grep {! ($ARG=~ $re)} @ar;

  my %attrs = $self->modattrs(@attrs);

  $self->{attrs}=\%attrs;


  # add input to raw
  push @{$self->{raw}},@ar;

  return $self;


};

# ---   *   ---   *   ---
# ^make and save to path

sub obj($class,$path,$s) {
  my $self=$class->def($s);
  return $self->save($path);

};

# ---   *   ---   *   ---
# output final buf

sub proc($self,$mod=undef) {


  # expand this object into a list of tokens
  my $out=join ', ',$self->expand();


  # get attributes + modifiers
  my %attrs=(defined $mod && length $mod)
    ? $self->modattrs($mod)
    : %{$self->{attrs}}
    ;


  # ^apply
  if(! $attrs{unroll}) {
    $out="($out :$attrs{weight})";

  };


  $out .= ', BREAK' if $attrs{break};


  return $out;

};

# ---   *   ---   *   ---
# ^generate and copy to clipboard!

sub clip($self,$mod=undef) {

  my $out=$self->proc($mod);
  $self->xclip($out);

  return;

};

# ---   *   ---   *   ---
# ^do the clipboard thing ;>

sub xclip($class,$s) {

  my $root = $class->dard;
  my @call = (
    qw(xclip -selection c -i),
    "$root/.tmp"

  );

  owc "$root/.tmp" => $s;
  system {$call[0]} @call;

  return;

};

# ---   *   ---   *   ---
# fetch, then proc

sub fetchp($class,$path,$mod=undef) {
  my $have=$class->fetch($path);
  return $have->proc($mod);

};

# ---   *   ---   *   ---
# reads object batch

sub build($class,$path) {


  # notify
  $WLog->fupdate(basef $path);


  # ctx
  my $re   = qr{(~|@)};
  my $lcom = qr{\#[^\n]+};

  # fstate
  my $dict={
    ROOT=>null,
    POST=>null,

  };


  # read file contents
  my @have=(

    grep  {length $ARG}
    map   {$ARG=~ s[$lcom][]sxmg;strip \$ARG;$ARG}

    split $re,orc $path

  );


  # proc file
  while(@have) {

    my $type=shift @have;
    my $data=shift @have;


    # have var?
    if($type eq '~') {
      my ($key,$value)=split $NSPACE_RE,$data;
      $dict->{$key}=$value;

    # have def!
    } else {

      my $idex = index $data,' ';
      my $key  = substr $data,0,$idex,null;

      strip \$key;
      $key="${key}$dict->{POST}";

      $class->obj("$dict->{ROOT}$key",$data);

    };

  };

  return;

};

# ---   *   ---   *   ---
# ^bat

sub dirbuild($class,$path) {



  # get ctx
  my $dst  = $class->darf;
  my $tree = walk $path,-r=>1,-x=>[qr{.+\..*}];


  # get files in need of update
  my @file=(
    grep {moo $dst,$ARG}
    $tree->get_file_list()

  );

  # ^notify and run
  $WLog->mprich(

    $class,

    'rebuilding object '
  . ansim basef($path)=>'update'

  ) if @file;

  map {$class->build($ARG)} @file;


  return;

};

# ---   *   ---   *   ---
# encode to binary

sub to_bin($self,$path) {


  # dump [cnt => tokens]
  my $out   = null;
  my @raw   = @{$self->{raw}};

  my $have  = bpack word=>int @raw;
     $out  .= $have->{ct};

     $have  = bpack cstr => @raw;
     $out  .= $have->{ct};


  # dump [weight => bool array]
  $have  = bpack 'real,byte'=>(

    $self->{attrs}->{weight},int(
      ($self->{attrs}->{unroll} << 0)
    | ($self->{attrs}->{break}  << 1)

    ),

  );

  $out .= $have->{ct};


  # write to archive and give
  return $self->dar->store($path,$out);

};

# ---   *   ---   *   ---
# ^undo

sub from_bin($class,$path) {


  # no refs!
  $class=ref $class
  if length ref $class;


  # read entry from archive
  my $body=$class->dar->load($path);


  # read [cnt => tokens]
  my $have = bunpacksu word=>\$body;
  my $cnt  = $have->{ct}->[0];

     $have = bunpacksu cstr=>\$body,0,$cnt;
  my $raw  = $have->{ct};


  # read [weight => bool array]
     $have   = bunpacksu 'real,byte'=>\$body,0,2;
  my $weight = $have->{ct}->[0];
  my $flags  = $have->{ct}->[1];


  # rebuild object and give
  return $class->new(

    raw   => $raw,
    attrs => {

      weight => (sprintf "%.3f",$weight),

      unroll => $flags & 1,
      break  => $flags & 2,

    },

  );

};

# ---   *   ---   *   ---
# dbout

sub err($self,$me,%O) {

  $WLog   //= Arstd::WLog->genesis;
  $O{lvl} //= $AR_FATAL;

  $WLog->err($me,%O,from => ref $self);

  return;

};

# ---   *   ---   *   ---
# atexit

END {

  my $class = St::cpkg;
  my $file  = $class->darf;

  $class->dar->fclose();

};

# ---   *   ---   *   ---
1; # ret
