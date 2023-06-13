# Why I use PyQt

  - Developed some Python scripts that used **OpenCV**
      - "Pattern Matching Kit"
      - "Image Cropping Kit"
  - OpenCV provides a API for GUI tools based on PyQt
  - Decided to use PyQt directly instead of OpenCV specific API

## Other reasons to use PyQt

  - **Cross platform** -- write once, run on multiple platforms.
  - **Rapid prototyping** -- less combersome than C++
  - **Native widgets** -- makes use of native widgets when possible
  - **2D graphics model** -- complete API for interactive 2D visualizations

# Part 1: What is Qt

Qt is a cross-platform desktop computing GUI framework

  - Free software (LGPL)
    - Option of buying commercial licenses
  - Develops native apps for
    - Windows, MacOS
    - Linux
      - Core of the KDE Plasma desktop environment

## Qt History

  - Originally developed for Linux
  - Actively maintained since 1995
  - Python bindings maintained since 1998
  - Changed corporate ownership several times (Trolltech, Nokia, now
    "The Qt Company").
  - (pronounced "Cute")

## Model-View-Controller (MVC)

  - Somewhat different from Model-View-Update (React, Vue)
  - Must be careful about model state
  - **My opinion:** best used for small apps, developing larger apps
    require paying for professional tooling

## Programming languages

  - Primarily C++
    - has Python and JavaScript wrappers
  - Qt Creator (optional)
    - Visual GUI builder tools
  - QML (optional)
    - an XML schema for declarative GUI

## Proprietary developer tools (C++ and QML only)

  - Qt Design Studio
  - Qt Quality Assurance tools
      - Static analysis (e.g. code coverage)
      - Automated GUI testing
      - *(Third-party apps that were acquired by The Qt Company)*
  - *(I use none of the Qt professional tools, just Emacs)*

## Qt Designer (free)

![](../../../assets/images/2023-05-23-GUIs-in-PyQt5-pics/qt-designer-screenshot.png)

## Qt Design Studio (1)

![](../../../assets/images/2023-05-23-GUIs-in-PyQt5-pics/qt-design-studio_image-png-Dec-10-2020-04-03-18-99-PM.png)

## Qt Design Studio (2)

![](../../../assets/images/2023-05-23-GUIs-in-PyQt5-pics/qt-design-studio_connection-editor.png)

## Froglogic "Coco" code covereage analysis

(Originally a third-party tool acquired by *The Qt Company*)

![(Source froglogic.com)](../../../assets/images/2023-05-23-GUIs-in-PyQt5-pics/froglogic-coco_coverage-770x542.png)

## Provides many extensions

  - OpenGL views (built-in)
  - 3D widgets, modeling controlls
  - SQL database integration, ORM
  - Multimedia, AV codecs and playback
  - WebKit web views
  - Sensors, GPS, touch screen, BlueTooth, game pads, etc.

# KDE Plasma apps showcase

Brief photo slideshow of KDE apps:

  - <https://apps.kde.org/>

## KDE Plasma: desktop environment for Linux

![(source OMGBuntu)](../../../assets/images/2023-05-23-GUIs-in-PyQt5-pics/plasma-5_omgbuntu.jpg)

## Calindori: calendar app

![](../../../assets/images/2023-05-23-GUIs-in-PyQt5-pics/calindori_screenshot.png)

## KCalc: simple desktop calculator

![](../../../assets/images/2023-05-23-GUIs-in-PyQt5-pics/kcalc_statistics-screenshot.png)

## Dolphin: extensible file browser

![](../../../assets/images/2023-05-23-GUIs-in-PyQt5-pics/dolphin_pop-up-terminal-screenshot.png)

## "Kig" high-school geometry learning tool

![](../../../assets/images/2023-05-23-GUIs-in-PyQt5-pics/kig_screenshot.png)

## KWave: waveform visualizer

![](../../../assets/images/2023-05-23-GUIs-in-PyQt5-pics/kwave_screenshot.png)

## Marble: world atlas app

![](../../../assets/images/2023-05-23-GUIs-in-PyQt5-pics/marble_screenshot.png)

## KMPlot: graphing calculator

![](../../../assets/images/2023-05-23-GUIs-in-PyQt5-pics/kmplot_screenshot.png)

## Calligra: like Microsoft Office suite

!["Plan" app](../../../assets/images/2023-05-23-GUIs-in-PyQt5-pics/calligra-suite_plan_screenshot.png)

## Okular: PDF reader with annotation tool

![](../../../assets/images/2023-05-23-GUIs-in-PyQt5-pics/okular_annotation-screnshot.png)

## KEXI: like Microsoft Access

![Query designer](../../../assets/images/2023-05-23-GUIs-in-PyQt5-pics/kexi_3-1-query-designer_screenshot.png)

## KEXI: like Microsoft Access

