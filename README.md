# IMGPROMPT

Small toolkit for writing image generation prompts: `imgprompt` builds a local database of token lists from text files so that complex prompts can be written with ease.

The mechanism is simple: individual prompt elements are written as lists, and these elements themselves may contain references to other lists. These are then later processed and expanded into a full, formatted prompt.

In a nutshell, `imgprompt` takes a formatted string as input, analyzes it, and then outputs a prompt based on that input.


## SETUP

- Get [`avtomat`](https://github.com/Liebranca/avtomat?tab=readme-ov-file#installation).

- Get [`daf`](https://github.com/Liebranca/daf?tab=readme-ov-file#setup).


Once you have both:

```bash
cd  $ARPATH
git clone https://github.com/Liebranca/imgprompt
cd  imgprompt

./install.pl && ./imgprompt
```


There, you're done.


## USAGE EXAMPLE

```perl

# import
use lib "$ENV{ARPATH}/lib/";
use imgprompt;

# make a new element
my $elem=imgprompt->def(q[

  * mylib/foreground-00 :1.02;
  * mylib/background-13 :1.01;

  * mylib/filter-A0 :1.01;

  -ur

]);

# (optional) save to database!
$elem->save('path/to/lib/');


# process element and output result
print $elem->proc();

```


## USER METHODS

### imgprompt::def([$class|$self],$s)

- Takes a source string `$s` and turns it into an `imgprompt` element, ready to be processed.

- If call with an instance, it will concatenate the new definition to the previous content.


### imgprompt::save($self,$path)

- Write the calling instance to the database, using the provided `$path` as key.


### imgprompt::obj($class,$path,$s)

- Given a `$path` to use as key into the database and a source string `$s`, generate an `imgprompt` instance via `def` and `save` that instance to the provided path.


### imgprompt::proc($self,$mod=undef)

- Process the calling instance, expanding any elements within.

- If a string `$mod` is provided, detailing attributes, the default modifiers for this element are overriden.


### imgprompt::fetch($class,$path)

- Look for `$path` within the database.

- Throw if not found, else return an `imgprompt` instance.


### imgprompt::fetchp($class,$path,$mod=undef)

- `fetch $path`.

- `proc` the fetched element, passing modifiers if `$mod` is provided.

- Return the expanded element as a string.


## SOURCE FILES

`imgprompt` can use text files to build it's local database. These source files have the following syntax rules:

- Names starting with an `~` ascii tilde define a variable. For instance, `~ROOT name/of/lib/` sets the base database path for all elements within that file.

- Names starting with an `@` atsign define an element, that is, a list of tokens.

- Names starting with an `*` asterisk mean database lookup. As an example, `* name/of/lib/elem-name` would attempt fetching an element declared as `@elem-name` within the `name/of/lib/` database path.

- A `,` comma separates tokens within a list, while a `;` semicolon inserts a `BREAK`.


Additionally, the following *modifiers* can be utilized at the end of an element declaration or fetch:

- `-ur` unrolls a list, that is, pastes it __without parentheses__.

- `-bk` forces the insertion of a `BREAK` at the end of a list.

- A `:` colon followed by a number assigns a weight to an element. If this is not specified, `:1.00` is used by default.


## SOURCE FILE EXAMPLE

Let's look at a minimal `imgprompt` file to better demonstrate the syntax:

```$

~ROOT camera/

@lens-xn
  extremely narrow lens,
  low field of vision,

@close-f
  extreme close-up shot,
  straight angle,
  front view,

@head-shot
  * camera/close-f -ur,
  * camera/lens-xn -ur,
  
  :1.07  

```


Broken down:

- We define `~ROOT` as `camera/` -- this means all elements in this file will utilize that as the base of their database path.

- We define the elements `lens-xn` and `close-f`, detailing a kind of camera lens and shot.

- Both elements are unrolled and combined into the new element `head-shot`, and given a standard weight of `:1.07`.


Now whenever we want to reuse this exact camera setup, we can use `* camera/head-shot` inside another definition, and the line will be expanded to the full list of tokens.


## PENDING

The class methods `build` and `dirbuild` allow us to read these source files to update the database. Currently, `avtomat` must be tweaked for this process to be fully automated.

As such, we're leaving the process of building from source outside of the documentation, since the current work-around is only a temporary hack.


## CHANGELOG

### v0.00.8a

- Made the files public ;>

- Wrote initial documentation.

- Slight cleanup of original implementation.
