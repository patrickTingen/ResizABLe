# ResizABLe
Generic library to make any screen resizable in the OpenEdge ABL

## Introduction
Resizing windows in the ABL has always been challenging. There is no support out-of-the-box and if you want your windows to resize including their contents, you had to program it yourself. Anyone that has played with this will probably agree that something that looks so easy on paper, is so challenging in practice. 

## What this program can do for you
This program provides an easy way of making your window resize properly. Just tick the 'resize' toggle on the Window properties in the APP Builder and run the library. That's it. The result will be a window that can be resized and that will resize its contents too. 

## What this program cannot do
Straightforward windows are no problem, nor embedded frames. Problems arise when you are using tabs since the program can not (yet) handle these. ADM programs should work fine, as long as they don't have tabs. 

## How to use it?
1. make sure 'resize' is checked in your window properties
2. run this library persistent from the main block of your program
3. have fun!

Run the program like this:
```
  RUN resizable.p ({&WINDOW-NAME}:HANDLE).
```

## How does it work?
The program will make itself persistent and attach a dynamic resize trigger to your window.
It maintains a temp-table with the original x and y position, as well as the width and heigth of all widgets. At the start of your program it determines the original size of your window. By defining a WINDOW-RESIZED trigger it keeps track of changes in size and when it is resized, it repositions and resizes all widgets relative to the starting size of the window.

The trick is that you have to keep track of exactly *when* to resize the frame. If the window grows, resize the frame first and then the contents, if the frame shrinks, do the opposite. 

## Existing ON WINDOW-RESIZED event
If you have an already existing event for WINDOW-RESIZED, then the one in ResizABLe will not fire. You can force this by calling it explicitely. Save the handle of the persistent library when you start it:
```
  DEFINE VARIABLE ghResizable AS HANDLE NO-UNDO.
  RUN resizable.p PERSISTENT SET ghResizable ({&WINDOW-NAME}:HANDLE).
```
Then run it from inside your own WINDOW-RESIZED trigger:
```
  RUN WindowResized IN ghResizable(INPUT {&window-name}:HANDLE).
```

## Feedback appreciated
If you use the library and have some feedback for me, don't hesitate; I'd love to have this code improved. 