![Form builder](../../../assets/images/2023-05-23-GUIs-in-PyQt5-pics/kexi_3-0-gui_screenshot.png)

## KRWard: IDE for R Programming Language

![](../../../assets/images/2023-05-23-GUIs-in-PyQt5-pics/rkward_r-lang-frontend_screenshot.png)

## KLabPlot: Matlab-like app

![plots example](../../../assets/images/2023-05-23-GUIs-in-PyQt5-pics/klabplot_basic-plots-linux-screenshot.png)

## KLabPlot: Matlab-like app

![](../../../assets/images/2023-05-23-GUIs-in-PyQt5-pics/klabplot_space-debris-linux-screenshot.png)

## KdenLive: non-linear video editor

![](../../../assets/images/2023-05-23-GUIs-in-PyQt5-pics/kdenlive-screenshot.png)

# Part 2

Basics of GUI app development in Python

## PyQt: Python Bindings

  - Maintained by "Riverbank Computing" company, UK
  - Non-trivial Python bindings
      - Converting Python data to C++ native data
      - Contending with Python garbage collection
      - Must make callbacks written in Python callable from C++
      - Mechanisms for Python inhereitence and method overriding to work
        the same as in C++
      - Providing PEP 484 type hinting for all APIs
  - <https://www.riverbankcomputing.com/static/Docs/PyQt5/index.html>

## PyQt: Python Documentation

  - Most documentation written by third parties
  - Easiest to read C++ documentation and hand-translate examples to
    Python.
  - Python Wiki: <https://wiki.python.org/moin/PyQt/>
  - Book: Michael Herrmann, "*Python and Qt: the best parts*"
  - *(I was able to learn from free online resources.)*

## Building blocks (1): widges, events, properties

  - **Widgets:** tab bars, scroll bars, push buttons, list views,
    pull-down menus
  - **Event handlers:** callback functions responding to *primitive*
    mouse/keyboard events.
  - **Properties:** fields with getters and setters, changes
    automatically updates widget drawing on screen
      - e.g. a text fields current string

## Building blocks (2): signals, slots, connections

  - **Signals:** complex combination of primitive events that trigger
    widget-specific actions
      - e.g. when list view item is double-clicked
  - **Slots:** public methods used as callbacks, can be "connected" to
    signals to be triggered on certain events.
  - **Connections:** are an object that maintain a link between a signal
    and slot. Can be disconnected/deleted
  - Using these building blocks, simple interfaces can be designed
    without the need for custom widgets.

## Object oriented programming: method overriding

  - When you want to combine multiple widgets into a single more complex
    widget.
  - Signals and slots are usually not enough.
  - A custom widget inherits from a parent widget (e.g. `QWidget` or
    `QListView`)
  - Override signals and slots to customize behavior (e.g. update state
    variables)

<https://doc.qt.io/qt-5/qtwidgets-index.html>

## Declaring your own reusable widget

  - Most code occurs in `__init__()` constructor
  - Create sub-widgets and layout
  - Place sub-widgets into layout object:
      - `QBoxLayout`
      - `QFormLayout`
      - `QGridLayout`
      - `QStackedLayout`
  - Define slots to update model: `@pyqtSlot()` decorator
  - Connect child widget signals to slots

## The **Graphics View Framework**

  - Interactive 2D visualizations
  - Arbitrarily sized canvas (`QGraphicsScene`)
  - Easily renders large number of objects (`QGraphicsItem`)
  - Graphics view widget provides (`QGraphicsView`)
      - translating (with scroll bars)
      - scaling
      - rotation

<https://doc.qt.io/qt-6/graphicsview.html>

## Diagram Scene Example (tutorial)

![](../../../assets/images/2023-05-23-GUIs-in-PyQt5-pics/diagramscene.png)

<https://doc.qt.io/qt-5/qtwidgets-graphicsview-diagramscene-example.html>

## Pattern Matching Tool

I created an app to run a pattern matching algorithm using OpenCV to
select parts of a "target" image that are similar to a "pattern"
image. There is a slider to interactively controlo the smilarity
threshold, making it easier to discover the optimal threshold value to
be used.

![](../../../assets/images/2023-05-23-GUIs-in-PyQt5-pics/screenshot_pattern-matching.png)

## Image Crop Tool

I created an app to run the [ORB feature detection algorithm](https://en.wikipedia.org/wiki/Oriented_FAST_and_rotated_BRIEF)
and automatically crop features from a list of images relative to a
rectangle drawn on a reference image.

![](../../../assets/images/2023-05-23-GUIs-in-PyQt5-pics/screenshot_image-crop.png)

## Conclusion

  - Large improvement for little effort
    
      - It requires relatively few lines of code to create a small,
        single-window GUI.

  - Consider using if your project could be improved with simple
    interactive widgets.

