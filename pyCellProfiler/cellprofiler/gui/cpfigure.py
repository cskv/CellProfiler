""" cpfigure.py - provides a frame with a figure inside

"""
__version__ = "$Revision: 1 "

import numpy
import wx
import matplotlib
import matplotlib.cm
import matplotlib.patches
import matplotlib.backends.backend_wxagg

from cellprofiler.gui import get_icon

def create_or_find(parent=None, id=-1, title="", 
                   pos=wx.DefaultPosition, size=wx.DefaultSize,
                   style=wx.DEFAULT_FRAME_STYLE, name=wx.FrameNameStr,
                   subplots=None ):
    """Create or find a figure frame window"""
    if parent:
        window = parent.FindWindowByName(name)
        if window:
            return window
    return CPFigureFrame(parent, id, title, pos, size, style, name, subplots)

MENU_FILE_SAVE = wx.NewId()
MENU_ZOOM_IN = wx.NewId()
MENU_ZOOM_OUT = wx.NewId()

MODE_NONE = 0   # mouse tool mode - do nothing
MODE_ZOOM = 1   # mouse tool mode - zoom in

class CPFigureFrame(wx.Frame):
    """A wx.Frame with a figure inside"""
    
    def __init__(self, parent=None, id=-1, title=None, 
                 pos=wx.DefaultPosition, size=wx.DefaultSize,
                 style=wx.DEFAULT_FRAME_STYLE, name=wx.FrameNameStr, 
                 subplots=None):
        """Initialize the frame:
        
        parent   - parent window to this one, typically CPFrame
        id       - window ID
        title    - title in title bar
        pos      - 2-tuple position on screen in pixels
        size     - 2-tuple size of frame in pixels
        style    - window style
        name     - searchable window name
        subplots - 2-tuple indicating the layout of subplots inside the window
        """
        super(CPFigureFrame,self).__init__(parent, id, title, pos, size, style, name)
        self.mouse_mode = MODE_NONE
        self.zoom_stack = []
        self.mouse_down = None
        sizer = wx.BoxSizer()
        self.figure = figure= matplotlib.figure.Figure()
        self.panel  = matplotlib.backends.backend_wxagg.FigureCanvasWxAgg(self,-1,self.figure) 
        self.SetSizer(sizer)
        sizer.Add(self.panel,1,wx.EXPAND)
        self.Bind(wx.EVT_PAINT,self.on_paint)
        if subplots:
            self.subplots = numpy.zeros(subplots,dtype=object)
            self.zoom_rects = numpy.zeros(subplots,dtype=object)
        self.add_menu()
        self.figure.canvas.mpl_connect('button_press_event', self.on_button_press)
        self.figure.canvas.mpl_connect('motion_notify_event', self.on_mouse_move)
        self.figure.canvas.mpl_connect('button_release_event', self.on_button_release)
        self.SetIcon(get_icon())
        self.Fit()
        self.Show()
    
    def add_menu(self):
        self.MenuBar = wx.MenuBar()
        self.__menu_file = wx.Menu()
        self.__menu_file.Append(MENU_FILE_SAVE,"&Save")
        self.MenuBar.Append(self.__menu_file,"&File")
        
        self.__menu_zoom = wx.Menu()
        self.__menu_item_zoom_in = \
            self.__menu_zoom.AppendCheckItem(MENU_ZOOM_IN,"&Zoom in")
        wx.EVT_MENU(self,MENU_ZOOM_IN,self.on_zoom_in)
        self.__menu_item_zoom_out = \
            self.__menu_zoom.Append(MENU_ZOOM_OUT,"&Zoom out")
        wx.EVT_MENU(self,MENU_ZOOM_OUT,self.on_zoom_out)
        self.__menu_item_zoom_out.Enable(len(self.zoom_stack) > 0)
        self.MenuBar.Append(self.__menu_zoom, "&Zoom")
    
    def on_paint(self, event):
        dc = wx.PaintDC(self)
        self.panel.draw(dc)
    
    def on_zoom_in(self,event):
        if self.mouse_mode == MODE_NONE:
            self.mouse_mode = MODE_ZOOM
        else:
            self.mouse_mode = MODE_NONE
            
    def on_zoom_out(self, event):
        if self.subplots != None and len(self.zoom_stack) > 0:
            old_extents = self.zoom_stack.pop()
            for subplot in self.subplots.flatten():
                if subplot:
                    subplot.set_xlim(old_extents[0][0],old_extents[0][1])
                    subplot.set_ylim(old_extents[1][0],old_extents[1][1])
        self.__menu_item_zoom_out.Enable(len(self.zoom_stack) > 0)
        self.Refresh()
    
    def on_button_press(self, event):
        if event.inaxes:
            self.mouse_down = (event.xdata,event.ydata)
            for x in range(self.subplots.shape[0]):
                for y in range(self.subplots.shape[1]):
                    plot = self.subplots[x,y]
                    if plot:
                        self.zoom_rects[x,y] = matplotlib.patches.Rectangle(self.mouse_down, 1,1,fill=False,edgecolor='red',linewidth=1,linestyle='solid')
                        plot.add_patch(self.zoom_rects[x,y])
            self.figure.canvas.draw()
            self.Refresh()
            
    
    def on_mouse_move(self, event):
        if event.inaxes and self.mouse_down:
            x0 = min(self.mouse_down[0], event.xdata)
            x1 = max(self.mouse_down[0], event.xdata)
            y0 = min(self.mouse_down[1], event.ydata)
            y1 = max(self.mouse_down[1], event.ydata)
            for zoom_rect in self.zoom_rects.flatten():
                if zoom_rect:
                    zoom_rect.set_x(x0)
                    zoom_rect.set_y(y0)
                    zoom_rect.set_width(x1-x0)
                    zoom_rect.set_height(y1-y0)
            self.figure.canvas.draw()
            self.Refresh()
    
    def on_button_release(self,event):
        if event.inaxes and self.mouse_down:
            x0 = min(self.mouse_down[0], event.xdata)
            x1 = max(self.mouse_down[0], event.xdata)
            y0 = min(self.mouse_down[1], event.ydata)
            y1 = max(self.mouse_down[1], event.ydata)
            self.mouse_down = None
            old_limits = None
            for x in range(self.subplots.shape[0]):
                for y in range(self.subplots.shape[1]):
                    if self.zoom_rects[x,y]:
                        self.zoom_rects[x,y].remove()
                        self.zoom_rects[x,y] = 0
                    if self.subplots[x,y]:
                        if not old_limits:
                            old_x0,old_x1 = self.subplots[x,y].get_xlim()
                            old_y0,old_y1 = self.subplots[x,y].get_ylim()  
                            old_limits = ((old_x0, old_x1),
                                          (old_y0, old_y1))
                        self.subplots[x,y].set_xlim(x0,x1)
                        self.subplots[x,y].set_ylim(y0,y1)
            self.zoom_stack.append(old_limits)
            self.figure.canvas.draw()
            self.Refresh()
            self.__menu_item_zoom_out.Enable(True)
            
    def subplot(self,x,y):
        """Return the indexed subplot
        
        x - column
        y - row
        """
        if self.subplots[x,y] == 0:
            rows, cols = self.subplots.shape
            plot = self.figure.add_subplot(cols,rows,x+y*rows+1)
            self.subplots[x,y] = plot
        return self.subplots[x,y]
    
