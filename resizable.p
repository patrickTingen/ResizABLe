/*------------------------------------------------------------------------
  Name : Resizable.p
  Desc : Library to make any ABL window resizable
  
  Notes:
    1. make sure 'resize' is checked in your window properties
    2. run this library persistent from the main block of your program
    3. have fun!

  More info: https://github.com/patrickTingen/ResizABLe

  Parameters:
    phWindow : handle to your window

  History:
  08-03-2018 PT Created
  ----------------------------------------------------------------------*/

DEFINE INPUT PARAMETER phWindow AS HANDLE NO-UNDO.

DEFINE TEMP-TABLE ttWidget NO-UNDO
  FIELD ttHandle AS HANDLE
  FIELD ttX      AS DECIMAL /* calculated x-position in pixels */
  FIELD ttY      AS DECIMAL /* calculated y-position in pixels */
  FIELD ttWidth  AS DECIMAL /* calculated width in pixels */
  FIELD ttHeight AS DECIMAL /* calculated height in pixels */
  INDEX iPrim IS PRIMARY UNIQUE ttHandle.
  
DEFINE VARIABLE giMinFactorHor  AS INTEGER NO-UNDO INITIAL 1.
DEFINE VARIABLE giMinFactorVer  AS INTEGER NO-UNDO INITIAL 1.
DEFINE VARIABLE giOrgHeight     AS INTEGER NO-UNDO.
DEFINE VARIABLE giOrgWidth      AS INTEGER NO-UNDO.
DEFINE VARIABLE gdPrevFactorHor AS DECIMAL NO-UNDO.
DEFINE VARIABLE gdPrevFactorVer AS DECIMAL NO-UNDO.

/* Init */
ASSIGN 
  giOrgHeight = phWindow:HEIGHT-PIXELS
  giOrgWidth  = phWindow:WIDTH-PIXELS
  phWindow:MAX-WIDTH-PIXELS  = SESSION:WIDTH-PIXELS
  phWindow:MAX-HEIGHT-PIXELS = SESSION:HEIGHT-PIXELS.

/* Trap resize actions */
ON 'WINDOW-RESIZED' OF phWindow ANYWHERE PERSISTENT 
  RUN WindowResized IN THIS-PROCEDURE 
    ( INPUT phWindow ).


PROCEDURE maximizeWindow:
  /* Resize a window to its maximum dimensions
  */
  DEFINE INPUT PARAMETER phWindow AS HANDLE NO-UNDO.

  phWindow:MOVE-TO-TOP().
  phWindow:WINDOW-STATE = 1. /* Maximized */
  RUN WindowResized(phWindow).
  
END PROCEDURE. /* maximizeWindow */


PROCEDURE setMinimalResizeFactor:
  /* Set the minimal resizing factor for the window
  ** For ADM windows this seems to be 1, for plain ABL windows 0
  */
  DEFINE INPUT PARAMETER piMinHor AS DECIMAL NO-UNDO.
  DEFINE INPUT PARAMETER piMinVer AS DECIMAL NO-UNDO.
  
  ASSIGN
    giMinFactorHor = piMinHor
    giMinFactorVer = piMinVer.
    
END PROCEDURE. /* setMinimalResizeFactor */


PROCEDURE windowResized:
  /* Resize the frame and all the widget it contains to the new window size
  */
  DEFINE INPUT PARAMETER phWindow AS HANDLE NO-UNDO.

  DEFINE VARIABLE dFactorHor AS DECIMAL NO-UNDO.
  DEFINE VARIABLE dFactorVer AS DECIMAL NO-UNDO.

  /* Calculate resizing factor relative to starting size */
  dFactorHor = MAXIMUM(giMinFactorHor, phWindow:WIDTH-PIXELS / giOrgWidth).
  dFactorVer = MAXIMUM(giMinFactorVer, phWindow:HEIGHT-PIXELS / giOrgHeight).
  
  RUN lockWindow(phWindow, YES).
  phWindow:WIDTH-PIXELS = giOrgWidth * dFactorHor.
  phWindow:HEIGHT-PIXELS = giOrgHeight * dFactorVer.
  RUN resizeFrame(phWindow, phWindow:FIRST-CHILD, dFactorHor, dFactorVer).
  RUN lockWindow(phWindow, NO).
  
  gdPrevFactorHor = dFactorHor.
  gdPrevFactorVer = dFactorVer.

END PROCEDURE. /* windowResized */


