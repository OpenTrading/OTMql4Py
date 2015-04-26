# -*-mode: python; py-indent-offset: 4; tab-width: 8; encoding: utf-8-dos; coding: utf-8 -*-

import sys

from Queue import Queue
from Tkinter import Tk, Frame, Scrollbar, Text, Menu, \
    YES, BOTH, SUNKEN, END, INSERT, RIGHT, LEFT
from tkMessageBox import showerror

class ScrolledText(Frame):

    def __init__(self, parent=None, text='', sFile=None):
        Frame.__init__(self, parent)
        self.pack(expand=YES, fill=BOTH)                 # make me expandable
        self.make_widgets()
        self.settext(text, sFile)

    def make_widgets(self):
        sbar = Scrollbar(self)
        text = Text(self, relief=SUNKEN)
        sbar.config(command=text.yview)                   # xlink sbar and text
        text.config(yscrollcommand=sbar.set)             # move one moves other
        sbar.pack(side=RIGHT, fill=YES)                   # pack first=clip last
        text.pack(side=LEFT, expand=YES, fill=BOTH)       # text clipped first
        self.text = text

    def settext(self, text='', sFile=None):
        if sFile:
            text = open(sFile, 'r').read()
        self.text.delete('1.0', END)                     # delete current text
        self.text.insert('1.0', text)                    # add at line 1, col 0
        self.text.mark_set(INSERT, '1.0')                # set insert cursor
        self.text.focus()                                # save user a click

    def gettext(self):                                   # returns a string
        return self.text.get('1.0', END+'-1c')           # first through last

class Shell(ScrolledText):

    def __init__(self, parent=None):
        ScrolledText.__init__(self, parent=None)
        self.charque = Queue()
        self.lineque = Queue()
        # sys.stdout = self
        # sys.stderr = self
        # sys.stdin = self

    def readline(self):
        return self.lineque.get()

    def write(self, stuff):
        self.text.insert("end", stuff)
        self.text.yview_pickplace("end")
        # self.master.update()

    def flush(self):
        self.master.update()
        return None

    def writelines(self, lines):
        for line in lines:
            self.write(line)


class MenuBar(Menu):

    def __init__(self, *args, **kwargs):
        Menu.__init__(self, *args, **kwargs)
        self.create_widgets()
        self.master = args[0]

    def not_impl(self):
        showerror(message='Not implemented')

    def create_widgets(self):
        file_menu = Menu(self)
        file_menu.add_command(label='Open', command=self.not_impl)
        file_menu.add_command(label='Save', command=self.not_impl)
        file_menu.add_command(label='Quit', command=self.quit)
        self.add_cascade(label="File", underline=1, menu=file_menu)

    def quit(self):
        self.master.destroy()

class MainFrame(Frame):
    def __init__(self, parent=None, title=None, **kwargs):
        Frame.__init__(self, parent)
        self.pack(expand=YES, fill=BOTH)
        self.create_widgets(title)
        self.master = parent

    def create_widgets(self, title=None):
        self.menu_bar = MenuBar(self.master)
        self.master.config(menu=self.menu_bar)
        self.master.title(title or 'papy_gui')

        self.shell = Shell(self)
        self.shell.pack()


def test():
    root = Tk()
    frame = MainFrame(root, title='Python IO')
    sys.stdout = frame.shell
    print "Hello World"
    sys.stdout.flush()
    root.mainloop()
    try:
        root.destroy()
    except:
        pass
    sys.stdout = sys.__stdout__

