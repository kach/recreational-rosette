* March 13, 2017 -- initial version

By way of introduction, here is an email excerpt from spring 2017.

> I'm currently taking a music theory class at school, and we spend a lot of
> time harmonizing melodies for 4 voices (soprano-alto-tenor-bass). Sadly,
> there are a *lot* of tricky rules you need to follow to do this. For example,
> each voice has a range, and consecutive notes cannot be too far apart.

> Just for fun, I encoded these rules in Rosette (with symbolic notes) to see
> what would happen. It turns out that this works surprisingly well!

A usage guide follows.

---

This program takes a sequence of melody notes, and generates a bunch of
symbolic chords (one per melody note). Then, it makes a series of assertions
about things like:
  - Vocal ranges for chord tones (soprano/alto/tenor/bass)
  - Which intervals sound good together
  - How to transition between chords fluidly
(This covers around the first semester of my music theory class.)

Next, the program queries the solver for a solution. Individual notes are
represented by symbolic numbers corresponding to the MIDI encoding (in which
middle C is 60). So, the output from the solver can easily be interpreted as
music.

Finally, we output GNU Lilypond [0] sources, which can be written to a file and
then compiled:
  $ lilypond foo.ly
That operation creates
  (1) a PDF file, foo.pdf, containing the score
  (2) a MIDI file, foo.midi, containing the music
To render the MIDI file to meaningful audio, we can use TiMidity++ [1]:
  $ timidity foo.midi
The -Ow flag will create a .wav file instead of playing it directly. The .wav
file can then be converted to mp3 or any other format easily.

The PDF file can be printed and played on piano. I also turned one such PDF in
for an assignment and got a decent grade on it. (Your mileage may vary!)

Two related papers are cited below. Both of them use MUCH more code than what
is listed here!
An expert system for harmonizing chorales in the style of J.S. Bach
  Kemal Ebcioglu
  http://www.sciencedirect.com/science/article/pii/074310669090055A
Making Music with AI: Some examples
  Ram'on Lopez de Mantaras
  http://www.iiia.csic.es/files/pdfs/1265.pdf

[0] http://lilypond.org/
    Easy to install; web client at http://lilybin.com/
[1] https://en.wikipedia.org/wiki/TiMidity%2B%2B
    Installable via Homebrew
