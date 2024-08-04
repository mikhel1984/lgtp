# ltab
Read gp3 / gp4 / gp5 files and show tabulature in console.
Based on [PyGuitarPro](https://github.com/Perlence/PyGuitarPro) lib.

Usage:
```
lua viewer.lua file_name   # Show content
lua viewer.lua file_name track_number  # print tab
```

### Example 
```
lua  viewer.lua  sample.gp3  1

	Smoke On The Water
Ritchie [Overdriven Guitar]
Key:	C major
Tempo:	118	

  1                                                                       
 E5|   :!  ---------------------|------------------|---------------------|
 B4| 4 :!* ---------------------|------------------|---------------------|
 G4|   :!  ------ 3 --- 5 ------|--- 3 --- 6  5 ---|------ 3 --- 5 --- 3 |
 D4|   :!   5 --- 3 --- 5 --- 5 |--- 3 --- 6  5 ---| 5 --- 3 --- 5 --- 3 |
 A3| 4 :!*  5 --------------- 5 |------------------| 5 ------------------|
 E3|   :!  ---------------------|------------------|---------------------|
dur        |' |' |' |'  | |' |'  |' |' |' |'  |  |  |' |' |' |'  | |' |'  

  4              x1              
 E5|------------  !|------------|
 B4|------------ *!|------------|
 G4|------------  !|------------|
 D4|--- 5  5 ---  !|--- 5  5  5/|
 A3|--- 5  5 --- *!|--- 5  5  5/|
 E3|------------  !|------------|
dur |' |'  b  |     |' |'  b  |  

Notation
/ slide
```


