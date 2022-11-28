---
layout: single
title: Python and the Model-View-Update GUI Revolution
issue-date: 2022.11.22
author: James Brock, Ramin Honary
tags: Python GUI React MVC
excerpt: Model-View-Update, sometimes called the "Elm Architecture," and Python frameworks that implement this design
---

In roughly the past 10 years,  GUI development, especially on the web,
but also  for other  platforms, has transitioned  to a  design pattern
known  as  the  Model-View-Update  (MVU)  paradigm,  sometimes  called
"Immediate  Mode GUIs,"  or also  the "Elm  Architecture," as  the Elm
programming language made this  idea popular. Web-based MVU frameworks
like React.js  and Vue.js have  taken the  world by storm,  because it
makes GUI  programming much  easier.  It  relieves programmers  of the
burden of managing GUI state by transferring this task to an algorithm
built-in to the framework, this algorithm  is usually referred to as a
"virtual document object model."

At Cross-Compass, the work our  data scientists do involves developing
machine learning  solutions to  solve each customer's  unique problem.
But  what all  solutions  have  in common  is  that  a Python  machine
learning framework is used for the solution. Usually, this is PyTorch,
but  it could  also be  Tensorflow or  Keras as  well. Other  big data
frameworks like  Pandas are also  used. When we deliver  to customers,
the machine  learning solution  often needs  a GUI  written on  top of
scripts in  order for it  to be useful  to end users.