PROCEDURE resizeFrame:
  /* Resize contents of a frame 
  */
  DEFINE INPUT PARAMETER phParent    AS HANDLE  NO-UNDO.
  DEFINE INPUT PARAMETER phFrame     AS HANDLE  NO-UNDO.
  DEFINE INPUT PARAMETER pdFactorHor AS DECIMAL NO-UNDO.
  DEFINE INPUT PARAMETER pdFactorVer AS DECIMAL NO-UNDO.
  
  DEFINE VARIABLE hWidget AS HANDLE NO-UNDO. /* general purpose widget handle */
  DEFINE BUFFER bWidget FOR ttWidget.
  
  /* prevent errors when resizing to too small sizes */
  IF pdFactorHor < 0.15 OR pdFactorVer < 0.15 THEN RETURN. 
  
  ASSIGN phFrame:SCROLLABLE = TRUE NO-ERROR.
  
  /* If the window grows, resize the frame as well */
  IF pdFactorHor > gdPrevFactorHor THEN
    ASSIGN phFrame:WIDTH-PIXELS = phParent:WIDTH-PIXELS 
           phFrame:VIRTUAL-WIDTH-PIXELS = phParent:WIDTH-PIXELS NO-ERROR.

  IF pdFactorVer > gdPrevFactorVer THEN
    ASSIGN phFrame:HEIGHT-PIXELS = phParent:HEIGHT-PIXELS 
           phFrame:VIRTUAL-HEIGHT-PIXELS = phParent:HEIGHT-PIXELS NO-ERROR.

  /* Walk the widgets of the frame */
  ASSIGN hWidget = phFrame:FIRST-CHILD:FIRST-CHILD. /* first field-level widget */
  DO WHILE VALID-HANDLE(hWidget):
    FIND bWidget WHERE bWidget.ttHandle = hWidget NO-ERROR.
    IF NOT AVAILABLE bWidget THEN 
    DO:
      CREATE bWidget.
      ASSIGN bWidget.ttHandle = hWidget
             bWidget.ttX      = hWidget:X
             bWidget.ttY      = hWidget:Y
             bWidget.ttWidth  = hWidget:WIDTH-PIXELS
             bWidget.ttHeight = hWidget:HEIGHT-PIXELS.
    END.

    ASSIGN hWidget:X = TRUNCATE(bWidget.ttX * pdFactorHor,0)
           hWidget:Y = TRUNCATE(bWidget.ttY * pdFactorVer,0).

    /* Resize embedded frame */
    IF hWidget:TYPE = 'frame' THEN
      RUN resizeFrame(phFrame, hWidget, pdFactorHor, pdFactorVer). 

    ASSIGN hWidget:WIDTH-PIXELS = TRUNCATE(bWidget.ttWidth * pdFactorHor,0).
    
    IF LOOKUP(hWidget:TYPE,"fill-in,text,literal,button") = 0 THEN
      hWidget:HEIGHT-PIXELS = TRUNCATE(bWidget.ttHeight * pdFactorVer,0) NO-ERROR.

    ASSIGN hWidget = hWidget:NEXT-SIBLING.
  END. /* WHILE VALID-HANDLE(hWidget) */
  
  /* If the window shrinked, resize the frame as well */
  IF pdFactorHor < gdPrevFactorHor THEN
    ASSIGN phFrame:WIDTH-PIXELS = phParent:WIDTH-PIXELS 
           phFrame:VIRTUAL-WIDTH-PIXELS = phParent:WIDTH-PIXELS NO-ERROR.

  IF pdFactorVer < gdPrevFactorVer THEN
    ASSIGN phFrame:HEIGHT-PIXELS = phParent:HEIGHT-PIXELS 
           phFrame:VIRTUAL-HEIGHT-PIXELS = phParent:HEIGHT-PIXELS NO-ERROR.

  phFrame:SCROLLABLE = NO.
END PROCEDURE. /* resizeFrame */


PROCEDURE lockWindow:
  /* Lock / unlock updates that Windows does to windows.
  */
  DEFINE INPUT PARAMETER phWindow AS HANDLE  NO-UNDO.
  DEFINE INPUT PARAMETER plLock   AS LOGICAL NO-UNDO.

  DEFINE VARIABLE iRet AS INTEGER NO-UNDO.

  /* Locking / unlocking windows */
  &GLOBAL-DEFINE WM_SETREDRAW     11
  &GLOBAL-DEFINE RDW_ALLCHILDREN 128
  &GLOBAL-DEFINE RDW_ERASE         4
  &GLOBAL-DEFINE RDW_INVALIDATE    1

  IF NOT VALID-HANDLE(phWindow) THEN RETURN.

  IF plLock THEN
    RUN SendMessageA(phWindow:HWND, {&WM_SETREDRAW}, 0, 0, OUTPUT iRet).
  ELSE 
  DO:
    RUN SendMessageA(phWindow:HWND, {&WM_SETREDRAW}, 1, 0, OUTPUT iRet).
    RUN RedrawWindow(phWindow:HWND, 0, 0, {&RDW_ALLCHILDREN} + {&RDW_ERASE} + {&RDW_INVALIDATE}, OUTPUT iRet).
  END.
END PROCEDURE. /* lockWindow */


PROCEDURE SendMessageA EXTERNAL "user32.dll":
  DEFINE INPUT  PARAMETER hwnd   AS long NO-UNDO.
  DEFINE INPUT  PARAMETER wmsg   AS long NO-UNDO.
  DEFINE INPUT  PARAMETER wparam AS long NO-UNDO.
  DEFINE INPUT  PARAMETER lparam AS long NO-UNDO.
  DEFINE RETURN PARAMETER rc     AS long NO-UNDO.
END PROCEDURE.


PROCEDURE RedrawWindow EXTERNAL "user32.dll":
  DEFINE INPUT PARAMETER v-hwnd  AS LONG NO-UNDO.
  DEFINE INPUT PARAMETER v-rect  AS LONG NO-UNDO.
  DEFINE INPUT PARAMETER v-rgn   AS LONG NO-UNDO.
  DEFINE INPUT PARAMETER v-flags AS LONG NO-UNDO.
  DEFINE RETURN PARAMETER v-ret  AS LONG NO-UNDO.
END PROCEDURE.