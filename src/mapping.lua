
local map = {}
map.instruments = {
-- Piano
[0]="Acoustic Grand Piano", "Bright Acoustic Piano", "Electric Grand Piano",
"Honky-tonk Piano", "Electric Piano 1", "Electric Piano 2", "Harpsichord", "Clavinet",
-- Chromatic Percussion
"Celesta", "Glockenspiel", "Music Box", "Vibraphone", "Marimba", "Xylophone",
"Tubular Bells", "Dulcimer",
-- Organ
"Drawbar Organ", "Percussive Organ", "Rock Organ", "Church Organ", "Reed Organ",
"Accordion", "Harmonica", "Tango Accordion",
-- Guitar
"Acoustic Guitar (nylon)", "Acoustic Guitar (steel)", "Electric Guitar (jazz)",
"Electric Guitar (clean)", "Electric Guitar (muted)", "Overdriven Guitar",
"Distortion Guitar", "Guitar harmonics",
-- Bass
"Acoustic Bass", "Electric Bass (finger)", "Electric Bass (pick)", "Fretless Bass",
"Slap Bass 1", "Slap Bass 2", "Synth Bass 1", "Synth Bass 2",
-- Strings
"Violin", "Viola", "Cello", "Contrabass", "Tremolo Strings", "Pizzicato Strings",
"Orchestral Harp", "Timpani", "String Ensemble 1", "String Ensemble 2", 
"Synth Strings 1", "Synth Strings 2", "Choir Aahs", "Voice Oohs", "Synth Voice",
"Orchestra Hit",
-- Brass
"Trumpet", "Trombone", "Tuba", "Muted Trumpet", "French Horn", "Brass Section",
"Synth Brass 1", "Synth Brass 2",
-- Reed
"Soprano Sax", "Alto Sax", "Tenor Sax", "Baritone Sax", "Oboe", "English Horn",
"Bassoon", "Clarinet",
-- Pipe
"Piccolo", "Flute", "Recorder", "Pan Flute", "Blown Bottle", "Shakuhachi",
"Whistle", "Ocarina",
-- Synth Lead
"Lead 1 (square)", "Lead 2 (sawtooth)", "Lead 3 (calliope)", "Lead 4 (chiff)",
"Lead 5 (charang)", "Lead 6 (voice)", "Lead 7 (fifths)", "Lead 8 (bass + lead)",
-- Synth Pad
"Pad 1 (new age)", "Pad 2 (warm)", "Pad 3 (polysynth)", "Pad 4 (choir)", 
"Pad 5 (bowed)", "Pad 6 (metallic)", "Pad 7 (halo)", "Pad 8 (sweep)", 
-- Synth Effects
"FX 1 (rain)", "FX 2 (soundtrack)", "FX 3 (crystal)", "FX 4 (atmosphere)",
"FX 5 (brightness)", "FX 6 (goblins)", "FX 7 (echoes)", "FX 8 (sci-fi)",
-- Ethnic
"Sitar", "Banjo", "Shamisen", "Koto", "Kalimba", "Bag pipe", "Fiddle", "Shanai",
-- Percussive
"Tinkle Bell", "Agogo", "Steel Drums", "Woodblock", "Taiko Drum", 
"Melodic Tom", "Synth Drum",
-- Sound effects
"Reverse Cymbal", "Guitar Fret Noise", "Breath Noise", "Seashore", "Bird Tweet",
"Telephone Ring", "Helicopter", "Applause", "Gunshot",
}

map.keySignature = {
-- major
{[-8]='Fb', [-7]='Cb', [-6]='Gb', [-5]='Db', [-4]='Ab', [-3]='Eb', [-2]='Bb', [-1]='F', 
[0]='C', 'G', 'D', 'A', 'E', 'B', 'F#', 'C#', 'G#'},
-- minor
{[-8]='Db', [-7]='Ab', [-6]='Eb', [-5]='Bb', [-4]='F', [-3]='C', [-2]='G', [-1]='D',
[0]='A', 'E', 'B', 'F#', 'C#', 'G#', 'D#', 'A#', 'E#'},
}

map.duration = {
  [-2]=' o', [-1]=' b', [0]=' |', '|\'', '|"', '32', '64', 
  [-3]='|"\'', [-4]='|""', [-5]='128', [-6]='256',  
}

map.string = {
  ' C', 'C#', ' D', 'D#', ' E', ' F', 'F#', ' G', 'G#', ' A', 'A#', ' B',
}

map.effects = {
  ghost=')', naturalHarm='*', artificialHarm='A', vibrato='~', fadeIn='<',
  tap='T', slap='S', pop='P', letRing='L', hammer='⏜', bend='^', slide='/',
  accentuated='>', tremoloBar='v', trill='𝆖', tremoloPicking="t", palmMute='M',
  stoccato='.',
  ind={}, 
}
map.effects.ind[1] = map.effects.tap
map.effects.ind[2] = map.effects.slap
map.effects.ind[3] = map.effects.pop

return map