Python provides [TkInter](https://docs.python.org/3/library/tkinter.html )
for  native GUIs,  but the  result  is often  sub-optimal for  various
reasons, not the least of which is  that it is a more traditional MVC,
not an MVU  framework.  Furthermore, TkInter cannot easily  be used to
develop web-based  applications.  Developing  a web-based GUI  is even
more  difficult,  often  requiring another  programming  language  and
runtime (JavaScript  or TypeScript, on  top of Node.js), and  our data
scientists  do  not   specialize  in  the  skills   required  for  web
development with these technologies.

The best  solution for  Cross-Compass is  a GUI  development framework
that allows data scientists to easily write GUI applications that take
a few  inputs, present  a few views  of the data,  and can  be written
entirely in  Python.  In this blog  post, we discuss what  MVU is, and
investigate  two  MVU  frameworks  available  to  Python  programmers:
[StreamLit](https://streamlit.io/    )     for    web     GUIs,    and
[re-wx](https://github.com/chriskiehl/re-wx ) for native GUIs.

# Model-View-Update: Declarative GUIs

For an in-depth discussion of the MVU architecture, we would recommend
you  read  the blog  post  [Model-View-Update  (MVU)  -- How  Does  It
Work?](https://thomasbandt.com/model-view-update  ), by  Thomas Bandt.
In summary, MVU  is similar to the  Model-View-Controller (MVC) design
pattern. In MVC, the "controller" is a callback in the event loop that
responds  to  events from  the  environment,  and is  responsible  for
redrawing parts of the view and updating the model.

The  MVU  pattern differs  only  in  that  the "controller"  does  not
manipulate the  view directly, only  the model can be  modified, which
lets  us simplify  the  controller  to a  single  function called  the
"update"  function.   What instead  redraws  the  view is  a  function
built-in  to  the MVU  framework.   The  model  includes a  tree  data
structure called  a "document," containing drawable  components called
"widgets,"  and this  tree  structure fully  describes,  in a  simple,
**declarative** way, what is to be drawn on screen.

Declarative code tends to be very simple to read, write, and maintain,
because, essentially, one single piece of  code will map to one single
artifact in the running program.  Your code basically becomes a simple
markup language for what the end users use.

Whenever the  update function  responds to an  event and  modifies the
"document"  model tree,  the view  function automatically  redraws the
entire view  by traversing the  entire tree, redrawing each  widget it
finds.  To improve  efficiency, usually a "diff" algorithm  is used to
compare the updated  view (sometimes called the  "virtual document" or
"virtual-DOM") with  the current  view, and only  the portions  of the
view that  have changed between  the virtual document and  the current
document are re-drawn.

Because the framework  is responsible for inspecting the  state of the
document  and re-drawing  the  view automatically,  this relieves  the
burden of  inspecting state and  triggering redrawing portions  of the
view off  of the programmer, and  thus allows them to  focus on simply
manipulating the document model in response to updating events.

# MVU frameworks for Python

Two solutions that  we have had experience with  at Cross-Compass that
provide a MVU to Python programmers are:

 1. [StreamLit](https://streamlit.io/ ) for web-based GUIs

 2. [re-wx](https://github.com/chriskiehl/re-wx ) for native GUIs,
    which us an MVU framework based on the
    [wxPython](https://www.wxpython.org/ ) GUI library.

## [StreamLit](https://streamlit.io/ )

StreamLit provides a web server with a proprietary document model, and
a JavaScript front-end  that can translate this document  model to the
web  browser's  own  "document  object model"  (DOM).   The  StreamLit
document is a black box; all manipulation to the document is done with
easy-to-use StreamLit APIs.   There are APIs to  produce several kinds
of useful  widgets, including  some widgets designed  specifically for
use in machine learning projects:

  - Buttons, toggles, menus, sliders, input fields, tabs
  - "Magic" text, Markdown text
  - Pandas tables (spreadsheet-like)
  - Plotly plots (interactive)
  - Error messages displayed in browser
  - Side bar page navigation
  - Automatic "Loading" indicator as script executes

In fact,  a StreamLit programmer does  not even need to  think about a
document model at all, because the Python script itself is the "update
function"  of the  MVU  framework.  All  one  needs to  do  is call  a
StreamLit API  to **declare** a that  the widget exists in  the Python
script.  Any events that occur in  the GUI front-end (the web browser)
are transmitted  to the StreamLit  server, and the server  rereuns the
entire Python  script in response  to update the model.   Updating the
model is a  simple as inspecting the persistent  state and programming
the  logic that  chooses  to  declare (or  not  declare) a  particular
widget.

The StreamLit  server manages the persistent  state, every web-browser
connection (called a  "session") creates a persistent  state unique to
that session. Here is a simple  app that displays a counter that shows
how many times a button has been clicked.

```python
import StreamLit as st

# ---------- Setup persistent state: ----------

if st.session_state['click_counter'] is not None:
    st.session_state['click_counter'] = 0

# ---------- Construct widgets: ----------

if st.session_state['click_counter'] > 0:

    # Note: writing a string anywhere in the script creates
    # a widget to display that string in the GUI.

    f'Clicked {st.session_state['click_counter']} times.'

else:

    'Please press the button.'

if st.button('Click me'):

    # The act of calling "st.button()" creates the button
    # widget in the document model.

    # The "st.button()" function returns "True" if this
    # script is being run in response to the event that
    # this button has been clicked.

    st.session_state['click_counter'] += 1

else:

    # If this script is being run in response to some
    # other event (not a button click event), we should
    # simply not update the click counter.

    pass

```

All of these API's are very [well
documented](https://docs.streamlit.io ) with many examples, I would
strongly encourage interested readers to browse the
documentation. There is also an ecosystem of third-party plugins to
the StreamLit server that provide additional widgets for various use
cases. Of course, there is also a JavaScript API for extending the
StreamLit server with custom widgets.

### StreamLit caveats:

The  StreamLit server  actually  contains it's  own customized  Python
interpreter  (which is  still implemented  with Python's  own standard
library so no external libraries are necessary), and each GUI updating
script that generates  GUI elements is run in  this custom interpreter
environment.   This allows  the server  to perform  several convenient
functions for Python programmers:

  - Loads library dependencies only once, even if the GUI update
    script is run hundreds of times in response to events.

  - Manages the session state automatically, even when multiple web
    browsers are using the server.

  - Render parts of the GUI as they are constructed, even before
    script execution has completed.

  - Display a spinner widget (indicating to the end user to "please
    wait") when the GUI updating script takes time to run to
    completion.

  - Catch exceptions that occur in the GUI updating scripts, and
    display the stack trace as widgets in the GUI. This makes it very
    easy to find bugs and correct them as the program runs.

Since the update function produces the GUI elements visible in the web
browser,  the programmer  must take  care to  ensure the  GUI updating
scripts  runs as  quickly  as possible.  The script  need  not run  to
completion  for elements  to  become  visible, but  the  GUI will  not
respond to events (mouse clicks, text inputs) until the script has run
to completion.

Multi-threading  is  generally not  possible  in  GUI update  scripts,
although the StreamLit server is multi-threaded.

There  are other  tools to  improve  performance of  the GUI  updating
script.

  - The `st.session_state` can be used to cache the result of
    expensive computations, for example, setting up a Tensorflow
    execution context.

  - The `@st.experimental_memo` function can be used to "memoize"
    function computations.

    ```python
    @st.experimental_memo
    def crunch_data_frame(pandas_data_frame):
        ...
        # Suppose this function takes a while to execute,
        # but only needs to run 1 time.
        ...

    ```

### What is "memoization?"

A memoized function will run only once for each input given to it, and
the return  value of that function  is cached in a  dictionary mapping
that return value to the given  input.  Then, every subsequent call to
that  memoized  function will  return  the  cached value  rather  than
re-computing  it again,  so  long as  the input  to  that function  is
identical to some previous call to that function.

For example, if  the function is called with an  input, say a variable
`pandas_data_frame`, and the pointer  to this `pandas_data_frame` does
not  exist in  the memoizing  dictionary, the  function runs,  and the
return  value of  the function  is mapped  to the  `pandas_data_frame`
pointer. The next time the memoized  function is called with the exact
same input pointer to `pandas_data_frame`,  looking up this pointer in
the  memoizing dictionary  will find  value (a  "cache hit")  that was
returned the  last time this  function was  called, and this  value is
returned rather than actually running the function.

**Be careful** when using pointers  to mutable data, like file paths,
as memoizing  inputs. If the content  of the file changes  in the file
system, but the path does not change,  the file path might result in a
cache  hit  and   return  the  function  return   value,  rather  than
re-computing the new data at that file path.

## [re-wx](https://github.com/chriskiehl/re-wx )

**NOTE:** re-wx is still fairly experimental,  and may not be the best
choice  for  programming  large  applications that  will  need  to  be
maintained over a long period of  time.  It is better suited for small
apps intended as deliverable for short-term contracts.

The re-wx library provides a [React-like](https://reactjs.org/ )
framework (hence "re") around the [wxPython](https://www.wxpython.org/
) widget library (hence "wx").  The wxPython library is itself is a
library providing Python language bindings to the
[wxWidgets](https://www.wxwidgets.org/ ) library, which is a
platform-independent GUI library that runs well on Windows, Mac OS,
and Linux.

The  document model  of  the  re-wx library  is  a  tree of  "element"
nodes. Every element is simply a  dictionary with 2 fields: `type` and
`props`.  The `type`  field  indicates which  wxWidget constructor  to
call, the `props`  field is a dictionary that  indicates exactly which
arguments are to  be passed to the constructor when  the view function
runs. The  `props` field is  a dictionary often contains  a `children`
property, and  the `children`  of the Element  create branches  of the
tree data structure.

So  when  constructing your  GUI  document,  rather than  call  widget
constructor  functions  directly,  you  "freeze" the  calls  to  these
functions as  an element in a  tree of elements. The  of elements tree
thus  become  the  **declarative**  data  structure  of  the  "virtual
document," which re-wx can automatically render as a view.

```python
from rewx.components import Frame, StaticText, Button

clicked = False

def click_handler():
    # Toggle the 'clicked' global variable
    clicked = not clicked

element = \
  { 'type': Frame,
    'props':
    { 'title': "App Main",
      'children':
      [ { 'type': StaticText,
          'props':
          { 'label':
              "Hello, world!" if not clicked else
                "Thanks for clicking!"
          },
        },
        { 'type': Button,
          'props':
          { 'label': 'Click me!',
            'on_click': click_handler,
          }
        }
      ]
    }
  }
```

For the  sake of simplifying  the code,  a function called  `wsx()` is
provided which takes the `type`, `props`, and `children` as a list (in
that order) without  needing to specify the  keywords `type`, `props`,
and `children`  each time.   For example, the  above element  could be
rewritten with `wsx()` like so:

```python
from rewx.components import Frame, StaticText
from rewx import wsx 

clicked = False

def click_handler():
    # Toggle the 'clicked' global variable
    clicked = not clicked

element = \
  wsx(
    [ Frame,
      {'title': "App Main"},
      [ StaticText,
        { 'label':
            "Hello, world!" if not clicked else
              "Thanks for clicking!"
        },
      ],
      [ Button,
        { 'label': 'Click me!',
          'on_click': click_handler,
        },
      ],
    ])
```

As you can see, it is a  slightly more concise way to declare the same
tree  structure,  without needing  to  write  the `type`  and  `props`
keyword for each element node.

### Rendering, and the main event loop

Simply use the `rewx.render()` function, which does all of the work of
constructing every element  and all children in the  element tree, and
inserting all  children into  the appropriate widgets.   When `render`
steps  through  an   element  starting  with  a   `Frame`,  the  frame
constructor is called which creates a new window for your app, and all
children of the `Frame` are  rendered as widgets contained within that
frame.  The  wxPython library also  ensures that deleting  one element
will also delete the children of that element.

```python
import wx 
from rewx.components import Frame, StaticText, Button
from rewx import wsx, render

clicked = False

def click_handler():
    ...

element = ...

if __name__ == '__main__':
    app = wx.App()
    frame = render(element, None) 

    # 'frame' is not used, here, but you can keep the
    # handle to manipulate the main app window.

```

**NOTE:** that  at this  time, unfortunately, the  `render()` function
does not actually perform a "diff" on the virtual document model. What
this  means is,  after every  single event  in the  GUI (every  button
click,  every text  entry), causes  the  entire document  model to  be
deleted and  a new  document model  to be  constructed. While  the new
model  is  being constructed,  the  GUI  freezes.   This does  have  a
performance penalty,  and for GUIs  with many elements, end  users may
begin to notice the GUI start  to feel "heavy" or "slow." Hopefully at
some point in the near future, this issue will be resolved.

### Grouping widgets into larger components

A class  is provided  so that you  do not need  to store  the stateful
parts of your app in the  global variable context. Simply declare your
own class extending the `rewx.Component` class. Lets rewrite the above
example as a subclass of `rewx.Component`.

```python
from rewx import wsx, render, Component
from rewx.components import Frame, StaticText, Button

class HelloApp(Component):
    def ___init___():
        self.clicked = False;

    def click_handler(self):
        # Toggle the 'clicked' global variable
        self.clicked = not self.clicked

    def render(self):
        return wsx(
          [ Frame,
            {'title': "App Main"},
            [ StaticText,
              { 'label':
                  "Hello, world!" if not self.clicked else
                    "Thanks for clicking!"
              },
            ],
            [ Button,
              { 'label': 'Click me!',
                'on_click': self.click_handler,
              },
            ],
          ])

if __name__ == '__main__':
    app = wx.App()
    element = HelloApp()
    frame = render(element.render(), None) 

```

# Conclusions

We have  seen two  practical implementations of  the Model-View-Update
(MVU)  design pattern:  StreamLit for  the web,  and re-wx  for native
applications   (via   wxPython).   We   have   also   seen  in   these
implementations  how the  MVU  design pattern  greatly simplifies  the
programming of GUI applications by reducing most of the programming to
merely **declaring**  the document  model of the  GUI. Changes  to the
structure take place by inspecting the state of the program and making
decisions to declare (or not declare) portions of the document tree.


Then the framework provides some mechanism for rendering the document
as a  view. In StreamLit,  the rendering  mechanism is the  GUI update
script interpreter  internal to  the StreamLit  server. In  re-wx, the
rendering mechanism is simply  the `rewx.render()` API function called
in the main function of the program.

The  MVU framework  also takes  control  of the  event listening,  and
dispatches  events  by  simply  re-running  the  update  function.  In
StreamLit,  the update  function  is the  entire  Python script  which
declares a  new GUI document  structure every time  it is run.  In the
case of  re-wx, the update  function is  the `render()` method  of the
`rewx.Component`  class,  which  simply   returns  a  new  declarative
structure.
