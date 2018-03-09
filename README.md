# ResizABLe
Generic library to make any screen resizable in the OpenEdge ABL

## Introduction
Resizing windows in the ABL has always been challenging. There is no support out-of-the-box and if you want your windows to resize including their contents, you had to program it yourself. Anyone that has played with this will probably agree that something that looks so easy on paper, is so challenging in practice. 

## What this program can do for you
This program provides an easy way of making your window resize properly. Just tick the 'resize' toggle on the Window properties in the APP Builder and run the library. That's it. The result will be a window that can be resized and that will resize its contents too. 

## What this program cannot do
Straightforward windows are no problem, nor embedded frames. Problems arise when you are using tabs since the program can not (yet) handle these. ADM programs should work fine, as long as they don't have tabs. 

## How does it work?
The program maintains a temp-table with the original x and y position, as well as the width and heigth of all widgets. At the start of your program it determines the original size of your window. By defining a WINDOW-RESIZED trigger it keeps track of changes in size and when it is resized, it repositions and resizes all widgets relative to the starting size of the window.

The trick is that you have to keep track of exactly *when* to resize the frame. If the window grows, resize the frame first and then the contents, if the frame shrinks, do the opposite. 

## Feedback appreciated
If you use the library and have some feedback for me, don't hesitate; I'd love to have this code improved. 
